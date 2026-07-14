# Configuration Reference

This reference lists the configuration names used by the native app and
Supabase functions. It deliberately contains no secret values.

## Native public configuration

These values may be delivered by an Xcode Run environment for local work or by
build settings copied into `Info.plist` for archives.

| Key | Purpose | Required for |
|---|---|---|
| `PROSEPAL_GATEWAY_URL` | HTTPS URL of `generate-card` | Careful generation |
| `PROSEPAL_SUPABASE_URL` | Supabase project URL | Auth and account maintenance |
| `PROSEPAL_SUPABASE_ANON_KEY` | Supabase publishable/legacy anon key | Auth and authenticated public APIs |
| `PROSEPAL_PREMIUM_PRODUCT_IDS` | Comma-separated StoreKit products | Paywall, purchase, restore |
| `PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID` | Preferred product identifier | Recommended paywall selection |

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are accepted as native local fallbacks,
but the `PROSEPAL_` names are the app-facing contract.

The Supabase client key must be either a modern `sb_publishable_...` key or a
legacy three-segment anon JWT. A project reference alone is not an API key and
is treated as unconfigured.

## Native local-only configuration

| Key | Purpose | Rule |
|---|---|---|
| `PROSEPAL_DEV_GATEWAY_SECRET` | Authorizes the staging anonymous-development path | Local scheme only; archive validation rejects it |

The local staging scheme is ignored by Git. See
[Staging](../operations/staging.md).

If that scheme is restored while Xcode is open, quit and reopen Xcode before
running the app. Xcode can retain the previous launch environment in memory
even after the scheme file on disk has been replaced and validated.

## Archive delivery

TestFlight and App Store archives do not inherit Xcode Run environment values.
The app target’s build settings provide the gateway URL, Supabase URL, and
publishable key to `Info.plist`. The archive validation build phase fails when
required public values are missing or insecure, when environment/target values
are mixed, or when a development/privileged secret is embedded.

## Generate-card secrets and policy

| Key | Purpose |
|---|---|
| `GATEWAY_DEV_ALLOW_ANONYMOUS` | Explicitly enables the staging-only anonymous path |
| `PROSEPAL_DEV_GATEWAY_SECRET` | Required secret whenever anonymous development is enabled |
| `PROSEPAL_AI_PROVIDER` | Provider adapter mode; current server accepts `openai-compatible` |
| `PROSEPAL_AI_PROVIDER_URL` | Provider endpoint |
| `PROSEPAL_AI_PROVIDER_API_KEY` | Provider credential |
| `PROSEPAL_AI_PROVIDER_MODEL` | Primary configured model |
| `PROSEPAL_AI_PROVIDER_FALLBACK_MODELS` | Optional ordered model fallbacks |
| `PROSEPAL_AI_PROVIDER_JSON_MODE` | Optional structured-output request flag |
| `PROSEPAL_AI_PROVIDER_TIMEOUT_MS` | Optional bounded provider timeout |
| `PROSEPAL_AI_PROVIDER_MAX_TOKENS` | Optional output-token bound |
| `PROSEPAL_AI_PROVIDER_TEMPERATURE` | Optional generation temperature |
| `PROSEPAL_AI_PROVIDER_SLOT` | Privacy-safe operator slot label |
| `SUPABASE_URL` | Project URL supplied by Supabase runtime |
| `SUPABASE_SERVICE_ROLE_KEY` | Privileged database client used only in Edge Functions |

Provider values and the service-role key must never enter an app bundle, shared
scheme, log, screenshot, or evidence file.

## Apple sign-in and deletion secrets

`delete-user` and `exchange-apple-token` use:

- `APPLE_TEAM_ID`
- `APPLE_CLIENT_ID`
- `APPLE_KEY_ID`
- `APPLE_PRIVATE_KEY`
- Supabase runtime URL, anon key, and service-role key as required by the
  function.

The Apple private key is sensitive signing material.

## App Store server configuration

Notification and reconciliation functions use the applicable subset of:

- `APP_STORE_PREMIUM_PRODUCT_IDS` or `PROSEPAL_PREMIUM_PRODUCT_IDS`
- `APP_STORE_ENVIRONMENT`
- `APP_STORE_BUNDLE_ID`
- `APP_STORE_APP_APPLE_ID`
- `APP_STORE_ROOT_CERTIFICATES_PEM`
- `APP_STORE_ENABLE_ONLINE_CHECKS`
- `APP_STORE_SERVER_API_KEY_ID`
- `APP_STORE_SERVER_API_ISSUER_ID`
- `APP_STORE_SERVER_API_PRIVATE_KEY`
- `APP_STORE_RECONCILE_SECRET`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Production requires the numeric App Apple ID where the verification library
expects it. Private keys, reconciliation secrets, and signed payloads remain
server-side.

## Feedback function

`send-feedback` uses:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `RESEND_API_KEY`
- `FEEDBACK_TO_EMAIL`
- `FEEDBACK_FROM_EMAIL`

## Product identifiers

- `com.prosepal.pro.yearly`
- `com.prosepal.pro.monthly`
- `com.prosepal.pro.weekly`

Local StoreKit configuration lives at
`prosepal-ios/App/ProsePalStaging.storekit`.

## Validation

- Runtime URL parsing accepts HTTPS remote URLs; insecure loopback is limited to
  explicit debug policy.
- Local empty or malformed values become “not configured” rather than
  half-configured state.
- Archive validation checks required public values without printing them.
- Repository scans and release evidence must confirm privileged values are
  absent.
