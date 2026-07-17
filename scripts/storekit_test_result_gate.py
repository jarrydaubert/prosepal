#!/usr/bin/env python3

"""Reject an app-hosted StoreKit result unless every expected test passed."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


REQUIRED_COUNT_FIELDS = (
    "totalTestCount",
    "passedTests",
    "failedTests",
    "skippedTests",
)


def validate_summary(summary: dict[str, Any], expected_count: int) -> list[str]:
    errors: list[str] = []
    counts: dict[str, int] = {}

    for field in REQUIRED_COUNT_FIELDS:
        value = summary.get(field)
        if type(value) is not int or value < 0:
            errors.append(f"{field} must be a non-negative integer")
        else:
            counts[field] = value

    if errors:
        return errors

    total = counts["totalTestCount"]
    passed = counts["passedTests"]
    failed = counts["failedTests"]
    skipped = counts["skippedTests"]

    if total != expected_count:
        errors.append(f"expected {expected_count} tests, but xcresult reported {total}")
    if failed != 0:
        errors.append(f"failedTests must be 0, but was {failed}")
    if skipped != 0:
        errors.append(f"skippedTests must be 0, but was {skipped}")
    if passed != total:
        errors.append(f"passedTests must equal totalTestCount ({total}), but was {passed}")
    if passed + failed + skipped != total:
        errors.append(
            "passedTests + failedTests + skippedTests must equal totalTestCount"
        )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("summary", type=Path)
    parser.add_argument("--expected-count", type=int, required=True)
    args = parser.parse_args()

    if args.expected_count <= 0:
        parser.error("--expected-count must be positive")

    try:
        loaded = json.loads(args.summary.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"StoreKit release gate could not read xcresult summary: {error}", file=sys.stderr)
        return 1

    if not isinstance(loaded, dict):
        print("StoreKit release gate expected a JSON object", file=sys.stderr)
        return 1

    errors = validate_summary(loaded, args.expected_count)
    if errors:
        print("StoreKit release gate failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        "StoreKit release gate passed: "
        f"{loaded['passedTests']} passed, 0 failed, 0 skipped."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
