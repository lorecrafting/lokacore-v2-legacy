"""Stage-gate regression tests. All approvals here are synthetic temporary data."""
from copy import deepcopy
import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import readiness
import test_readiness
from contract_model import canonical, strict_json


class StagedReadiness(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def setup_record(self, stage='A1', deferred=True):
        data = test_readiness.PreparationCases().synthetic_setup(self.root)
        if deferred:
            data['devices'] = readiness.template()['devices']
            data['toolchain'] = {
                key: value if key in readiness.A1_TOOLS else None
                for key, value in data['toolchain'].items()
            }
            data['server']['ram_gb'] = 8  # A1 is not common-host load qualification.
        return self.bind(data, stage)

    def bind(self, data, stage):
        path = self.root / data['setup_review']['path']
        review = strict_json(path.read_text())
        review['setup_digest'] = readiness.setup_digest(data, stage)
        raw = canonical(review)
        path.write_bytes(raw)
        data['setup_review']['sha256'] = readiness.sha256(raw)
        return data

    def test_a1_allows_deferred_native_inventory_but_not_a2(self):
        data = self.setup_record()
        readiness.require_ready(data, self.root, 'A1')
        with self.assertRaises(ValueError):
            readiness.require_ready(data, self.root)
        with self.assertRaises(ValueError):
            readiness.require_ready(data, self.root, 'A2')

    def test_stage_bound_review_cannot_escalate_even_with_full_inventory(self):
        for reviewed, requested in (('A1', 'A2'), ('A2', 'A1')):
            data = self.setup_record(reviewed, deferred=False)
            readiness.require_ready(data, self.root, reviewed)
            with self.assertRaisesRegex(ValueError, 'exact configuration'):
                readiness.require_ready(data, self.root, requested)

    def test_a1_still_requires_actual_runtime_versions_and_common_approvals(self):
        for name in readiness.A1_TOOLS:
            data = self.setup_record()
            data['toolchain'][name] = None
            self.bind(data, 'A1')
            with self.subTest(tool=name), self.assertRaises(ValueError):
                readiness.require_ready(data, self.root, 'A1')
        for key, value in (('accepted_spec_commit', None), ('candidate_author_ids', []),
                           ('status', 'preparation_pending')):
            data = self.setup_record()
            data[key] = value
            self.bind(data, 'A1')
            with self.subTest(key=key), self.assertRaises(ValueError):
                readiness.require_ready(data, self.root, 'A1')

    def test_a1_does_not_waive_hashes_or_independent_review(self):
        for key in ('r0_acceptance', 'oracle_review', 'setup_review', 'toolchain_lock'):
            data = self.setup_record()
            data[key]['sha256'] = 'f' * 64
            with self.subTest(key=key), self.assertRaises(ValueError):
                readiness.require_ready(data, self.root, 'A1')
        for key in ('oracle_review', 'setup_review'):
            data = self.setup_record()
            path = self.root / data[key]['path']
            review = strict_json(path.read_text())
            review['reviewer_id'] = review['subject_author_ids'][0]
            path.write_bytes(canonical(review))
            data[key]['sha256'] = readiness.sha256(path.read_bytes())
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, 'subject-author'):
                readiness.require_ready(data, self.root, 'A1')

    def test_deferred_is_not_permission_for_malformed_or_ranged_values(self):
        for field, value in (('installed_ram_gb', True), ('installed_ram_gb', -1),
                             ('sku', {}), ('model', 'unknown')):
            data = self.setup_record()
            data['devices']['ios'][field] = value
            self.bind(data, 'A1')
            with self.subTest(field=field), self.assertRaises(ValueError):
                readiness.require_ready(data, self.root, 'A1')
        data = self.setup_record()
        data['toolchain']['xcode'] = 'latest'
        self.bind(data, 'A1')
        with self.assertRaises(ValueError):
            readiness.require_ready(data, self.root, 'A1')

    def test_a2_keeps_native_gate_and_explicit_iphone_11_class(self):
        data = self.setup_record('A2', deferred=False)
        readiness.require_ready(data, self.root)
        for field, value in (('qualification_class', 'iphone-se-2'), ('installed_ram_gb', 3)):
            changed = deepcopy(data)
            changed['devices']['ios'][field] = value
            self.bind(changed, 'A2')
            with self.assertRaises(ValueError):
                readiness.require_ready(changed, self.root)
        data = self.setup_record('A2', deferred=False)
        data['toolchain']['xcode'] = None
        self.bind(data, 'A2')
        with self.assertRaises(ValueError):
            readiness.require_ready(data, self.root)

    def test_stage_domain_separation_preserves_legacy_full_setup_digest(self):
        data = readiness.template()
        raw = canonical({key: value for key, value in data.items()
                         if key not in {'status', 'setup_review'}})
        self.assertEqual(readiness.setup_digest(data), hashlib.sha256(raw).hexdigest())
        self.assertEqual(readiness.setup_digest(data, 'A1'),
                         hashlib.sha256(b'loka-r1-a1-setup-v1\x00' + raw).hexdigest())
        with self.assertRaises(ValueError):
            readiness.setup_digest(data, 'A3')
        with self.assertRaises(ValueError):
            readiness.require_ready(data, self.root, 'A3')

    def test_real_pending_and_permanent_template_reject_both_stages(self):
        for name in ('conformance/r1-run-manifest.template.json',
                     'prep/after-pr-10/setup.pending.json'):
            data = strict_json((readiness.ROOT / name).read_text())
            for stage in readiness.STAGES:
                with self.subTest(path=name, stage=stage), self.assertRaises(ValueError):
                    readiness.require_ready(data, readiness.ROOT, stage)

    def test_cli_defaults_to_a2_and_a1_pass_has_limited_scope(self):
        data = self.setup_record()
        path = self.root / 'manifest.json'
        path.write_bytes(canonical(data))
        args = [sys.executable, str(readiness.ROOT / 'checks/readiness.py'),
                '--require-ready', str(path), '--evidence-root', str(self.root)]
        default = subprocess.run(args, capture_output=True, text=True)
        self.assertEqual(default.returncode, 1)
        a1 = subprocess.run(args + ['--stage', 'A1'], capture_output=True, text=True)
        self.assertEqual(a1.returncode, 0, a1.stderr)
        self.assertIn('A1 ONLY', a1.stdout)
        self.assertNotEqual(subprocess.run(args + ['--stage', 'A3'], capture_output=True).returncode, 0)


if __name__ == '__main__':
    unittest.main()
