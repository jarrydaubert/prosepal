#!/bin/bash

set -euo pipefail

LCOV_FILE="${1:-coverage/lcov.info}"
SERVICE_PATH_MATCH="${SERVICE_PATH_MATCH:-lib/core/services/}"
MIN_COVERAGE="${MIN_COVERAGE:-35}"

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "Coverage file not found: $LCOV_FILE" >&2
  exit 1
fi

if ! [[ "$MIN_COVERAGE" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Invalid MIN_COVERAGE value: $MIN_COVERAGE" >&2
  exit 1
fi

read -r hit_lines total_lines < <(
  awk -v needle="$SERVICE_PATH_MATCH" '
    BEGIN { in_scope = 0; hit = 0; total = 0 }
    /^SF:/ {
      file = substr($0, 4)
      in_scope = index(file, needle) > 0
      next
    }
    in_scope && /^DA:/ {
      split(substr($0, 4), fields, ",")
      total++
      if ((fields[2] + 0) > 0) {
        hit++
      }
    }
    END { printf "%d %d\n", hit, total }
  ' "$LCOV_FILE"
)

if [[ "$total_lines" -eq 0 ]]; then
  echo "No coverage lines found matching: $SERVICE_PATH_MATCH" >&2
  exit 1
fi

coverage_pct="$(
  awk -v hit="$hit_lines" -v total="$total_lines" 'BEGIN { printf "%.2f", (hit * 100.0) / total }'
)"

echo "Service coverage: $coverage_pct% (hit $hit_lines / total $total_lines, threshold $MIN_COVERAGE%)"

if ! awk -v actual="$coverage_pct" -v min="$MIN_COVERAGE" 'BEGIN { exit (actual + 0.00001 < min) ? 1 : 0 }'; then
  echo "Service coverage gate failed: $coverage_pct% < $MIN_COVERAGE%" >&2
  exit 1
fi

echo "Service coverage gate passed."
