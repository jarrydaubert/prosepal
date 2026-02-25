# AGENTS.md - Prosepal

This file is the canonical agent contract for this repo.
`CLAUDE.md` defers to this file.

## Goal

Ship safely: reliability and security first, then feature work.

## Source Of Truth

- Release scope and gates: `docs/NEXT_RELEASE_BRIEF.md`
- DevOps runbook: `docs/DEVOPS.md`
- Open work only: `docs/BACKLOG.md`
- Documentation rules: `docs/DOCS_POLICY.md`

## Working Rules

- Preserve existing architecture unless a change is required for safety/reliability.
- Keep auth, payments, entitlement, and AI flows deterministic and testable.
- Do not log secrets, tokens, or sensitive user content.
- Keep evergreen docs free of TODOs/status; move open work to backlog.

## Required Validation Before Handoff

Run what is relevant to the change:

```bash
flutter analyze
flutter test
./scripts/test_critical_smoke.sh
```

For DevOps/workflow changes, also ensure `docs/DEVOPS.md` is updated.

If any required validation cannot be run, state that clearly.

## Test Stability

- Blocking gates must remain deterministic.
- Mark flaky tests with `tags: ['flaky']` and keep them out of blocking CI until fixed.
- Track flaky test fixes in `docs/BACKLOG.md` with clear DoD.
