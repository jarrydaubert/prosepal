# ProsePal Native iOS

This directory contains the active SwiftUI app, Swift package, Xcode project,
embedded system-surface targets, and native tests.

## Read first

- [Getting started](../docs/operations/getting-started.md)
- [Native architecture](../docs/engineering/architecture.md)
- [V1 launch contract](../docs/product/v1-launch-contract.md)
- [Staging](../docs/operations/staging.md)
- [Testing](../docs/quality/testing.md)
- [Backlog](../docs/BACKLOG.md)

## Package layout

- `App/` — app target, assets, entitlements, StoreKit configuration, and root
  dependency composition.
- `Sources/ProsePalDomain/` — product taxonomy, text policy, and stable request
  and response contracts.
- `Sources/ProsePalAPI/` — generation, auth, StoreKit, configuration, and local
  data services.
- `Sources/ProsePalUI/` — observable app models and SwiftUI surfaces.
- `Tests/` — XCTest and Swift Testing coverage.
- `Widgets/` — widget and Control Center/Action Button surfaces.
- `ShareExtension/` — sanitized text/URL handoff into the app.

## Validation

```bash
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Use the shared `ProsePal` scheme for ordinary development. Use the ignored local
staging scheme only through the [staging runbook](../docs/operations/staging.md);
never commit scheme secrets, receipts, tokens, screenshots, or provider assets.
