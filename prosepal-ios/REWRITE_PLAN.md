# Native iOS Rewrite Plan

## Ground Rules

The Flutter app is the production/reference implementation. The native rewrite
lives under `prosepal-ios/` until it is explicitly promoted through App Store,
privacy, entitlement, and release gates.

The target AI architecture is gateway-first:

```text
Client app
  -> ProsePal API
  -> request verification
  -> auth and abuse controls
  -> entitlement and usage policy
  -> AI Gateway / Model Router
  -> provider adapters
  -> Standard, Premium, local, or template generation lane
```

The SwiftUI app should send structured intent and render `CardResponse`. It
should not choose model IDs, hold provider keys, or import generation-provider
SDKs.

## Phase 1: Native Shell

Outcome:

- SwiftUI app shell exists in `prosepal-ios/` as a runnable Xcode app target.
- Domain and API contracts compile under Swift Package Manager.
- Mock and template generation let the UI be developed without a live gateway.
- Native compose, drafts, saved messages, and settings surfaces use SwiftUI
  platform conventions instead of copying Flutter screens.
- No production services or provider keys are required.

Validation:

```bash
cd prosepal-ios
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

## Phase 2: Product Parity Map

Outcome:

- Flutter occasions, relationships, tones, lengths, and spelling preferences
  are mapped to native domain models.
- The first native create slice carries the full Flutter catalogue shape into
  Swift while presenting it through a searchable, grouped iOS picker.
- Generation, results, history, paywall, auth, settings, and support flows have
  parity notes against the Flutter reference.
- Local data migration risks are documented before choosing same-bundle release.

Validation:

- Domain contract tests cover encoded request/response shapes.
- Request construction tests prove the compose draft maps native fields into
  `CardIntent`.
- UI previews use only mock/template clients.

## Phase 3: Auth And Entitlement Continuity

Outcome:

- Supabase auth wrapper exists behind a protocol.
- RevenueCat entitlement wrapper exists behind a protocol.
- Identity mapping preserves current policy:
  - signed in: Supabase user ID
  - signed out: persisted app-specific anonymous ID
- The client displays entitlement state but does not enforce Premium routing.

Validation:

- Unit tests prove identity transitions do not leak stale entitlement state.
- Sandbox manual evidence covers purchase, restore, anonymous purchase, sign-in,
  and account switch.

## Phase 4: Gateway Contract Integration

Outcome:

- `GatewayMessageWritingClient` calls a ProsePal-owned endpoint.
- Requests carry contract versions, app version, locale, lane request, and an
  idempotency key.
- Responses map to user-safe generation states.
- Timeout, retry eligibility, degraded generation, and usage display are handled
  without provider/model names.

Validation:

- Contract tests cover successful, fallback, rate-limit, timeout, blocked, and
  unavailable responses.
- No raw user content is logged.

## Phase 5: Controlled R&D/TestFlight

Outcome:

- Internal TestFlight build runs against staging or mock gateway.
- App Store continuity is decided:
  - same Apple Developer Team
  - same bundle ID if viable
  - same App Store listing if viable
  - same subscription product IDs if viable
- Privacy labels and support docs are updated before any real gateway traffic.

Validation:

- Wired iOS evidence covers launch, auth, entitlement restore, generation,
  degraded-generation UX, history, settings, and account deletion.

## Phase 6: Production Promotion Decision

Outcome:

- ADR approves any gateway production rollout.
- Current production baseline remains available until migration gates pass.
- Rollback can happen server-side without a mobile app release.

Validation:

- Gateway evals show Standard does not meaningfully regress against the current
  free-user production experience.
- Premium shows measurable uplift over Standard.
- Entitlement enforcement is server-side and verified.
