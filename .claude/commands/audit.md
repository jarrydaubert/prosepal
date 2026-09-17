---
description: Deep code and architecture audit of a system or file
argument-hint: [target]
---

# /audit

Run a read-only, risk-first audit of the named app/backend/system/file.
MUST NOT change code or external state.

Read AGENTS.md, docs/BACKLOG.md and the relevant PRODUCT/ARCHITECTURE boundaries.
Source/tests establish implementation; BACKLOG can reopen its design. Do not
infer three choices, forced/anonymous purchase policy or preferred provider loops
from existing code. Report only new, regressed or still-unmitigated issues.

Inspect the owning code/tests for auth/account ordering, StoreKit/server
entitlement, generation cancellation/stale results, SwiftData/recovery and
extension handoffs. Check happy/failure/retry/offline/relaunch behaviour, bounded
network work, user-content/secret handling, SQL privileges/quota/idempotency and
actual provider-call suppression. Preserve audited healthy boundaries.

Use docs/RUNBOOK.md for relevant validation; deployed, Apple and device proof
cannot be inferred from source. Do not execute remote/paid probes without scope authorization.

Output findings ordered by user impact/release risk, with severity, verified
file/symbol/line evidence, trigger, consequence and smallest justified action.
Separate demonstrated defects, open decisions, evidence gaps and residual risk;
identify checks not run. Propose only unresolved new work with a testable DoD.
