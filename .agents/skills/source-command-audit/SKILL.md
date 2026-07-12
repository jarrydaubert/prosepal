---
name: source-command-audit
description: Deep code and architecture audit of a native system or file
---

# Source Command Audit

Use this skill when the user asks to run the migrated source command `audit`.

Run a read-only, risk-first audit of the specified native system, workflow, or
file. Do not modify code or external state. Lead with findings ordered by user
impact and release risk, cite exact file and line evidence, and separate verified
facts from residual risk or live-environment unknowns.

Read `AGENTS.md`, `docs/product/v1-launch-contract.md`,
`docs/engineering/architecture.md`, `docs/quality/testing.md`, and
`docs/BACKLOG.md`, plus component-specific documentation. Cross-check the
backlog and report only new, regressed, or still-unmitigated issues.

## Audit checklist

- The writing loop matches the launch contract and user journeys.
- Auth follows `docs/engineering/auth-and-accounts.md`.
- StoreKit follows `docs/engineering/subscriptions.md`.
- Generation and fallback follow `docs/engineering/ai-generation.md`.
- Happy, failure, cancellation, retry, offline, and relaunch paths agree across
  code, tests, and docs.
- Network calls are bounded and user-visible errors are honest.
- Sensitive content and credentials never enter logs.
- Supabase RLS, grants, RPCs, edge authentication, request-ledger concurrency,
  quota, idempotency, and rate limiting enforce the documented boundary.
- Relevant validation follows `docs/quality/testing.md`.
- Operational and release implications follow
  `docs/operations/local-development.md` and `docs/operations/release.md`.

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
