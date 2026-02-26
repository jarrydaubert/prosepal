# Supabase Tests

Pre-release verification tests for Supabase database and edge functions.

**Run in:** Supabase Dashboard > SQL Editor (database) / Terminal (edge functions)  
**Last Verified:** 2026-01-22 (v1.1.0)

---

## Test 1: Verify Tables Exist

```sql
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

**Expected Output (6 tables):**
```json
[
  {"tablename": "apple_credentials"},
  {"tablename": "device_usage"},
  {"tablename": "rate_limit_config"},
  {"tablename": "rate_limit_log"},
  {"tablename": "user_entitlements"},
  {"tablename": "user_usage"}
]
```

---

## Test 2: Verify RPC Functions Exist

```sql
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

**Expected Output (9+ functions):**
```json
[
  {"routine_name": "check_and_increment_usage", "routine_type": "FUNCTION"},
  {"routine_name": "check_device_free_tier", "routine_type": "FUNCTION"},
  {"routine_name": "check_rate_limit", "routine_type": "FUNCTION"},
  {"routine_name": "cleanup_rate_limit_logs", "routine_type": "FUNCTION"},
  {"routine_name": "is_user_pro", "routine_type": "FUNCTION"},
  {"routine_name": "remove_user_from_devices", "routine_type": "FUNCTION"},
  {"routine_name": "save_apple_authorization_code", "routine_type": "FUNCTION"},
  {"routine_name": "sync_user_usage", "routine_type": "FUNCTION"},
  {"routine_name": "update_updated_at_column", "routine_type": "FUNCTION"}
]
```

Note: `rls_auto_enable` may also appear (Supabase internal).

---

## Test 3: Verify RLS Policies (Optimized)

```sql
SELECT tablename, policyname, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Expected:** All policies should contain `(SELECT auth.uid())` not just `auth.uid()`.

**Key policies to verify:**
| Table | Policy | Type |
|-------|--------|------|
| apple_credentials | apple_credentials_select | SELECT |
| apple_credentials | apple_credentials_insert | INSERT |
| apple_credentials | apple_credentials_update | UPDATE |
| user_entitlements | Users can read own entitlements | SELECT |
| user_usage | Users can view own usage | SELECT |
| user_usage | No direct inserts to user_usage | INSERT (deny) |
| user_usage | No direct updates to user_usage | UPDATE (deny) |

---

## Test 4: Test `is_user_pro` Function

### 4.1: Non-existent user
```sql
SELECT is_user_pro('00000000-0000-0000-0000-000000000000');
```

**Expected:** `{"is_user_pro": false}`

### 4.2: Real user (get user ID first)
```sql
-- Find a user ID
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- Then test
SELECT is_user_pro('YOUR_USER_ID');
```

**Expected:** `true` or `false` depending on entitlement status.

---

## Test 5: Test `check_and_increment_usage`

### 5.1: Check current usage
```sql
SELECT * FROM user_usage WHERE user_id = 'YOUR_USER_ID';
```

### 5.2: Test increment
```sql
SELECT check_and_increment_usage(
  'YOUR_USER_ID'::UUID,
  true,  -- is_pro (or false for free tier)
  '2026-01'  -- current month key
);
```

**Expected Output:**
```json
{
  "check_and_increment_usage": {
    "allowed": true,
    "is_pro": true,
    "pro_source": "server",
    "limit": 500,
    "remaining": 495,
    "total_count": 2,
    "monthly_count": 5
  }
}
```

**Verify:** `monthly_count` and `total_count` should increment by 1.

---

## Test 6: Test `check_rate_limit`

```sql
SELECT check_rate_limit(
  'YOUR_USER_ID'::UUID,
  'test-device-fingerprint-12345',
  'generation'
);
```

**Expected Output:**
```json
{
  "check_rate_limit": {
    "allowed": true,
    "retry_after": 0,
    "reason": null
  }
}
```

---

## Test 7: Test `sync_user_usage` (Monotonic Protection)

### 7.1: Get current values
```sql
SELECT total_count, monthly_count, month_key FROM user_usage 
WHERE user_id = 'YOUR_USER_ID';
```

### 7.2: Try to sync LOWER values
```sql
SELECT sync_user_usage(
  'YOUR_USER_ID'::UUID,
  0,  -- Try to reset total to 0
  0,  -- Try to reset monthly to 0
  '2025-01'  -- Old month
);
```

**Expected (from SQL Editor):**
```json
{"sync_user_usage": {"error": "Unauthorized", "success": false}}
```

Note: "Unauthorized" is expected in SQL Editor because `auth.uid()` is NULL. This confirms the security check works.

### 7.3: Verify values unchanged
```sql
SELECT total_count, monthly_count, month_key FROM user_usage 
WHERE user_id = 'YOUR_USER_ID';
```

**Expected:** Values should be identical to 7.1 (no decrease).

---

## Test 8: Test `check_device_free_tier`

```sql
SELECT check_device_free_tier('test-device-id-12345', 'ios');
```

**Expected Output:**
```json
{
  "check_device_free_tier": {
    "allowed": true,
    "is_new_device": true,
    "device_fingerprint": "test-dev..."
  }
}
```

---

## Test 9/10: Test RLS Blocks Direct Writes to user_usage

### Test UPDATE (as authenticated role)
```sql
SET ROLE authenticated;

