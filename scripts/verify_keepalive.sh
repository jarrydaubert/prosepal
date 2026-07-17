#!/usr/bin/env bash
# Verifies the public.keepalive() RPC on one Supabase project.
#
# Usage:
#   PROSEPAL_KEEPALIVE_URL=https://<project-ref>.supabase.co \
#   PROSEPAL_KEEPALIVE_ANON_KEY=<public-anon-or-publishable-key> \
#   ./scripts/verify_keepalive.sh
#
# Calls only the dedicated read-only keepalive RPC with the public key.
# Prints the HTTP status and returned server timestamp; never prints the URL
# or key. Exits non-zero on any non-2xx or malformed response.

set -euo pipefail

URL="${PROSEPAL_KEEPALIVE_URL:-}"
KEY="${PROSEPAL_KEEPALIVE_ANON_KEY:-}"

if [ -z "$URL" ] || [ -z "$KEY" ]; then
  echo "Set PROSEPAL_KEEPALIVE_URL and PROSEPAL_KEEPALIVE_ANON_KEY first." >&2
  exit 2
fi

RESPONSE_FILE="$(mktemp "${TMPDIR:-/tmp}/prosepal-keepalive-response.XXXXXX")"
trap 'rm -f "$RESPONSE_FILE"' EXIT

HTTP_CODE="$(
  curl --silent --show-error \
    --connect-timeout 10 \
    --max-time 30 \
    --retry 3 \
    --retry-delay 5 \
    --retry-connrefused \
    --output "$RESPONSE_FILE" \
    --write-out '%{http_code}' \
    -X POST "${URL%/}/rest/v1/rpc/keepalive" \
    -H "apikey: ${KEY}" \
    -H "Authorization: Bearer ${KEY}" \
    -H "Content-Type: application/json" \
    --data '{}'
)" || {
  echo "Keepalive request did not complete after retries." >&2
  exit 1
}

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
  echo "Keepalive failed: HTTP $HTTP_CODE" >&2
  exit 1
fi

if ! grep -Eq '"?[0-9]{4}-[0-9]{2}-[0-9]{2}' "$RESPONSE_FILE"; then
  echo "Keepalive failed: HTTP $HTTP_CODE but the response was not a server timestamp." >&2
  exit 1
fi

echo "HTTP $HTTP_CODE"
echo "server_timestamp=$(tr -d '"' < "$RESPONSE_FILE")"
echo "Keepalive RPC is working."
