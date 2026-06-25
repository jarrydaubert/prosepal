# Security

This is the active security posture for the native iOS app in `prosepal-ios/`.
The previous Flutter security document is archived at
`docs/legacy-flutter/SECURITY.md`.

## Principles

- Do not log secrets, auth tokens, receipts, provider payloads, prompts,
  recipient details, relationship memory, or generated drafts.
- Keep UI/provider boundaries provider-agnostic.
- Keep generation behind `MessageWritingService`; do not add client-direct
  Firebase AI, Vertex AI, Gemini, OpenAI, Anthropic, or other provider SDK paths
  to the native UI app by default.
- Use StoreKit 2 for native subscriptions. RevenueCat is not a native
  dependency.
- Treat Supabase production as protected infrastructure. Agents must not run
  deploys, migrations, secret commands, or production-affecting operations
  unless the user explicitly authorizes a specific command.

## Native Client

- Sign in with Apple is the primary auth path.
- Auth/session material belongs in Keychain-backed storage.
- Relationship memory and saved drafts are local-first through SwiftData.
- User-facing diagnostics must be metadata-only.
- Local Xcode schemes, `xcuserdata`, StoreKit receipts, Supabase temp/link
  state, and generated evidence must remain untracked.

## Supabase

Known refs:

- staging: `llolwgqphwnhbiqewmcq`
- production: `mwoxtqxzunsjmbdqezif`

Rules:

- `supabase/.temp/` and `supabase/.branches/` are ignored and must not be
  tracked.
- Staging migrations must use the guarded script and explicit `STAGING_DB_URL`.
- Never use `supabase db push --linked` for remote DB mutation.
- Function deploys to staging must target
  `--project-ref llolwgqphwnhbiqewmcq`.
- Production changes require explicit human approval and a separate runbook.

## Subscriptions

Native entitlement direction:

- StoreKit 2 for local product/purchase/restore UX.
- App Store Server Notifications V2 and App Store Server API reconciliation on
  Supabase.
- Server entitlement is authoritative for paid limits/extras.

Staging proof is not complete until the checklist in `docs/BACKLOG.md` is
evidenced.

## Historical Flutter Security

For old production-reference behavior, inspect:

- tag `flutter-prod-freeze-2026-06-25`
- branch `legacy/flutter-production-reference`
- `docs/legacy-flutter/SECURITY.md`
