# AGENTS.md - Prosepal

This file is the canonical agent contract for this repo.
`CLAUDE.md` defers to this file.

## Goal

Ship safely: reliability and security first, then feature work.

## Active Direction

The active build direction is the native SwiftUI rewrite in `prosepal-ios/`.

- Native target: iOS 26-first, person-first Moment Sheet.
- Native stack: SwiftUI, SwiftData, StoreKit 2, Sign in with Apple, Foundation
  Models, and a ProsePal-owned `MessageWritingService` boundary.
- Production identity: reuse the existing ProsePal App Store Connect app and
  bundle ID `com.prosepal.prosepal`; staging is UAT via local-only Xcode scheme
  and staging services, not a second public app by default.
- Native must remain provider-agnostic in the UI: no provider/model names, no
  Firebase AI / Vertex AI / Gemini-direct client path, no RevenueCat dependency,
  and no third-party provider SDKs by default.
- The previous Flutter production app is archived at tag
  `flutter-prod-freeze-2026-06-25` and branch
  `legacy/flutter-production-reference`. Do not recreate Flutter files on
  `main`; read the archive only when historical behavior or App Review context
  is needed.

## Source Of Truth

- Native technical direction: `prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`
- Release/readiness scope and gates: `docs/NEXT_RELEASE_BRIEF.md`
- DevOps runbook: `docs/DEVOPS.md`
- Open work only: `docs/BACKLOG.md`
- Documentation rules: `docs/DOCS_POLICY.md`

## Working Rules

- Preserve existing architecture unless a change is required for safety/reliability.
- Keep auth, payments, entitlement, and AI flows deterministic and testable.
- Do not log secrets, tokens, or sensitive user content.
- Keep evergreen docs free of TODOs/status; move open work to backlog.

## Verification

- Do not present guesses as facts.
- Verify files, commands, and behavior before claiming they exist or passed.
- If something is uncertain or unverified, say so clearly.

## Required Validation Before Handoff

Run what is relevant to the change:

For native iOS work:

```bash
cd prosepal-ios
swift build
swift test
```

For DevOps/workflow changes, also ensure `docs/DEVOPS.md` is updated.

If any required validation cannot be run, state that clearly.

## Test Stability

- Blocking gates must remain deterministic.
- Mark flaky tests with `tags: ['flaky']` and keep them out of blocking CI until fixed.
- Track flaky test fixes in `docs/BACKLOG.md` with clear DoD.
