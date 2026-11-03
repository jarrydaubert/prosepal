# ProsePal

A small iPhone app for writing thoughtful personal messages. The SwiftUI app,
Swift package and tests live in `prosepal-ios/`; the backend lives in `supabase/`.

Agents start with [AGENTS.md](AGENTS.md). Source/tests describe implementation;
[BACKLOG](docs/BACKLOG.md) owns unresolved work and intended changes.

- [PRODUCT](docs/PRODUCT.md): scope and settled product constraints.
- [ARCHITECTURE](docs/ARCHITECTURE.md): ownership and dependency boundaries.
- [RUNBOOK](docs/RUNBOOK.md): build, validation, staging and release procedures.
- [CONFIGURATION](docs/CONFIGURATION.md): exact keys and where to supply them.
- [WRITING EVALUATION](docs/WRITING_EVALUATION.md): synthetic evaluation protocol.

## Engineering decisions

- **Native replacement.** The current App Store build is the earlier Flutter
  client, archived at tag `flutter-prod-freeze-2026-06-25`. `main` is its
  SwiftUI replacement under the same App Store identity and is not yet released.
- **Automated scores are advisory.** The implemented evaluation protocol uses
  blind, position-balanced human review, frozen before engine identities and
  automated findings are revealed. Invented facts, changed meaning, coercion and
  leakage are never averaged away. See [WRITING EVALUATION](docs/WRITING_EVALUATION.md).
- **Privacy claims follow the actual route.** On-device writing is preferred;
  online processing needs truthful permission and provenance, never a route label.

Open questions and unresolved decisions live only in [BACKLOG](docs/BACKLOG.md).

Local build (macOS, Xcode with iOS 26 SDK and Swift 6.2 or later):

```bash
cd prosepal-ios
swift build
```

Git preserves deleted documentation and the archived Flutter production app.
