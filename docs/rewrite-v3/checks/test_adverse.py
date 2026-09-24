"""Adverse known answers (ADR-069). Models are checked against frozen answers, never the reverse."""
from __future__ import annotations
import copy
from pathlib import Path
import unittest
from unittest.mock import patch

from contract_model import ContractModel, canonical, strict_json, uniform
from composition_model import CompositionModel
from lantern_model import LanternModel

ROOT = Path(__file__).resolve().parents[1]
DATA = strict_json((ROOT/'conformance/adverse-cases.json').read_text())


def replay(test, model, steps):
    for i, step in enumerate(steps):  # no subTest here: the mutant check needs the failure to raise
        op = step.get('op', 'invoke')
        if op == 'invoke':
            result = model.invoke(copy.deepcopy(step['request']), **step.get('options', {}))
        elif op == 'recover':
            result = model.recover()
        else:
            result = model.settle(step['committed'])
        test.assertEqual(result, step['result'], f'step {i}')
        test.assertEqual(canonical(model.memory), canonical(step['state']), f'step {i}')
        test.assertEqual(model.durable, step.get('durable', step['state']), f'step {i}')
        if 'published' in step:
            test.assertEqual(model.published, step['published'], f'step {i}')


def tiny(case):
    model = ContractModel(case['credit'])
    if 'initial_state' in case:
        model.memory = copy.deepcopy(case['initial_state']); model.durable = copy.deepcopy(case['initial_state'])
    return model


class AdverseCases(unittest.TestCase):
    def test_uniform(self):
        for row in DATA['uniform']:
            with self.subTest(row=row):
                if 'error' in row:
                    with self.assertRaisesRegex(ValueError, row['error']):
                        uniform(row['state'], row['bound'], row['max_draws'])
                else:
                    self.assertEqual(uniform(row['state'], row['bound'], row['max_draws']), (row['value'], row['next_state']))

    def test_tiny(self):
        for case in DATA['tiny']:
            with self.subTest(case=case['id']):
                replay(self, tiny(case), case['steps'])

    def test_composition(self):
        limits = strict_json((ROOT/'conformance/composition-profile.json').read_text())['limits']
        for case in DATA['composition']:
            with self.subTest(case=case['id']):
                kw = {'advance_target': case['advance_target']} if 'advance_target' in case else {}
                result = CompositionModel({**limits, **case.get('limits', {})}).evaluate(
                    copy.deepcopy(case['initial']), copy.deepcopy(case['root']), copy.deepcopy(case['rules']), **kw)
                self.assertEqual(result, case['expected'])

    def test_lantern(self):
        traces = {t['id']: t for t in strict_json((ROOT/'conformance/lantern-traces.json').read_text())['traces']}
        for case in DATA['lantern']:
            with self.subTest(case=case['id']):
                p = case['prefix']; model = LanternModel()
                for step in traces[p['trace']]['steps'][p['from']:p['to']]:
                    model.invoke(step['request'])
                replay(self, model, case['steps'])

    def test_restoring_rng_after_failed_check_is_caught(self):
        case = next(c for c in DATA['tiny'] if c['id'] == 'failed-check-commits-next-rng')
        model = tiny(case); original = model._decide
        def bad_decide(req):
            state, code, events, ok = original(req)
            if code == 'check_failed': state['rng'] = model.memory['rng'][:]
            return state, code, events, ok
        with patch.object(model, '_decide', side_effect=bad_decide):
            with self.assertRaises(AssertionError): replay(self, model, case['steps'])


if __name__ == '__main__': unittest.main()
