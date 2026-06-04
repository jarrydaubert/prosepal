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
- Draft results are reached from the Create flow rather than as a permanent
  major tab.
- Result cards support copy, share, edit, save, and context-menu actions.
- Saved messages persist locally with occasion, relationship, tone, length,
  recipient, date, list search, detail view, edit, copy, share, and delete.
- Standard usage is represented with a local placeholder state.
- Premium selection opens a native placeholder sheet instead of importing a
  subscription SDK.
- Retry and degraded-generation states now have visible, user-safe actions.
- The Create Generate action is keyboard-aware: the large bottom action hides
  while typing and a compact keyboard toolbar action remains available.
- Settings now uses clearer grouped sections for Account, Writing, Generation,
  Privacy, Support, and Runtime.
- The occasion picker leads with Most Used options and keeps the full catalogue
  in searchable grouped sections.
- First launch now routes through a lightweight three-step onboarding flow that
  can be skipped or completed locally before entering Create.
- The native onboarding flow now reuses the Flutter reference logo and
  onboarding artwork from Swift Package resources.
- The native UI accent palette is aligned with the Flutter brand direction:
  navy backgrounds, coral primary actions, warm premium gold, and white-forward
  onboarding typography.

## Brand Assets

The native SwiftUI package intentionally copies shared brand assets from the
Flutter reference app into `ProsePalUI` resources so the rewrite can use them
without changing production Flutter files:

- `Sources/ProsePalUI/Resources/Brand/logo.png`
- `Sources/ProsePalUI/Resources/Brand/splash_transparent.png`
- `Sources/ProsePalUI/Resources/Onboarding/slide_1.png`
- `Sources/ProsePalUI/Resources/Onboarding/slide_2.png`
- `Sources/ProsePalUI/Resources/Onboarding/slide_3.png`
- `App/Assets.xcassets/AppIcon.appiconset`
- `App/Assets.xcassets/LaunchLogo.imageset`
- `App/LaunchScreen.storyboard`

The current palette source is the Flutter reference in
`../lib/shared/theme/app_colors.dart`. Native tokens are mirrored in
`ProsePalRootView.swift` for this first slice. The app target now uses the
Flutter iOS AppIcon set and a native launch storyboard with a navy background
and centered ProsePal icon.

## Apple-Native Setup Notes

The app is intentionally dependency-light and SwiftUI-first. It uses
`NavigationStack`, `TabView`, Swift concurrency, system materials, searchable
lists, native sheets, and `#Preview`.

Some "modern Apple" capabilities are deliberately deferred:

- `.xcconfig` files and environment-specific schemes should be added when there
  are real staging/production gateway endpoints or signing environments.
- SwiftData should wait until local history, migration, and cloud-sync ownership
  are decided.
- AppIntents/Siri shortcuts should wait until the core create/save flows are
  stable enough to expose as system actions.
- Newer visual material effects should stay compatible with the iOS 17 minimum
  target and should not push ProsePal into a techy visual style.

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
