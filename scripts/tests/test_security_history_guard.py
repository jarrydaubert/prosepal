from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
GUARD = REPO_ROOT / "scripts" / "security_history_guard.sh"


class SecurityHistoryGuardTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary_directory.name)
        self.env = os.environ.copy()
        self.env.update(
            {
                "GIT_AUTHOR_NAME": "Test Author",
                "GIT_AUTHOR_EMAIL": "author@example.com",
                "GIT_COMMITTER_NAME": "Test Committer",
                "GIT_COMMITTER_EMAIL": "committer@example.com",
                "GIT_CONFIG_GLOBAL": "/dev/null",
                "GIT_CONFIG_SYSTEM": "/dev/null",
            }
        )
        self.git("init", "--quiet")

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def git(self, *args: str) -> None:
        subprocess.run(
            ["git", *args],
            cwd=self.repo,
            env=self.env,
            check=True,
            capture_output=True,
            text=True,
        )

    def write(self, path: str, contents: str) -> None:
        destination = self.repo / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(contents)

    def commit_all(self, message: str) -> None:
        self.git("add", "--all")
        self.git("commit", "--quiet", "-m", message)

    def run_guard(
        self,
        *,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["/bin/bash", str(GUARD)],
            cwd=self.repo,
            env=env or self.env,
            check=False,
            capture_output=True,
            text=True,
        )

    def assert_guard_fails(self, expected_message: str) -> None:
        result = self.run_guard()
        self.assertNotEqual(result.returncode, 0, "expected guard failure")
        self.assertIn(expected_message, result.stderr)
        self.assertNotIn("Git history secret guard passed", result.stdout)

    def test_clean_history_passes_after_every_scan(self) -> None:
        self.write("README.md", "clean repository\n")
        self.write(".env.example", "PUBLIC_PLACEHOLDER=value\n")
        self.commit_all("clean baseline")

        result = self.run_guard()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Git history secret guard passed", result.stdout)

    def test_tracked_dotenv_file_fails(self) -> None:
        self.write(".env.local", "LOCAL_ONLY=value\n")
        self.commit_all("track local environment")

        self.assert_guard_fails("Tracked dotenv file is not allowed: .env.local")

    def test_historical_dotenv_file_fails_after_removal(self) -> None:
        self.write("config/.env.staging", "STAGING_ONLY=value\n")
        self.commit_all("add historical environment")
        self.git("rm", "--quiet", "config/.env.staging")
        self.git("commit", "--quiet", "-m", "remove historical environment")

        self.assert_guard_fails(
            "Historical dotenv file is not allowed: config/.env.staging"
        )

    def test_renamed_dotenv_to_example_fails(self) -> None:
        self.write(".env.local", "LOCAL_ONLY=value\n")
        self.commit_all("add local environment")
        self.git("mv", ".env.local", ".env.example")
        self.git("commit", "--quiet", "-m", "rename to example environment")

        self.assert_guard_fails(
            "Historical dotenv file is not allowed: .env.local"
        )

    def test_copied_dotenv_to_example_then_deleted_fails(self) -> None:
        self.write(".env.local", "LOCAL_ONLY=value\n")
        self.commit_all("add local environment")
        self.write(".env.example", "LOCAL_ONLY=value\n")
        self.commit_all("copy to example environment")
        self.git("rm", "--quiet", ".env.local")
        self.git("commit", "--quiet", "-m", "remove local environment")

        self.assert_guard_fails(
            "Historical dotenv file is not allowed: .env.local"
        )

    def test_high_risk_secret_pattern_fails(self) -> None:
        secret_assignment = (
            "SUPABASE_SERVICE_ROLE"
            + '_KEY="'
            + "abcdefghijklmnopqrstuvwxyz123456"
            + '"\n'
        )
        self.write(
            "config.txt",
            secret_assignment,
        )
        self.commit_all("add leaked credential")

        self.assert_guard_fails(
            "Rotate affected keys and rewrite history before merging"
        )

    def test_missing_required_tool_fails_closed(self) -> None:
        self.write("README.md", "clean repository\n")
        self.commit_all("clean baseline")
        empty_path = self.repo / "empty-path"
        empty_path.mkdir()
        restricted_env = self.env.copy()
        restricted_env["PATH"] = str(empty_path)

        result = self.run_guard(env=restricted_env)

        self.assertNotEqual(result.returncode, 0, "expected missing tool failure")
        self.assertIn("Missing required command: git", result.stderr)
        self.assertNotIn("Git history secret guard passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
