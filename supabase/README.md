# Supabase Edge Functions

## delete-user

Handles account deletion (App Store requirement).

**Deployed to:** `mwoxtqxzunsjmbdqezif`

### Deploy changes
```bash
supabase functions deploy delete-user --project-ref mwoxtqxzunsjmbdqezif
```

### Test locally
```bash
supabase functions serve delete-user
```

## send-feedback

Relays authenticated in-app feedback to the support inbox through Resend.

**Deployed to:** `mwoxtqxzunsjmbdqezif`

### Required secrets
- `RESEND_API_KEY`
- `FEEDBACK_TO_EMAIL`
- `FEEDBACK_FROM_EMAIL`
- existing `SUPABASE_URL` / `SUPABASE_ANON_KEY`
- `supabase/config.toml` must include `[functions.send-feedback] verify_jwt = false`
  because this function validates the Supabase user inside the function body.

### Deploy changes
```bash
supabase functions deploy send-feedback --project-ref mwoxtqxzunsjmbdqezif
```

### Test locally
```bash
supabase functions serve send-feedback
```

## generate-card

Accepts the native SwiftUI `CardRequest` contract and returns `CardResponse`
without exposing provider names, model names, or provider payloads to the
client. This is a native iOS R&D gateway path only; Flutter production routing
remains client-direct Firebase AI / Vertex AI.

**Production deployment:** not enabled as the default AI path. Production
gateway rollout still requires the approval gates in
`docs/architecture/AI_GATEWAY_STRATEGY.md`.

### Required environment

Authenticated mode is the default:

- existing `SUPABASE_URL` / `SUPABASE_ANON_KEY`
- `supabase/config.toml` must include `[functions.generate-card] verify_jwt = false`
  because this function validates auth inside the function body.

Explicit local anonymous mode is available for native R&D:

- `GATEWAY_DEV_ALLOW_ANONYMOUS=true`
- optional `PROSEPAL_DEV_GATEWAY_SECRET`

OpenAI-compatible dev-provider mode uses a full chat-completions style endpoint:

- `PROSEPAL_AI_PROVIDER=openai-compatible`
- `PROSEPAL_AI_PROVIDER_URL`
- `PROSEPAL_AI_PROVIDER_API_KEY`
- `PROSEPAL_AI_PROVIDER_MODEL`
- optional `PROSEPAL_AI_PROVIDER_FALLBACK_MODELS`
- optional `PROSEPAL_AI_PROVIDER_JSON_MODE=true`
- optional `PROSEPAL_AI_PROVIDER_TIMEOUT_MS`
- optional `PROSEPAL_AI_PROVIDER_MAX_TOKENS`
- optional `PROSEPAL_AI_PROVIDER_TEMPERATURE`
- optional `PROSEPAL_AI_PROVIDER_SLOT`

`PROSEPAL_AI_PROVIDER_SLOT` is internal operational metadata only. Do not show
provider or model names in user-facing app UI.

When `PROSEPAL_DEV_GATEWAY_SECRET` is configured, anonymous dev requests must
include the matching `X-ProsePal-Dev-Gateway-Secret` header. This is a staging
guard only; production rollout still requires real auth, entitlement, abuse
controls, and the gateway approval gates.

### Deploy changes

Deploy only to an approved development or staging project until the production
gateway rollout gates are met:

```bash
supabase functions deploy generate-card --project-ref <dev-or-staging-project-ref>
```

### Test locally

Dev-provider mode:

```bash
GATEWAY_DEV_ALLOW_ANONYMOUS=true \
PROSEPAL_AI_PROVIDER=openai-compatible \
PROSEPAL_AI_PROVIDER_URL=https://<dev-provider-host>/v1/chat/completions \
PROSEPAL_AI_PROVIDER_API_KEY=<secret> \
PROSEPAL_AI_PROVIDER_MODEL=<dev-model-id> \
PROSEPAL_AI_PROVIDER_FALLBACK_MODELS=<fallback-model-id-1,fallback-model-id-2> \
supabase functions serve generate-card
```

Run the handler tests:

```bash
deno test --allow-env supabase/functions/generate-card/index.test.ts
```

### Staging gateway runbook

Staging project:

- Project ref: `llolwgqphwnhbiqewmcq`
- Function URL:
  `https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card`
- Deploy source worktree: `/private/tmp/prosepal-ios-native-worktree`

Native iOS Xcode scheme environment variable:

```text
PROSEPAL_GATEWAY_URL=https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card
```

Optional staging guard Xcode scheme environment variable, required only when
the matching Supabase secret is configured:

```text
PROSEPAL_DEV_GATEWAY_SECRET=<staging-only-secret>
```

Required Supabase secrets, names only:

- `GATEWAY_DEV_ALLOW_ANONYMOUS`
- optional `PROSEPAL_DEV_GATEWAY_SECRET`
- `PROSEPAL_AI_PROVIDER`
- `PROSEPAL_AI_PROVIDER_URL`
- `PROSEPAL_AI_PROVIDER_API_KEY`
- `PROSEPAL_AI_PROVIDER_MODEL`
- optional `PROSEPAL_AI_PROVIDER_FALLBACK_MODELS`
- optional `PROSEPAL_AI_PROVIDER_JSON_MODE`
- optional `PROSEPAL_AI_PROVIDER_TIMEOUT_MS`
- optional `PROSEPAL_AI_PROVIDER_MAX_TOKENS`
- optional `PROSEPAL_AI_PROVIDER_TEMPERATURE`
- optional `PROSEPAL_AI_PROVIDER_SLOT`

