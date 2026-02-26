#!/bin/bash
# Remove generated local artifacts for a clean working tree.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

DRY_RUN=0
DEEP=0

usage() {
  cat <<'EOF'
Usage: ./scripts/cleanup.sh [options]

Options:
  --dry-run   Show what would be removed without deleting anything
  --deep      Also run `flutter clean`
  -h, --help  Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --deep)
      DEEP=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

remove_path() {
  local target="$1"

  if [[ ! -e "$target" ]]; then
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] rm -rf $target"
    return
  fi

  rm -rf "$target"
  echo "Removed: $target"
}

TARGETS=(
  "$PROJECT_DIR/build"
  "$PROJECT_DIR/coverage"
  "$PROJECT_DIR/artifacts/wired"
  "$PROJECT_DIR/custom_lint.log"
)

for target in "${TARGETS[@]}"; do
  remove_path "$target"
done

if [[ "$DEEP" -eq 1 ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] flutter clean"
  else
    (cd "$PROJECT_DIR" && flutter clean)
  fi
fi

echo "Cleanup complete."
