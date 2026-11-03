# Configuration keys

Names only; no values/secrets in Git. [RUNBOOK](RUNBOOK.md) owns procedures.
Exact consumers: `NativeRuntimeConfig.swift`, `App/Info.plist`, Xcode build phases
and each `supabase/functions/<function>/index.ts`. Inspect them for defaults/constraints.

## App public values

Local Run: ignored user scheme environment. Archive: target build settings/public
xcconfig → Info.plist. Run environments MUST NOT be assumed to configure an archive.

| Key | Owner/use |
|---|---|
| `PROSEPAL_GATEWAY_URL` | HTTPS generation endpoint |
| `PROSEPAL_SUPABASE_URL` | HTTPS auth/account project URL |
| `PROSEPAL_SUPABASE_ANON_KEY` | Public publishable/legacy anon key; never service-role |
| `PROSEPAL_PREMIUM_PRODUCT_IDS` | Comma-separated StoreKit inventory |
| `PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID` | Recommended configured product |
| `PROSEPAL_RETIRED_PREMIUM_PRODUCT_IDS` | Historical entitlement recognition; excluded from paywall |

`SUPABASE_URL`/`SUPABASE_ANON_KEY` are accepted local aliases; prefer the app-facing
`PROSEPAL_` names. A project ref alone is not a publishable key. Validate effective
Release settings and archive contents; G-1 owns missing production Premium configuration.
Product inventory: `com.prosepal.pro.yearly`, `com.prosepal.pro.monthly`,
`com.prosepal.pro.weekly`. Verify App Store Connect availability separately.

## Local-only secret

`PROSEPAL_DEV_GATEWAY_SECRET`: ignored local scheme and staging Edge secrets only.
MUST NOT enter a shared scheme or archive. Anonymous development also requires
server `GATEWAY_DEV_ALLOW_ANONYMOUS=true`; it is not production access.

## Edge Function secrets/policy

Supply through the target Supabase project's function secrets/runtime, not the app.
Never print environment dumps or signing material. Keep staging/production credentials
separate. Credentials/reconciliation secrets/signed payloads MUST NOT enter logs/evidence.

| Function boundary | Keys (applicable subset) |
|---|---|
| Runtime/database | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`; service-role stays server-only |
| Generation adapter | `PROSEPAL_AI_PROVIDER`, `PROSEPAL_AI_PROVIDER_URL`, `PROSEPAL_AI_PROVIDER_API_KEY`, `PROSEPAL_AI_PROVIDER_MODEL`, `PROSEPAL_AI_PROVIDER_FALLBACK_MODELS` |
| Generation parameters | `PROSEPAL_AI_PROVIDER_JSON_MODE`, `PROSEPAL_AI_PROVIDER_TIMEOUT_MS`, `PROSEPAL_AI_PROVIDER_MAX_TOKENS`, `PROSEPAL_AI_PROVIDER_TEMPERATURE`, `PROSEPAL_AI_PROVIDER_SLOT` |
| Apple token exchange/deletion | `APPLE_TEAM_ID`, `APPLE_CLIENT_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` |
| App Store notifications/reconciliation | `APP_STORE_PREMIUM_PRODUCT_IDS` (or `PROSEPAL_PREMIUM_PRODUCT_IDS`), `APP_STORE_ENVIRONMENT`, `APP_STORE_BUNDLE_ID`, `APP_STORE_APP_APPLE_ID`, `APP_STORE_ROOT_CERTIFICATES_PEM`, `APP_STORE_ENABLE_ONLINE_CHECKS` |
| App Store Server API/reconciliation | `APP_STORE_SERVER_API_KEY_ID`, `APP_STORE_SERVER_API_ISSUER_ID`, `APP_STORE_SERVER_API_PRIVATE_KEY`, `APP_STORE_RECONCILE_SECRET` |
| Feedback | `RESEND_API_KEY`, `FEEDBACK_TO_EMAIL`, `FEEDBACK_FROM_EMAIL` |

Provider keys describe current implementation, not a settled provider/fallback
architecture; W-8 owns that decision. Configurable endpoints do not prove deployment.
`APPLE_CLIENT_ID` must match the target's approved Apple identity. Production JWS
verification requires the numeric App Apple ID where the verifier expects it.

## Operator and CI configuration

- `STAGING_DB_URL`: credential-bearing operator shell input to the guarded staging
  migration helper; never print or commit. Do not infer it from local link state.
- `PROSEPAL_SUPABASE_DB_URL`: optional local concurrency-harness database override.
- Keepalive public keys/URLs and production-enable variable: RUNBOOK's keepalive section.
- StoreKit/UI result paths and scheme-backup override: RUNBOOK and script usage.