UPDATE user_usage 
SET total_count = 0 
WHERE user_id = 'YOUR_USER_ID';

RESET ROLE;
```

**Expected:** `Success. No rows returned` (0 rows affected - RLS blocked it).

### Verify data unchanged
```sql
SELECT total_count FROM user_usage WHERE user_id = 'YOUR_USER_ID';
```

**Expected:** Value should be unchanged.

---

## Test 11: Verify Rate Limit Config

```sql
SELECT identifier_type, endpoint, max_requests, window_seconds, enabled 
FROM rate_limit_config 
ORDER BY identifier_type;
```

**Expected Output:**
```json
[
  {"identifier_type": "device", "endpoint": "generation", "max_requests": 30, "window_seconds": 60, "enabled": true},
  {"identifier_type": "global", "endpoint": "generation", "max_requests": 1000, "window_seconds": 60, "enabled": true},
  {"identifier_type": "ip", "endpoint": "generation", "max_requests": 50, "window_seconds": 60, "enabled": true},
  {"identifier_type": "user", "endpoint": "generation", "max_requests": 20, "window_seconds": 60, "enabled": true}
]
```

---

## Test 12: Test `cleanup_rate_limit_logs`

```sql
SELECT cleanup_rate_limit_logs();
```

**Expected:** Returns integer (number of deleted rows, may be 0).

---

## Test 13: Verify No Duplicate Policies

```sql
SELECT tablename, policyname, cmd, COUNT(*) 
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename, policyname, cmd
HAVING COUNT(*) > 1;
```

**Expected:** Empty result (no rows returned).

---

## Test 14: Verify Indexes

```sql
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

**Expected (10 indexes):**
```json
[
  {"indexname": "apple_credentials_pkey", "tablename": "apple_credentials"},
  {"indexname": "idx_apple_credentials_user", "tablename": "apple_credentials"},
  {"indexname": "device_usage_pkey", "tablename": "device_usage"},
  {"indexname": "rate_limit_config_identifier_type_endpoint_key", "tablename": "rate_limit_config"},
  {"indexname": "rate_limit_config_pkey", "tablename": "rate_limit_config"},
  {"indexname": "idx_rate_limit_cleanup", "tablename": "rate_limit_log"},
  {"indexname": "idx_rate_limit_lookup", "tablename": "rate_limit_log"},
  {"indexname": "rate_limit_log_pkey", "tablename": "rate_limit_log"},
  {"indexname": "user_entitlements_pkey", "tablename": "user_entitlements"},
  {"indexname": "user_usage_pkey", "tablename": "user_usage"}
]
```

**Should NOT include (dropped):**
- `idx_device_usage_last_seen`
- `idx_user_usage_updated`
- `idx_user_entitlements_expires`

