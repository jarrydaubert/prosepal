# ProsePal iOS Native Rewrite

This folder is the native SwiftUI rewrite area for ProsePal.

The existing Flutter app remains the current production and reference
implementation. Do not delete, move, or replace the Flutter app while working
in this folder.

## Direction

- iOS-first, Android deferred.
- Swift, SwiftUI, async/await, Swift Package Manager.
- Minimum app target: iOS 17.
- Native UX direction: `NATIVE_UX_DIRECTION.md`.
- Keep RevenueCat initially for entitlement continuity unless an ADR chooses
  otherwise.
- Keep Supabase where it remains useful for auth, backend, and data continuity.
- Do not add Firebase AI or any client-direct model provider SDK here.

## AI Architecture

The source of truth is:

- `../docs/architecture/AI_GATEWAY_STRATEGY.md`

The SwiftUI client must depend on a ProsePal-owned message-writing capability:

```text
SwiftUI app
  -> MessageWritingClient
  -> ProsePal API / AI Gateway contract
  -> CardRequest / CardResponse
```

Provider names, model names, provider payloads, provider SDK response shapes,
and routing policy stay behind the ProsePal API boundary.

## App Structure

The checked-in native app is split into a small Xcode app target and Swift
package modules:

- `ProsePal`: SwiftUI iOS app target in `ProsePal.xcodeproj`.
- `ProsePalDomain`: provider-agnostic product and API contract models.
- `ProsePalAPI`: message-writing client protocol, gateway client, mock client,
  and deterministic template fallback client.
- `ProsePalUI`: modern SwiftUI app surfaces that depend only on the
  `MessageWritingClient` contract.

## Native Parity Progress

The first functional parity slice brings the native product vocabulary closer
to the Flutter reference while keeping the iOS design direction:

- 40 Flutter occasions are represented in the native domain layer.
- 14 Flutter relationship types are represented.
- 9 Flutter tones are represented.
- Message length uses the Flutter-aligned `Brief`, `Standard`, and `Detailed`
  naming and sentence guidance.
- Spelling preference is represented as `Automatic`, `US English`, and
  `UK English`.
- The Create surface uses a compact selected occasion card, popular shortcuts,
  and a searchable grouped occasion sheet instead of copying the Flutter
  occasion grid.
- The compose form builds a structured `CardIntent` from occasion,
  relationship, tone, length, spelling, recipient, include, avoid, and context
  fields.
- The template gateway client still returns fake deterministic drafts, but now
  respects the expanded intent fields.

No RevenueCat, Supabase, Firebase, Sentry, analytics, or provider SDKs are
included in this slice.

Run the native contract tests and simulator build from this folder:

```bash
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

To run interactively, open `ProsePal.xcodeproj` in Xcode and choose the
`ProsePal` scheme on an iOS simulator.

## Non-Goals For This First Slice

- No production AI routing change.
- No Firebase AI client-direct integration.
- No provider keys.
- No model/provider names in user-facing UI.
- No final App Store release target decision encoded in project settings yet.
