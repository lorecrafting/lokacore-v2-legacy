"""Readiness/model checks only. All test setup records are SYNTHETIC, not evidence."""
from __future__ import annotations
from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest

from contract_model import canonical, strict_json
from composition_model import CompositionModel, all_matches
from lantern_model import LanternModel
import readiness
import release_scope

ROOT = Path(__file__).resolve().parents[1]


def req(identity, action, **payload):
    return {'id': identity, 'actor': 'hero', 'action': action, **({'input': payload} if payload else {})}


class CompositionCases(unittest.TestCase):
    def setUp(self):
        self.profile = strict_json((ROOT/'conformance/composition-profile.json').read_text())
        self.limits = self.profile['limits']
        self.cases = strict_json((ROOT/'conformance/composition-cases.json').read_text())['cases']

    def test_known_answers_and_input_immutability(self):
        for case in self.cases:
            with self.subTest(case=case['id']):
                before = canonical(case)
                result = CompositionModel(self.limits).evaluate(case['initial'],case['root'],case['rules'])
                self.assertEqual(result, case['expected'])
                self.assertEqual(canonical(result), canonical(case['expected']))
                self.assertEqual(canonical(case), before)

    def test_file_registry_reordering_is_not_semantic(self):
        case = next(c for c in self.cases if c['id']=='canonical-registry-order')
        model = CompositionModel(self.limits)
        self.assertEqual(model.evaluate(case['initial'],case['root'],list(reversed(case['rules']))),case['expected'])

    def test_explicit_sequence_order_is_semantic(self):
        case = next(c for c in self.cases if c['id']=='explicit-sequence')
        result = CompositionModel(self.limits).evaluate(case['initial'],list(reversed(case['root'])),[])
        self.assertNotEqual(result,case['expected'])
        self.assertEqual(result['state']['facts']['flag'],1)

    def test_distinct_events_are_delivered_not_transaction_deduped(self):
        state = CompositionModel.initial(); state['active']=['observer']
        signal={'op':'event.emit','event':'proof.signal','payload':{}}
        rule={'id':'observer','event':'proof.signal','guard':None,'ops':[]}
        result=CompositionModel(self.limits).evaluate(state,[signal,signal],[rule])
        self.assertEqual(result['deliveries'],['1:observer','2:observer'])

    def test_shared_child_budget_and_cycle_rollback(self):
        state=CompositionModel.initial(); state['active']=['loop']
        signal={'op':'event.emit','event':'proof.signal','payload':{}}
        rule={'id':'loop','event':'proof.signal','guard':None,'ops':[signal]}
        for field in ('operations','events','deliveries','reaction_depth','query_steps'):
            with self.subTest(field=field):
                limits={**self.limits,field:2}
                result=CompositionModel(limits).evaluate(state,[signal],[rule])
                self.assertEqual(result['code'],'budget_'+field)
                self.assertEqual(result['state'],state)
                self.assertEqual(result['events'],[])

    def test_output_budget_does_not_publish_partial_events(self):
        state=CompositionModel.initial()
        result=CompositionModel({**self.limits,'output_bytes':20}).evaluate(state,[{'op':'event.emit','event':'proof.signal','payload':{'text':'x'*40}}],[])
        self.assertEqual(result['code'],'budget_output_bytes'); self.assertEqual(result['events'],[])

    def test_bounds_have_no_silent_clamp(self):
        state=CompositionModel.initial()
        root=[{'op':'fact.add','fact':'count','amount':2147483647},{'op':'fact.add','fact':'count','amount':1}]
        result=CompositionModel(self.limits).evaluate(state,root,[])
        self.assertEqual(result['code'],'resource_bounds'); self.assertEqual(result['state'],state)

    def test_due_followup_must_exceed_advance_target(self):
        state=CompositionModel.initial()
        result=CompositionModel(self.limits).evaluate(state,[{'op':'job.schedule','id':'too_soon','due':8}],[],advance_target=19)
        self.assertEqual(result['code'],'nonfuture_job')

    def test_job_caps_and_unique_identity(self):
        state=CompositionModel.initial()
        root=[{'op':'job.schedule','id':'one','due':7},{'op':'job.schedule','id':'two','due':8}]
        for field in ('created_jobs','pending_jobs'):
            with self.subTest(field=field):
                result=CompositionModel({**self.limits,field:1}).evaluate(state,root,[])
                self.assertEqual(result['code'],'budget_'+field); self.assertEqual(result['state'],state)
        result=CompositionModel(self.limits).evaluate(state,[root[0],root[0]],[])
        self.assertEqual(result['code'],'duplicate_job')

    def test_selector_overflow_is_not_truncation(self):
        with self.assertRaisesRegex(ValueError,'selector_cardinality'):all_matches([1,2,3],2)
        self.assertEqual(all_matches([1,2],2),[1,2])

    def test_unregistered_operations_and_malformed_policies_fail(self):
        model=CompositionModel(self.limits); state=CompositionModel.initial()
        for op in ({'op':'set_component','path':'inventory','value':1},{'op':'fact.set','fact':'flag','value':True}):
            self.assertEqual(model.evaluate(state,[op],[])['kind'],'fault')
        rule={'id':'bad','event':'proof.signal','guard':{'source':'always_allow'},'ops':[]}
        self.assertEqual(model.evaluate(state,[],[rule])['code'],'unknown_policy')


    def test_guard_equality_does_not_coerce_boolean_to_integer(self):
        state=CompositionModel.initial();state['active']=['a'];state['facts']['flag']=1
        rule={'id':'a','event':'proof.signal','guard':{'source':'overlay','key':'flag','equals':True},'ops':[]}
        result=CompositionModel(self.limits).evaluate(state,[{'op':'event.emit','event':'proof.signal','payload':{}}],[rule])
        self.assertEqual(result['deliveries'],[])

    def test_invalid_advance_target_and_enum_arithmetic_fail(self):
        state=CompositionModel.initial();model=CompositionModel(self.limits)
        for target in (True,'19',5):
            self.assertEqual(model.evaluate(state,[],[],advance_target=target)['code'],'invalid_time')
        self.assertEqual(model.evaluate(state,[{'op':'fact.add','fact':'flag','amount':1}],[])['code'],'invalid_operation')

    def test_competing_transfers_cannot_duplicate_custody(self):
        state=CompositionModel.initial();state['active']=['a','b']
        rules=[{'id':n,'event':'proof.signal','guard':None,'ops':[{'op':'item.transfer','item':'lantern','source':'hero','destination':dest}]} for n,dest in [('a','bag'),('b','room')]]
        result=CompositionModel(self.limits).evaluate(state,[{'op':'event.emit','event':'proof.signal','payload':{}}],rules)
        self.assertEqual(result['code'],'conflicting_write'); self.assertEqual(result['state'],state)

    def test_profile_covers_every_experiment_cap(self):
        self.assertEqual(self.profile['profile_id'],'initial-composition-r1@1')
        self.assertEqual(set(self.limits),{'operations','query_steps','events','deliveries','reaction_depth','selector_cardinality','created_jobs','pending_jobs','due_jobs_per_advance','scene_auto_advances','output_bytes'})
        self.assertTrue(all(type(v) is int and v>0 for v in self.limits.values()))


