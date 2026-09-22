"""Presentation regression tests; they do not validate engine semantics."""
from pathlib import Path
import shutil
import tempfile
import unittest

import packet_navigation as nav


class ReaderNavigationTests(unittest.TestCase):
    def test_packet_navigation_and_links(self):
        nav.validate()

    def test_generator_preserves_every_document_body(self):
        for name in nav.DOCUMENTS:
            with self.subTest(name=name):
                text = (nav.ROOT / name).read_text()
                body = nav.strip_navigation(text)
                self.assertEqual(body, nav.strip_navigation(nav.render(name, body)))
                self.assertEqual(nav.render(name, text), nav.render(name, nav.render(name, text)))

    def test_code_fences_do_not_create_headings(self):
        text = '# Title\n\n## Real\n\n```yaml\n## Not a section\n```\n~~~\n## Nor this\n~~~\n'
        self.assertEqual([h[1] for h in nav.headings(text)], ['Title', 'Real'])

    def test_heading_slug_and_duplicate_collision(self):
        text = '# Test\n## R3 — Contract/schema foundation\n## Same\n## Same\n## Same-1\n'
        self.assertEqual([h[2] for h in nav.headings(text)],
                         ['test', 'r3--contractschema-foundation', 'same', 'same-1', 'same-1-1'])

    def test_malformed_navigation_fails_closed(self):
        for text in [nav.START, nav.END, nav.START + nav.START + nav.END,
                     nav.END + nav.START, nav.START + nav.END]:
            with self.subTest(text=text), self.assertRaises(ValueError):
                nav.strip_navigation(text)

    def test_unclosed_fence_fails(self):
        with self.assertRaises(ValueError):
            list(nav.headings('# Title\n```python\nx = 1'))

    def test_stale_menu_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'packet'
            shutil.copytree(nav.ROOT, root)
            path = root / '01-core-principles.md'
            path.write_text(path.read_text().replace('## 1. Product principles', '## 1. Renamed principles'))
            with self.assertRaisesRegex(ValueError, 'stale navigation'):
                nav.validate(root)

    def test_missing_milestone_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'packet'
            shutil.copytree(nav.ROOT, root)
            path = root / 'R-MILESTONES.md'
            path.write_text('\n'.join(l for l in path.read_text().splitlines() if not l.startswith('| [R6P]')))
            with self.assertRaisesRegex(ValueError, 'each top-level R'):
                nav.validate(root)

    def test_bad_local_file_and_heading_links_are_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for target in ['missing.md', '#missing-section']:
                (root / 'a.md').write_text(f'# Present\n\n[broken]({target})\n')
                with self.subTest(target=target), self.assertRaisesRegex(ValueError, 'missing local'):
                    nav.validate_links(root)

    def test_reference_documents_are_labeled_informative(self):
        for prefix in ['12-', '13-', '17-', '18-', '20-', '22-']:
            name = next(n for n in nav.DOCUMENTS if n.startswith(prefix))
            self.assertTrue(nav.DOCUMENTS[name][0].startswith('Informative'))


if __name__ == '__main__':
    unittest.main()
