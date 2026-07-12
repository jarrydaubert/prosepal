---
description: Deep security review using Prosepal's native threat boundaries
argument-hint: [scope]
---

# /sec-review - Security Review

Run a read-only security review of the native app, Supabase backend, release
configuration, or a named subsystem.

## Rules

- Do not modify code or external state.
- Prioritize findings by exploitability and impact; cite file and line evidence.
- Read `AGENTS.md`, `docs/engineering/architecture.md`,
  `docs/engineering/data-and-privacy.md`,
  `docs/engineering/auth-and-accounts.md`,
  `docs/engineering/subscriptions.md`,
  `docs/engineering/gateway-request-ledger.md`,
  `docs/reference/configuration.md`, `docs/operations/release.md`, and
  `docs/BACKLOG.md` as applicable.
- Report only new, regressed, or still-unmitigated risks.
- State explicitly when live Supabase, Apple, StoreKit, or archive evidence was
  not verified.

## Review areas

### Authentication and accounts

- Sign in with Apple uses nonce/state correctly and Supabase verifies identity.
- Refresh rotation, terminal/transient errors, sign-out races, account switching,
  and deletion are deterministic.
- Tokens remain in the device-bound Keychain and never enter logs.

### Data and client security

- SwiftData and shared-container data respect documented ownership and deletion.
- Sensitive message text, prompts, tokens, and PII are absent from telemetry.
- Release builds contain no dev secrets; public runtime configuration is HTTPS
  and target-correct.
- URL schemes, extension payloads, and deep links validate untrusted input.

### Supabase and gateway

- RLS is enabled and grants do not exceed policy intent.
- Security-definer functions set safe search paths and restrict execution.
- Edge functions authenticate before protected or provider-billed operations.
- Request validation, timeouts, rate limits, quota reservation, idempotency,
  provider fallback, and logging follow the request-ledger contract.
- Service-role and provider credentials never cross into the client.

### Payments and entitlement

- StoreKit verification gates Premium access.
- Transaction updates converge before verified transactions are finished.
- Restore, refund, renewal, family-sharing, and sign-in transitions do not grant
  stale entitlement.

### Repository and release

- Workflows use least privilege and pinned actions where relevant.
- Secret-history and bundle-inspection checks remain effective.
- Release preflight blocks missing, placeholder, mixed-environment, or secret
  runtime configuration.

## Output

```markdown
## Security Findings
1. [CRITICAL/HIGH/MEDIUM] Issue title
   - Location: path:line
   - Evidence: ...
   - Impact: ...
   - Fix: ...

## Open Questions
- ...

## Residual Risk
- ...

## Backlog Additions (new work only)
- [item and testable definition of done]
```
