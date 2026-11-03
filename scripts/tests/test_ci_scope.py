import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / 'ci_scope.py'
spec = importlib.util.spec_from_file_location('ci_scope', SCRIPT)
scope = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scope)


class CIScopeTests(unittest.TestCase):
    def test_documentation_and_instructions_skip_product_gates(self):
        paths = ['docs/BACKLOG.md', 'AGENTS.md', 'CLAUDE.md', '.claude/commands/test.md',
                 '.agents/skills/source-command-test/SKILL.md', 'prosepal-ios/README.md',
                 'supabase/README.md', 'design-system/components/core/Avatar.prompt.md']
        self.assertEqual(scope.classify(paths), dict(native=False, supabase=False, codeql=False))

    def test_code_and_owning_tooling_select_relevant_gates(self):
        cases = {
            'prosepal-ios/Sources/ProsePalUI/View.swift': (True, False, False),
            'prosepal-ios/Package.swift': (True, False, False),
            'prosepal-ios/ProsePal.xcodeproj/project.pbxproj': (True, False, False),
            'prosepal-ios/App/ProsePalStaging.storekit': (True, False, False),
            'scripts/run_native_ui_tests.sh': (True, False, False),
            'supabase/functions/generate-card/index.ts': (False, True, True),
            'supabase/config.toml': (False, True, False),
            'supabase/migrations/001_example.sql': (False, True, False),
            'scripts/supabase-staging.sh': (False, True, False),
            'deno.lock': (False, True, True),
            'design-system/ui_kits/prosepal/screens.jsx': (False, False, True),
            'design-system/ui_kits/prosepal/index.html': (False, False, True),
            '.github/workflows/native-ui.yml': (True, False, True),
            '.github/workflows/codeql.yml': (False, False, True),
            '.github/workflows/supabase-keepalive.yml': (False, True, True),
            '.github/actions/example/action.yml': (True, True, True),
            '.github/workflows/ci.yml': (True, True, True),
            '.github/workflows/change-scope.yml': (True, True, True),
            'scripts/ci_scope.py': (True, True, True),
        }
        for path, expected in cases.items():
            with self.subTest(path=path):
                actual = scope.classify(['README.md', path])
                self.assertEqual(tuple(actual[key] for key in ('native', 'supabase', 'codeql')), expected)

    def test_scheduled_manual_and_unavailable_comparisons_run_full_gates(self):
        for event in ('schedule', 'workflow_dispatch'):
            with self.subTest(event=event):
                self.assertTrue(all(scope.classify(scope.changed_paths(event, {}, '')).values()))
        self.assertTrue(all(scope.classify(scope.changed_paths('push', {'before': '0' * 40}, 'a' * 40)).values()))

    def test_git_diff_handles_base_drift_deletions_and_renames(self):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.com',
                       GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.com',
                       GIT_CONFIG_GLOBAL='/dev/null', GIT_CONFIG_SYSTEM='/dev/null')

            def git(*args):
                return subprocess.check_output(['git', *args], cwd=directory, env=env, text=True).strip()

            def commit(path):
                target = Path(directory) / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text('example\n')
                git('add', '--all')
                git('commit', '--quiet', '-m', 'fixture')
                return git('rev-parse', 'HEAD')

            git('init', '--quiet', '--initial-branch=main')
            base = commit('prosepal-ios/Source.swift')
            git('switch', '--quiet', '-c', 'feature')
            docs_head = commit('docs/PRODUCT.md')
            git('switch', '--quiet', 'main')
            advanced_base = commit('supabase/functions/changed-on-main.ts')
            git('switch', '--quiet', 'feature')

            def classify_event(event_name, event, head):
                # Exercise the actual CLI, including GitHub output serialization.
                event_path = Path(directory) / 'event.json'
                output_path = Path(directory) / 'output'
                event_path.write_text(json.dumps(event))
                output_path.write_text('')
                subprocess.run(['python3', str(SCRIPT)], cwd=directory, check=True, capture_output=True,
                               env=dict(env, GITHUB_EVENT_NAME=event_name, GITHUB_EVENT_PATH=str(event_path),
                                        GITHUB_SHA=head, GITHUB_OUTPUT=str(output_path)), timeout=5)
                return dict(line.split('=') for line in output_path.read_text().splitlines())

            event = {'pull_request': {'base': {'sha': advanced_base}, 'head': {'sha': docs_head}}}
            self.assertEqual(classify_event('pull_request', event, docs_head),
                             dict(native='false', supabase='false', codeql='false'))
            git('mv', 'prosepal-ios/Source.swift', 'docs/old-source.md')
            git('commit', '--quiet', '-m', 'rename fixture')
            head = git('rev-parse', 'HEAD')
            self.assertEqual(classify_event('push', {'before': base}, head),
                             dict(native='true', supabase='false', codeql='false'))
            self.assertTrue(all(value == 'true' for value in
                                classify_event('push', {'before': 'f' * 40}, head).values()))


if __name__ == '__main__':
    unittest.main()
