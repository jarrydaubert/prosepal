# ProsePal Native iOS

This folder contains the native SwiftUI rebuild for ProsePal.

The active product direction is greenfield, iOS-first, and craft-first. The
native app is no longer trying to clone the Flutter flow or preserve Flutter
parity as a UI constraint. The old grouped Create/Saved/Settings prototype is
scaffolding; the target product is the person-first Moment Sheet.

## Read First

- `NATIVE_2026_TECHNICAL_DIRECTION.md` - active native product, design, and
  technical direction.
- `NATIVE_DEVICE_DEBUG_RUNBOOK.md` - local staging, tethered-device, StoreKit,
  auth, and gateway proof.
- `../docs/BACKLOG.md` - open work and Definitions of Done.
- `../docs/architecture/AI_GATEWAY_STRATEGY.md` - server gateway strategy for
  cloud/careful generation.

Superseded planning, audit, and parity reports are intentionally removed from
this folder. Git history preserves them; new work should not use them as active
handoff material.

## Locked Direction

- Public name: ProsePal.
- Internal concept name: Near.
- Deployment floor: iOS 26.
- Production app identity: existing ProsePal App Store Connect app and bundle
  ID `com.prosepal.prosepal`.
- Staging/UAT: local-only Xcode scheme and staging Supabase/StoreKit
  configuration, not a second public App Store app.
- Primary flow: person-first Moment Sheet.
- Product spine: `person -> moment -> what is true -> draft -> adjust -> send`.
- Product boundary: Moment messages, not manuscripts, documents, scenes,
  characters, or project libraries.
- AI lanes: `Private draft` and `Take more care`.
- Subscriptions: StoreKit 2 only in the native client.
- Identity: Sign in with Apple first.
- Storage: SwiftData for the on-device relationship vault.
- UI: Liquid Glass on control/navigation surfaces; opaque, paper-like content.
- Architecture: one `MessageWritingService` boundary between UI and generation.

## Native App Shape

```text
Launch
  -> first-run welcome
  -> Moment Sheet
  -> Write draft when the user is ready
  -> warmer / shorter / more direct / take more care
  -> copy / share / send / save

Supporting surfaces
  -> relationship vault and Truth Beads
  -> saved local messages
  -> settings, account, subscription, privacy, legal
  -> App Intents, WidgetKit, Control Center, Share extension
```

The occasion catalogue remains useful product intelligence, but it sits beneath
the person-first flow. It is not the visual structure of the app.

## Architecture Boundary

```text
SwiftUI Moment Sheet
  -> MomentModel
  -> MessageWritingService
      -> PrivateDraftClient
      -> CarefulClient
      -> MockClient
```

The UI must not depend on provider SDKs, provider payloads, model IDs, gateway
internals, or StoreKit receipt details. Product copy must not expose provider or
model names.

## Local Staging Configuration

Use the untracked `ProsePal Local Staging` Xcode scheme for tethered-device and
simulator work. The tracked Xcode project keeps the production bundle ID
`com.prosepal.prosepal`; staging/UAT is selected by Run environment values and
StoreKit configuration, not by committing a different shared project identity.
Keep secrets in the local scheme or local files only.

```text
PROSEPAL_GATEWAY_URL=https://<project-ref>.supabase.co/functions/v1/generate-card
PROSEPAL_DEV_GATEWAY_SECRET=<staging-only-secret>
PROSEPAL_SUPABASE_URL=https://<project-ref>.supabase.co
PROSEPAL_SUPABASE_ANON_KEY=<supabase-anon-key>
PROSEPAL_PREMIUM_PRODUCT_IDS=com.prosepal.pro.yearly,com.prosepal.pro.monthly,com.prosepal.pro.weekly
PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID=com.prosepal.pro.yearly
```

Do not commit local Xcode schemes, Supabase `.temp` link state, provider keys,
StoreKit receipts, auth tokens, screenshots, generated evidence, or model
assets.

## Diagnostics

Native diagnostics use Apple `OSLog` with subsystem:

```text
com.prosepal.prosepal
```

Logs may include event names, lane names, response categories, request IDs,
counts, and latency buckets. Logs must not include raw recipient names, user
details, prompt text, generated message text, tokens, receipts, provider
payloads, provider keys, or provider/model IDs.

## Package Layout

- `App/` - SwiftUI app target, launch storyboard, app assets, StoreKit config.
- `Sources/ProsePalDomain` - product and API contract models.
- `Sources/ProsePalAPI` - message-writing services, gateway, auth, StoreKit,
  runtime config, and platform clients.
- `Sources/ProsePalUI` - native SwiftUI surfaces.
- `Tests/` - Swift Testing and XCTest coverage.

## Validation

From `prosepal-ios/` after native code changes:

```bash
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

When staging gateway behavior or request headers change, also run the repo-level
staging smoke:

```bash
./scripts/prosepal-staging-smoke.sh
```