class CompositionMutationSensitivity(unittest.TestCase):
    """Known-bad source variants executed in memory; not exhaustive mutation coverage."""
    def test_specific_mutants_are_detected_by_frozen_answers(self):
        source=(ROOT/'checks/composition_model.py').read_text()
        limits=strict_json((ROOT/'conformance/composition-profile.json').read_text())['limits']
        cases={c['id']:c for c in strict_json((ROOT/'conformance/composition-cases.json').read_text())['cases']}
        mutants=[
            ('canonical-registry-order', "ordered = sorted(rules, key=lambda r: r['id'])", 'ordered = list(rules)'),
            ('emission-eligibility', " and r['id'] in state['active']", ''),
            ('independent-conflict', "if target in writers and writers[target] != group:", 'if False:'),
            ('all-or-nothing-capacity', "'state': deepcopy(initial), 'events': [], 'deliveries': []", "'state': state, 'events': [], 'deliveries': []"),
        ]
        for case_id,old,new in mutants:
            with self.subTest(mutant=case_id):
                self.assertEqual(source.count(old),1)
                namespace={'__name__':'composition_model'}
                exec(compile(source.replace(old,new),'<controlled-test-mutant>','exec'),namespace)
                case=cases[case_id]
                result=namespace['CompositionModel'](limits).evaluate(case['initial'],case['root'],case['rules'])
                self.assertNotEqual(result,case['expected'])


