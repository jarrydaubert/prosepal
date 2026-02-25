# Supabase Verification Runbook

## Purpose

Verify database schema, RPC security, and edge-function behavior used by the app.

## Prerequisites

- Access to Supabase project dashboard and SQL editor.
- Access token/secret for edge-function calls where required.
- Test user accounts available for authenticated flow checks.
- `psql` installed locally for automated read-only verification.
- `SUPABASE_DB_URL` connection string for the target project.

## Automated Read-Only Verification

Run the non-destructive database checks:

```bash
SUPABASE_DB_URL="postgresql://..." ./scripts/verify_supabase_readonly.sh
```

What this script verifies:
- required app tables exist,
- required RPC/functions exist,
- RLS is enabled on protected tables,
- at least one RLS policy exists on each protected table.

Notes:
- This script is read-only and does not mutate data.
- Edge-function behavior checks and destructive/security-sensitive checks remain manual.

## Database Verification

### 1) Required tables exist

```sql
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

Pass criteria:
- Required app tables are present (usage, entitlement, rate-limit, and auth-related app tables).

### 2) Required RPC/functions exist

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

Pass criteria:
- Required functions for usage checks, device free-tier checks, rate limiting, and entitlement checks are present.

### 3) RLS policies are present and scoped to caller identity

```sql
SELECT tablename, policyname, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

Pass criteria:
- User-scoped tables are protected by policies enforcing caller identity.
- Direct writes to protected usage/entitlement tables are denied where expected.

## RPC Behavior Verification

### 4) Entitlement lookup

```sql
SELECT is_user_pro('00000000-0000-0000-0000-000000000000');
```

Pass criteria:
- Function returns a deterministic result and does not throw.

### 5) Usage check/increment path

```sql
SELECT check_and_increment_usage(
  'YOUR_USER_ID'::UUID,
  true,
  'YYYY-MM'
);
```

Pass criteria:
- Response shape matches app expectations.
- Counters move monotonically and limits are enforced.

### 6) Rate-limit check

```sql
SELECT check_rate_limit(
  'YOUR_USER_ID'::UUID,
  'test-device-fingerprint',
  'generation'
);
```

Pass criteria:
- Function returns allow/deny + retry metadata consistently.

### 7) Device free-tier check

```sql
SELECT check_device_free_tier('test-device-id', 'ios');
```

Pass criteria:
- Response indicates allowed/blocked and reason without error.

### 8) Monotonic sync protection

```sql
SELECT sync_user_usage(
  'YOUR_USER_ID'::UUID,
  0,
  0,
  '2000-01'
);
```

Pass criteria:
- Unauthorized/decreasing write attempts are blocked.

## Edge Function Verification

### 9) `delete-user`

Pass criteria:
- Authenticated caller can trigger delete flow.
- Missing/invalid auth is rejected.
- User data cleanup path completes without privilege escalation.

### 10) `exchange-apple-token`

Pass criteria:
- Valid request stores required token material for compliant account deletion flow.
- Invalid auth code or auth context fails safely.

### 11) `revenuecat-webhook`

Pass criteria:
- Signature/secret validation enforced.
- Entitlement updates applied only for valid events.
- Anonymous/no-op events are safely ignored where configured.

## Failure Handling

- Capture SQL/function output and request/response payloads.
- Open/update a backlog item with: failing step, repro query/request, expected vs actual.
- Block release promotion when auth, entitlement, usage, or deletion-path checks fail.
