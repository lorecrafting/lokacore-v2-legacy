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

    def test_f1_valid_partial_inventory_does_not_require_other_native_fields(self):
        for platform, minimum, target in (('ios', '16.4', 'iphone-11'),
                                          ('android', '10', 'galaxy-a14-4gb')):
            for field, value in (('qualification_class', target), ('installed_ram_gb', 4),
                                 ('architecture', 'arm64'), ('os_version', minimum),
                                 ('model', 'owner-reported partial inventory')):
                data = self.setup_record()
                data['devices'][platform][field] = value
                self.bind(data, 'A1')
                with self.subTest(platform=platform, field=field):
                    readiness.require_ready(data, self.root, 'A1')

    def test_f1_supplied_device_semantics_reject_even_after_review_rebinding(self):
        for platform in ('ios', 'android'):
            for field, value in (('qualification_class', 'iphone-se-2'),
                                 ('installed_ram_gb', 3), ('installed_ram_gb', True),
                                 ('architecture', 'x86_64'), ('os_version', 'latest'),
                                 ('os_version', '9'), ('os_version', '16.x'),
                                 ('os_version', 17), ('os_version', '１７.０')):
                data = self.setup_record()
                data['devices'][platform][field] = value
                self.bind(data, 'A1')
                with self.subTest(platform=platform, field=field, value=value):
                    with self.assertRaisesRegex(ValueError, 'device detail'):
                        readiness.require_ready(data, self.root, 'A1')
        data = self.setup_record()
        data['devices']['ios']['os_version'] = '16.3.9'
        self.bind(data, 'A1')
        with self.assertRaises(ValueError):
            readiness.require_ready(data, self.root, 'A1')

    def test_f2_full_runtime_versions_are_runtime_specific_at_both_stages(self):
        versions = {'node': '24.21.0', 'typescript': '6.0.3',
                    'elixir': '1.20.4', 'otp': '28.4'}
        for stage in readiness.STAGES:
            for tool, version in versions.items():
                data = self.setup_record(stage, deferred=stage == 'A1')
                data['toolchain'][tool] = version
                self.bind(data, stage)
                readiness.require_ready(data, self.root, stage)
            for version in ('28.4.1', '28.4.1.2'):
                data = self.setup_record(stage, deferred=stage == 'A1')
                data['toolchain']['otp'] = version
                self.bind(data, stage)
                readiness.require_ready(data, self.root, stage)
        data = self.setup_record()
        data['toolchain']['elixir'] = '1.20.4+build.7'
        self.bind(data, 'A1')
        readiness.require_ready(data, self.root, 'A1')

    def test_non_a1_tool_rejects_non_ascii_digits_like_elixir(self):
        for value in ('٢٨', '１６.２'):
            data = self.setup_record('A2', deferred=False)
            data['toolchain']['xcode'] = value
            self.bind(data, 'A2')
            with self.subTest(value=value):
                with self.assertRaisesRegex(ValueError, 'exact stable version/build'):
                    readiness.require_ready(data, self.root, 'A2')

    def test_f2_partial_ranged_hash_and_malformed_runtime_identities_reject(self):
        for stage in readiness.STAGES:
            for tool in readiness.A1_TOOLS:
                bad = ['latest', '^24.21.0', '1.2.x', '1.2.3-rc1', '1..2',
                       'a' * 40, '1' * 40, '0' * 40, '', None, 28, '２８.４']
                bad += ['28', '28.4**', '28.4+patched'] if tool == 'otp' else [
                    '24', '1.20', '1.2.3.4', '01.2.3', '1.2.3+', '1.2.3+a..b']
                for value in bad:
                    data = self.setup_record(stage, deferred=stage == 'A1')
                    data['toolchain'][tool] = value
                    self.bind(data, stage)
                    with self.subTest(stage=stage, tool=tool, value=value):
                        with self.assertRaisesRegex(ValueError, 'exact stable version/build'):
                            readiness.require_ready(data, self.root, stage)

    def test_f3_invalid_explicit_stage_is_controlled_but_other_syntax_stays_argparse(self):
        base = [sys.executable, str(readiness.ROOT / 'checks/readiness.py')]
        for mode in (['--check-template'], ['--require-ready',
                     str(readiness.ROOT / 'prep/after-pr-10/setup.pending.json')]):
            for stage in ('A3', 'a1'):
                result = subprocess.run(base + mode + ['--stage', stage],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn('NOT READY: unsupported readiness stage', result.stderr)
        syntax = subprocess.run(base + ['--check-template', '--unexpected'],
                                capture_output=True, text=True)
        self.assertEqual(syntax.returncode, 2)

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

    def test_real_setup_is_a1_only_and_template_rejects_both_stages(self):
        # The real setup holds genuine A1 approvals (2026-09-23); it must still fail A2.
        template = strict_json((readiness.ROOT / 'conformance/r1-run-manifest.template.json').read_text())
        real = strict_json((readiness.ROOT / 'prep/after-pr-10/setup.pending.json').read_text())
        for stage in readiness.STAGES:
            with self.subTest(path='template', stage=stage), self.assertRaises(ValueError):
                readiness.require_ready(template, readiness.ROOT, stage)
        readiness.require_ready(real, readiness.ROOT, 'A1')
        with self.assertRaises(ValueError):
            readiness.require_ready(real, readiness.ROOT, 'A2')

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
        self.assertEqual(subprocess.run(args + ['--stage', 'A3'], capture_output=True).returncode, 1)


if __name__ == '__main__':
    unittest.main()