class LanternCases(unittest.TestCase):
    def setUp(self):self.data=strict_json((ROOT/'conformance/lantern-traces.json').read_text())
    def ready(self):
        model=LanternModel()
        for step in self.data['traces'][0]['steps'][:-1]:model.invoke(step['request'])
        return model
    def choice(self,ending='leave'):
        return req('resolve','choose',choice_id=ending,continuation_id='proof-choice:talk')

    def test_both_exact_choice_traces(self):
        for trace in self.data['traces']:
            model=LanternModel(); self.assertEqual(model.memory,self.data['initial_state'])
            for step in trace['steps']:
                with self.subTest(trace=trace['id'],request=step['request']['id']):
                    self.assertEqual(model.invoke(step['request']),step['result'])
                    self.assertEqual(canonical(model.memory),canonical(step['state']))
                    self.assertEqual(model.durable,step['state'])

    def test_early_acquisition_is_state_credit_not_event_replay(self):
        model=LanternModel()
        for step in self.data['traces'][0]['steps'][1:8]:model.invoke(step['request'])
        self.assertEqual(model.memory['quest'],'absent')
        self.assertEqual(model.invoke(req('early-accept','activate'))['code'],'activated_with_possession')
        self.assertEqual(model.invoke(req('talk','talk'))['code'],'choice_opened')
        self.assertEqual(model.invoke(self.choice())['code'],'resolved_leave')

    def test_drop_after_choice_rejects_then_can_close(self):
        model=self.ready();model.invoke(req('drop','drop'));before=deepcopy(model.memory)
        self.assertEqual(model.invoke(self.choice())['code'],'not_owned')
        self.assertEqual(model.memory,before)
        self.assertEqual(model.invoke(req('close','close_choice'))['code'],'choice_closed')
        self.assertEqual(model.memory['quest'],'active')

    def test_schedule_change_rejects_new_choice_but_not_receipt(self):
        model=self.ready();model.invoke(req('wait','wait',until=19)); before=deepcopy(model.memory)
        self.assertEqual(model.invoke(self.choice())['code'],'not_present');self.assertEqual(model.memory,before)
        self.assertEqual(model.invoke(req('close','close_choice'))['code'],'choice_closed')
        model=self.ready();first=model.invoke(self.choice());model.invoke(req('wait','wait',until=19));before=deepcopy(model.memory)
        self.assertEqual(model.invoke({**self.choice(),'view':'view:0'}),{**first,'delivery':'replay'})
        self.assertEqual(model.memory,before)

    def test_altered_choice_conflicts_and_narration_does_not_repeat(self):
        model=self.ready();model.invoke(self.choice());before=deepcopy(model.memory)
        self.assertEqual(model.invoke(self.choice('carry'))['code'],'integrity_conflict')
        self.assertEqual(model.invoke(self.choice())['delivery'],'replay')
        self.assertEqual(model.memory,before);self.assertEqual(len(model.memory['narration']),1)

    def test_rollback_discards_all_choice_consequences(self):
        model=self.ready();before=deepcopy(model.memory)
        self.assertEqual(model.invoke(self.choice(),fault='before_commit')['code'],'rolled_back')
        self.assertEqual(model.memory,before);self.assertEqual(model.durable,before)
        self.assertIsNone(model.memory['milestone'])
        self.assertEqual(model.invoke(self.choice())['code'],'resolved_leave')

    def test_uncertain_commit_and_restored_narration(self):
        for committed in (False,True):
            with self.subTest(committed=committed):
                model=self.ready();before=deepcopy(model.memory)
                model.invoke(self.choice(),fault='commit_pending')
                self.assertEqual(model.recover()['code'],'commit_pending')
                self.assertEqual(model.invoke(req('other','wait',until=19))['code'],'commit_pending')
                self.assertEqual(model.memory,before)
                model.settle(committed);model.recover();result=model.invoke(self.choice())
                self.assertEqual(result['delivery'],'replay' if committed else 'new')
                self.assertEqual(len(model.memory['narration']),1)
                self.assertEqual(model.memory['milestone']['key'],'proof.terminal')

    def test_commit_before_display_recovers_without_repeating(self):
        model=self.ready();model.invoke(self.choice(),fault='after_commit_before_memory')
        self.assertEqual(model.memory['narration'],[])
        model.recover();before=canonical(model.memory)
        self.assertEqual(model.invoke(self.choice())['delivery'],'replay')
        self.assertEqual(canonical(model.memory),before)
        self.assertEqual(model.memory['narration'][0]['text_key'],'proof.leave')

    def test_reading_has_no_time_rng_or_game_state_effect(self):
        model=self.ready();before=canonical(model.memory)
        for i in range(10):model.invoke(req('read-'+str(i),'look'))
        self.assertEqual(canonical(model.memory),before)

    def test_stale_new_choice_and_unavailable_exit_leave_state(self):
        model=self.ready();before=canonical(model.memory)
        self.assertEqual(model.invoke({**self.choice(),'view':'view:0'})['code'],'stale_view')
        self.assertEqual(model.invoke(req('blocked','move',direction='west'))['code'],'exit_unavailable')
        self.assertEqual(canonical(model.memory),before)


