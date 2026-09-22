"""Specification checks only: no production engine, real DB, mobile or R1 claims."""
from __future__ import annotations
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from contract_model import ContractModel, canonical, divide, initial_state, rng_next, strict_json, uniform
import release_scope

ROOT = Path(__file__).resolve().parents[1]

def request(identity: str, action: str, **fields) -> dict:
    return {'id':identity,'actor':'hero','action':action,**fields}

class ContractCases(unittest.TestCase):
    def test_explicit_cases(self):
        data=strict_json((ROOT/'conformance/cases.json').read_text())
        self.assertEqual(data['fixture_version'],1)
        for case in data['cases']:
            with self.subTest(case=case['id']):
                model=ContractModel(case['credit'])
                for i,step in enumerate(case['steps']):
                    with self.subTest(step=i):
                        self.assertEqual(model.invoke(step['request'],**step['options']),step['result'])
                        self.assertEqual(model.memory,step['state'])
                        self.assertEqual(model.durable,step['state'])
                        self.assertEqual(canonical(model.memory),canonical(step['state']))

    def ready(self) -> ContractModel:
        model=ContractModel()
        model.invoke(request('a','activate'))
        model.invoke(request('n','move',input={'direction':'north'}))
        return model

    def test_failed_attempt_commits_known_next_rng_and_replays(self):
        model=self.ready()
        words=[27274249,25704967,31982592,12605441]
        model.memory['rng']=words[:]; model.durable=copy.deepcopy(model.memory)
        result=model.invoke(request('fail','take'))
        self.assertEqual((result['kind'],result['code']),('accepted','check_failed'))
        self.assertEqual(model.memory['rng'],[15224335,29364750,272377353,1125134346])
        self.assertEqual(model.memory['lantern'],'green')
        snapshot=canonical(model.memory)
        replay=model.invoke(request('fail','take',view='view:0'))
        self.assertEqual(replay,{**result,'delivery':'replay'})
        self.assertEqual(canonical(model.memory),snapshot)
        next_rng=rng_next(model.memory['rng'])[1]
        model.invoke(request('new-attempt','take'))
        self.assertEqual(model.memory['rng'],next_rng)

    def test_rejection_has_no_game_advancement_and_stable_receipt(self):
        model=ContractModel(); before=canonical(model.memory)
        a=model.invoke(request('x','take'))
        self.assertEqual((a['kind'],a['code']),('rejected','not_present'))
        self.assertEqual(canonical(model.memory),before)
        model.invoke(request('n','move',input={'direction':'north'}))
        b=model.invoke(request('x','take'))
        self.assertEqual(b,{**a,'delivery':'replay'})
        self.assertEqual(model.memory['lantern'],'green')

    def test_unauthorized_cannot_read_receipt(self):
        model=self.ready(); model.invoke(request('x','take'))
        for req,auth in [(request('x','take'),False),({**request('x','take'),'actor':'other'},True)]:
            with self.subTest(req=req):
                before=copy.deepcopy(model.receipts)
                self.assertEqual(model.invoke(req,authorized=auth)['code'],'unauthorized')
                self.assertEqual(model.receipts,before)

    def test_changed_intent_conflicts_but_transport_metadata_does_not(self):
        model=self.ready(); original=request('x','take'); first=model.invoke(original)
        before=canonical(model.memory)
        for change in [{'input':{'maximum_price':1}},{'targets':['lantern','other']},{'action':'drop'}]:
            with self.subTest(change=change):
                self.assertEqual(model.invoke({**original,**change})['code'],'integrity_conflict')
                self.assertEqual(canonical(model.memory),before)
        replay=model.invoke({**original,'session':'new','seq':999,'route':'other','view':'view:0'})
        self.assertEqual(replay,{**first,'delivery':'replay'})

    def test_target_order_and_semantic_continuation_are_in_digest(self):
        model=self.ready(); a=request('i','take',targets=['a','b'])
        self.assertNotEqual(model._intent(a),model._intent({**a,'targets':['b','a']}))
        a=request('i','choose',input={'choice_id':'carry','continuation_id':'one'})
        self.assertNotEqual(model._intent(a),model._intent({**a,'input':{'choice_id':'carry','continuation_id':'two'}}))

    def test_consumed_choice_replays_but_altered_choice_conflicts(self):
        model=self.ready(); model.invoke(request('x','take'))
        choice=request('c','choose',input={'choice_id':'leave','continuation_id':'lantern-offer-1'})
        first=model.invoke(choice); self.assertEqual(first['code'],'choice_completed')
        model.invoke(request('s','move',input={'direction':'south'}))
        state=copy.deepcopy(model.memory)
        self.assertEqual(model.invoke({**choice,'view':'view:0'}),{**first,'delivery':'replay'})
        self.assertEqual(model.memory,state) # Historical receipt cannot replace current view/state.
        self.assertEqual(model.invoke({**choice,'input':{'choice_id':'carry','continuation_id':'lantern-offer-1'}})['code'],'integrity_conflict')
        self.assertEqual(model.invoke({**choice,'id':'new-choice'})['code'],'invalid_choice')

    def test_new_stale_invocation_rejects_without_game_change(self):
        model=self.ready(); state=canonical(model.memory)
        self.assertEqual(model.invoke(request('x','take',view='view:0'))['code'],'stale_view')
        self.assertEqual(canonical(model.memory),state)

    def test_definite_rollback_does_not_publish_or_advance(self):
        model=self.ready(); before=copy.deepcopy(model.memory); count=len(model.published)
        result=model.invoke(request('x','take'),fault='before_commit')
        self.assertEqual(result['code'],'rolled_back')
        self.assertEqual(model.memory,before); self.assertEqual(model.durable,before)
        self.assertEqual(len(model.published),count); self.assertNotIn('x',model.receipts)
        self.assertEqual(model.invoke(request('x','take'))['code'],'taken')

    def test_pending_commit_absent_receipt_does_not_allow_rerun(self):
        for committed in [True,False]:
            with self.subTest(committed=committed):
                model=self.ready(); before=copy.deepcopy(model.memory)
                self.assertEqual(model.invoke(request('x','take'),fault='commit_pending')['code'],'commit_pending')
                self.assertNotIn('x',model.receipts)
                self.assertEqual(model.recover()['code'],'commit_pending')
                self.assertEqual(model.invoke(request('other','take'))['code'],'commit_pending')
                self.assertEqual(model.memory,before)
                model.settle(committed); model.recover()
                result=model.invoke(request('x','take'))
                self.assertEqual(result['code'],'taken')
                self.assertEqual(result['delivery'],'replay' if committed else 'new')
                self.assertEqual(model.memory['revision'],3)
                self.assertEqual(model.memory['rng'],[7,0,1026,12288])

    def test_after_commit_before_memory_recovers_and_replays(self):
        model=self.ready(); before=copy.deepcopy(model.memory)
        self.assertEqual(model.invoke(request('x','take'),fault='after_commit_before_memory')['code'],'commit_unknown')
        self.assertEqual(model.memory,before); self.assertEqual(model.durable['quest'],'resolved')
        self.assertEqual(model.invoke(request('x','take'))['code'],'commit_pending')
        model.recover()
        self.assertEqual(model.invoke(request('x','take'))['delivery'],'replay')
        self.assertEqual(model.memory,model.durable)

    def test_response_loss_does_not_duplicate_effects(self):
        model=self.ready()
        self.assertEqual(model.invoke(request('x','take'),fault='after_memory_before_response')['code'],'response_lost')
        count=len(model.published); model.recover()
        self.assertEqual(model.invoke(request('x','take'))['delivery'],'replay')
        self.assertEqual(len(model.published),count)

    def test_bad_envelope_and_fault_leave_no_mutations(self):
        model=ContractModel(); before=copy.deepcopy(model.memory)
        for req in [[],{},request('x','look',unknown=True),request('x','look',targets='wrong')]:
            with self.subTest(req=req):
                self.assertEqual(model.invoke(req)['kind'],'rejected')
                self.assertEqual(model.memory,before); self.assertEqual(model.receipts,{})
        with self.assertRaisesRegex(ValueError,'unknown_fault'):
            model.invoke(request('x','activate'),fault='typo')
        self.assertEqual(model.memory,before); self.assertEqual(model.receipts,{})

    def test_malformed_direction_is_typed_rejection(self):
        model=ContractModel()
        self.assertEqual(model.invoke(request('x','move',input={'direction':[]}))['code'],'invalid_input')
        self.assertEqual(model.memory,initial_state())

