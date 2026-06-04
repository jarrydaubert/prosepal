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

## Email Setup

Currently using Supabase built-in email (rate limited for testing).

**Pre-Launch Task** (see `docs/LAUNCH_CHECKLIST.md`):
- Configure custom SMTP in Supabase Dashboard > Settings > Auth > SMTP
- Recommended: Resend, SendGrid, or Postmark
- Required for production email delivery (magic links, password reset)
