---
description: Find dead code, dependencies and orphaned surfaces
argument-hint: [scope]
---

# /cleanup

Run a read-only cleanup audit of the named app/backend/repository scope.
MUST NOT change code or external state.

Read AGENTS.md and docs/BACKLOG.md. Inspect source/tests, package/Xcode metadata,
backend/migrations, scripts/workflows and retained docs/instructions as relevant.
Use rg/reference searches with compiler/registration/test evidence; absence of
textual callers alone does not prove an Apple convention entry point is dead.

Prioritize proven-unused declarations, assets, dependencies, navigation,
config/RPC/function paths, scripts and broken documentation consumers. Preserve
previews, protocol witnesses, runtime registration, executable fixtures and
applied migration history. Git is the prose archive; investment is not a reason
to retain obsolete documentation.

Output severity, kind, file/symbol, reference/reachability evidence, confidence
and safe action. Cross-check BACKLOG and propose only genuinely new unresolved work.