class NumericCases(unittest.TestCase):
    def test_known_rng_output_and_next_state(self):
        vectors=strict_json((ROOT/'conformance/numeric-vectors.json').read_text())
        state=vectors['initial_rng']
        for row in vectors['rng_steps']:
            output,state=rng_next(state)
            self.assertEqual(output,row['raw']); self.assertEqual(state,row['state'])

    def test_signed_division_known_answers(self):
        vectors=strict_json((ROOT/'conformance/numeric-vectors.json').read_text())
        for row in vectors['division']:
            self.assertEqual(divide(row['a'],row['b']),(row['q'],row['r']))
        for a,b in [(1,0),(True,1),(1<<53,1),(1,False)]:
            with self.assertRaises(ValueError): divide(a,b)

    def test_strict_numeric_and_encoding_cases(self):
        vectors=strict_json((ROOT/'conformance/numeric-vectors.json').read_text())
        for text in vectors['invalid_json']:
            with self.subTest(text=text),self.assertRaises((ValueError,UnicodeError)):
                strict_json(text)
        for row in vectors['canonical']:
            self.assertEqual(canonical(strict_json(row['input'])),row['expected'].encode())
        self.assertEqual(canonical({'s':'\b\t\n\f\r\x01"\\'}),b'{"s":"\\b\\t\\n\\f\\r\\u0001\\"\\\\"}')

    def test_rng_bounds_and_rejection_sampling(self):
        for words in [[0,0,0,0],[1,2,3],[-1,2,3,4],[True,2,3,4]]:
            with self.assertRaises(ValueError): rng_next(words)
        for bound in [0,-1,True,(1<<32)+1]:
            with self.assertRaises(ValueError): uniform([1,2,3,4],bound)
        with patch('contract_model.rng_next',side_effect=[((1<<32)-1,[1,1,1,1]),(5,[2,2,2,2])]):
            self.assertEqual(uniform([1,2,3,4],10),(5,[2,2,2,2]))
        with patch('contract_model.rng_next',return_value=((1<<32)-1,[1,1,1,1])):
            with self.assertRaisesRegex(ValueError,'rng_budget_exhausted'):
                uniform([1,2,3,4],10,max_draws=2)

