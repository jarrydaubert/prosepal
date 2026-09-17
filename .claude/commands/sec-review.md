---
description: Security review of ProsePal trust boundaries
argument-hint: [scope]
---

# /sec-review

Run a read-only review of the named app, backend, configuration or subsystem.
MUST NOT change code or external state.

Read AGENTS.md, docs/BACKLOG.md, docs/ARCHITECTURE.md and the relevant
CONFIGURATION/RUNBOOK procedure. Source/tests establish exact implemented controls.
Report only new, regressed or still-unmitigated risks; preserve sound audited boundaries.

Inspect nonce/token validation, refresh/sign-out/account-switch ordering,
Keychain isolation, deletion semantics, SwiftData/shared-input boundaries,
HTTPS/target-correct archives and bundled secrets. Inspect Edge authentication,
input limits/prompt fencing, SQL RLS/grants/search paths, quota/idempotency,
provider calls/logging and StoreKit/server entitlement ownership and ordering.
Check workflow privilege/secret guards. Preflight is not full archive/live-service proof.

Output findings ordered by exploitability and impact, with severity, exact
source/test evidence, reproduction conditions, impact and narrow remedy.
Separate verified findings, design questions, unverified live proof and residual
risk. Use synthetic content; never include credentials, writing, receipts or signed payloads.
