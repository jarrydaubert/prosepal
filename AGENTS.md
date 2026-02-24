# AGENTS.md - Prosepal

This file defines how coding agents should work in this repo. Keep it short and keep it true.

## Purpose

Prosepal is an AI-powered greeting-card message app focused on reliability, privacy, and safe release execution.

## Priorities

- Reliability first: infra/test hardening before new feature scope.
- Security and privacy by default: no secret leakage, no unsafe logging.
- Backlog is the only burn-down source for open work.
- Evergreen docs: runbooks/specs only, no status-style reporting.
- Preserve release safety guardrails learned from prior store issues.

## Source Of Truth

- Release scope and gates: `docs/NEXT_RELEASE_BRIEF.md`
- Outstanding work only: `docs/BACKLOG.md`
- Documentation rules: `docs/DOCS_POLICY.md`
- Testing approach: `docs/TEST_STRATEGY.md`
- Supabase verification: `docs/SUPABASE_TESTS.md`

## Before You Change Code

- Check existing patterns first; avoid unnecessary rewrites.
- Keep auth/payments/AI flows deterministic and testable.
- Validate platform-sensitive behavior (Apple/Google auth, purchases, restore).
- Avoid logging PII/secrets or exposing server credentials client-side.

## After You Change Code

- Run `flutter analyze`.
- Run `flutter test`.
- Run targeted integration tests for changed journeys when relevant.
- If you cannot run tests locally, state that clearly in your summary.

## Docs Rules

- Do not put TODO/in-flight/status notes in evergreen docs.
- Do not include test counts/pass-rate claims in evergreen docs.
- Move all open issues/actions to `docs/BACKLOG.md`.

## Testing Rules

- Keep blocking gates deterministic.
- Quarantine flaky tests from blocking gates until fixed.
- Track flaky fixes in backlog with clear definition of done.

## Repo Files

- `CLAUDE.md` is a Claude-specific compatibility profile.
- `.claude/commands/` contains optional Claude slash-command prompts.
- `README.md` is for human onboarding and day-to-day project setup.
