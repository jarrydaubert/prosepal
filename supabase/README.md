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

Template mode needs no provider secrets:

- `PROSEPAL_AI_PROVIDER=template`

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

### Deploy changes

Deploy only to an approved development or staging project until the production
gateway rollout gates are met:

```bash
supabase functions deploy generate-card --project-ref <dev-or-staging-project-ref>
```

### Test locally

Template fallback mode:

```bash
GATEWAY_DEV_ALLOW_ANONYMOUS=true PROSEPAL_AI_PROVIDER=template supabase functions serve generate-card
```

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

## Email Setup

Currently using Supabase built-in email (rate limited for testing).

**Pre-Launch Task** (see `docs/LAUNCH_CHECKLIST.md`):
- Configure custom SMTP in Supabase Dashboard > Settings > Auth > SMTP
- Recommended: Resend, SendGrid, or Postmark
- Required for production email delivery (magic links, password reset)
