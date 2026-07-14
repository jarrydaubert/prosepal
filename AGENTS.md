# AGENTS.md - Prosepal

This file is the canonical agent contract for this repo.
`CLAUDE.md` defers to this file.

## Goal

Ship safely: reliability and security first, then feature work.

## Active Direction

ProsePal is the SwiftUI iOS app in `prosepal-ios/`. It is the only
implementation. There is no second app, and no migration is in progress.

- Target: iOS 26-first, person-first Moment Sheet.
- Stack: SwiftUI, SwiftData, StoreKit 2, Sign in with Apple, Foundation
  Models, and a ProsePal-owned `MessageWritingService` boundary.
- Production identity: reuse the existing ProsePal App Store Connect app and
  bundle ID `com.prosepal.prosepal`; staging is UAT via local-only Xcode scheme
  and staging services, not a second public app by default.
- The app must remain provider-agnostic in the UI: no provider/model names, no
  Firebase AI / Vertex AI / Gemini-direct client path, no RevenueCat dependency,
  and no third-party provider SDKs by default.
- The previous Flutter production app is archived at tag
  `flutter-prod-freeze-2026-06-25` and branch
  `legacy/flutter-production-reference`. Do not recreate Flutter files on
  `main`; read the archive only when historical behavior or App Review context
  is needed.
- Remaining `Native*` names — symbols, Xcode targets, schemes, scripts, backlog
  headings, and docs — are historical residue from that transition, not a live
  product distinction. Do not infer a second app or an in-progress rewrite from
  them, and do not rename them opportunistically; renames are tracked in
  `docs/BACKLOG.md`. "Native" remains meaningful only where it describes an
  Apple platform capability, such as on-device generation or system surfaces.

## Source Of Truth

- Documentation index: `docs/README.md`
- Native technical architecture: `docs/engineering/architecture.md`
- Release/readiness scope and gates: `docs/product/v1-launch-contract.md`
- Development and release runbooks: `docs/operations/`
- Open work only: `docs/BACKLOG.md`
- Documentation rules: `docs/DOCS_POLICY.md`

## Working Rules

- Preserve existing architecture unless a change is required for safety/reliability.
- Keep auth, payments, entitlement, and AI flows deterministic and testable.
- Do not log secrets, tokens, or sensitive user content.
- Keep documentation evergreen: describe current behaviour, stable policy, or a
  runnable process rather than progress, test counts, dates, or “verified at”
  commit stamps.
- Put unresolved work only in `docs/BACKLOG.md`; keep completed history in Git,
  release evidence, or `docs/reference/feature-status.csv`.
- Anchor behavioural documentation to the owning source file and stable symbol
  names so a reader can verify it in one hop. Avoid line-number references in
  evergreen docs because normal edits make them stale.
- Update the owning document in the same change when a documented contract,
  workflow, configuration boundary, or public behaviour changes.
- Before adopting or redesigning around an Apple platform or AI-runtime API,
  verify availability, constraints, and known issues against current official
  Apple documentation. Cite any external claim that changes scope or
  architecture in the owning decision record or backlog item.

## Verification

- Do not present guesses as facts.
- Verify files, commands, and behavior before claiming they exist or passed.
- If something is uncertain or unverified, say so clearly.

## Required Validation Before Handoff

Run what is relevant to the change:

For native iOS work:

```bash
git diff --check
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

For repo/workflow changes, also run the relevant release preflight from
`docs/operations/local-development.md` and update the owning operations doc in
the same change.

If any required validation cannot be run, state that clearly.

## Test Stability

- Blocking gates must remain deterministic.
- Mark flaky tests with `tags: ['flaky']` and keep them out of blocking CI until fixed.
- Track flaky test fixes in `docs/BACKLOG.md` with clear DoD.