class PreparationCases(unittest.TestCase):
    def synthetic_setup(self,root):
        """Fabricated TEMPORARY records to test structure; never real acceptance."""
        data=readiness.template();data['status']='setup_reviewed'
        data['accepted_spec_commit']='0123456789abcdef0123456789abcdef01234567'
        data['candidate_author_ids']=['synthetic-author']
        for platform in ('ios','android'):
            data['devices'][platform]={k:'synthetic-test-only' for k in readiness.DEVICE_FIELDS}
            data['devices'][platform].update(qualification_class='iphone-11' if platform=='ios' else 'galaxy-a14-4gb', installed_ram_gb=4,architecture='arm64',os_version='16.4' if platform=='ios' else '10')
        data['server']={'model':'synthetic M1 fixture','os_build':'synthetic','cores':8,'ram_gb':16}
        data['toolchain']={k:'1.2.3' for k in readiness.TOOLS}
        def retain(path,raw):
            p=root/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
            return {'path':path,'sha256':readiness.sha256(raw)}
        data['toolchain_lock']=retain('test-only-lock.txt',b'synthetic lock, not a real dependency set')
        data['inputs']=[retain(p,(ROOT/p).read_bytes()) for p in readiness.INPUTS]
        r0={'accepted_spec_commit':data['accepted_spec_commit'],'disposition':'accepted','reviewer_id':'synthetic-owner','normative_files':list(readiness.NORMATIVE),'amendment_authority':'synthetic-only','cutover_destination':'synthetic-only'}
        data['r0_acceptance']=retain('r0.json',canonical(r0))
        review={'accepted_spec_commit':data['accepted_spec_commit'],'disposition':'approved','reviewer_id':'synthetic-reviewer','independent_of_candidate_authorship':True,'subject_author_ids':['synthetic-subject-author'],'independent_of_subject_authorship':True,'inputs':data['inputs']}
        data['oracle_review']=retain('oracle.json',canonical(review))
        review={k:v for k,v in review.items() if k!='inputs'};review['setup_digest']=readiness.setup_digest(data)
        data['setup_review']=retain('setup.json',canonical(review))
        return data

    def test_checked_in_template_is_honestly_incomplete(self):
        self.assertEqual(strict_json((ROOT/'conformance/r1-run-manifest.template.json').read_text()),readiness.template())
        with self.assertRaisesRegex(ValueError,'pending'):readiness.require_ready(readiness.template(),ROOT)

    def test_malformed_evidence_entries_fail_with_typed_diagnostic(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for entry in (None, 7, [], 'not-a-record'):
                data = self.synthetic_setup(root)
                data['inputs'][0] = entry
                with self.subTest(entry=entry), self.assertRaises(ValueError):
                    readiness.require_ready(data, root)
            data = self.synthetic_setup(root)
            record = root / data['r0_acceptance']['path']
            r0 = strict_json(record.read_text())
            r0['normative_files'].append({'not': 'a path'})
            raw = canonical(r0)
            record.write_bytes(raw)
            data['r0_acceptance']['sha256'] = readiness.sha256(raw)
            with self.assertRaisesRegex(ValueError, 'R0 acceptance'):
                readiness.require_ready(data, root)

    def test_complete_synthetic_records_validate_structure_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);data=self.synthetic_setup(root);readiness.require_ready(data,root)

    def test_missing_or_changed_records_fail(self):
        mutations=[lambda d:d.update(accepted_spec_commit=None),lambda d:d.update(schema_version=True),lambda d:d.update(candidate='B'),lambda d:d['devices']['android'].update(sku=None),lambda d:d['devices']['ios'].update(qualification_class='newer-phone'),lambda d:d['devices']['ios'].update(os_version='15.0'),lambda d:d['toolchain'].update(expo='latest'),lambda d:d['toolchain'].update(node='22.x'),lambda d:d['toolchain'].update(hermes='1.2.3-beta.1'),lambda d:d['inputs'].pop(),lambda d:d.update(candidate_author_ids=['synthetic-reviewer']),lambda d:d['oracle_review'].update(path=None),lambda d:d.update(measured_p95=1),lambda d:d['toolchain_lock'].update(path='../outside')]
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);original=self.synthetic_setup(root)
            for mutate in mutations:
                data=deepcopy(original);mutate(data)
                with self.subTest(mutation=mutate),self.assertRaises((ValueError,TypeError,KeyError)):
                    readiness.require_ready(data,root)

    def test_hash_tampering_and_review_rebinding_fail(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);data=self.synthetic_setup(root)
            p=root/data['inputs'][0]['path'];p.write_text(p.read_text()+'\nchanged\n')
            with self.assertRaisesRegex(ValueError,'hash mismatch'):readiness.require_ready(data,root)
            data=self.synthetic_setup(root);data['server']['cores']=9
            with self.assertRaisesRegex(ValueError,'configuration'):readiness.require_ready(data,root)

    def test_oracle_must_cover_exact_inputs_even_when_receipt_rehashed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);data=self.synthetic_setup(root)
            p=root/'oracle.json';review=strict_json(p.read_text());review['inputs']=review['inputs'][:-1]
            p.write_bytes(canonical(review));data['oracle_review']['sha256']=readiness.sha256(p.read_bytes())
            with self.assertRaisesRegex(ValueError,'exact inputs'):readiness.require_ready(data,root)

    def test_no_self_referential_setup_digest(self):
        data=readiness.template();before=readiness.setup_digest(data)
        data['setup_review']={'path':'after.json','sha256':'not-used'}
        self.assertEqual(readiness.setup_digest(data),before)
        data['devices']['ios']['model']='different'
        self.assertNotEqual(readiness.setup_digest(data),before)


