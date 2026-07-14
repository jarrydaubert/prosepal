# Service Endpoint Reference

The native app talks only to ProsePal-owned or Apple/Supabase boundaries. It
does not call a model provider directly.

## Supabase projects

| Environment | Project ref | Use |
|---|---|---|
| Staging | `llolwgqphwnhbiqewmcq` | UAT, gateway proof, auth and entitlement staging |
| Production | `mwoxtqxzunsjmbdqezif` | Protected production infrastructure |

## Edge Functions

Supabase Function URLs follow:

```text
https://<project-ref>.supabase.co/functions/v1/<function-name>
```

| Function | Caller | Purpose |
|---|---|---|
| `generate-card` | Native gateway client | Authenticates, reserves policy capacity, calls the configured provider, checks quality, and finalizes/replays the result |
| `delete-user` | Authenticated native account client | Requires Apple revocation for Apple accounts, validates cleanup, and deletes auth data with retry-safe failures |
| `exchange-apple-token` | Authenticated Apple account flow | Validates the caller and Apple grant, then stores only the refresh token required for later revocation |
| `send-feedback` | App feedback flow | Authenticates and forwards user-requested support feedback |
| `app-store-notifications` | Apple App Store server | Verifies notification JWS and records entitlement events |
| `app-store-reconcile-entitlement` | Guarded server/operator path | Reconciles authoritative App Store subscription state |

The native staging gateway URL is:

```text
https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card
```

## Database functions

| Function | Access | Purpose |
|---|---|---|
| `reserve_card_request` | Service role only | Atomically resolves idempotency, burst policy, and quota before provider work |
| `finalize_card_request` | Service role only | Completes or fails the current reservation attempt and charges successful authenticated usage once |
| `cleanup_gateway_requests` | Service role/cron | Removes expired replay payloads and old terminal or abandoned metadata |
| `cleanup_rate_limit_logs` | Cron/owner | Removes sliding-window attempt rows older than the retention window |
| legacy usage RPCs | Restricted legacy surface | Retained only for staged retirement; not the native generation path |

Client roles cannot read the gateway request ledger or invoke the reservation
and finalization functions.

## Apple services

- StoreKit 2 supplies products, purchases, restores, current transactions, and
  transaction updates to the app.
- App Store Server Notifications V2 supply signed subscription events.
- App Store Server API supplies authoritative reconciliation data.
- Sign in with Apple supplies native identity tokens and revocation endpoints.

## Historical endpoints

Firebase AI, Remote Config, RevenueCat, and Flutter client endpoints are frozen
under [history/flutter](../history/flutter/README.md). They are not native
runtime configuration.

## Safety rules

- Never place service-role, provider, Apple private-key, or reconciliation
  credentials in the native app.
- Never deploy or migrate production from an agent task without explicit human
  authorization for the exact operation.
- Use [Staging](../operations/staging.md) for guarded remote proof.
