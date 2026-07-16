# Supabase Inactivity Keepalive

A temporary Free-plan pre-launch control. Free-plan Supabase projects pause
after prolonged inactivity; a scheduled GitHub Actions workflow calls a
dedicated read-only RPC daily so production and staging register genuine
database activity.

This is not a substitute for a real plan: **before launch, the live production
project must move to a non-pausing paid Supabase plan.** That is a release
requirement, and this keepalive is retired once it happens.

## The RPC

Migration `supabase/migrations/20260716135000_add_keepalive_rpc.sql` defines
`public.keepalive()`:

- executes a genuine query (`SELECT now()`);
- reads no tables and writes no rows;
- returns only the server timestamp;
- `SECURITY INVOKER` with a pinned empty `search_path`;
- executable with the public anon/publishable key — no service-role
  credentials exist anywhere in this control;
- exposes no account, subscription, message, draft, or relationship data.

Expected response: HTTP 200 with a JSON timestamp string, for example
`"2026-07-16T03:17:04.123456+00:00"`.

## Workflow

`.github/workflows/supabase-keepalive.yml` runs daily at 03:17 UTC and on
manual `workflow_dispatch`. Production and staging run as independent matrix
jobs (`fail-fast: false`), so one environment failing never hides the other.
Each call sends both `apikey` and `Authorization: Bearer` headers, uses a 10 s
connect / 30 s total timeout, retries transient network failures up to 3 times
with a 5 s delay, and fails loudly on any non-2xx or non-timestamp response.
Failure output names only the environment — never URLs or key values. The
workflow calls only the keepalive RPC: no generation, authentication,
subscription, deletion, or user-data endpoints.

Production participation is gated by the repository variable
`KEEPALIVE_PRODUCTION_ENABLED`. While it is absent or not `true`, the
production job emits a neutral not-enabled notice and succeeds without calling
anything, so the scheduled workflow stays green on staging success alone. Once
the variable is `true`, production is called independently and missing
production secrets fail loudly.

Scheduling becomes operational only after the staging repository secrets below
are added; until then the staging job fails with an explicit
secrets-not-configured message.

## GitHub secret and variable setup

Repository → Settings → Secrets and variables → Actions. Public client values
only (never a service-role key):

| Secret | Value | When |
|---|---|---|
| `SUPABASE_STAGING_URL` | `https://<staging-project-ref>.supabase.co` | Now — activates scheduling |
| `SUPABASE_STAGING_ANON_KEY` | Staging public anon/publishable key | Now — activates scheduling |
| `SUPABASE_PRODUCTION_URL` | `https://<production-project-ref>.supabase.co` | Only at production approval |
| `SUPABASE_PRODUCTION_ANON_KEY` | Production public anon/publishable key | Only at production approval |

Repository variable (Variables tab, not a secret):

| Variable | Value | Meaning |
|---|---|---|
| `KEEPALIVE_PRODUCTION_ENABLED` | unset / `false` | Production skipped neutrally (default) |
| `KEEPALIVE_PRODUCTION_ENABLED` | `true` | Production called; missing secrets fail loudly |

The anon key is the client-side publishable key from Project Settings → API.
Do not create or store a service-role key for this workflow. An enabled
environment whose secrets are missing fails with an explicit message naming
the environment.

## Verification

Local, against any project:

```bash
PROSEPAL_KEEPALIVE_URL=https://<project-ref>.supabase.co \
PROSEPAL_KEEPALIVE_ANON_KEY=<public-anon-key> \
./scripts/verify_keepalive.sh
```

Staging smoke (resolves the staging URL and public key via the authenticated
Supabase CLI; touches staging only):

```bash
./scripts/keepalive-staging-smoke.sh
```

Manual curl (placeholders only):

```bash
curl -X POST "https://<project-ref>.supabase.co/rest/v1/rpc/keepalive" \
  -H "apikey: <public-anon-key>" \
  -H "Authorization: Bearer <public-anon-key>" \
  -H "Content-Type: application/json" \
  --data '{}'
```

Database contract test: `supabase test db` runs
`supabase/tests/keepalive_test.sql`, which pins the function's return type,
`SECURITY INVOKER`, stable volatility, restricted `search_path`, and
anon-executable grant.

## Status (2026-07-16)

- Staging runtime is proven: the migration is applied to the staging project
  and the smoke script returned HTTP 200 with a server timestamp through the
  public anon key, independently verified.
- The pgTAP contract test has not yet run because Docker was unavailable on
  the authoring machine; run `supabase test db` on the next local stack
  session.
- GitHub scheduling becomes operational only after the two staging repository
  secrets are added.
- Production remains behind explicit approval: its migration is not applied,
  its secrets are not set, and `KEEPALIVE_PRODUCTION_ENABLED` stays unset
  until approval.

## Failure and recovery

1. A red `Supabase keepalive` run names the failed environment in its error
   annotation. Check the other environment's job — they are independent.
2. `secrets are not configured` → add or fix that environment's repository
   secrets per the table above (production only fails this way once
   `KEEPALIVE_PRODUCTION_ENABLED` is `true`).
3. HTTP 401/403 → the stored anon key is wrong or was rotated; copy the current
   publishable key from Project Settings → API.
4. HTTP 404 → the keepalive migration is not applied to that project; apply it
   through the guarded migration path (staging: `./scripts/supabase-staging.sh
   db-push`; production: the approved production migration step).
5. Timeout/5xx → check the project is not paused or unhealthy in the Supabase
   dashboard (`supabase projects list`); resume it, then re-run the workflow
   via `workflow_dispatch`.
6. After any fix, trigger the workflow manually and confirm both jobs are
   green.

## Workflow health

A scheduler that silently stops running looks identical to success. Check the
`Supabase keepalive` workflow's run history at least weekly (GitHub also
disables cron workflows in repositories with no activity for 60 days —
re-enable it from the Actions tab if that happens). Treat a missing daily run
as a failure of this control.
