# Native iOS Delivery Plan

This is the active delivery plan for the SwiftUI rewrite in `prosepal-ios/`.
It replaces optimistic phase notes with a verified path from native prototype to
internal TestFlight and, later, possible replacement of the Flutter production
app.

## Purpose

Keep one practical plan for the native rewrite:

- preserve the current Flutter app as production and behavioral reference;
- keep the native app iOS-first, SwiftUI-first, dependency-light, and gateway-first;
- avoid copying Flutter screen-for-screen while preserving product capability;
- make visible what is real, what is placeholder, and what must be true before
  any production replacement decision.

## Non-Negotiables

- The Flutter app remains the production/reference implementation until a signed
  production promotion decision says otherwise.
- Native generation goes through a ProsePal-owned message-writing contract.
- The native app must not import Firebase AI, Vertex AI, or provider-direct
  generation SDKs.
- Provider names, model names, provider payloads, provider keys, and prompt
  internals stay out of user-facing UI.
- Runtime logs must not include raw recipient names, user details, prompt text,
  generated message text, tokens, secrets, or provider payloads.
- Anonymous users must be able to experience the core value before being forced
  into auth or purchase.
- Purchase and restore flows must respect Apple's prior review feedback:
  purchasing cannot be blocked behind mandatory account creation, and free vs
  paid capability must be clear.
- Release readiness requires physical iPhone evidence, not only simulator
  success.

## Current Verified State

The native app is a strong prototype, not a production replacement.

Real today:

- Xcode app target: `ProsePal`.
- Swift package modules: `ProsePalDomain`, `ProsePalAPI`, `ProsePalUI`.
- iOS 17+ target, SwiftUI, async/await, Swift Package Manager.
- No external package dependencies.
- No RevenueCat, Supabase client SDK, Firebase, Sentry, analytics, StoreKit, or
  provider SDK dependency in the native code.
- Domain parity for core writing vocabulary: occasions, relationships, tones,
  lengths, and spelling preference.
- Gateway HTTP client using `CardRequest` and `CardResponse`.
- Compose -> gateway generate -> results -> copy/share/edit/save flow.
- First-run welcome/onboarding state and local saved-message persistence.
- Privacy-safe local `OSLog` diagnostics for tethered-device testing.
- Native CI exists for Swift tests and simulator build, but is currently
  non-blocking while the rewrite remains R&D.

Placeholder or shell today:

- Sign in with Apple UI.
- Account state.
- Purchase, restore, manage subscription, and paywall fulfillment.
- Server-authoritative usage/entitlement display.
- Authenticated gateway token wiring.
- Account deletion/export.
- Analytics and crash reporting.
- Biometric lock.
- Calendar/reminder parity.
- Existing Flutter-user migration.
- Local on-device Standard generation.

Known structural risk:

- Most UI and app model code currently lives in one large SwiftUI source file.
  This is acceptable for prototype velocity but should be decomposed before the
  auth, payments, and migration work starts to pile on.

## Target Product Shape

Native iOS should feel like a modern iPhone app for writing thoughtful messages,
not a Flutter clone and not an AI control panel.

Primary flow:

```text
Launch
  -> first run welcome
  -> Create
  -> write a message for someone / some occasion
  -> gateway generation
  -> drafts
  -> copy, share, edit, save
```

Main tabs:

```text
Create
Saved
Settings
```

Future tabs should be earned by user value. Calendar/reminders remain a parity
requirement before replacement, but do not need to become a main tab until the
native product shape proves they deserve that prominence.

## Target AI Architecture

```text
SwiftUI app
  -> ProsePalAppModel
  -> MessageWritingClient
  -> ProsePal gateway contract
  -> request verification
  -> auth and abuse controls
  -> entitlement and usage policy
  -> AI Gateway / Model Router
  -> provider adapters or local generation lane
```

Standard and Premium are product lanes, not model names.

Target lane behavior:

- Standard now: staging gateway-backed generation for development and testing.
- Standard later: local on-device drafts after the LiteRT-LM/Gemma spike proves
  quality, performance, storage, and App Store suitability.
- Premium: cloud/frontier generation through the ProsePal gateway.

The native client depends on `MessageWritingClient` implementations such as:

- `GatewayMessageWritingClient`
- `LocalMessageWritingClient`
- `MockMessageWritingClient`

The UI never names Gemma, OpenRouter, Claude, GPT, Gemini, or provider/model IDs.

## Flutter Lessons To Preserve

The Flutter app contains hard-won release and App Review lessons. Native should
reuse the lessons, not the screens.

### App Review

