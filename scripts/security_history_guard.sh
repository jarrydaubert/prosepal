#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "❌ $1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

is_dotenv_path() {
  local basename="${1##*/}"
  [[ "$basename" == ".env" || "$basename" == .env.* ]]
}

is_allowed_dotenv_path() {
  [[ "${1##*/}" == ".env.example" ]]
}

echo "🔒 Running git history secret guard..."

for required_command in git mktemp rm sort; do
  require_command "$required_command"
done

# 1) Ensure no tracked local env file exists in current tree.
if ! tracked_files="$(git ls-files)"; then
  fail "Could not enumerate tracked files."
fi

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  if is_dotenv_path "$file" && ! is_allowed_dotenv_path "$file"; then
    fail "Tracked dotenv file is not allowed: $file"
  fi
done <<< "$tracked_files"

# 2) Ensure no non-example dotenv file exists anywhere in reachable history.
if ! history_objects="$(git rev-list --all --objects)"; then
  fail "Could not enumerate reachable history objects."
fi

while IFS=' ' read -r _object file; do
  [[ -z "${file:-}" ]] && continue
  if is_dotenv_path "$file" && ! is_allowed_dotenv_path "$file"; then
    fail "Historical dotenv file is not allowed: $file"
  fi
done <<< "$history_objects"

# 3) Scan reachable history for high-risk secret shapes.
# Keep this intentionally narrow to avoid false positives on public client keys.
pattern='sb_(service_role|secret)_[A-Za-z0-9._-]{20,}|SUPABASE_SERVICE_ROLE_KEY[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{16,}|REVENUECAT_(IOS|ANDROID)_KEY[[:space:]]*[:=][[:space:]]*["'\''](appl|goog)_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}'

tmp_hits="$(mktemp)"
trap 'rm -f "$tmp_hits"' EXIT

if ! revisions="$(git rev-list --all)"; then
  fail "Could not enumerate reachable revisions."
fi

while IFS= read -r rev; do
  [[ -z "$rev" ]] && continue
  if git grep -l -I -E "$pattern" "$rev" -- \
      ':(exclude)docs/**' \
      ':(exclude)**/*.md' \
      ':(exclude).env.example' \
      ':(exclude)test/**' >> "$tmp_hits"; then
    continue
  else
    grep_status=$?
    if [[ $grep_status -ne 1 ]]; then
      fail "High-risk secret scan failed for revision $rev."
    fi
  fi
done <<< "$revisions"

if [[ -s "$tmp_hits" ]]; then
  echo "High-risk secret patterns found in reachable history (commit:path):" >&2
  sort -u "$tmp_hits" >&2
  fail "Rotate affected keys and rewrite history before merging."
fi

echo "✅ Git history secret guard passed."
