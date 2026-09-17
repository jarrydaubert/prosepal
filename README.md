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

Local build (macOS, Xcode with iOS 26 SDK and Swift 6.2 or later):

```bash
cd prosepal-ios
swift build
```

Git preserves deleted documentation and the archived Flutter production app.
