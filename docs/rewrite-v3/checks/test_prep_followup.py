"""Focused regressions; synthetic reviews below are never acceptance evidence."""
from copy import deepcopy
from pathlib import Path
import tempfile
import unittest

import readiness
from contract_model import canonical, strict_json, rng_next, uniform
from account_progress_model import LocalJournal
import test_readiness


class PrepFollowup(unittest.TestCase):
    def test_template_equality_preserves_json_types(self):
        readiness.check_template(readiness.template())
        data = readiness.template()
        data['schema_version'] = True
        self.assertEqual(data, readiness.template())  # The concrete old false positive.
        with self.assertRaisesRegex(ValueError, 'template drift'):
            readiness.check_template(data)

    def test_subject_authorship_cannot_self_approve_even_after_rehashing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ('oracle_review', 'setup_review'):
                for change in ({'subject_author_ids': ['synthetic-reviewer']},
                               {'subject_author_ids': []},
                               {'subject_author_ids': [True]},
                               {'subject_author_ids': ['a', 'a']},
                               {'independent_of_subject_authorship': 1}):
                    data = test_readiness.PreparationCases().synthetic_setup(root)
                    path = root / data[name]['path']
                    review = strict_json(path.read_text())
                    review.update(change)
                    raw = canonical(review)
                    path.write_bytes(raw)
                    data[name]['sha256'] = readiness.sha256(raw)
                    with self.subTest(name=name, change=change):
                        with self.assertRaisesRegex(ValueError, 'subject-author separation'):
                            readiness.require_ready(data, root)

    def test_rng_malformed_input_has_controlled_diagnostic(self):
        for words in (None, 1, True, '1234', {}, [1, 2, 3], [1, True, 3, 4]):
            with self.subTest(words=words):
                with self.assertRaisesRegex(ValueError, 'invalid_rng_state'):
                    rng_next(words)
                with self.assertRaisesRegex(ValueError, 'invalid_rng_state'):
                    uniform(words, 10, 0)
        for budget in (None, True, -1, '1'):
            with self.assertRaisesRegex(ValueError, 'invalid_rng_budget'):
                uniform([1, 2, 3, 4], 10, budget)
        with self.assertRaisesRegex(ValueError, 'rng_budget_exhausted'):
            uniform([1, 2, 3, 4], 10, 0)

    def test_report_identity_components_are_unambiguous(self):
        # Both were formerly SHA256("a:b:c:1"), despite distinct run/milestone tuples.
        first = LocalJournal('a:b', 'a' * 64, 'A')
        second = LocalJournal('a', 'a' * 64, 'A')
        first_id = first.reach('c', 'done')
        second_id = second.reach('b:c', 'done')
        self.assertNotEqual(first_id, second_id)
        self.assertEqual(first_id, deepcopy(first).reach('c', 'done'))
