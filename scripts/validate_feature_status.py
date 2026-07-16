#!/usr/bin/env python3
"""Validate ProsePal's canonical feature-status JSONL ledger and CSV export."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from datetime import date
from pathlib import Path
from typing import Any

from export_feature_status_csv import (
    ARRAY_FIELDS,
    CSV_PATH,
    FIELD_ORDER,
    JSONL_PATH,
    REPO_ROOT,
    render_csv,
)


EXPECTED_RECORD_COUNT = 63
EXPECTED_IDS = tuple(f"US-{number:03d}" for number in range(1, EXPECTED_RECORD_COUNT + 1))
IMPLEMENTATION_STATUSES = frozenset({"Implemented", "Partial", "Removed"})
VERIFICATION_STATUSES = frozenset({"Verified", "Partial", "Unverified"})
ID_PATTERN = re.compile(r"US-\d{3}\Z")
COMMIT_PATTERN = re.compile(r"[0-9a-f]{7,40}\Z")
DATE_PATTERN = re.compile(r"\d{4}-\d{2}-\d{2}\Z")
REMOVAL_LANGUAGE = re.compile(
    r"\b(?:no|removed|absent|unavailable|does not|not expose|typed input only)\b",
    re.IGNORECASE,
)
PLACEHOLDER_REMAINDER = re.compile(
    r"\b(?:tbd|todo|tracked in backlog|see backlog|remaining work)\b",
    re.IGNORECASE,
)

# These labels describe retired user-facing concepts. They may name the removed
# ledger row or appear in compatibility/history notes, but must not drift back
# into descriptions of current behaviour.
OBSOLETE_TERMS = (
    "register selector",
    "take more care",
    "voice capture",
)


def canonical_json(record: dict[str, Any]) -> str:
    return json.dumps(record, ensure_ascii=False, separators=(",", ":"))


def parse_jsonl(errors: list[str]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    try:
        lines = JSONL_PATH.read_text(encoding="utf-8").splitlines(keepends=True)
    except OSError as error:
        errors.append(f"cannot read {JSONL_PATH.relative_to(REPO_ROOT)}: {error}")
        return records

    if not lines:
        errors.append("feature-status JSONL is empty")
        return records
    if not lines[-1].endswith("\n"):
        errors.append("feature-status JSONL must end with a newline")

    for line_number, raw_line in enumerate(lines, start=1):
        line = raw_line.removesuffix("\n")
        if line.endswith("\r"):
            errors.append(f"line {line_number}: use LF rather than CRLF")
            line = line[:-1]
        if not line:
            errors.append(f"line {line_number}: blank lines are not allowed")
            continue
        try:
            value = json.loads(line)
        except json.JSONDecodeError as error:
            errors.append(f"line {line_number}: invalid JSON: {error.msg}")
            continue
        if not isinstance(value, dict):
            errors.append(f"line {line_number}: each JSONL value must be an object")
            continue
        if tuple(value.keys()) != FIELD_ORDER:
            errors.append(
                f"line {line_number}: fields must appear exactly in canonical order: "
                + ", ".join(FIELD_ORDER)
            )
        if line != canonical_json(value):
            errors.append(
                f"line {line_number}: JSON formatting is not canonical; "
                "use compact UTF-8 JSON with no extra whitespace"
            )
        records.append(value)
    return records


# Deliberately gitignored private release evidence (screenshots, device
# captures). References into this root are validated for existence only where
# the local evidence store is present; a clean checkout (CI) cannot see these
# files by design, so there their repository-relative shape is still enforced
# but disk existence is not.
LOCAL_EVIDENCE_ROOT = Path("prosepal-ios/evidence")


def check_path(reference: str, field: str, record_id: str, errors: list[str]) -> None:
    path = Path(reference)
    if path.is_absolute() or ".." in path.parts:
        errors.append(f"{record_id}.{field}: reference must be repository-relative: {reference}")
        return
    candidate = REPO_ROOT / path
    if candidate.is_file():
        return
    is_local_evidence = path.parts[: len(LOCAL_EVIDENCE_ROOT.parts)] == LOCAL_EVIDENCE_ROOT.parts
    if is_local_evidence and not (REPO_ROOT / LOCAL_EVIDENCE_ROOT).is_dir():
        return
    errors.append(f"{record_id}.{field}: referenced file does not exist: {reference}")


def validate_record(record: dict[str, Any], index: int, errors: list[str]) -> None:
    record_id = record.get("id", f"record {index}")
    if set(record) != set(FIELD_ORDER):
        missing = sorted(set(FIELD_ORDER) - set(record))
        extra = sorted(set(record) - set(FIELD_ORDER))
        errors.append(f"{record_id}: missing fields={missing}; extra fields={extra}")
        return

    valid_types: dict[str, bool] = {}
    for field in FIELD_ORDER:
        value = record[field]
        if field in ARRAY_FIELDS:
            if not isinstance(value, list):
                errors.append(f"{record_id}.{field}: expected an array")
                valid_types[field] = False
                continue
            valid_types[field] = True
            entries_are_strings = all(
                isinstance(item, str) and bool(item.strip()) for item in value
            )
            if not entries_are_strings:
                errors.append(f"{record_id}.{field}: array entries must be non-empty strings")
            if entries_are_strings and len(value) != len(set(value)):
                errors.append(f"{record_id}.{field}: duplicate array entries are not allowed")
        else:
            valid_types[field] = isinstance(value, str) and bool(value.strip())
            if not valid_types[field]:
                errors.append(f"{record_id}.{field}: expected a non-empty string")

    if not valid_types["id"] or not ID_PATTERN.fullmatch(record["id"]):
        errors.append(f"{record_id}.id: expected US-NNN")
    implementation_status = (
        record["implementation_status"] if valid_types["implementation_status"] else None
    )
    verification_status = (
        record["verification_status"] if valid_types["verification_status"] else None
    )
    if implementation_status not in IMPLEMENTATION_STATUSES:
        errors.append(
            f"{record_id}.implementation_status: expected one of "
            f"{sorted(IMPLEMENTATION_STATUSES)}"
        )
    if verification_status not in VERIFICATION_STATUSES:
        errors.append(
            f"{record_id}.verification_status: expected one of "
            f"{sorted(VERIFICATION_STATUSES)}"
        )

    external_remaining = (
        record["external_evidence_remaining"]
        if valid_types["external_evidence_remaining"]
        else []
    )
    known_defects = record["known_defects"] if valid_types["known_defects"] else []
    remainders = external_remaining + known_defects
    if verification_status == "Partial" and not remainders:
        errors.append(
            f"{record_id}: Partial verification must state the remaining evidence or defect"
        )
    if verification_status == "Verified" and remainders:
        errors.append(
            f"{record_id}: Verified records cannot carry unresolved evidence or defects"
        )
    if verification_status == "Unverified" and not external_remaining:
        errors.append(
            f"{record_id}: Unverified records must state what verification evidence is missing"
        )

    for field in ("code_evidence", "test_evidence", "backlog_references"):
        value = record[field]
        if isinstance(value, list):
            for reference in value:
                if isinstance(reference, str):
                    check_path(reference, field, record_id, errors)

    if implementation_status == "Implemented":
        if not record["code_evidence"] or not record["test_evidence"]:
            errors.append(f"{record_id}: Implemented features require code and test evidence")
        if verification_status == "Unverified":
            errors.append(f"{record_id}: Implemented features cannot be Unverified")

    if implementation_status == "Partial":
        if verification_status != "Partial":
            errors.append(f"{record_id}: Partial implementation requires Partial verification")
        if not remainders:
            errors.append(
                f"{record_id}: Partial features must state the concrete remaining evidence or defect"
            )
        if "docs/BACKLOG.md" not in record["backlog_references"]:
            errors.append(f"{record_id}: Partial features require docs/BACKLOG.md")
        for remainder in remainders:
            if PLACEHOLDER_REMAINDER.search(remainder):
                errors.append(
                    f"{record_id}: Partial remainder must be concrete rather than a placeholder: "
                    f"{remainder}"
                )

    if implementation_status == "Removed":
        if not valid_types["expected_behaviour"] or not REMOVAL_LANGUAGE.search(
            record["expected_behaviour"]
        ):
            errors.append(
                f"{record_id}: Removed features must describe the absence of the active control"
            )
        if not record["code_evidence"] or not record["test_evidence"]:
            errors.append(f"{record_id}: Removed features require removal evidence")

    for field in FIELD_ORDER:
        if field == "compatibility_notes":
            continue
        if field == "feature" and implementation_status == "Removed":
            continue
        value = record[field]
        texts = value if isinstance(value, list) else [value]
        for text in texts:
            if not isinstance(text, str):
                continue
            lowered = text.casefold()
            for term in OBSOLETE_TERMS:
                if term in lowered:
                    errors.append(
                        f"{record_id}.{field}: obsolete term {term!r} belongs only in the "
                        "removed feature label or compatibility notes"
                    )

    if not valid_types["last_verified_commit"] or not COMMIT_PATTERN.fullmatch(
        record["last_verified_commit"]
    ):
        errors.append(f"{record_id}.last_verified_commit: expected a 7-40 character Git hash")
    else:
        result = subprocess.run(
            ["git", "cat-file", "-e", f"{record['last_verified_commit']}^{{commit}}"],
            cwd=REPO_ROOT,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            errors.append(
                f"{record_id}.last_verified_commit: commit is not available in this checkout: "
                f"{record['last_verified_commit']}"
            )
    try:
        if not valid_types["last_verified_date"] or not DATE_PATTERN.fullmatch(
            record["last_verified_date"]
        ):
            raise ValueError
        date.fromisoformat(record["last_verified_date"])
    except (TypeError, ValueError):
        errors.append(f"{record_id}.last_verified_date: expected YYYY-MM-DD")


def main() -> int:
    errors: list[str] = []
    records = parse_jsonl(errors)

    if len(records) != EXPECTED_RECORD_COUNT:
        errors.append(
            f"expected exactly {EXPECTED_RECORD_COUNT} records; found {len(records)}"
        )
    ids = [record.get("id") for record in records]
    string_ids = [record_id for record_id in ids if isinstance(record_id, str)]
    if len(string_ids) != len(set(string_ids)):
        errors.append("feature IDs must be unique")
    if tuple(ids) != EXPECTED_IDS:
        errors.append(
            "feature records must be ordered deterministically as the complete "
            "US-001 through US-063 sequence"
        )

    for index, record in enumerate(records, start=1):
        validate_record(record, index, errors)

    if records:
        try:
            expected_csv = render_csv(records)
        except (KeyError, TypeError, ValueError) as error:
            errors.append(f"cannot render generated CSV from invalid JSONL: {error}")
            expected_csv = None
        try:
            actual_csv = CSV_PATH.read_text(encoding="utf-8")
        except OSError as error:
            errors.append(f"cannot read generated CSV: {error}")
        else:
            if expected_csv is not None and actual_csv != expected_csv:
                errors.append(
                    "generated CSV does not match JSONL; run "
                    "python3 scripts/export_feature_status_csv.py"
                )

    if errors:
        print("Feature-status validation failed:", file=sys.stderr)
        for error in sorted(set(errors)):
            print(f"- {error}", file=sys.stderr)
        return 1

    verified = sum(record["verification_status"] == "Verified" for record in records)
    partial = sum(record["verification_status"] == "Partial" for record in records)
    print(
        f"Feature-status validation passed ({len(records)} records; "
        f"{verified} verified; {partial} partially verified)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