Apple previously rejected the Flutter app for requiring sign-in before purchase.
Native paywall design must therefore keep purchase available without mandatory
account creation. Sign in can be presented as a sync/restore benefit, and Sign
in with Apple should be first-class, but auth cannot be a hard gate before the
store purchase action unless a later App Review strategy explicitly changes.

Free vs paid capability must be plain:

- Standard/free capability and limits are visible.
- Premium capability is described as enhanced generation and higher limits.
- Subscription terms, privacy policy, and Apple's standard EULA path are present
  in App Store metadata and accessible from Settings/paywall surfaces.

### Build And Configuration

Flutter shipped a grey-screen release when config was missing from the release
build path. Native must not repeat that failure mode.

Native release builds need:

- explicit staging/production configuration strategy;
- no checked-in secrets;
- build-time or launch-time validation that required public config exists;
- user-safe blocking/degraded state when generation is not configured;
- release evidence proving the exact TestFlight/App Store build has the expected
  gateway environment.

### Identity And Entitlements

Flutter's production policy is the reference:

- authenticated identity maps to Supabase user ID;
- signed-out identity uses a persisted app-specific anonymous ID;
- RevenueCat entitlement continuity is likely retained initially unless an ADR
  selects StoreKit 2 direct verification;
- stale entitlement state must be cleared on account switch;
- restore and identity transitions require real-device evidence.

Native should start with Sign in with Apple only unless account-continuity
evidence requires another provider.

### Usage And Abuse Controls

Flutter's stronger pattern is server-authoritative usage enforcement. Native's
local usage display is only a temporary UI placeholder.

Target native behavior:

- gateway enforces usage, entitlement, auth, rate limits, and abuse controls;
- app renders gateway usage/entitlement state;
- failed generation does not consume visible allowance;
- free-limit, premium-required, rate-limit, timeout, and service-unavailable
  states have user-safe copy and retry/paywall actions;
- cost and abuse alerts are documented before production gateway rollout.

### Testing And Evidence

Do not over-trust soft journey tests. Native release confidence should come from
small, deterministic tests plus manual wired-device evidence for the flows that
depend on Apple, purchase, entitlement, auth, or live gateway behavior.

Evidence that matters:

- physical iPhone launch and first-run flow;
- Create keyboard behavior;
- staging gateway generation with privacy-safe logs;
- auth transition;
- purchase/restore/entitlement state;
- settings/legal/support surfaces;
- TestFlight install and smoke.

## Delivery Gates

### Gate 1: Prototype Truthfulness

Purpose: make the current native branch honest and maintainable.

Exit criteria:

- This plan is the active native delivery plan.
- Placeholder surfaces are explicitly named in docs and do not pretend to be
  production behavior.
- `REWRITE_PLAN.md` no longer claims Supabase or RevenueCat wrappers exist.
- Native CI status is described as non-blocking until promotion criteria change.
- Local evidence folders and Xcode user state remain uncommitted.

Validation:

```bash
cd prosepal-ios
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

### Gate 2: Native Create And Results Quality

Purpose: make the core writing loop feel like the product.

Exit criteria:

- Create flow preserves Flutter's information capture without adding extra taps.
- Occasion, relationship, tone, length, spelling, recipient, include, avoid, and
  context all map into `CardIntent`.
- Occasion selection avoids duplicated UI patterns.
- Keyboard does not hide active fields or the generation action.
- A visible loading/waiting state exists while generation is running.
- Results support copy, share, edit, save, retry, and change/start-over paths.
- No provider/model names appear in UI.

Validation:

```bash
cd prosepal-ios
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Manual evidence:

- first-run welcome;
- browse occasion;
- select relationship and tone;
- type with keyboard open;
- generate through staging gateway;
- view and act on drafts.

### Gate 3: Auth Identity

Purpose: replace account placeholders with a real identity path.

Exit criteria:

- Sign in with Apple works on device.
- Signed-out users can still use allowed Standard generation.
- Authenticated state is exposed to the app model through a protocol.
- `GatewayMessageWritingClient` receives auth tokens through its token provider.
- Account state survives relaunch and clears correctly on sign out.
- No stale entitlement or saved-account state leaks across user switches.

Validation:

- unit tests for signed-out, signed-in, sign-out, relaunch, and account switch;
- wired iPhone evidence for Sign in with Apple and sign out;
- gateway logs show authenticated requests without exposing tokens.

### Gate 4: Server Usage And Entitlement Policy

Purpose: remove cosmetic usage state from production paths.

Exit criteria:

- gateway returns usage/entitlement state in a stable client contract;
- app renders server usage state instead of decrementing production allowance
  locally;
