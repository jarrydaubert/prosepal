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

check_table_privilege_absent() {
  local role_name="$1"
  local table_name="$2"
  local privilege="$3"
  local has_privilege
  has_privilege="$(
    query_scalar "SELECT has_table_privilege('$role_name', '$SCHEMA.$table_name', '$privilege');"
  )"
  if [[ "$has_privilege" == "f" || "$has_privilege" == "false" ]]; then
    echo "[PASS] $role_name lacks $privilege on $SCHEMA.$table_name"
  else
    echo "[FAIL] $role_name has $privilege on $SCHEMA.$table_name"
    FAILURES=$((FAILURES + 1))
  fi
}

check_function_execute_absent() {
  local role_name="$1"
  local function_signature="$2"
  local has_privilege
  has_privilege="$(
    query_scalar "SELECT has_function_privilege('$role_name', '$SCHEMA.$function_signature', 'EXECUTE');"
  )"
  if [[ "$has_privilege" == "f" || "$has_privilege" == "false" ]]; then
    echo "[PASS] $role_name lacks EXECUTE on $SCHEMA.$function_signature"
  else
    echo "[FAIL] $role_name has EXECUTE on $SCHEMA.$function_signature"
    FAILURES=$((FAILURES + 1))
  fi
}

check_public_function_execute_absent() {
  local function_signature="$1"
  local has_privilege
  has_privilege="$(
    query_scalar "SELECT COALESCE(bool_or(acl.grantee = 0 AND acl.privilege_type = 'EXECUTE'), false) FROM pg_proc p CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) acl WHERE p.oid = '$SCHEMA.$function_signature'::regprocedure;"
  )"
  if [[ "$has_privilege" == "f" || "$has_privilege" == "false" ]]; then
    echo "[PASS] PUBLIC lacks EXECUTE on $SCHEMA.$function_signature"
  else
    echo "[FAIL] PUBLIC has EXECUTE on $SCHEMA.$function_signature"
    FAILURES=$((FAILURES + 1))
  fi
}

check_function_execute_present() {
  local role_name="$1"
  local function_signature="$2"
  local has_privilege
  has_privilege="$(
    query_scalar "SELECT has_function_privilege('$role_name', '$SCHEMA.$function_signature', 'EXECUTE');"
  )"
  if [[ "$has_privilege" == "t" || "$has_privilege" == "true" ]]; then
    echo "[PASS] $role_name can EXECUTE $SCHEMA.$function_signature"
  else
    echo "[FAIL] $role_name cannot EXECUTE $SCHEMA.$function_signature"
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

ANON_NO_SELECT_TABLES=(
  "user_usage"
  "user_entitlements"
  "device_usage"
  "rate_limit_log"
  "rate_limit_config"
  "apple_credentials"
)

AUTH_NO_SELECT_TABLES=(
  "user_entitlements"
  "device_usage"
  "rate_limit_log"
  "rate_limit_config"
  "apple_credentials"
)

PUBLIC_NO_EXECUTE_FUNCTIONS=(
  "check_and_increment_usage(uuid, boolean, text)"
  "check_device_free_tier(text, text, uuid, boolean)"
  "check_rate_limit(uuid, text, text)"
  "cleanup_rate_limit_logs()"
  "is_user_pro(uuid)"
  "save_apple_authorization_code(text)"
  "sync_user_usage(uuid, integer, integer, text)"
  "update_updated_at_column()"
)

ANON_NO_EXECUTE_FUNCTIONS=(
  "check_and_increment_usage(uuid, boolean, text)"
  "cleanup_rate_limit_logs()"
  "is_user_pro(uuid)"
  "save_apple_authorization_code(text)"
  "sync_user_usage(uuid, integer, integer, text)"
  "update_updated_at_column()"
)

AUTH_NO_EXECUTE_FUNCTIONS=(
  "cleanup_rate_limit_logs()"
  "is_user_pro(uuid)"
  "save_apple_authorization_code(text)"
  "update_updated_at_column()"
)

AUTH_EXECUTE_FUNCTIONS=(
  "check_and_increment_usage(uuid, boolean, text)"
  "check_device_free_tier(text, text, uuid, boolean)"
  "check_rate_limit(uuid, text, text)"
  "sync_user_usage(uuid, integer, integer, text)"
)

ANON_EXECUTE_FUNCTIONS=(
  "check_device_free_tier(text, text, uuid, boolean)"
  "check_rate_limit(uuid, text, text)"
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
echo "== Client role table privileges =="
for table in "${ANON_NO_SELECT_TABLES[@]}"; do
  check_table_privilege_absent "anon" "$table" "SELECT"
done
for table in "${AUTH_NO_SELECT_TABLES[@]}"; do
  check_table_privilege_absent "authenticated" "$table" "SELECT"
done

echo
echo "== Function execute privileges =="
for function_signature in "${PUBLIC_NO_EXECUTE_FUNCTIONS[@]}"; do
  check_public_function_execute_absent "$function_signature"
done
for function_signature in "${ANON_NO_EXECUTE_FUNCTIONS[@]}"; do
  check_function_execute_absent "anon" "$function_signature"
done
for function_signature in "${AUTH_NO_EXECUTE_FUNCTIONS[@]}"; do
  check_function_execute_absent "authenticated" "$function_signature"
done
for function_signature in "${AUTH_EXECUTE_FUNCTIONS[@]}"; do
  check_function_execute_present "authenticated" "$function_signature"
done
for function_signature in "${ANON_EXECUTE_FUNCTIONS[@]}"; do
  check_function_execute_present "anon" "$function_signature"
done

echo
if [[ "$FAILURES" -eq 0 ]]; then
  echo "Supabase read-only verification passed."
  exit 0
fi

echo "Supabase read-only verification failed with $FAILURES issue(s)." >&2
exit 1
