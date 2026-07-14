# Supabase Backend

This directory contains ProsePal Edge Functions, PostgreSQL migrations, pgTAP
tests, and local Supabase configuration.

## Functions

| Function | Purpose |
|---|---|
| `generate-card` | Authenticated, metered, idempotent careful generation |
| `delete-user` | Authenticated privileged account deletion and Apple revocation |
| `exchange-apple-token` | Stores Apple revocation material through a server boundary |
| `send-feedback` | Authenticated feedback delivery |
| `app-store-notifications` | App Store Server Notifications V2 verification |
| `app-store-reconcile-entitlement` | Guarded App Store entitlement reconciliation |

Exact endpoints and database RPCs are documented in
[Service endpoints](../docs/reference/service-endpoints.md). Configuration names
and secret boundaries are documented in
[Configuration](../docs/reference/configuration.md).

## Local validation

Start the local stack:

```bash
supabase start
```

Run the backend gates:

```bash
deno check supabase/functions/**/*.ts
find supabase/functions -name '*.test.ts' -exec deno test --allow-env {} +
supabase test db
./scripts/test_gateway_ledger_concurrency.sh
supabase db lint --local --level warning
```

The concurrency script connects to the local database on the standard Supabase
port unless `PROSEPAL_SUPABASE_DB_URL` supplies another local database URL.

## Remote safety

- Staging ref: `llolwgqphwnhbiqewmcq`.
- Production ref: `mwoxtqxzunsjmbdqezif`.
- Never use `supabase db push --linked` for remote mutation.
- Use an explicit staging project reference for function deploys.
- Use the guarded helper and human-supplied `STAGING_DB_URL` for staging
  migrations.
- Never print provider, service-role, Apple, reconciliation, database, or
  development-gateway secrets.

Follow [Staging](../docs/operations/staging.md) before any remote operation. No
command in this README authorizes a deployment or migration by itself.

## Migrations

Create migrations with:

```bash
supabase migration new <descriptive_name>
```

Test from a fresh local database when migration ordering or extension setup
changes:

```bash
supabase db reset --local
supabase test db
```

Do not edit or reorder an applied remote migration. Add a new migration.