`GATEWAY_DEV_ALLOW_ANONYMOUS=true` is for staging/native R&D only. Do not use
anonymous generation for production rollout.

Empty-body validation smoke:

```bash
curl -sS -X POST \
  'https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card' \
  -H 'Content-Type: application/json' \
  -H 'X-ProsePal-Dev-Gateway-Secret: <staging-only-secret-if-configured>' \
  -d '{}'
```

Expected shape:

```json
{
  "error": "Card intent is required",
  "user_safe_error": {
    "code": "missing_intent",
    "message": "Those message details could not be used. Try adjusting them."
  }
}
```

Synthetic generation smoke:

```bash
curl -sS -X POST \
  'https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card' \
  -H 'Content-Type: application/json' \
  -H 'X-ProsePal-Dev-Gateway-Secret: <staging-only-secret-if-configured>' \
  -d '{
    "idempotency_key": "staging-smoke-001",
    "requested_lane": "standard",
    "prompt_contract_version": 1,
    "output_contract_version": 1,
    "client_context": {
      "app_version": "0.1.0",
      "build_number": "1",
      "platform": "ios"
    },
    "intent": {
      "occasion": "birthday",
      "relationship": "parent",
      "tone": "heartfelt",
      "length": "brief",
      "spelling_preference": "uk",
      "locale_identifier": "en_GB",
      "recipient_name": "Alex",
      "things_to_include": ["a quiet cup of tea"],
      "things_to_avoid": ["age jokes"],
      "user_context": "Keep it warm and simple."
    }
  }'
```

Expected success shape:

- HTTP `200`
- `messages` has 3 generated message objects
- `lane_used` is `standard`
- `fallback_status` is `none`
- `quality_check.passed` is `true`
- `prompt_contract_version` is `1`
- `output_contract_version` is `1`

If `PROSEPAL_DEV_GATEWAY_SECRET` is configured and the request omits or sends a
wrong `X-ProsePal-Dev-Gateway-Secret` header, the function returns HTTP `401`
with `user_safe_error.code` set to `dev_gateway_secret_required`.

Operator logs for `generate-card` include request id prefix, requested lane,
contract versions, app version, platform, redacted user id, auth mode, provider
slot, server-side model id, fallback status, and latency. They intentionally do
not log raw user prompt/card content, generated message text, provider API keys,
authorization tokens, or provider payloads.

## app-store-notifications

Receives App Store Server Notifications V2 for the native StoreKit 2
subscription path. The function verifies Apple's `signedPayload` JWS with
Apple's App Store Server Library, maps `appAccountToken` to a Supabase user
UUID, and updates `user_entitlements` with App Store metadata.

This is the native iOS entitlement ingestion path. It stores metadata only;
signed payloads, receipts, raw transactions, auth tokens, and secrets must not
be logged or persisted.

### Required environment

- existing `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`
- `APP_STORE_BUNDLE_ID`
- `APP_STORE_ENVIRONMENT` (`Sandbox` or `Production`)
- `APP_STORE_ROOT_CERTIFICATES_PEM`
- `APP_STORE_PREMIUM_PRODUCT_IDS` or `PROSEPAL_PREMIUM_PRODUCT_IDS`
- `APP_STORE_APP_APPLE_ID` for production
- optional `APP_STORE_ENABLE_ONLINE_CHECKS=true`
- `supabase/config.toml` must include `[functions.app-store-notifications] verify_jwt = false`
  because Apple sends a signed JWS rather than a Supabase JWT.

## app-store-reconcile-entitlement

Manually reconciles native StoreKit entitlement through Apple's App Store Server
API. The function fetches subscription status for a transaction id, verifies the
Apple-signed transaction and renewal JWS payloads returned by Apple, and updates
`user_entitlements`.

This function is for operator/server reconciliation only. It requires
`X-ProsePal-App-Store-Reconcile-Secret` and stores metadata only; signed
payloads, receipts, private keys, raw transaction bodies, and auth tokens must
not be logged or persisted.

### Required environment

- existing `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`
- all `app-store-notifications` Apple environment values
- `APP_STORE_RECONCILE_SECRET`
- `APP_STORE_SERVER_API_PRIVATE_KEY`
- `APP_STORE_SERVER_API_KEY_ID`
- `APP_STORE_SERVER_API_ISSUER_ID`
- `supabase/config.toml` must include
  `[functions.app-store-reconcile-entitlement] verify_jwt = false`

### Request shape

```json
{
  "transaction_id": "<App Store transaction id>",
  "user_id": "<optional Supabase user UUID>"
}
```

If `user_id` is supplied and Apple's signed transaction contains a different
UUID `appAccountToken`, the function returns HTTP `409` and does not update
entitlement state.

### Deploy changes

Deploy only to an approved development or staging project until production
entitlement rollout gates are met:

```bash
supabase functions deploy app-store-notifications --project-ref <dev-or-staging-project-ref>
supabase functions deploy app-store-reconcile-entitlement --project-ref <dev-or-staging-project-ref>
```

### Test locally

```bash
deno test --allow-env supabase/functions/app-store-notifications/index.test.ts
deno test --allow-env supabase/functions/app-store-reconcile-entitlement/index.test.ts
```

Current limitation: paid gateway limits/extras are a separate follow-up slice
after App Store notification and reconciliation paths are proven in staging.

## Email Setup

Currently using Supabase built-in email (rate limited for testing).

**Pre-Launch Task** (see `docs/LAUNCH_CHECKLIST.md`):
- Configure custom SMTP in Supabase Dashboard > Settings > Auth > SMTP
- Recommended: Resend, SendGrid, or Postmark
- Required for production email delivery (magic links, password reset)
