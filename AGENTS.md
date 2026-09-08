# AGENTS.md - ProsePal

This file is the canonical agent contract for this repository.
`CLAUDE.md` defers to this file.

## Goal

Ship safely: reliability and security first, then feature work.

## Active Direction

ProsePal is the SwiftUI iOS app in `prosepal-ios/`. It is the only current
implementation. There is no second app, and no migration is in progress.

- Target: iOS 26-first, person-first Moment Sheet.
- Stack: SwiftUI, SwiftData, StoreKit 2, Sign in with Apple, Foundation
  Models, and a ProsePal-owned `MessageWritingService` boundary.
- Production identity: reuse the existing ProsePal App Store Connect app and
  bundle ID `com.prosepal.prosepal`. Staging is UAT through a local-only Xcode
  scheme and staging services, not a second public app by default.
- The app must remain provider-agnostic in the UI: no provider or model names,
  no Firebase AI, Vertex AI, or Gemini direct-client path, no RevenueCat
  dependency, and no third-party provider SDKs by default.
- The previous Flutter production app is archived at tag
  `flutter-prod-freeze-2026-06-25` and branch
  `legacy/flutter-production-reference`. Do not recreate Flutter files on
  `main`. Read the archive only when historical behaviour or App Review context
  is needed.
- Remaining `Native*` names in symbols, Xcode targets, schemes, scripts,
  backlog headings, and docs are historical residue from the transition, not a
  live product distinction. Do not infer a second app or an in-progress rewrite
  from them, and do not rename them opportunistically. Renames are tracked in
  `docs/BACKLOG.md`.
- "Native" remains meaningful where it describes an Apple platform capability,
  such as on-device generation or system surfaces.

## Sources Of Truth

- Documentation index: `docs/README.md`
- iOS technical architecture: `docs/engineering/architecture.md`
- SwiftUI architecture rules: `docs/engineering/swiftui-architecture.md`
- Release scope and gates: `docs/product/v1-launch-contract.md`
- Development and release runbooks: `docs/operations/`
- Open work only: `docs/BACKLOG.md`
- Documentation rules: `docs/DOCS_POLICY.md`
- Implemented behaviour and evidence:
  `docs/reference/feature-status.jsonl`

## Change Discipline

- Start work from the current `origin/main` unless the task explicitly names a
  different base.
- Keep each branch and pull request focused on one coherent change.
- Do not merge a pull request unless the user explicitly instructs you to
  merge it.
- Do not expand a task into adjacent cleanup, redesign, dependency upgrades, or
  naming changes without evidence that they are required.
- Approved backlog items and documented architecture decisions may
  intentionally change file ownership or structure. Execute their accepted
  target rather than reopening settled design decisions.
- Preserve established state ownership and dependency direction unless an
  approved backlog item, documented architecture decision, or
  safety/reliability requirement calls for change.
- Avoid big-bang rewrites. Prefer independently reviewable slices with explicit
  ownership, tests, previews, and rollback boundaries.
- Do not introduce coordinators, routers, managers, service locators, wrapper
  abstractions, or new view models without a demonstrated ownership or
  substitution need.
- Never create a second source of truth for authentication, entitlement,
  generation, navigation, persistence, or draft state.

## Working Rules

- Keep authentication, payments, entitlement, account deletion, and AI flows
  deterministic and testable.
- Keep provider, StoreKit, Keychain, Supabase, persistence schemas, and
  persistence-service implementations outside `ProsePalUI`. Feature-owned
  SwiftData queries and `modelContext` coordination follow
  `docs/engineering/swiftui-architecture.md`.
- Do not log secrets, tokens, receipts, credentials, or sensitive user content.
- Preserve user-visible behaviour and accessibility identifiers unless an
  approved product change explicitly changes them.
- User-facing SwiftUI surfaces extracted into a feature boundary require useful,
  compiling previews for representative states.
- Prefer behavioural, rendering, or direct contract tests over source-string
  existence checks. Do not merely repoint a brittle source guard when a real
  test seam is available.
- Keep documentation evergreen. Describe current behaviour, stable policy, or a
  runnable process rather than progress, test counts, dates, temporary status,
  or "verified at" commit stamps.
- Put unresolved work only in `docs/BACKLOG.md`. Keep completed history in Git,
  release evidence, or the canonical feature-status ledger.
- Edit `docs/reference/feature-status.jsonl` only, then regenerate
  `docs/reference/feature-status.csv` with
  `python3 scripts/export_feature_status_csv.py`. Never edit the CSV export by
  hand.
- Anchor behavioural documentation to the owning source file and stable symbol
  names so a reader can verify it in one hop.
- Avoid line-number references in evergreen documentation because routine edits
  make them stale.
- Update the owning document in the same change when a documented contract,
  workflow, configuration boundary, ownership boundary, or public behaviour
  changes.
- Update `prosepal-under-the-hood.html` in the same PR when a change materially
  alters user-visible flow, generation routing, privacy/data boundaries,
  persistence, auth/account lifecycle, subscriptions, recovery or gateway
  behaviour. Skip trivial refactors that do not change the described flow.
- Before adopting or redesigning around an Apple platform or AI runtime API,
  verify availability, constraints, and known issues against current official
  Apple documentation. Record any external claim that changes scope or
  architecture in the owning decision record or backlog item.

## Verification

- Do not present assumptions or guesses as verified facts.
- Verify files, symbols, commands, behaviour, and repository state before
  claiming they exist or passed.
- If something is uncertain, unavailable, skipped, or unverified, state that
  clearly.
- Do not describe a pull request as green or merge-ready until the current head
  commit, required hosted checks, merge state, and unresolved review threads
  have been checked.
- Report every required validation that could not be run and explain why.

## Required Validation Before Handoff

Run every category relevant to the change.

### iOS source changes

From the repository root:

```bash
git diff --check

(
  cd prosepal-ios
  swift build
  swift test
  xcodebuild \
    -project ProsePal.xcodeproj \
    -target ProsePal \
    -sdk iphonesimulator \
    CODE_SIGNING_ALLOWED=NO \
    build
)
```

Run focused UI automation, simulator checks, StoreKit tests, Supabase tests, or
physical-device evidence when the touched contract requires them.

### Documentation or instruction changes

From the repository root:

```bash
git diff --check
./scripts/validate_docs.sh
./scripts/release_preflight.sh native --no-env-file
```

When `docs/reference/feature-status.jsonl` changes, also run:

```bash
python3 scripts/validate_feature_status.py
python3 scripts/export_feature_status_csv.py --check
```

### Repository, workflow, or release-process changes

Run the relevant release preflight and workflow validation documented in
`docs/operations/local-development.md`. Update the owning operations document
in the same change when the runnable process changes.

## Test Stability

- Blocking checks must remain deterministic.
- Do not mask instability with arbitrary sleeps, retries, broad timeouts, or
  weakened assertions.
- Keep known flaky tests out of blocking CI until fixed.
- The repository has no general flaky-test tag. If temporary exclusion is
  unavoidable, change only the narrowest owning test invocation or workflow
  selection. Do not invent a tagging convention inside unrelated work.
- Track each flaky-test fix in `docs/BACKLOG.md` with a clear definition of done.
- A skipped test is not passing evidence. Record why it is skipped and what
  evidence is still required.

## Handoff

Report:

- the files and contracts changed
- the validation run and its result
- any validation not run
- deliberate non-goals and untouched regions
- the pull request URL, head commit, merge state, hosted checks, and unresolved
  review threads when a pull request was opened

Stop at the requested boundary. Do not merge, deploy, promote production
configuration, mutate production data, or submit to App Store Connect without
explicit approval for that exact action.
