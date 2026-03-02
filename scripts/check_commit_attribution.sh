#!/usr/bin/env bash
# Fails when Co-authored-by trailers are present without explicit approval marker.
# Approval marker: [allow-coauthor]

set -euo pipefail

readonly ALLOW_MARKER='[allow-coauthor]'
readonly TRAILER_PATTERN='^[[:space:]]*[Cc]o-[Aa]uthored-[Bb]y:'

usage() {
  cat <<'EOF'
Usage:
  ./scripts/check_commit_attribution.sh --message-file <path>
  ./scripts/check_commit_attribution.sh --range <git-range>

Examples:
  ./scripts/check_commit_attribution.sh --message-file .git/COMMIT_EDITMSG
  ./scripts/check_commit_attribution.sh --range HEAD~3..HEAD
EOF
}

contains_coauthor_trailer() {
  local input_file="$1"
  grep -Eq "$TRAILER_PATTERN" "$input_file"
}

contains_allow_marker() {
  local input_file="$1"
  grep -Fq "$ALLOW_MARKER" "$input_file"
}

check_single_message_file() {
  local message_file="$1"

  if [[ ! -f "$message_file" ]]; then
    echo "Commit attribution guard failed: message file not found: $message_file" >&2
    exit 1
  fi

  if contains_coauthor_trailer "$message_file" && ! contains_allow_marker "$message_file"; then
    cat >&2 <<EOF
Commit attribution guard failed.
Found Co-authored-by trailer without explicit approval marker.

If intentional, add $ALLOW_MARKER to the commit message body.
EOF
    exit 1
  fi
}

check_commit_range() {
  local range="$1"
  local failures=0

  if ! git rev-list "$range" >/dev/null 2>&1; then
    echo "Commit attribution guard failed: invalid git range: $range" >&2
    exit 1
  fi

  while IFS= read -r commit_sha; do
    local tmp_file
    tmp_file="$(mktemp)"
    git log -1 --pretty=%B "$commit_sha" > "$tmp_file"

    if contains_coauthor_trailer "$tmp_file" && ! contains_allow_marker "$tmp_file"; then
      echo "Commit $commit_sha has Co-authored-by trailer without $ALLOW_MARKER" >&2
      failures=1
    fi

    rm -f "$tmp_file"
  done < <(git rev-list --reverse "$range")

  if [[ "$failures" -ne 0 ]]; then
    cat >&2 <<EOF
Commit attribution guard failed.
Add $ALLOW_MARKER to intentionally co-authored commits, or remove stale trailers.
EOF
    exit 1
  fi
}

main() {
  if [[ "$#" -ne 2 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    --message-file)
      check_single_message_file "$2"
      ;;
    --range)
      check_commit_range "$2"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
