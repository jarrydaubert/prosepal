from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
GUARD = REPO_ROOT / "scripts" / "check_commit_attribution.sh"

TRUSTED_BOT_TRAILER = (
    "Co-authored-by: Copilot Autofix powered by AI "
    "<62310815+github-advanced-security[bot]@users.noreply.github.com>"
)
GITHUB_COMMITTER = ("GitHub", "noreply@github.com")
HUMAN_COMMITTER = ("Test Human", "human@example.com")


class CheckCommitAttributionTests(unittest.TestCase):
    def run_guard_on_commit(
        self,
        message: str,
        committer: tuple[str, str],
    ) -> subprocess.CompletedProcess[str]:
        """Create a throwaway repo with a base commit plus one commit under
        test, then run the guard over exactly that commit."""
        with tempfile.TemporaryDirectory() as directory:
            env = os.environ.copy()
            env.update(
                {
                    "GIT_AUTHOR_NAME": "Test Author",
                    "GIT_AUTHOR_EMAIL": "author@example.com",
                    "GIT_COMMITTER_NAME": committer[0],
                    "GIT_COMMITTER_EMAIL": committer[1],
                    "GIT_CONFIG_GLOBAL": "/dev/null",
                    "GIT_CONFIG_SYSTEM": "/dev/null",
                }
            )

            def git(*args: str) -> None:
                subprocess.run(
                    ["git", *args],
                    cwd=directory,
                    env=env,
                    check=True,
                    capture_output=True,
                    text=True,
                )

            git("init", "--quiet")
            git("commit", "--allow-empty", "--quiet", "-m", "base commit")
            git("commit", "--allow-empty", "--quiet", "-m", message)

            return subprocess.run(
                [str(GUARD), "--range", "HEAD~1..HEAD"],
                cwd=directory,
                env=env,
                check=False,
                capture_output=True,
                text=True,
            )

    def assert_passes(self, message: str, committer: tuple[str, str]) -> None:
        result = self.run_guard_on_commit(message, committer)
        self.assertEqual(
            result.returncode,
            0,
            f"expected guard pass, got: {result.stderr}",
        )

    def assert_fails(self, message: str, committer: tuple[str, str]) -> None:
        result = self.run_guard_on_commit(message, committer)
        self.assertNotEqual(result.returncode, 0, "expected guard failure")
        self.assertIn("Co-authored-by trailer", result.stderr)

    def test_plain_commit_without_trailer_passes(self) -> None:
        self.assert_passes("normal change", HUMAN_COMMITTER)

    def test_trusted_security_autofix_with_github_committer_passes(self) -> None:
        self.assert_passes(
            f"Potential fix for a code scanning finding\n\n{TRUSTED_BOT_TRAILER}",
            GITHUB_COMMITTER,
        )

    def test_trusted_trailer_without_github_committer_fails(self) -> None:
        self.assert_fails(
            f"Locally crafted commit\n\n{TRUSTED_BOT_TRAILER}",
            HUMAN_COMMITTER,
        )

    def test_spoofed_numeric_identity_fails(self) -> None:
        spoofed = TRUSTED_BOT_TRAILER.replace("62310815", "99999999")
        self.assert_fails(f"Spoofed fix\n\n{spoofed}", GITHUB_COMMITTER)

    def test_lookalike_bot_name_fails(self) -> None:
        spoofed = TRUSTED_BOT_TRAILER.replace(
            "github-advanced-security[bot]",
            "github-advanced-security2[bot]",
        )
        self.assert_fails(f"Spoofed fix\n\n{spoofed}", GITHUB_COMMITTER)

    def test_non_noreply_domain_fails(self) -> None:
        spoofed = TRUSTED_BOT_TRAILER.replace(
            "@users.noreply.github.com",
            "@users.noreply.github.com.evil.example",
        )
        self.assert_fails(f"Spoofed fix\n\n{spoofed}", GITHUB_COMMITTER)

    def test_arbitrary_human_coauthor_fails(self) -> None:
        self.assert_fails(
            "Pairing session\n\nCo-authored-by: Someone Else <someone@example.com>",
            HUMAN_COMMITTER,
        )

    def test_human_coauthor_with_allow_marker_passes(self) -> None:
        self.assert_passes(
            "Pairing session\n\n[allow-coauthor]\n\n"
            "Co-authored-by: Someone Else <someone@example.com>",
            HUMAN_COMMITTER,
        )

    def test_trusted_trailer_plus_extra_human_trailer_fails(self) -> None:
        self.assert_fails(
            f"Mixed attribution\n\n{TRUSTED_BOT_TRAILER}\n"
            "Co-authored-by: Someone Else <someone@example.com>",
            GITHUB_COMMITTER,
        )


if __name__ == "__main__":
    unittest.main()