---

## Quick Checklist

| # | Test | Pass |
|---|------|------|
| 1 | Tables exist (6) | ☐ |
| 2 | RPC functions exist (9) | ☐ |
| 3 | RLS policies optimized | ☐ |
| 4 | `is_user_pro` works | ☐ |
| 5 | `check_and_increment_usage` works | ☐ |
| 6 | `check_rate_limit` works | ☐ |
| 7 | `sync_user_usage` auth protected | ☐ |
| 8 | `check_device_free_tier` works | ☐ |
| 9/10 | Direct writes blocked | ☐ |
| 11 | Rate limit config correct | ☐ |
| 12 | `cleanup_rate_limit_logs` works | ☐ |
| 13 | No duplicate policies | ☐ |
| 14 | Indexes optimized | ☐ |

---

## Troubleshooting

### "function does not exist" errors
- Check parameter types - use `::UUID` for user IDs
- Check function signature in migrations folder

### "Unauthorized" in sync_user_usage
- Expected in SQL Editor (no auth context)
- Test in-app for full functionality

### RLS not blocking writes
- Ensure running as `authenticated` role, not `postgres`
- Use `SET ROLE authenticated;` before test

---

# Edge Function Tests

**Run in:** Terminal with `curl` or Supabase Dashboard > Edge Functions > Logs

**Project ref:** `mwoxtqxzunsjmbdqezif`

---

## Test 15: Verify Edge Functions Deployed

```bash
supabase functions list --project-ref mwoxtqxzunsjmbdqezif
```

**Expected (3 functions):**
```
┌───────────────────────┬────────┬────────────────┐
│ NAME                  │ STATUS │ VERSION        │
├───────────────────────┼────────┼────────────────┤
│ delete-user           │ Active │ ...            │
│ exchange-apple-token  │ Active │ ...            │
│ revenuecat-webhook    │ Active │ ...            │
└───────────────────────┴────────┴────────────────┘
```

---

## Test 16: Test `delete-user` Function

### 16.1: Test without auth (should fail)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/delete-user' \
  -H 'Content-Type: application/json'
```

**Expected:** `{"error":"No authorization header"}` (401)

### 16.2: Test with invalid token (should fail)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/delete-user' \
  -H 'Authorization: Bearer invalid-token' \
  -H 'Content-Type: application/json'
```

**Expected:** `{"error":"Invalid user"}` (401)

### 16.3: Test with valid user (DESTRUCTIVE - use test account only!)
```bash
# Get access token for test user first, then:
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/delete-user' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json'
```

**Expected:** `{"success":true,"message":"Account deleted successfully"}` (200)

**Verify in Dashboard:**
- User removed from auth.users
- user_usage row deleted
- user_entitlements row deleted
- apple_credentials row deleted (if Apple user)

---

## Test 17: Test `exchange-apple-token` Function

### 17.1: Test without auth (should fail)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/exchange-apple-token' \
  -H 'Content-Type: application/json' \
  -d '{}'
```

**Expected:** `{"error":"No authorization header"}` (401)

### 17.2: Test without authorization_code (should fail)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/exchange-apple-token' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{}'
```

**Expected:** `{"error":"Missing authorization_code"}` (400)

### 17.3: Test with invalid code (should fail gracefully)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/exchange-apple-token' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"authorization_code":"invalid-code"}'
```

**Expected:** `{"error":"Token exchange failed"}` (500)

**Note:** Full success test requires real Apple Sign In flow - verify via app testing.

---

## Test 18: Test `revenuecat-webhook` Function

### 18.1: Test without auth (should fail)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/revenuecat-webhook' \
  -H 'Content-Type: application/json' \
  -d '{}'
```

**Expected:** `{"error":"Unauthorized"}` (401)

### 18.2: Test with wrong secret (should fail)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/revenuecat-webhook' \
  -H 'Authorization: Bearer wrong-secret' \
  -H 'Content-Type: application/json' \
  -d '{}'
