#!/usr/bin/env python3
"""Export the canonical feature-status JSONL ledger as a generated CSV."""

from __future__ import annotations

import argparse
import csv
import io
import json
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
JSONL_PATH = REPO_ROOT / "docs/reference/feature-status.jsonl"
CSV_PATH = REPO_ROOT / "docs/reference/feature-status.csv"
GENERATED_NOTICE = (
    "# GENERATED FILE - DO NOT EDIT. "
    "Source: docs/reference/feature-status.jsonl"
)
FIELD_ORDER = (
    "id",
    "area",
    "feature",
    "user_story",
    "expected_behaviour",
    "implementation_status",
    "verification_status",
    "code_evidence",
    "test_evidence",
    "external_evidence_remaining",
    "known_defects",
    "backlog_references",
    "compatibility_notes",
    "last_verified_commit",
    "last_verified_date",
)
ARRAY_FIELDS = frozenset(
    {
        "code_evidence",
        "test_evidence",
        "external_evidence_remaining",
        "known_defects",
        "backlog_references",
        "compatibility_notes",
    }
)


def load_records(path: Path = JSONL_PATH) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, start=1):
            if not line.strip():
                raise ValueError(f"blank JSONL line at {path}:{line_number}")
            value = json.loads(line)
            if not isinstance(value, dict):
                raise ValueError(f"JSONL value is not an object at {path}:{line_number}")
            records.append(value)
    return records


def render_csv(records: list[dict[str, Any]]) -> str:
    output = io.StringIO(newline="")
    output.write(f"{GENERATED_NOTICE}\n")
    writer = csv.DictWriter(output, fieldnames=FIELD_ORDER, lineterminator="\n")
    writer.writeheader()
    for record in records:
        row: dict[str, str] = {}
        for field in FIELD_ORDER:
            value = record[field]
            row[field] = "; ".join(value) if field in ARRAY_FIELDS else value
        writer.writerow(row)
    return output.getvalue()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="fail if the generated CSV differs from the checked-in export",
    )
    args = parser.parse_args()

    try:
        records = load_records()
        rendered = render_csv(records)
    except (OSError, ValueError, json.JSONDecodeError, KeyError, TypeError) as error:
        print(f"Feature-status export failed: {error}", file=sys.stderr)
        return 1

    if args.check:
        try:
            current = CSV_PATH.read_text(encoding="utf-8")
        except OSError as error:
            print(f"Feature-status export check failed: {error}", file=sys.stderr)
            return 1
        if current != rendered:
            print(
                "Generated feature-status CSV is stale. Run "
                "python3 scripts/export_feature_status_csv.py.",
                file=sys.stderr,
            )
            return 1
        print("Generated feature-status CSV matches the canonical JSONL ledger.")
        return 0

    CSV_PATH.write_text(rendered, encoding="utf-8", newline="")
    print(
        f"Exported {len(records)} feature records to "
        f"{CSV_PATH.relative_to(REPO_ROOT)}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
