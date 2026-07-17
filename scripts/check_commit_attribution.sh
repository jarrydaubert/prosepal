#!/usr/bin/env bash
# Fails when Co-authored-by trailers are present without explicit approval marker.
# Approval marker: [allow-coauthor]

set -euo pipefail

readonly ALLOW_MARKER='[allow-coauthor]'
readonly TRAILER_PATTERN='^[[:space:]]*[Cc]o-[Aa]uthored-[Bb]y:'
readonly DEPENDABOT_COAUTHOR_REGEX='^[[:space:]]*[Cc]o-[Aa]uthored-[Bb]y:[[:space:]]*dependabot\[bot\][[:space:]]*<49699333\+dependabot\[bot\]@users\.noreply\.github\.com>[[:space:]]*$'
readonly DEPENDABOT_AUTHOR_REGEX='^dependabot\[bot\] <49699333\+dependabot\[bot\]@users\.noreply\.github\.com>$'
readonly GITHUB_COMMITTER_REGEX='^GitHub <noreply@github\.com>$'
readonly DEPENDABOT_SIGNOFF_REGEX='^[[:space:]]*[Ss]igned-off-by:[[:space:]]*dependabot\[bot\][[:space:]]*<support@github\.com>[[:space:]]*$'
readonly GITHUB_PR_SUBJECT_REGEX='^.+ \(#[0-9]+\)$'
readonly GITHUB_NOREPLY_COAUTHOR_REGEX='^[[:space:]]*[Cc]o-[Aa]uthored-[Bb]y:[[:space:]]*.+[[:space:]]*<[0-9]+\+[^<>[:space:]]+@users\.noreply\.github\.com>[[:space:]]*$'
# Exactly the GitHub Advanced Security Copilot Autofix bot, applied from the
# repository's own code-scanning findings via the GitHub web flow. Any other
# identity — including lookalike names, different numeric IDs, or non-noreply
# domains — still requires the explicit [allow-coauthor] marker.
readonly GITHUB_SECURITY_AUTOFIX_COAUTHOR_REGEX='^[[:space:]]*[Cc]o-[Aa]uthored-[Bb]y:[[:space:]]*Copilot Autofix powered by AI <62310815\+github-advanced-security\[bot\]@users\.noreply\.github\.com>[[:space:]]*$'

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

is_dependabot_only_coauthor() {
  local input_file="$1"
  local author_line="$2"
  local trailer_count

  if [[ ! "$author_line" =~ $DEPENDABOT_AUTHOR_REGEX ]]; then
    return 1
  fi

  trailer_count="$(grep -Ec "$TRAILER_PATTERN" "$input_file" || true)"

  if [[ "$trailer_count" -ne 1 ]]; then
    return 1
  fi

  grep -Eq "$DEPENDABOT_COAUTHOR_REGEX" "$input_file"
}

is_github_security_autofix_coauthor_only() {
  local input_file="$1"
  local committer_line="$2"
  local trailer_count

  # Copilot Autofix commits are created by the GitHub web flow; a locally
  # crafted commit does not carry the GitHub committer identity.
  if [[ ! "$committer_line" =~ $GITHUB_COMMITTER_REGEX ]]; then
    return 1
  fi

  trailer_count="$(grep -Ec "$TRAILER_PATTERN" "$input_file" || true)"
  if [[ "$trailer_count" -lt 1 ]]; then
    return 1
  fi

  # Every co-author trailer must be exactly the trusted bot; one extra
  # trailer of any other identity keeps the marker requirement.
  while IFS= read -r trailer_line; do
    if [[ ! "$trailer_line" =~ $GITHUB_SECURITY_AUTOFIX_COAUTHOR_REGEX ]]; then
      return 1
    fi
  done < <(grep -E "$TRAILER_PATTERN" "$input_file")

  return 0
}

is_github_dependabot_squash_merge() {
  local input_file="$1"
  local _author_line="$2"
  local committer_line="$3"
  local subject_line
  local trailer_count

  if [[ ! "$committer_line" =~ $GITHUB_COMMITTER_REGEX ]]; then
    return 1
  fi

  # GitHub squash merges of Dependabot-derived PRs may keep GitHub-generated
  # noreply co-author trailers for Dependabot and the maintainer who merged it.
  trailer_count="$(grep -Ec "$TRAILER_PATTERN" "$input_file" || true)"

  if [[ "$trailer_count" -lt 1 ]]; then
    return 1
  fi

  if ! grep -Eq "$DEPENDABOT_COAUTHOR_REGEX" "$input_file"; then
    return 1
  fi

  while IFS= read -r trailer_line; do
    if [[ ! "$trailer_line" =~ $DEPENDABOT_COAUTHOR_REGEX ]] \
      && [[ ! "$trailer_line" =~ $GITHUB_NOREPLY_COAUTHOR_REGEX ]]; then
      return 1
    fi
  done < <(grep -E "$TRAILER_PATTERN" "$input_file")

  if ! grep -Eq "$DEPENDABOT_SIGNOFF_REGEX" "$input_file"; then
    return 1
  fi

  subject_line="$(head -n1 "$input_file")"
  [[ "$subject_line" =~ $GITHUB_PR_SUBJECT_REGEX ]]
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
    local author_line
    local committer_line
    tmp_file="$(mktemp)"
    git log -1 --pretty=%B "$commit_sha" > "$tmp_file"
    author_line="$(git log -1 --pretty='%an <%ae>' "$commit_sha")"
    committer_line="$(git log -1 --pretty='%cn <%ce>' "$commit_sha")"

    if contains_coauthor_trailer "$tmp_file" \
      && ! contains_allow_marker "$tmp_file" \
      && ! is_dependabot_only_coauthor "$tmp_file" "$author_line" \
      && ! is_github_security_autofix_coauthor_only "$tmp_file" "$committer_line" \
      && ! is_github_dependabot_squash_merge "$tmp_file" "$author_line" "$committer_line"; then
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
