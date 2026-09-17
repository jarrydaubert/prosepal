# ProsePal agent contract

## Precedence and truth

1. User task/instructions.
2. `AGENTS.md`: repository working rules.
3. [BACKLOG](docs/BACKLOG.md): known defects, unresolved work and change intent.
4. [PRODUCT](docs/PRODUCT.md) and [ARCHITECTURE](docs/ARCHITECTURE.md): stable boundaries.
5. Source code and tests: exact implemented behaviour.
6. [RUNBOOK](docs/RUNBOOK.md) and [CONFIGURATION](docs/CONFIGURATION.md): operations.
7. Git history: consult only when historical context is needed.

Source/tests say what exists; BACKLOG says what is wrong, unresolved or intended
to change. MUST NOT use old prose to override a newer backlog decision or treat
an intended change as implemented. Read only contracts relevant to the task.

## Change discipline

- MUST fetch and start from current `origin/main` unless the task names another base.
- Preserve others' working-tree changes. Keep one coherent change per branch/PR.
- MUST NOT expand scope into adjacent cleanup, redesign, upgrades or renaming.
- Preserve state ownership and dependency direction unless the task/backlog
  explicitly changes them or a demonstrated reliability/security need requires it.
- Prefer deletion and small reviewable slices over new machinery or big rewrites.
- MUST NOT create parallel auth, entitlement, generation, navigation, persistence
  or draft owners. New abstractions need a demonstrated ownership/substitution need.
- Preserve visible behaviour and accessibility identifiers unless explicitly changed.
- Extracted user-facing surfaces need useful compiling previews and meaningful
  behavioural coverage. Preserve existing shrink-only structural ratchets.
- Keep auth, payments, account deletion and generation deterministic and testable.
- Test observable outcomes; source-string checks are not behavioural proof.
- Blocking tests MUST be bounded and deterministic. Do not hide instability with
  sleeps, retries, broad timeouts or weakened assertions. There is no general
  flaky-test tag; narrowly exclude an unavoidable flaky invocation and track its
  fix/restoration in BACKLOG. Skipped tests are not passing evidence.

## Safety and documentation

- MUST NOT log, commit or expose secrets, tokens, receipts, credentials or user writing.
- MUST NOT send privileged/provider credentials into the app or shared schemes.
- MUST verify current official Apple availability/constraints before adopting
  platform/runtime APIs; record scope-changing findings in BACKLOG or a retained contract.
- Unresolved work belongs only in BACKLOG; completed history belongs in Git and
  private release evidence. Do not maintain another implementation ledger.
- Update retained docs only when their stable product/ownership boundary,
  operational command or configuration contract changes. Do not narrate source.
- Keep docs terse; use owning files/symbols, not durable line numbers, test counts,
  verification stamps or progress reports. Git is the documentation archive.

## Validation and handoff

MUST run every relevant category in [RUNBOOK](docs/RUNBOOK.md#validation).
For documentation/instruction/script changes, run from the repository root:

```bash
git diff --check
./scripts/validate_docs.sh
./scripts/release_preflight.sh native --no-env-file
```

For iOS executable changes, run Swift build/tests and the unsigned simulator
build from RUNBOOK, plus focused UI/device/StoreKit checks when the contract
requires them. Backend changes require the relevant Deno/SQL gates there.
Script/workflow changes require syntax and relevant deterministic checks.

Verify facts before claiming them. Report changed files/contracts, validation
results, every required check not run and why, deliberate non-goals, and any
material limitation. For a PR, report URL, current head, merge state, required
hosted checks and unresolved review threads. MUST NOT call it green/merge-ready
without checking those at the current head.

MUST NOT merge, deploy, promote production configuration, mutate production
data or submit to App Store Connect without explicit approval for that exact action.
