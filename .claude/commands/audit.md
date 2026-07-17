---
description: Deep code and architecture audit of a system or file
argument-hint: [target]
---

# /audit - Deep Code Audit

Run a read-only, risk-first audit of the specified native system, workflow, or file.

## Rules

- Do not modify code or external state.
- Lead with findings ordered by user impact and release risk.
- Cite exact file and line evidence.
- Read `AGENTS.md`, `docs/product/v1-launch-contract.md`,
  `docs/engineering/architecture.md`, `docs/quality/testing.md`, and
  `docs/BACKLOG.md`, plus any component-specific documentation.
- Cross-check the backlog; report only new, regressed, or still-unmitigated
  issues.
- Separate verified facts from residual risk and live-environment unknowns.

## Usage

```text
/audit [target]
```

Examples: `/audit auth`, `/audit subscriptions`, `/audit gateway`, or
`/audit prosepal-ios/Sources/ProsePalCore/AuthSession.swift`.

## Checklist

### Core product behavior

- The five-step writing loop matches `docs/product/v1-launch-contract.md` and
  `docs/product/user-journeys.md`.
- Sign-in remains optional for first value and follows
  `docs/engineering/auth-and-accounts.md`.
- StoreKit entitlement, restore, and transaction-update behavior follows
  `docs/engineering/subscriptions.md`.
- Generation, fallback, timeout, and refusal behavior follows
  `docs/engineering/ai-generation.md`.
- SwiftData changes preserve the relationship-vault and draft-recovery
  contracts.

### Correctness and resilience

- Happy, failure, cancellation, retry, offline, and relaunch paths agree across
  code, tests, and docs.
- State invalidation after sign-in, sign-out, purchase, restore, and deletion is
  deterministic.
- Network calls have bounded timeouts and honest user-visible errors.
- Sensitive content and credentials never enter logs or diagnostics.

### Backend and cost controls

- Supabase RLS, grants, and security-definer RPCs enforce the intended boundary.
- Edge functions authenticate before protected or provider-billed work.
- The request ledger, quota, idempotency, and rate limits follow
  `docs/engineering/gateway-request-ledger.md`.
- Usage and entitlement decisions remain server-authoritative where required.

### Validation and release

- Tests catch plausible regressions and remain deterministic.
- Relevant commands come from `docs/quality/testing.md`.
- Operational and release implications follow
  `docs/operations/local-development.md` and `docs/operations/release.md`.
- UI changes account for accessibility and release evidence requirements.

## Output

```markdown
## Findings
1. [CRITICAL/HIGH/MEDIUM] Issue title
   - Location: path:line
   - Evidence: ...
   - Impact: ...
   - Suggested fix: ...

## Open Questions
- ...

## Residual Risk
- ...

## Backlog Additions (new work only)
- [item and testable definition of done]
```