class PlanningCases(unittest.TestCase):
    def setUp(self): self.data=json.loads((ROOT/'release-scope.json').read_text())
    def test_scope_generated_and_links_match(self):
        release_scope.validate(self.data); release_scope.check_links()
        self.assertEqual(release_scope.render(self.data),(ROOT/'release-scope.md').read_text())
    def test_proof_subset_does_not_shrink_chapter(self):
        proof,_,_=release_scope.applicable(self.data,'proof')
        full,_,gates=release_scope.applicable(self.data,'chapter_one')
        self.assertLess(len(proof),len(full)); self.assertEqual(len(full),37)
        self.assertIn('TRANSACTION',gates); self.assertNotIn('ESCROW',gates); self.assertNotIn('INSTANCE',gates)
        self.assertIn('ESCROW',release_scope.applicable(self.data,'chapter_three')[2])
    def test_mutated_scope_inputs_fail(self):
        mutations=[lambda d:d['capabilities'].pop(), lambda d:d['capabilities'].append(d['capabilities'][0]),
                   lambda d:d['always_gates'].remove('AUTHORITY'),lambda d:d['chapter_one'].update(rooms=4),
                   lambda d:d['capabilities'][0].update(first_required='chapter_three'),
                   lambda d:d['features'][0]['gates'].append('unknown'),
                   lambda d:d['features'].append(d['features'][0]),
                   lambda d:d.update(status='accepted'),lambda d:d.update(schema_version=True)]
        for mutate in mutations:
            data=copy.deepcopy(self.data); mutate(data)
            with self.subTest(mutate=mutate),self.assertRaises(ValueError): release_scope.validate(data)
    def test_summary_mutation_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            (root/'conformance').mkdir()
            for path in ['INDEX.md','15-acceptance-scenarios.md','conformance/contract-links.json']:
                (root/path).write_text((ROOT/path).read_text())
            (root/'INDEX.md').write_text((root/'INDEX.md').read_text().replace('| A3 |','| WRONG |',1))
            with self.assertRaisesRegex(ValueError,'summary drift'): release_scope.check_links(root)

class MutationSensitivity(unittest.TestCase):
    """Known bad variants prove these assertions catch the specified regressions only."""
    def test_precommit_publication_mutant_is_caught(self):
        model=ContractModel(); original=model._decide
        def bad_decide(req):
            result=original(req); model.published.extend(result[2]); return result
        with patch.object(model,'_decide',side_effect=bad_decide):
            model.invoke(request('a','activate'),fault='before_commit')
        with self.assertRaises(AssertionError): self.assertEqual(model.published,[])
    def test_discard_failed_rng_mutant_is_caught(self):
        model=ContractModel(); model.memory['room']='green'
        model.memory['rng']=[27274249,25704967,31982592,12605441]
        model.durable=copy.deepcopy(model.memory); original=model._decide
        def bad_decide(req):
            state,code,events,ok=original(req)
            if code=='check_failed': state['rng']=model.memory['rng'][:]
            return state,code,events,ok
        with patch.object(model,'_decide',side_effect=bad_decide): model.invoke(request('x','take'))
        with self.assertRaises(AssertionError):
            self.assertEqual(model.memory['rng'],[15224335,29364750,272377353,1125134346])
    def test_revalidate_retry_before_lookup_mutant_is_caught(self):
        class BadModel(ContractModel):
            def invoke(self,req,**kwargs):
                if req.get('action')=='take' and self.memory['lantern']!=self.memory['room']:
                    return self._response('rejected','not_present',self.memory['revision'])
                return super().invoke(req,**kwargs)
        model=BadModel(); model.invoke(request('n','move',input={'direction':'north'}))
        model.invoke(request('x','take'))
        with self.assertRaises(AssertionError): self.assertEqual(model.invoke(request('x','take'))['delivery'],'replay')
    def test_ignoring_semantic_payload_mutant_is_caught(self):
        class BadModel(ContractModel):
            def _intent(self,req):
                return super()._intent({**req,'input':{}})
        model=BadModel(); model.invoke(request('a','activate'))
        model.invoke(request('n','move',input={'direction':'north'})); model.invoke(request('t','take'))
        a=request('x','choose',input={'choice_id':'carry','continuation_id':'lantern-offer-1'})
        model.invoke(a)
        b={**a,'input':{'choice_id':'leave','continuation_id':'different-offer'}}
        with self.assertRaises(AssertionError): self.assertEqual(model.invoke(b)['code'],'integrity_conflict')

if __name__=='__main__': unittest.main()
