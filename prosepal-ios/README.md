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
- `ARCHITECTURE.md` for the native Standard/Premium AI client direction

The SwiftUI client must depend on a ProsePal-owned message-writing capability:

```text
SwiftUI app
  -> MessageWritingClient
  -> ProsePal API / AI Gateway contract
  -> CardRequest / CardResponse
```

Provider names, model names, provider payloads, provider SDK response shapes,
and routing policy stay behind the ProsePal API boundary.

## Gateway Development

The app target is gateway-first at launch:

- if `PROSEPAL_GATEWAY_URL` is set in the Xcode scheme environment or app
  Info.plist, the app uses `GatewayMessageWritingClient`;
- otherwise generation fails with a user-safe unavailable state.

This switch is for native R&D and review builds. It does not add Firebase AI,
Vertex AI, provider SDKs, provider keys, model names, or local/template
generation to the iOS app.

Simulator local endpoint:

```text
PROSEPAL_GATEWAY_URL=http://127.0.0.1:54321/functions/v1/generate-card
```

Physical devices cannot use the Mac's `127.0.0.1`. For tethered-device testing,
prefer an HTTPS development/staging Supabase function URL:

```text
PROSEPAL_GATEWAY_URL=https://<project-ref>.supabase.co/functions/v1/generate-card
```

Local anonymous gateway mode requires the function environment variable
`GATEWAY_DEV_ALLOW_ANONYMOUS=true`. Authenticated mode will be the default once
the native auth path is connected.

Authenticated gateway requests use the existing Supabase
`check_and_increment_usage` RPC after a successful, quality-checked generation.
The RPC enforces caller identity with `auth.uid()` and verifies entitlement from
server state. Successful authenticated responses include `CardResponse.usage`;
usage-limit or usage-RPC failures fail closed with a user-safe error and no
generated messages in the client response. Anonymous development mode does not
call this authenticated usage RPC.

Staging anonymous gateway traffic can be guarded with a shared development
secret. When the Supabase function has `PROSEPAL_DEV_GATEWAY_SECRET` configured,
set the same value in the Xcode scheme environment so the native client sends
the `X-ProsePal-Dev-Gateway-Secret` header:

```text
PROSEPAL_DEV_GATEWAY_SECRET=<staging-only-secret>
```

Do not put provider keys, model names, or production secrets in the app target.

## Native Diagnostics

The native app uses local Apple `OSLog` diagnostics for tethered-device work.
Filter Xcode Console or Console.app by subsystem:

```text
com.prosepal.native
```

Categories:

- `flow`: launch, onboarding, tab changes, picker choices, generation lifecycle,
  paywall boundaries, copy/share/edit/save/delete actions.
- `gateway`: gateway request start, response status, lane used, fallback status,
  message counts, total generated character count, and latency.

These diagnostics intentionally do not log recipient names, personal details,
raw prompt text, generated message text, authorization tokens, provider API
keys, or provider payloads. Gateway operator logs may include the configured
server-side model id for debugging, but model/provider names must stay out of
the user-facing UI and client response contract.

## App Structure

The checked-in native app is split into a small Xcode app target and Swift
package modules:

- `ProsePal`: SwiftUI iOS app target in `ProsePal.xcodeproj`.
- `ProsePalDomain`: provider-agnostic product and API contract models.
- `ProsePalAPI`: message-writing client protocol, lane router, gateway client,
  local model storage shell, and mock client for tests/previews.
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
  `UK English`; it lives in Settings and silently shapes the gateway request.
- The Create surface is recipient-first, then occasion-led, with one selected
  occasion card and a searchable grouped occasion sheet instead of copying the
  Flutter occasion grid.
- Relationship and tone expose selected native summary rows on Create, with the
  full Flutter option sets available in searchable native sheets rather than
  oversized dropdowns or visible grids.
- The compose form builds a structured `CardIntent` from occasion,
  relationship, tone, length, spelling, recipient, include, avoid, and context
  fields.
- Runtime generation is gateway-only; tests and previews use mock responses
  rather than template generation.
- Future local Standard generation now has a storage shell for app-private
  Application Support model files; it does not download or run a model yet.
- Message results are reached from the Create flow rather than as a permanent
  major tab.
- Result cards support copy, share, edit, save, and context-menu actions.
- Saved messages persist locally with occasion, relationship, tone, length,
  recipient, date, list search, detail view, edit, copy, share, and delete.
- Standard usage uses gateway-provided `CardResponse.usage` when present; the
  staging gateway now returns that summary for authenticated requests after the
  existing Supabase usage RPC allows and increments the generation. The local
  decrement remains a temporary development placeholder for anonymous native
  R&D builds.
- Premium selection opens a native placeholder sheet instead of importing a
  subscription SDK.
- Retry and degraded-generation states now have visible, user-safe actions.
- The Create Write Message action is keyboard-aware: the large bottom action hides
  while typing and a compact keyboard toolbar action remains available.
- Settings now uses clearer grouped sections for Account, Writing, Generation,
  Privacy, Support, and About.
- The occasion picker leads with Most Used options and keeps the full catalogue
  in searchable grouped sections.
- First launch now routes through a lightweight single-screen welcome flow that
  can be completed locally before entering Create.
- The native welcome flow uses brand color, typography, and SF Symbols rather
  than logo or artwork-led screens.
- The launch storyboard is intentionally plain navy with no logo or marketing
  copy.
- The native UI accent palette is aligned with the Flutter brand direction:
  navy backgrounds, coral primary actions, warm premium gold, and white-forward
  onboarding typography.

## Brand Assets

The native app keeps the Flutter iOS app icon set for brand continuity:

- `App/Assets.xcassets/AppIcon.appiconset`
- `App/LaunchScreen.storyboard`

The current launch screen and first-run welcome screen deliberately do not
display a logo. Unused onboarding and launch-logo bitmap assets are not shipped
in the native target.

The current palette source is the Flutter reference in
`../lib/shared/theme/app_colors.dart`. Native tokens are mirrored in
`ProsePalRootView.swift` for this first slice. The app target now uses the
Flutter iOS AppIcon set and a native launch storyboard with a plain navy
background.

## Apple-Native Setup Notes

The app is intentionally dependency-light and SwiftUI-first. It uses
`NavigationStack`, `TabView`, Swift concurrency, system materials, searchable
lists, native sheets, and `#Preview`.

Native auth plumbing has started without adding a third-party SDK:

- `AuthSessionController` owns the current session and exposes the gateway
  access-token provider.
- `KeychainAuthSessionStore` keeps Supabase session tokens in the app keychain,
  not `UserDefaults`.
- `SupabaseAuthClient` implements only the Apple ID-token exchange needed to
  turn a native Apple credential into a Supabase session.
- `GatewayMessageWritingClient` receives an Authorization bearer token from the
  session controller when a valid session exists.

The Sign in with Apple button is still a placeholder in the UI until the native
Apple credential request, entitlement/capability setup, and wired-device proof
are completed.

Some "modern Apple" capabilities are deliberately deferred:

- `.xcconfig` files and environment-specific schemes should be added when there
  are real staging/production gateway endpoints or signing environments.
- SwiftData should wait until local history, migration, and cloud-sync ownership
  are decided.
- AppIntents/Siri shortcuts should wait until the core create/save flows are
  stable enough to expose as system actions.
- Newer visual material effects should stay compatible with the iOS 17 minimum
  target and should not push ProsePal into a techy visual style.

No RevenueCat, Supabase SDK, Firebase, Sentry, analytics, provider SDKs, or
StoreKit purchase SDKs are included in this slice.

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
