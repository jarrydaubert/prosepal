# Native iOS Readiness Brief

## Purpose

Define the active delivery objective for ProsePal: a native iOS SwiftUI rewrite
under `prosepal-ios/`, built inside the existing repository while the Flutter
app remains the live production/reference implementation.

This document is the shareable release/readiness brief. Open work lives only in
`docs/BACKLOG.md`.

## Product Direction

ProsePal is a greeting-card and personal-message writing app. The native iOS app
should help someone quickly write the words for a real moment: birthday, thank
you, apology, sympathy, celebration, awkward message, or everyday text.

Native iOS direction:

- iOS-first.
- SwiftUI-first.
- Gateway-first.
- Dependency-light.
- Modern, warm, calm, premium, and Apple-native.
- Full functional parity with Flutter before any production replacement.
- Flutter behavior is the product reference; Flutter screens are not the native
  visual spec.

## Production Boundary

The existing Flutter app remains production until a separate replacement
decision is made.

Flutter production facts:

- Flutter app is the live/reference app.
- Flutter production generation remains client-direct Firebase AI / Vertex AI.
- Flutter production service ownership, release checks, and emergency hotfixes
  remain valid production operations.

Native rewrite facts:

- Native app lives in `prosepal-ios/`.
- Native generation must use a ProsePal-owned gateway contract.
- Native app must not use Firebase AI, Vertex AI, provider SDKs, or model names
  as client-facing architecture.
- Standard and Premium are product lanes, not model names.
- The native client collects structured intent, calls the gateway contract,
  renders `CardResponse`, and handles loading, retry, usage, entitlement,
  timeout, and service-unavailable states.

## Non-Negotiables

- Do not delete or modify the Flutter app as part of native rewrite work unless
  the change is an explicit production hotfix or read-only reference audit.
- Do not change Flutter production AI routing during native work.
- Do not commit secrets, provider keys, local Xcode schemes, Supabase `.temp`
  state, StoreKit receipts, generated evidence, or model binaries.
- Do not expose provider/model names in native user-facing UI.
- Do not log raw recipient names, card details, prompt text, generated drafts,
  tokens, receipts, provider payloads, or provider keys.
- Do not add third-party SDKs by default. Add dependencies only when a native
  gate requires them and the privacy/operational tradeoff is understood.
- Purchase must not be blocked behind mandatory account creation; this preserves
  the prior App Review lesson from the Flutter release.

## Active Readiness Gates

The actionable backlog is `docs/BACKLOG.md`. Its native gates are:

| Gate | Outcome |
|------|---------|
| `N-IOS-01` | Core Create and Results quality. |
| `N-IOS-02` | Staging gateway reliability and operator runbook. |
| `N-IOS-03` | Sign in with Apple identity path. |
| `N-IOS-04` | Server-authoritative usage and entitlement state. |
| `N-IOS-05` | Native paywall, purchase, and restore. |
| `N-IOS-06` | Auth, purchase, restore, and account-switch edge cases. |
| `N-IOS-07` | Settings, support, privacy, and legal parity. |
| `N-IOS-08` | Saved, history, and local data model. |
| `N-IOS-09` | Existing Flutter user migration and App Store continuity. |
| `N-IOS-10` | Native TestFlight and CI promotion gates. |
| `N-IOS-11` | Native privacy, logging, and diagnostics hardening. |
| `N-IOS-12` | Local Standard generation spike. |

## Native App Shape

Target navigation:

```text
Launch
  -> first-run welcome
  -> Create
  -> gateway generation
  -> Drafts
  -> copy, share, edit, save

Tabs
  Create
  Saved
  Settings
```

Calendar/reminders remain a parity consideration before replacement, but they do
not need a primary tab until the native product shape proves they deserve one.

## Auth And Purchase Policy

Native should prefer Sign in with Apple first.

Authentication is for:

- account continuity
- saved/cloud behavior when implemented
- restore continuity
- support/account deletion
- authenticated gateway usage

Authentication is not a forced pre-purchase wall.

Subscription implementation must be decided deliberately:

- RevenueCat may be retained for entitlement continuity.
- StoreKit 2 direct handling may be used if it is clearly better for the native
  app.
- Do not mix the two accidentally.
- Gateway/server entitlement policy remains authoritative for Premium
  generation.

## AI Architecture

Native target:

```text
SwiftUI app
  -> MessageWritingClient
  -> ProsePal gateway contract
  -> request verification
  -> auth and abuse controls
  -> entitlement and usage policy
  -> AI Gateway / Model Router
  -> provider adapters or local lane
```

Standard now uses the staging gateway for development and testing.

Long-term Standard may become local on-device generation after a separate
LiteRT-LM/Gemma spike proves quality, performance, storage, privacy, and App
Store suitability.

Premium remains cloud/frontier generation through the gateway.

## Validation Commands

Native validation when `prosepal-ios/` changes:

```bash
cd prosepal-ios
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Gateway validation when staging generation changes:

```bash
./scripts/prosepal-staging-smoke.sh
deno test --allow-env supabase/functions/generate-card/index.test.ts
```

Flutter production validation remains relevant only for Flutter production
changes:

```bash
flutter analyze
flutter test
./scripts/test_critical_smoke.sh
```

## Read These First

1. `docs/BACKLOG.md` - native open work and DoD.
2. `prosepal-ios/NATIVE_PRODUCT_NORTH_STAR.md` - product/UX bridge from Flutter
   behavior to native iOS shape.
3. `prosepal-ios/REWRITE_PLAN.md` - detailed native delivery gates and scenario
   matrix.
4. `docs/architecture/AI_GATEWAY_STRATEGY.md` - long-term AI architecture.
5. `docs/DEVOPS.md` - validation, CI, and operations.

## Non-Goals For The Native Rewrite Branch

- No Android rewrite work.
- No Firebase AI / Vertex AI client-direct SwiftUI path.
- No provider SDKs in the native client.
- No template generation fallback in the app.
- No forced first-run paywall.
- No hard login wall before purchase.
- No production gateway promotion without explicit release approval.
