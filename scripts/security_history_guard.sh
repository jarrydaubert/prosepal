#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "❌ $1" >&2
  exit 1
}

echo "🔒 Running git history secret guard..."

# 1) Ensure no tracked local env file exists in current tree.
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  if [[ "$file" != ".env.example" ]]; then
    fail "Tracked dotenv file is not allowed: $file"
  fi
done < <(git ls-files | rg '^\.env($|\.)' || true)

# 2) Ensure no non-example dotenv file exists anywhere in reachable history.
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  if [[ "$file" != ".env.example" ]]; then
    fail "Historical dotenv file is not allowed: $file"
  fi
done < <(
  git rev-list --all --objects |
    awk '{print $2}' |
    rg '^\.env($|\.)' |
    sort -u ||
    true
)

if git rev-list --all -- .env.local | rg -q .; then
  fail ".env.local exists in reachable git history."
fi

# 3) Scan reachable history for high-risk secret shapes.
# Keep this intentionally narrow to avoid false positives on public client keys.
pattern='sb_(service_role|secret)_[A-Za-z0-9._-]{20,}|SUPABASE_SERVICE_ROLE_KEY[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{16,}|REVENUECAT_(IOS|ANDROID)_KEY[[:space:]]*[:=][[:space:]]*["'\''](appl|goog)_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}'

tmp_hits="$(mktemp)"
trap 'rm -f "$tmp_hits"' EXIT

while IFS= read -r rev; do
  git grep -l -I -E "$pattern" "$rev" -- \
    ':(exclude)docs/**' \
    ':(exclude)**/*.md' \
    ':(exclude).env.example' \
    ':(exclude)test/**' >> "$tmp_hits" || true
done < <(git rev-list --all)

if [[ -s "$tmp_hits" ]]; then
  echo "High-risk secret patterns found in reachable history (commit:path):" >&2
  sort -u "$tmp_hits" >&2
  fail "Rotate affected keys and rewrite history before merging."
fi

echo "✅ Git history secret guard passed."