class ReadinessDocumentConsistency(unittest.TestCase):
    def test_direction_is_not_fabricated_acceptance(self):
        envelope=(ROOT/'r1-acceptance-envelope.md').read_text()
        self.assertIn('proposed-event containment',envelope)
        self.assertIn('proposed state is not authoritative',envelope)
        self.assertNotIn('approved target state',envelope)
        self.assertNotIn('Every numeric threshold remains proposed',envelope)
        for row in ('| Tiny | 2 | 5 | 10 |','| Medium synthetic | 5 | 15 | 30 |','| Stress synthetic | 15 | 40 | 80 |'):
            self.assertIn(row,envelope)
        self.assertIn('R0 acceptance and independent review remain pending',(ROOT/'README.md').read_text())
        self.assertIn('tests A (one TypeScript kernel) first',(ROOT/'README.md').read_text())

    def test_readiness_cases_and_work_package_are_routed(self):
        acceptance=(ROOT/'15-acceptance-scenarios.md').read_text()
        for family,count in (('COMPOSE',7),('RUN',6),('READY',2)):
            for number in range(1,count+1):
                self.assertEqual(acceptance.count(f'### {family}-{number:02} — '),1)
        for path in ('README.md','14-implementation-plan.md','R-MILESTONES.md','REVIEW-GUIDE.md'):
            self.assertIn('r1-work-package.md',(ROOT/path).read_text())


class PublicRunScopeCases(unittest.TestCase):
    def test_save_obligations_are_public_story_not_proof_or_realm_gates(self):
        data = strict_json((ROOT / 'release-scope.json').read_text())
        release_scope.validate(data)
        for tier in ('chapter_one', 'chapter_two', 'chapter_three'):
            with self.subTest(tier=tier):
                self.assertIn('RUN', release_scope.applicable(data, tier)[2])
                bad = deepcopy(data)
                bad['platform_gates'][tier].remove('RUN')
                with self.assertRaises(ValueError):
                    release_scope.validate(bad)
        for tier in ('proof', 'realm'):
            self.assertNotIn('RUN', data['platform_gates'][tier])
            bad = deepcopy(data)
            bad['platform_gates'][tier].append('RUN')
            with self.assertRaises(ValueError):
                release_scope.validate(bad)


if __name__=='__main__':unittest.main()
