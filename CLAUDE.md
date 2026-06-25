# CLAUDE.md - Prosepal

Claude-specific compatibility profile.

Canonical agent rules live in `AGENTS.md`. If there is any conflict, `AGENTS.md` is the source of truth.
Do not invent facts, files, or validation results; verify or state uncertainty.

## Active Direction

The active product/build direction is the native SwiftUI rewrite in
`prosepal-ios/`.

- Target: iOS 26-first, person-first Moment Sheet.
- Stack: SwiftUI, SwiftData, StoreKit 2, Sign in with Apple, Foundation Models,
  ProsePal `MessageWritingService` seam.
- Native must not use RevenueCat, Firebase AI, Vertex AI, Gemini-direct,
  provider SDKs, or provider/model names in user-facing UI.
- The previous Flutter production app is archived at tag
  `flutter-prod-freeze-2026-06-25` and branch
  `legacy/flutter-production-reference`. Read the archive for lessons only; do
  not treat Flutter screens or routing as the native product spec.

## Quick Commands

Native Swift workflow:

```bash
cd prosepal-ios
swift build
swift test
```

## Canonical Docs

- `AGENTS.md`
- `docs/NEXT_RELEASE_BRIEF.md`
- `docs/BACKLOG.md`
- `prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`
- `docs/DOCS_POLICY.md`
- `docs/DEVOPS.md`

## Claude Commands

Custom prompts live in `.claude/commands/`.
