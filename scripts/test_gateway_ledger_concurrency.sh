#!/bin/bash

set -euo pipefail

DB_URL="${PROSEPAL_SUPABASE_DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
TEST_USER_ID="33333333-3333-3333-3333-333333333333"
FINGERPRINT="eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
TMP_DIR="$(mktemp -d /tmp/prosepal-ledger-concurrency.XXXXXX)"

cleanup() {
  psql "$DB_URL" -v ON_ERROR_STOP=1 -q <<SQL >/dev/null 2>&1 || true
DELETE FROM public.rate_limit_log WHERE identifier = '$TEST_USER_ID';
DELETE FROM auth.users WHERE id = '$TEST_USER_ID';
SQL
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if ! pg_isready -d "$DB_URL" >/dev/null 2>&1; then
  echo "Local Supabase database is unavailable. Run 'supabase start' first." >&2
  exit 1
fi

psql "$DB_URL" -v ON_ERROR_STOP=1 -q <<SQL
DELETE FROM public.rate_limit_log WHERE identifier = '$TEST_USER_ID';
DELETE FROM auth.users WHERE id = '$TEST_USER_ID';
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at
) VALUES (
  '$TEST_USER_ID',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'ledger-race@example.invalid', '',
  NOW(), NOW(), NOW()
);
SQL

reserve() {
  local key="$1"
  local output="$2"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -Atq -c "
    SELECT public.reserve_card_request(
      '$TEST_USER_ID', FALSE, '$key', '$FINGERPRINT',
      'standard', 'prompt-1:output-1'
    )->>'outcome';
  " >"$output"
}

reserve "race-a" "$TMP_DIR/race-a" &
PID_A=$!
reserve "race-b" "$TMP_DIR/race-b" &
PID_B=$!
wait "$PID_A"
wait "$PID_B"

RACE_RESULTS="$(sort "$TMP_DIR/race-a" "$TMP_DIR/race-b" | tr '\n' ' ')"
if [[ "$RACE_RESULTS" != "quota_exhausted reserved " ]]; then
  echo "Expected one reserved and one quota_exhausted result; got: $RACE_RESULTS" >&2
  exit 1
fi

# Reset the first race before verifying duplicate-key serialization.
psql "$DB_URL" -v ON_ERROR_STOP=1 -q <<SQL
DELETE FROM public.gateway_requests WHERE subject = '$TEST_USER_ID';
DELETE FROM public.rate_limit_log WHERE identifier = '$TEST_USER_ID';
SQL

reserve "duplicate-key" "$TMP_DIR/duplicate-a" &
PID_A=$!
reserve "duplicate-key" "$TMP_DIR/duplicate-b" &
PID_B=$!
wait "$PID_A"
wait "$PID_B"

DUPLICATE_RESULTS="$(sort "$TMP_DIR/duplicate-a" "$TMP_DIR/duplicate-b" | tr '\n' ' ')"
if [[ "$DUPLICATE_RESULTS" != "in_flight reserved " ]]; then
  echo "Expected one reserved and one in_flight duplicate; got: $DUPLICATE_RESULTS" >&2
  exit 1
fi

ROW_COUNT="$(psql "$DB_URL" -Atq -c "
  SELECT COUNT(*) FROM public.gateway_requests
  WHERE subject = '$TEST_USER_ID' AND idempotency_key = 'duplicate-key';
")"
if [[ "$ROW_COUNT" != "1" ]]; then
  echo "Expected one duplicate-key ledger row; got: $ROW_COUNT" >&2
  exit 1
fi

echo "Gateway ledger concurrency checks passed."
