---
name: source-command-sec-review
description: Deep security review using Prosepal's native trust boundaries
---

# Source Command Security Review

Use this skill when the user asks to run the migrated source command
`sec-review`.

Run a read-only review of the native app, Supabase backend, release
configuration, or named subsystem. Prioritize findings by exploitability and
impact and cite exact evidence. Do not modify code or external state.

Read `AGENTS.md`, `docs/engineering/architecture.md`,
`docs/engineering/data-and-privacy.md`,
`docs/engineering/auth-and-accounts.md`,
`docs/engineering/subscriptions.md`,
`docs/engineering/gateway-request-ledger.md`,
`docs/reference/configuration.md`, `docs/operations/release.md`, and
`docs/BACKLOG.md` as applicable. Report only new, regressed, or
still-unmitigated risks, and identify live evidence that was not verified.

## Review checklist

- Sign in with Apple nonce, refresh rotation, sign-out races, account switching,
  and deletion.
- Device-bound Keychain handling and metadata-only diagnostics.
- SwiftData/shared-container ownership, deletion, and extension boundaries.
- HTTPS and target-correct archive configuration with no bundled secrets.
- Supabase RLS, grants, safe security-definer RPCs, and edge authentication.
- Request validation, timeouts, rate limits, quota reservation, idempotency,
  provider fallback, and logging.
- StoreKit verification, transaction convergence, restore, refund, renewal, and
  account transitions.
- Least-privilege workflows, secret-history checks, bundle inspection, and
  release preflight.

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