- `402`, `403`, `408`, `409`, `422`, `425`, `429`, and `5xx` states map to
  user-safe UX;
- Premium selection opens paywall when locked and does not unlock until the
  entitlement source says it is active;
- no provider/model fields are exposed in client responses.

Validation:

- contract tests for usage, entitlement, rate-limit, timeout, blocked, and
  unavailable responses;
- staging curl evidence;
- wired iPhone evidence for free-limit and retry states.

### Gate 5: Payments And Restore

Purpose: make Premium real without repeating App Review mistakes.

Exit criteria:

- entitlement source is selected by ADR: RevenueCat initially, or StoreKit 2 if
  there is a stronger reason;
- purchase is possible without mandatory account creation;
- Sign in with Apple is framed as sync/restore/account continuity;
- restore works from paywall and Settings;
- anonymous purchase -> sign in -> entitlement reconciliation is verified;
- subscription product IDs and App Store listing continuity are decided;
- Terms, privacy policy, restore, and subscription copy are App Review-ready.

Validation:

- StoreKit sandbox or RevenueCat sandbox evidence;
- physical iPhone purchase/restore/entitlement smoke;
- App Store metadata review notes;
- no fake Premium state in tests or runtime.

### Gate 6: Saved, History, Settings, Support, And Legal Parity

Purpose: preserve the non-generation product surface users expect.

Exit criteria:

- Saved/history behavior is intentionally defined and implemented.
- Settings includes account, subscription, restore, writing preferences, privacy,
  support, legal, version, and diagnostics surfaces.
- Support path is user-controlled and does not leak secrets or raw message
  content.
- Data export and account deletion either work or are hidden until they do.
- Biometric lock and calendar/reminders are either implemented to native quality
  or explicitly deferred from the replacement release.

Validation:

- unit/UI tests for local saved-message behavior;
- wired iPhone evidence for settings/support/legal/account flows;
- privacy review of diagnostics payloads.

### Gate 7: Migration And App Store Continuity

Purpose: decide whether native can replace Flutter production safely.

Exit criteria:

- same Apple Developer Team is confirmed;
- bundle ID and App Store listing strategy is approved;
- subscription product ID continuity is approved;
- existing Flutter user history/entitlement migration is designed and tested;
- rollback strategy is documented;
- privacy labels and release notes reflect the native runtime;
- TestFlight install, launch, generate, auth, paywall, restore, settings, and
  support sanity pass on physical iPhone.

Validation evidence folder:

```text
artifacts/release/<release-tag>/native-ios/
```

Required evidence:

- version/build record;
- `swift test` log;
- simulator build log;
- wired iPhone smoke summary;
- staging/production gateway config summary with no secrets;
- auth evidence;
- purchase/restore/entitlement evidence;
- App Store Connect metadata review;
- TestFlight sanity;
- secret audit;
- rollback plan;
- owner sign-off.

## Operating Rules

- Keep implementation PRs small enough to review.
- Each PR should move one gate forward and update this plan only when the gate
  contract changes.
- Do not add SDKs speculatively. Add dependencies only when a gate requires
  them and the ownership/privacy/release impact is understood.
- Do not promote native CI to blocking until the branch is no longer R&D or
  native code becomes release-critical.
- Do not commit local evidence, `.xcuserdata`, Supabase `.temp`, provider keys,
  shared secrets, model binaries, or generated build products.

## Immediate Next PRs

1. Native create/results quality pass.
   Entry: current gateway generation works on staging.
   Exit: no duplicate occasion UI, keyboard-safe create flow, visible loading
   state, improved results actions, tests and wired screenshot evidence.

2. Auth identity slice.
   Entry: placeholder account surfaces are visible but non-functional.
   Exit: Sign in with Apple works on device, app model has real signed-in state,
   gateway token provider is wired, and sign-out clears state.

3. Server usage/entitlement contract slice.
   Entry: gateway is reachable and auth token path exists.
   Exit: app renders gateway usage/entitlement state and stops relying on local
   allowance as production truth.

4. Premium/paywall/restore slice.
   Entry: entitlement contract exists.
   Exit: real purchase/restore path works in sandbox, does not force sign-in
   before purchase, and preserves entitlement continuity policy.

## End State

The native app is eligible to replace Flutter production only when:

- the core writing loop is better on iPhone than the Flutter flow;
- auth, entitlement, usage, purchase, restore, support, and legal flows are real;
- gateway policy is server-authoritative and privacy-safe;
- existing user continuity has a tested migration path;
- physical-device and TestFlight evidence pass;
- App Review risks from the Flutter release history are explicitly addressed;
- rollback to the current Flutter production baseline remains available until
  the native release is approved.
