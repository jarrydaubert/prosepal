# CLAUDE.md - Prosepal

Claude-specific compatibility profile.

Canonical agent rules live in `AGENTS.md`. If there is any conflict, `AGENTS.md` is the source of truth.
Do not invent facts, files, or validation results; verify or state uncertainty.

## Active Direction

ProsePal is the SwiftUI iOS app in `prosepal-ios/`. It is the only
implementation. There is no second app, and no migration is in progress.

- Target: iOS 26-first, person-first Moment Sheet.
- Stack: SwiftUI, SwiftData, StoreKit 2, Sign in with Apple, Foundation Models,
  ProsePal `MessageWritingService` seam.
- Production identity: reuse the existing ProsePal App Store Connect app and
  bundle ID `com.prosepal.prosepal`; staging is UAT via local-only Xcode scheme
  and staging services, not a second public app by default.
- The app must not use RevenueCat, Firebase AI, Vertex AI, Gemini-direct,
  provider SDKs, or provider/model names in user-facing UI.
- The previous Flutter production app is archived at tag
  `flutter-prod-freeze-2026-06-25` and branch
  `legacy/flutter-production-reference`. Read the archive for lessons only; do
  not treat Flutter screens or routing as the product spec.
- Remaining `Native*` names — symbols, targets, schemes, scripts, and docs — are
  historical residue from that transition, not a live product distinction. Do not
  infer a second app or an in-progress rewrite from them. See `AGENTS.md`.

## Quick Commands

Swift workflow:

```bash
cd prosepal-ios
swift build
swift test
```

## Canonical Docs

- `AGENTS.md`
- `docs/README.md`
- `docs/product/v1-launch-contract.md`
- `docs/BACKLOG.md`
- `docs/engineering/architecture.md`
- `docs/DOCS_POLICY.md`
- `docs/operations/local-development.md`

## Claude Commands

Custom prompts live in `.claude/commands/`.
