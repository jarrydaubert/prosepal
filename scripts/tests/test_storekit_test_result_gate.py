from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
GATE = REPO_ROOT / "scripts" / "storekit_test_result_gate.py"


class StoreKitTestResultGateTests(unittest.TestCase):
    def run_gate(self, summary: dict[str, object]) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            summary_path = Path(directory) / "summary.json"
            summary_path.write_text(json.dumps(summary), encoding="utf-8")
            return subprocess.run(
                [
                    sys.executable,
                    str(GATE),
                    str(summary_path),
                    "--expected-count",
                    "12",
                ],
                check=False,
                capture_output=True,
                text=True,
            )

    def test_zero_failed_and_zero_skipped_with_expected_count_passes(self) -> None:
        result = self.run_gate(
            {
                "totalTestCount": 12,
                "passedTests": 12,
                "failedTests": 0,
                "skippedTests": 0,
            }
        )

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_any_skipped_storekit_test_rejects_release_gate(self) -> None:
        result = self.run_gate(
            {
                "totalTestCount": 12,
                "passedTests": 11,
                "failedTests": 0,
                "skippedTests": 1,
            }
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("skippedTests must be 0", result.stderr)

    def test_any_failed_storekit_test_rejects_release_gate(self) -> None:
        result = self.run_gate(
            {
                "totalTestCount": 12,
                "passedTests": 11,
                "failedTests": 1,
                "skippedTests": 0,
            }
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("failedTests must be 0", result.stderr)

    def test_missing_scenarios_reject_release_gate(self) -> None:
        result = self.run_gate(
            {
                "totalTestCount": 11,
                "passedTests": 11,
                "failedTests": 0,
                "skippedTests": 0,
            }
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected 12 tests", result.stderr)


if __name__ == "__main__":
    unittest.main()
