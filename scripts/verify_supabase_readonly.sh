#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  SUPABASE_DB_URL="postgresql://..." ./scripts/verify_supabase_readonly.sh

Optional:
  SUPABASE_SCHEMA=public   # default: public
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required but not installed." >&2
  exit 1
fi

if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
  echo "SUPABASE_DB_URL is required." >&2
  usage
  exit 1
fi

SCHEMA="${SUPABASE_SCHEMA:-public}"
FAILURES=0

query_scalar() {
  local sql="$1"
  psql "$SUPABASE_DB_URL" \
    -v ON_ERROR_STOP=1 \
    -X \
    -A \
    -t \
    -c "$sql" | tr -d '[:space:]'
}

check_table_exists() {
  local table_name="$1"
  local count
  count="$(query_scalar "SELECT COUNT(*) FROM pg_tables WHERE schemaname = '$SCHEMA' AND tablename = '$table_name';")"
  if [[ "$count" == "1" ]]; then
    echo "[PASS] table exists: $SCHEMA.$table_name"
  else
    echo "[FAIL] missing table: $SCHEMA.$table_name"
    FAILURES=$((FAILURES + 1))
  fi
}

check_function_exists() {
  local function_name="$1"
  local count
  count="$(
    query_scalar "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = '$SCHEMA' AND p.proname = '$function_name';"
  )"
  if [[ "$count" -ge 1 ]]; then
    echo "[PASS] function exists: $SCHEMA.$function_name"
  else
    echo "[FAIL] missing function: $SCHEMA.$function_name"
    FAILURES=$((FAILURES + 1))
  fi
}

check_rls_enabled() {
  local table_name="$1"
  local rls_enabled
  rls_enabled="$(
    query_scalar "SELECT COALESCE(c.relrowsecurity, false) FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = '$SCHEMA' AND c.relname = '$table_name' LIMIT 1;"
  )"
  if [[ "$rls_enabled" == "t" || "$rls_enabled" == "true" ]]; then
    echo "[PASS] RLS enabled: $SCHEMA.$table_name"
  else
    echo "[FAIL] RLS disabled or table missing: $SCHEMA.$table_name"
    FAILURES=$((FAILURES + 1))
  fi
}

check_policy_exists() {
  local table_name="$1"
  local count
  count="$(query_scalar "SELECT COUNT(*) FROM pg_policies WHERE schemaname = '$SCHEMA' AND tablename = '$table_name';")"
  if [[ "$count" -ge 1 ]]; then
    echo "[PASS] policy present: $SCHEMA.$table_name ($count policies)"
  else
    echo "[FAIL] no policies found: $SCHEMA.$table_name"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "Running Supabase read-only verification against schema: $SCHEMA"
echo

REQUIRED_TABLES=(
  "user_usage"
  "user_entitlements"
  "device_usage"
  "rate_limit_log"
  "rate_limit_config"
  "apple_credentials"
)

REQUIRED_FUNCTIONS=(
  "is_user_pro"
  "check_and_increment_usage"
  "check_rate_limit"
  "check_device_free_tier"
  "sync_user_usage"
  "remove_user_from_devices"
  "save_apple_authorization_code"
)

RLS_TABLES=(
  "user_usage"
  "user_entitlements"
  "device_usage"
  "rate_limit_log"
  "apple_credentials"
)

echo "== Tables =="
for table in "${REQUIRED_TABLES[@]}"; do
  check_table_exists "$table"
done

echo
echo "== Functions =="
for function_name in "${REQUIRED_FUNCTIONS[@]}"; do
  check_function_exists "$function_name"
done

echo
echo "== RLS + Policies =="
for table in "${RLS_TABLES[@]}"; do
  check_rls_enabled "$table"
  check_policy_exists "$table"
done

echo
if [[ "$FAILURES" -eq 0 ]]; then
  echo "Supabase read-only verification passed."
  exit 0
fi

echo "Supabase read-only verification failed with $FAILURES issue(s)." >&2
exit 1
