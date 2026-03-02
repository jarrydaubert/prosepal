#!/usr/bin/env bash
# Blocks newly introduced literal neutral colors in feature UI code.
# Guard scope is diff-based to prevent regressions without requiring
# immediate full-repo refactors.

set -euo pipefail

readonly DEFAULT_ALLOWLIST='scripts/config/theme_token_usage_allowlist.tsv'
readonly COLOR_LITERAL_PATTERN='Colors\.(white|black|grey([A-Za-z0-9_.\[\]]*)?)'
ADDED_LINES_FILE=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/check_theme_token_usage.sh --base <git-ref> [--head <git-ref>] [--allowlist <path>] [--scope <pathspec>...]

Examples:
  ./scripts/check_theme_token_usage.sh --base origin/main --head HEAD
  ./scripts/check_theme_token_usage.sh --base HEAD~1 --scope lib/features
EOF
}

is_allowlisted() {
  local file="$1"
  local line="$2"
  local allowlist_path="$3"

  while IFS=$'\t' read -r path_regex line_regex reason || [[ -n "${path_regex:-}${line_regex:-}${reason:-}" ]]; do
    if [[ -z "${path_regex:-}" ]]; then
      continue
    fi
    if [[ "$path_regex" =~ ^[[:space:]]*# ]]; then
      continue
    fi
    if [[ "$file" =~ $path_regex ]] && [[ "$line" =~ $line_regex ]]; then
      return 0
    fi
  done < "$allowlist_path"

  return 1
}

main() {
  local base_ref=""
  local head_ref="HEAD"
  local allowlist_path="$DEFAULT_ALLOWLIST"
  local scopes=("lib/features")

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --base)
        base_ref="${2:-}"
        shift 2
        ;;
      --head)
        head_ref="${2:-}"
        shift 2
        ;;
      --allowlist)
        allowlist_path="${2:-}"
        shift 2
        ;;
      --scope)
        scopes+=("${2:-}")
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "$base_ref" ]]; then
    echo "Theme token guard failed: --base is required." >&2
    usage
    exit 1
  fi

  if [[ ! -f "$allowlist_path" ]]; then
    echo "Theme token guard failed: allowlist file not found: $allowlist_path" >&2
    exit 1
  fi

  if ! git rev-parse --verify "$base_ref^{commit}" >/dev/null 2>&1; then
    echo "Theme token guard failed: invalid base ref: $base_ref" >&2
    exit 1
  fi
  if ! git rev-parse --verify "$head_ref^{commit}" >/dev/null 2>&1; then
    echo "Theme token guard failed: invalid head ref: $head_ref" >&2
    exit 1
  fi

  ADDED_LINES_FILE="$(mktemp)"
  trap 'rm -f "${ADDED_LINES_FILE:-}"' EXIT

  git diff --unified=0 "$base_ref" "$head_ref" -- "${scopes[@]}" \
    | awk '
      /^\+\+\+ b\// { file = substr($0, 7); next }
      /^\+[^+]/ { print file "\t" substr($0, 2) }
    ' > "$ADDED_LINES_FILE"

  if [[ ! -s "$ADDED_LINES_FILE" ]]; then
    echo "Theme token guard: no added lines in scoped paths."
    exit 0
  fi

  local -a violations=()
  while IFS=$'\t' read -r file line; do
    if [[ -z "$file" ]]; then
      continue
    fi

    if [[ "$line" =~ $COLOR_LITERAL_PATTERN ]]; then
      if is_allowlisted "$file" "$line" "$allowlist_path"; then
        continue
      fi
      violations+=("$file: $line")
    fi
  done < "$ADDED_LINES_FILE"

  if [[ "${#violations[@]}" -gt 0 ]]; then
    echo "Theme token guard failed: found newly introduced literal Colors.white/black/grey usage." >&2
    echo "Use AppColors or Theme.of(context).colorScheme tokens instead." >&2
    echo "If a brand-required exception is necessary, document it in $allowlist_path." >&2
    echo >&2
    printf '  - %s\n' "${violations[@]}" >&2
    exit 1
  fi

  echo "Theme token guard passed: no newly introduced literal neutral Colors usage."
}

main "$@"
