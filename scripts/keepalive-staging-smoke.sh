#!/usr/bin/env bash
# Staging smoke test for the public.keepalive() RPC.
#
# Resolves the staging project URL and public anon key through the
# authenticated Supabase CLI (both are public client values; they are still
# never printed) and runs the shared verification script against staging only.
# Production is never touched.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGING_PROJECT_REF="llolwgqphwnhbiqewmcq"

ANON_KEY="$(
  supabase projects api-keys --project-ref "$STAGING_PROJECT_REF" -o json 2>/dev/null |
    python3 -c '
import json
import sys

keys = {entry.get("name"): entry.get("api_key") for entry in json.load(sys.stdin)}
print(keys.get("anon") or keys.get("publishable") or "")
'
)"

if [ -z "$ANON_KEY" ]; then
  echo "Could not resolve the staging anon key. Run supabase login first." >&2
  exit 2
fi

echo "Checking ProsePal staging keepalive..."
echo "Project ref: $STAGING_PROJECT_REF"

PROSEPAL_KEEPALIVE_URL="https://${STAGING_PROJECT_REF}.supabase.co" \
  PROSEPAL_KEEPALIVE_ANON_KEY="$ANON_KEY" \
  "$SCRIPT_DIR/verify_keepalive.sh"
