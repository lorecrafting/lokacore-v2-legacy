"""ACCOUNT contract examples and negative controls, not production integration."""
from copy import deepcopy
from pathlib import Path
import json
import unittest

from account_progress_model import AccountProgress, LocalJournal, SOURCE, canonical
import release_scope

OLD, NEW = 'a' * 64, 'b' * 64
REQUIREMENT = 'onboarding.loka_fundamentals@1'
POLICY = {'version': 1, 'requires': [REQUIREMENT], 'ungated': False}


def server():
    known = {(r, 'prologue_completed'): frozenset({'prior', 'fox'}) for r in [OLD, NEW]}
    known[(OLD, 'story_started')] = frozenset({'started'})
    rules = {REQUIREMENT: {'purpose': 'onboarding', 'sources': [SOURCE],
                          'alternatives': {(r, 'prologue_completed', o)
                                           for r in [OLD, NEW] for o in ['prior', 'fox']}}}
    s = AccountProgress(known, rules)
    s.create('A'); s.create('B')
    return s


def report(rid='report-1', run='run-1', milestone='prologue_completed', outcome='fox', release=OLD):
    return {'report_id': rid, 'run_id': run, 'release_hash': release,
            'milestone': milestone, 'outcome': outcome, 'revision': 7}


class AccountProgressTests(unittest.TestCase):
    def setUp(self):
        self.s = server()
        self.s.bind('A', 'run-1', OLD)

    def accept(self, data=None, **kw):
        return self.s.ingest('A', canonical(data or report()), **kw)

    def test_offline_commit_and_later_sync(self):
        local = LocalJournal('run-1', OLD, 'A')
        rid = local.reach('prologue_completed', 'fox')
        self.assertEqual(local.flush('A', self.s, online=False), 0)
        self.assertIn(rid, local.pending)
        self.assertFalse(self.s.completed('A'))
        self.assertEqual(local.flush('A', self.s), 1)
        self.assertTrue(self.s.completed('A'))
        self.assertFalse(local.pending)

    def test_local_rollback_keeps_both_outcome_and_queue_absent(self):
        local = LocalJournal('run-1', OLD, 'A')
        local.reach('prologue_completed', 'fox', rollback=True)
        self.assertEqual(local.state, {'milestones': {}, 'revision': 0})
        self.assertFalse(local.pending)

    def test_lost_ack_replays_without_double_credit(self):
        local = LocalJournal('run-1', OLD, 'A')
        local.reach('prologue_completed', 'fox')
        with self.assertRaisesRegex(ValueError, 'acknowledgement_lost'):
            local.flush('A', self.s, fault='after_commit')
        self.assertTrue(local.pending)
        self.assertTrue(self.s.completed('A'))
        self.assertEqual(local.flush('A', self.s), 1)
        self.assertEqual(len(self.s.milestones), 1)

    def test_restored_backup_requeues_stable_identity(self):
        local = LocalJournal('run-1', OLD, 'A'); local.reach('prologue_completed', 'fox')
        backup = deepcopy(local)
        local.flush('A', self.s); backup.flush('A', self.s)
        self.assertEqual(len(self.s.receipts), 1)
        self.assertEqual(len(self.s.milestones), 1)

    def test_same_id_different_payload_conflicts(self):
        self.accept()
        with self.assertRaisesRegex(ValueError, 'idempotency_conflict'):
            self.accept(report(outcome='prior'))

    def test_new_id_same_milestone_dedupes_but_conflicting_outcome_fails(self):
        self.accept(); self.accept(report(rid='report-2'))
        self.assertEqual(len(self.s.milestones), 1)
        with self.assertRaisesRegex(ValueError, 'milestone_conflict'):
            self.accept(report(rid='report-3', outcome='prior'))

    def test_cross_account_client_and_server_binding(self):
        local = LocalJournal('run-1', OLD, 'A'); local.reach('prologue_completed', 'fox')
        with self.assertRaisesRegex(ValueError, 'local_binding_conflict'): local.flush('B', self.s)
        with self.assertRaisesRegex(ValueError, 'run_not_owned'):
            self.s.ingest('B', canonical(report()))
        with self.assertRaisesRegex(ValueError, 'run_bound_elsewhere'): self.s.bind('B', 'run-1', OLD)
        self.assertTrue(local.pending)

    def test_explicit_guest_claim_once(self):
        local = LocalJournal('guest-run', OLD)
        local.reach('prologue_completed', 'fox')
        self.assertEqual(local.flush(None, self.s), 0)
        local.claim('A', self.s);local.flush('A', self.s)
        self.assertTrue(self.s.completed('A'))
        with self.assertRaisesRegex(ValueError, 'local_binding_conflict'): local.claim('B', self.s)

    def test_out_of_order_start_cannot_erase_completion(self):
        self.accept();self.s.bind('A','other-run',OLD)
        self.accept(report(rid='start', run='other-run', milestone='story_started', outcome='started'))
        self.assertTrue(self.s.completed('A'))
        self.assertTrue(self.s.admit('A', POLICY)['eligible'])

    def test_bad_schema_evidence_and_economic_fields_fail(self):
        for key,value in [('account_id','B'),('source','server_authoritative_run'),('currency',100),
                          ('unlocked',True),('entitlement','all'),('revision',True),('revision',-1),
                          ('run_id',[]),('release_hash','not-approved'),('milestone','invented'),
                          ('outcome','invented')]:
            data=report();data[key]=value
            with self.subTest(key=key,value=value),self.assertRaises(ValueError):self.accept(data)
        self.assertFalse(self.s.receipts)
        with self.assertRaises(ValueError):self.s.ingest('A', '{"report_id":"x","report_id":"y"}')
        with self.assertRaises(ValueError):self.s.ingest('A', ' ' * 4097)

    def test_old_new_releases_and_all_intended_endings_qualify(self):
        for release in [OLD,NEW]:
            for ending in ['prior','fox']:
                s=server();s.bind('A','run-1',release);s.ingest('A',canonical(report(release=release,outcome=ending)))
                self.assertTrue(s.admit('A',POLICY)['eligible'])
                self.assertFalse(s.admit('B',POLICY)['eligible'])

    def test_server_evidence_requirement_not_met_by_offline_report(self):
        self.accept();self.s.requirements[REQUIREMENT]['sources']=['server_authoritative_run']
        self.assertFalse(self.s.admit('A',POLICY)['eligible'])
        self.assertEqual(next(iter(self.s.milestones.values()))['source'],SOURCE)

    def test_invalid_and_accidentally_empty_policies_fail_closed(self):
        for policy in [{},dict(POLICY, requires=[]),dict(POLICY,requires=['unknown']),
                       dict(POLICY,requires=[[]]),dict(POLICY,ungated=True),dict(POLICY,version=True)]:
            with self.subTest(policy=policy),self.assertRaises(ValueError):self.s.admit('A',policy)
        self.assertTrue(self.s.admit('A',dict(POLICY,requires=[],ungated=True))['eligible'])

    def test_requirement_policy_cannot_grant_competitive_value(self):
        self.accept();self.s.requirements[REQUIREMENT]['purpose']='currency'
        with self.assertRaisesRegex(ValueError,'unknown_or_invalid_requirement'):self.s.admit('A',POLICY)

    def test_stale_admission_and_withdrawal_replay(self):
        receipt=self.accept();old_version=self.s.progress_version
        self.s.withdraw('A','run-1','prologue_completed')
        self.assertEqual(receipt,self.accept())
        self.assertFalse(self.s.admit('A',POLICY)['eligible'])
        with self.assertRaisesRegex(ValueError,'stale_progress'):
            self.s.admit('A',POLICY,expected_version=old_version)
        self.accept(report(rid='another'))
        self.assertFalse(self.s.admit('A',POLICY)['eligible'])

    def test_server_confirmed_rollback_has_no_partial_acceptance(self):
        with self.assertRaisesRegex(ValueError,'confirmed_rollback'):self.accept(fault='before_commit')
        self.assertFalse(self.s.receipts);self.assertFalse(self.s.milestones)
        self.accept();self.assertTrue(self.s.completed('A'))

    def test_deletion_between_validation_and_commit_blocks_acceptance(self):
        with self.assertRaisesRegex(ValueError,'account_unavailable'):self.accept(fault='delete_before_commit')
        self.assertFalse(self.s.receipts);self.assertFalse(self.s.milestones)
        with self.assertRaises(ValueError):self.accept()
        with self.assertRaises(ValueError):self.s.create('A')
        self.s.create('new-account-same-email')
        with self.assertRaises(ValueError):self.s.bind('new-account-same-email','run-1',OLD)

    def test_deleted_queue_is_not_rebound_but_local_game_still_works(self):
        local=LocalJournal('run-1',OLD,'A');local.reach('prologue_completed','fox');self.s.delete('A')
        with self.assertRaises(ValueError):local.flush('A',self.s)
        self.assertTrue(local.stopped)
        with self.assertRaises(ValueError):local.claim('B',self.s)
        local.reach('later_local_checkpoint','visited')
        self.assertIn('later_local_checkpoint',local.state['milestones'])

    def test_account_metadata_does_not_change_portable_state(self):
        a=LocalJournal('run-1',OLD,'A');b=LocalJournal('run-1',OLD,'B')
        a.reach('prologue_completed','fox');b.reach('prologue_completed','fox')
        self.assertEqual(a.state,b.state)

    def test_registered_run_cannot_silently_change_release(self):
        with self.assertRaisesRegex(ValueError, 'run_not_owned'):
            self.accept(report(release=NEW))
        with self.assertRaisesRegex(ValueError, 'run_bound_elsewhere'):
            self.s.bind('A', 'run-1', NEW)
        self.assertFalse(self.s.milestones)

    def test_policy_changed_between_check_and_admission(self):
        self.accept()
        with self.assertRaisesRegex(ValueError, 'stale_policy'):
            self.s.admit('A', dict(POLICY, version=2), expected_policy_version=1)

    def test_launch_scope_and_summary_obligations(self):
        root=Path(__file__).resolve().parents[1]
        data=json.loads((root/'release-scope.json').read_text())
        release_scope.validate(data)
        self.assertNotIn('ACCOUNT',release_scope.applicable(data,'proof')[2])
        self.assertIn('ACCOUNT',release_scope.applicable(data,'chapter_one')[2])
        for tier,value in [('chapter_one',[]),('proof',['ACCOUNT'])]:
            bad=deepcopy(data);bad['platform_gates'][tier]=value
            with self.assertRaises(ValueError):release_scope.validate(bad)
        plan=(root/'14-implementation-plan.md').read_text()
        self.assertIn('### R12A — Launch accounts and Story progress',plan)
        self.assertNotIn('introduce PostgreSQL dev/test/runtime infrastructure needed by platform services',plan)
        spec=(root/'23-accounts-progress-admission.md').read_text()
        self.assertIn('first public Story release',spec)
        self.assertIn('not** a fifth `StateScope`',spec)


if __name__=='__main__':unittest.main()
