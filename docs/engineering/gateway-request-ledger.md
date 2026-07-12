# Gateway Request Ledger

The gateway request ledger is the server-side boundary that decides whether a
generation may enter paid provider work. It combines request identity, burst
control, quota reservation, replay, final charging, and retention in one row so
those concerns cannot race independently.

## Why it exists

Mobile requests can time out after the server has already generated a response.
Users also retry, processes restart, and parallel calls can arrive at the last
available allowance. A simple “check quota, generate, then increment” sequence
cannot prevent duplicate provider cost or ambiguous charges under those races.

The ledger gives each logical request one durable identity:

```text
(subject, idempotency_key)
  + request fingerprint
  + reservation attempt token
  + reserved / completed / failed state
```

## Data model

`public.gateway_requests` stores:

- authenticated user UUID or the single guarded `dev-anonymous` subject;
- idempotency key and SHA-256 request fingerprint;
- a per-attempt reservation token;
- `reserved`, `completed`, or `failed` status;
- attempt count, lane, contract version, and privacy-safe failure bucket;
- entitlement/month metadata used during reservation;
- a successful response payload for short-lived replay; and
- reservation and payload expiry timestamps.

The table uses row-level security and grants no table access to `anon` or
`authenticated`. Only service-role Edge Function calls can use its RPCs.

## Reservation

`reserve_card_request` takes:

```text
user ID or guarded anonymous mode
idempotency key
request fingerprint
lane
contract version
```

It takes a transaction-scoped advisory lock for the subject before resolving
identity, quota, and rate policy. This serializes competing requests for the
same user while leaving different users independent.

Current outcomes are:

| Outcome | Meaning | Provider call allowed? |
|---|---|---|
| `reserved` | New or reclaimed attempt owns a fresh reservation token | Yes |
| `replay` | Completed response is still inside its replay window | No |
| `replay_expired` | Logical request completed but its response payload is gone | No |
| `idempotency_conflict` | Same key was reused with different provider-affecting input | No |
| `in_flight` | Another unexpired attempt owns the request | No |
| `quota_exhausted` | Effective usage plus active reservations reaches policy | No |
| `rate_limited` | Subject reached the short sliding-window limit | No |

Current repository policy allows one lifetime generation for a free
authenticated user and 500 per month for an entitled user. Active reservations
count against the decision, so parallel calls cannot all pass the final slot.
The burst boundary is 10 provider-bound attempts per subject in 60 seconds.

Anonymous development uses the same burst reservation but is reachable only
when the Edge Function’s explicit development flag and separate secret are both
configured.

## Lease and reclaim

A reservation lease lasts 120 seconds. A retry with the same key and fingerprint
receives `in_flight` while that lease is active. After expiry, reservation can
be reclaimed with a new token and incremented attempt count.

The per-attempt token matters because the original provider call may return
late. `finalize_card_request` rejects a token from an older attempt instead of
letting stale work complete the reclaimed row.

## Finalization

The Edge Function finalizes only after provider output passes response and
quality checks:

```text
reserved -> completed  charge authenticated usage once; cache safe response
reserved -> failed     record failure bucket; do not charge usage
```

Repeated matching finalization is idempotent. Missing rows, stale tokens, and
illegal transitions return explicit outcomes rather than silently changing
state. A completed response must be a JSON object.

One deliberate trade-off exists: if generation succeeds but finalization is
temporarily unavailable, the Edge Function returns the generated message with a
privacy-safe diagnostic marker. This avoids discarding useful output, but it
means release evidence must prove the finalization-failure policy is acceptable.

## Retention and cleanup

| Data | Retention |
|---|---|
| Successful replay payload containing generated text | At most 24 hours |
| Terminal or abandoned request metadata | 7 days |
| Sliding-window rate-attempt rows | 1 hour |

An hourly `pg_cron` job runs `cleanup_gateway_requests` and
`cleanup_rate_limit_logs`. Full keys, fingerprints, generated messages, and
prompt content are not written to operational logs.

## Native retry continuity

For an initial careful draft, `CarefulRequestKeyStore` persists the request key
plus a non-content request identity for up to 24 hours. An unchanged retry or
relaunch can therefore reach ledger replay instead of producing and charging
again. Replay expiry or fingerprint conflict clears the pending key and requires
another explicit user action.

The current durable store covers initial careful drafts. Expansion to Adjust and
Take More Care is tracked only in [BACKLOG.md](../BACKLOG.md).

## Verification

```bash
deno test --allow-env supabase/functions/generate-card/index.test.ts
supabase test db
./scripts/test_gateway_ledger_concurrency.sh
```

The Deno suite proves provider-call suppression and Edge outcome mapping. pgTAP
proves permissions, transitions, expiry, and cleanup. The concurrency harness
uses separate PostgreSQL sessions to prove real locking and uniqueness races.

## Source map

- `supabase/migrations/20260712170634_gateway_request_ledger.sql`
- `supabase/functions/generate-card/index.ts`
- `supabase/functions/generate-card/index.test.ts`
- `supabase/tests/gateway_request_ledger_test.sql`
- `scripts/test_gateway_ledger_concurrency.sh`
- `prosepal-ios/Sources/ProsePalAPI/CarefulRequestKeyStore.swift`

## Related documentation

- [AI generation](./ai-generation.md)
- [Generation contract](../reference/generation-contract.md)
- [Staging](../operations/staging.md)
