import subprocess
import tempfile
import unittest
from pathlib import Path


VALIDATOR = Path(__file__).resolve().parents[1] / 'validate_docs.sh'


class ValidateDocsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.write('scripts/validate_docs.sh', VALIDATOR.read_text())
        for name in ('AGENTS.md', 'CLAUDE.md', 'README.md', 'SECURITY.md',
                     'prosepal-ios/README.md', 'supabase/README.md', 'design-system/readme.md'):
            self.write(name, '')
        self.write('docs/BACKLOG.md', '- [ ] Unresolved work\n')

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def run_validator(self):
        return subprocess.run(['bash', 'scripts/validate_docs.sh'], cwd=self.root,
                              capture_output=True, text=True, timeout=5)

    def test_completed_backlog_entries_fail(self):
        for marker in ('x', 'X'):
            with self.subTest(marker=marker):
                self.write('docs/BACKLOG.md', f'- [ ] Open\n  - [{marker}] Completed\n')
                result = self.run_validator()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('docs/BACKLOG.md:2: completed checkbox', result.stderr)

    def test_valid_recursive_links_pass_without_index_or_manifest(self):
        self.write('design-system/assets/example file.svg', '<svg/>')
        self.write('design-system/components/core/Avatar.prompt.md',
                   '[Example](../../assets/example%20file.svg#preview)\n- [x] Visual example\n')
        self.write('design-system/ui_kits/example/index.html',
                   '<a href="../../components/core/Avatar.prompt.md?view=1#example">Example</a>'
                   "<img src='../../assets/example%20file.svg'>"
                   '<a href="https://example.com/remote">Remote</a>'
                   '<a href="#preview">Fragment</a><img src="/web-root.svg">')
        result = self.run_validator()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_broken_recursive_links_fail(self):
        for name, content in (
            ('components/core/Avatar.prompt.md', '[Missing](missing.md)'),
            ('ui_kits/example/index.html', '<a href="missing.html">Missing</a>'),
            ('ui_kits/example/index.html', "<img src='missing.svg'>"),
        ):
            with self.subTest(name=name, content=content):
                path = f'design-system/{name}'
                self.write(path, content)
                result = self.run_validator()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(f'{path}: broken local link: missing.', result.stderr)
                (self.root / path).unlink()


if __name__ == '__main__':
    unittest.main()