```

**Expected:** `{"error":"Unauthorized"}` (401)

### 18.3: Test with valid secret + anonymous user (should skip)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/revenuecat-webhook' \
  -H 'Authorization: Bearer YOUR_WEBHOOK_SECRET' \
  -H 'Content-Type: application/json' \
  -d '{
    "api_version": "1.0",
    "event": {
      "type": "INITIAL_PURCHASE",
      "app_user_id": "$RCAnonymousID:abc123",
      "product_id": "com.prosepal.pro.monthly",
      "original_app_user_id": "$RCAnonymousID:abc123"
    }
  }'
```

**Expected:** `{"success":true,"message":"Skipped anonymous user"}` (200)

### 18.4: Test with valid secret + real UUID (creates/updates entitlement)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/revenuecat-webhook' \
  -H 'Authorization: Bearer YOUR_WEBHOOK_SECRET' \
  -H 'Content-Type: application/json' \
  -d '{
    "api_version": "1.0",
    "event": {
      "type": "INITIAL_PURCHASE",
      "app_user_id": "YOUR_TEST_USER_UUID",
      "product_id": "com.prosepal.pro.monthly",
      "expiration_at_ms": 1735689600000,
      "original_app_user_id": "YOUR_TEST_USER_UUID"
    }
  }'
```

**Expected:** `{"success":true}` (200)

**Verify in Dashboard:**
```sql
SELECT * FROM user_entitlements WHERE user_id = 'YOUR_TEST_USER_UUID';
```
Should show `is_pro = true`.

### 18.5: Test expiration event (revokes Pro)
```bash
curl -X POST \
  'https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/revenuecat-webhook' \
  -H 'Authorization: Bearer YOUR_WEBHOOK_SECRET' \
  -H 'Content-Type: application/json' \
  -d '{
    "api_version": "1.0",
    "event": {
      "type": "EXPIRATION",
      "app_user_id": "YOUR_TEST_USER_UUID",
      "product_id": "com.prosepal.pro.monthly",
      "original_app_user_id": "YOUR_TEST_USER_UUID"
    }
  }'
```

**Expected:** `{"success":true}` (200)

**Verify:** `is_pro = false` in user_entitlements.

---

## Test 19: Verify Edge Function Logs

Check recent invocations in Supabase Dashboard:
1. Go to Edge Functions
2. Select each function
3. Check Logs tab for errors

**What to look for:**
- No 500 errors in normal operation
- Auth failures logged (401s expected for bad requests)
- Successful operations logged with redacted user IDs

---

## Quick Checklist (Edge Functions)

| # | Test | Pass |
|---|------|------|
| 15 | All 3 functions deployed | ☐ |
| 16 | `delete-user` auth works | ☐ |
| 17 | `exchange-apple-token` validation works | ☐ |
| 18.1 | `revenuecat-webhook` rejects no auth | ☐ |
| 18.2 | `revenuecat-webhook` rejects wrong secret | ☐ |
| 18.3 | `revenuecat-webhook` skips anonymous | ☐ |
| 18.4 | `revenuecat-webhook` grants Pro | ☐ |
| 18.5 | `revenuecat-webhook` revokes Pro | ☐ |
| 19 | No errors in logs | ☐ |

---

## Deploying Edge Functions

```bash
# Deploy all functions
cd supabase

supabase functions deploy delete-user --project-ref mwoxtqxzunsjmbdqezif
supabase functions deploy exchange-apple-token --project-ref mwoxtqxzunsjmbdqezif
supabase functions deploy revenuecat-webhook --project-ref mwoxtqxzunsjmbdqezif
```

## Environment Variables Required

Set in Supabase Dashboard > Edge Functions > Secrets:

| Function | Variables |
|----------|-----------|
| All | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` (auto-set) |
| `delete-user` | `APPLE_TEAM_ID`, `APPLE_CLIENT_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` |
| `exchange-apple-token` | `APPLE_TEAM_ID`, `APPLE_CLIENT_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` |
| `revenuecat-webhook` | `REVENUECAT_WEBHOOK_SECRET` |
