#!/usr/bin/env bash
set -euo pipefail

SECRET_FILE="$HOME/.config/prosepal/staging-gateway-secret"
PROJECT_REF="llolwgqphwnhbiqewmcq"
ENDPOINT="https://${PROJECT_REF}.supabase.co/functions/v1/generate-card"
RESPONSE_FILE="$(mktemp "${TMPDIR:-/tmp}/prosepal-staging-smoke-response.XXXXXX.json")"

cleanup() {
  if [ "${KEEP_PROSEPAL_SMOKE_RESPONSE:-0}" != "1" ] && [ -f "$RESPONSE_FILE" ]; then
    rm -f "$RESPONSE_FILE"
  fi
}
trap cleanup EXIT

if [ ! -f "$SECRET_FILE" ]; then
  echo "Missing staging gateway secret file: $SECRET_FILE"
  exit 1
fi

PROSEPAL_DEV_GATEWAY_SECRET="$(cat "$SECRET_FILE")"

if [ -z "$PROSEPAL_DEV_GATEWAY_SECRET" ]; then
  echo "Staging gateway secret file is empty"
  exit 1
fi

echo "Checking ProsePal staging generate-card..."
echo "Project ref: $PROJECT_REF"

HTTP_CODE="$(
  curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
    -X POST "$ENDPOINT" \
    -H 'Content-Type: application/json' \
    -H "X-ProsePal-Dev-Gateway-Secret: ${PROSEPAL_DEV_GATEWAY_SECRET}" \
    -d "{
      \"idempotency_key\": \"terminal-staging-smoke-$(date +%s)\",
      \"requested_lane\": \"standard\",
      \"prompt_contract_version\": 1,
      \"output_contract_version\": 1,
      \"client_context\": {
        \"app_version\": \"0.1.0\",
        \"build_number\": \"1\",
        \"platform\": \"ios\"
      },
      \"intent\": {
        \"occasion\": \"birthday\",
        \"relationship\": \"parent\",
        \"tone\": \"heartfelt\",
        \"length\": \"brief\",
        \"spelling_preference\": \"uk\",
        \"locale_identifier\": \"en_GB\",
        \"recipient_name\": \"Alex\",
        \"things_to_include\": [\"a quiet cup of tea\"],
        \"things_to_avoid\": [\"age jokes\"],
        \"user_context\": \"Keep it warm and simple.\"
      }
    }"
)"

if [ "$HTTP_CODE" != "200" ]; then
  echo "HTTP $HTTP_CODE"
  echo "Response saved to $RESPONSE_FILE"
  KEEP_PROSEPAL_SMOKE_RESPONSE=1
  exit 1
fi

python3 - "$RESPONSE_FILE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())

messages = data.get("messages", [])
quality_passed = data.get("quality_check", {}).get("passed")
fallback = data.get("fallback_status")
lane = data.get("lane_used")

if len(messages) != 3:
    raise SystemExit(f"Expected 3 messages, got {len(messages)}")

if quality_passed is not True:
    raise SystemExit(f"quality_check.passed was not true: {quality_passed}")

print("HTTP 200")
print(f"lane_used={lane}")
print(f"fallback_status={fallback}")
print(f"message_count={len(messages)}")
print("ProsePal staging generate-card is working")
PY
