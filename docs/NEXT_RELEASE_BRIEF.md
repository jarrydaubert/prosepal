# Native iOS Readiness Brief

## Purpose

Define the active delivery objective for ProsePal: a native iOS SwiftUI rebuild
under `prosepal-ios/`, built inside the existing repository.

This document is the shareable release/readiness brief. Open work lives only in
`docs/BACKLOG.md`.

## Product Direction

ProsePal is a thoughtful personal-message app. The native iOS app should help
someone show up for the people who matter: remember the moment, say what is
true, and get the message sent.

Native iOS direction:

- iOS 26-first.
- SwiftUI-first.
- Person-first Moment Sheet.
- Dependency-light and Apple-native.
- Private draft for everyday moments.
- Take more care for harder moments.
- StoreKit 2, Sign in with Apple, SwiftData, and Foundation Models.
- Flutter screens are not the native visual or interaction spec.

## Native Boundary

Native rewrite facts:

- Native app lives in `prosepal-ios/`.
- Native UI depends on a ProsePal-owned `MessageWritingService` boundary.
- Private draft is the everyday/on-device lane where available.
- Take more care is the cloud/careful lane through the ProsePal gateway or
  approved Apple-native cloud path.
- Provider/model names must not appear in user-facing UI.
- Careful/sensitive drafting is a safety and quality route, not a Premium
  billing gate.
- Server entitlement remains authoritative for future subscription-gated
  Premium limits/extras and any paid cloud capability.

## Non-Negotiables

- Do not commit secrets, provider keys, local Xcode schemes, Supabase `.temp`
  state, StoreKit receipts, generated evidence, or model binaries.
- Do not expose provider/model names in native user-facing UI.
- Do not log raw recipient names, card details, prompt text, generated drafts,
  tokens, receipts, provider payloads, or provider keys.
- Do not add Firebase AI, Vertex AI, RevenueCat, Sentry, analytics SDKs, or
  provider SDKs by default.
- Do not force sign-in before purchase.
- Do not build or maintain the grouped-form UI as a product fallback once the
  Moment Sheet stands up.

## Active Readiness Gates

The actionable backlog is `docs/BACKLOG.md`. Its native gates are:

| Gate | Outcome |
|------|---------|
| `N-IOS-01` | Moment Sheet foundation. |
| `N-IOS-02` | Private draft lane. |
| `N-IOS-03` | Take more care lane. |
| `N-IOS-04` | Relationship vault, Truth Beads, and Voice Card. |
| `N-IOS-05` | Careful Mode, Pressure Check, and crisis path. |
| `N-IOS-06` | Out-of-app native surfaces. |
| `N-IOS-07` | StoreKit 2 and server entitlement. |
| `N-IOS-08` | Sign in with Apple, account, deletion, and export. |
| `N-IOS-09` | Saved, settings, privacy, support, and legal. |
| `N-IOS-10` | Native iOS 26 CI, TestFlight, and release evidence. |
| `N-IOS-11` | Privacy-safe diagnostics and observability. |
| `N-IOS-12` | Legacy grouped-form removal. |
| `N-IOS-13` | Retire legacy island and reconcile docs to the native direction. |
| `N-IOS-14` | Native visual system and Moment rail/content discipline. |
| `N-IOS-15` | Promote native iOS to active main and archive Flutter baseline. |

## Native App Shape

```text
Launch
  -> first-run welcome
  -> Moment Sheet
  -> private draft when enough context exists
  -> adjust / take more care
  -> copy, share, send, save

Supporting surfaces
  relationship vault
  saved local messages
  settings/account/subscription/privacy/legal
  App Intents / widget / Control Center / Share extension
```

The product starts person-first. Occasion taxonomy exists underneath the moment
model and should not become a giant visible grid.

## Auth And Purchase Policy

Native uses Sign in with Apple first.

Authentication is for:

- account continuity
- saved/cloud behavior when implemented
- restore continuity
- support/account deletion
- authenticated gateway usage

Authentication is not a forced pre-purchase wall.

Subscription implementation:

- StoreKit 2 in the native client.
- Server/gateway entitlement policy is authoritative for future Premium
  limits/extras and any paid cloud capability.
- App Store Server Notifications V2 and App Store Server API reconciliation are
  the intended server-side entitlement path.

## AI Architecture

Native target:

```text
SwiftUI Moment Sheet
  -> MomentModel
  -> MessageWritingService
      -> PrivateDraftClient
      -> CarefulClient
      -> MockClient
```

The careful/cloud lane uses the ProsePal gateway where request verification,
abuse control, usage policy, and server secrets belong. Premium billing is a
separate limits/extras concern. The private/everyday lane is native and local
where device capability allows.

## Validation Commands

Native validation when `prosepal-ios/` changes:

```bash
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Gateway validation when staging generation changes:

```bash
./scripts/prosepal-staging-smoke.sh
deno test --allow-env supabase/functions/generate-card/index.test.ts
```

Flutter is archived and is not validated on active `main`. Use tag
`flutter-prod-freeze-2026-06-25` or branch
`legacy/flutter-production-reference` only for historical inspection.

## Read These First

1. `docs/BACKLOG.md` - native open work and DoD.
2. `prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md` - native product,
   design, and technical direction.
3. `prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md` - local staging and device
   proof.
4. `docs/architecture/AI_GATEWAY_STRATEGY.md` - cloud/gateway strategy.
5. `docs/DEVOPS.md` - validation, CI, and operations.

## Non-Goals For The Native Rewrite Branch

- No Android rewrite work.
- No Firebase AI / Vertex AI client-direct SwiftUI path.
- No provider SDKs in the native client.
- No template generation fallback in the app.
- No forced first-run paywall.
- No hard login wall before purchase.
- No production gateway promotion without explicit release approval.
- No RevenueCat dependency.
- No Flutter screen parity requirement.
