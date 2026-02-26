#!/bin/bash

set -euo pipefail

UPDATE=0
if [[ "${1:-}" == "--update" ]]; then
  UPDATE=1
  shift
fi

CMD=(flutter test test/widgets/goldens/critical_screens_golden_test.dart)
if [[ "$UPDATE" -eq 1 ]]; then
  CMD+=(--update-goldens)
fi

"${CMD[@]}" "$@"

echo
echo "Visual regression suite complete."
echo "Golden failures/diffs are written under: test/failures/"
