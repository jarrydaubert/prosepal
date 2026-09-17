---
description: Test gaps and deterministic regression coverage
argument-hint: [scope]
---

# /test

Review or implement meaningful tests for the requested scope.
Read AGENTS.md and docs/BACKLOG.md; use docs/RUNBOOK.md for validation commands.

Before adding a test, name the plausible regression it catches. Prefer observable
outcomes, injected clocks/clients/persistence, bounded synchronization and
hermetic stubs. Source-string presence or rendering without assertions is not
behavioural proof. Keep production/runtime behaviour unchanged unless requested.

Choose the owning seam: auth/account ordering, StoreKit/server ownership,
Swift/gateway contracts, cancellation/late results, SQL concurrency/quota/replay,
persistence/rollback/migration/deletion or critical accessible UI wiring.
Run only relevant categories; live Apple/provider/SQL deployments are separate evidence.

Blocking tests MUST be deterministic and bounded. Fix flaky tests; if narrow
exclusion is unavoidable, track restoration in BACKLOG. There is no general
flaky-test tag. Do not mask failures with sleeps/retries/weakened assertions.

Report findings by severity, executed commands/results and every omitted gate
with reason. New tests must state their regression; failures must include the
concise error and artifact path. Never claim live/device proof from local mocks.
