# Native User Journeys

## Purpose

Define the user journey policy for the native iOS rewrite. These journeys are
derived from the Flutter app's useful behavior and App Review lessons, but they
are expressed as SwiftUI-native product flows.

Open implementation work belongs in `docs/BACKLOG.md`.

## Core Policy

```text
Standard value first
Purchase without mandatory account creation
Sign in for continuity, restore confidence, support, and authenticated gateway usage
Gateway/server state is authoritative for usage and Premium access
```

## Launch

```text
Launch
  -> first run? Welcome
  -> biometric lock enabled and signed in? Lock
  -> otherwise Create
```

Rules:

- Do not show a marketing splash on every launch.
- Do not force sign-in during welcome/onboarding.
- Do not hard-paywall the user before they have experienced core value.
- If required configuration is missing, show a user-safe unavailable state with
  a retry/support path rather than a blank screen.

## First Use

```text
Welcome
  -> Start writing
  -> Create
  -> choose occasion / relationship / tone / length / details
  -> Generate through gateway
  -> Drafts
  -> Copy, Share, Edit, or Save
```

Rules:

- Occasion remains the product anchor.
- Recipient/relationship context should help the user think about the message
  without making the flow feel like a generic document form.
- The full Flutter option set remains available, but native presentation should
  use searchable sheets, grouped lists, compact controls, and keyboard-safe
  forms.

## Standard Generation

```text
Create
  -> Standard
  -> gateway request
  -> Drafts
```

Rules:

- Native Standard generation is gateway-backed during staging/native R&D.
- Long-term Standard may become local on-device generation after a separate
  approved spike.
- The app must not use client-side template generation as a runtime fallback.
- The app must not expose provider/model names.

## Premium Boundary

Good Premium triggers:

- user taps Premium generation
- gateway reports free limit reached
- user chooses a Premium-only future capability
- user opens Subscription from Settings

Bad Premium trigger:

- immediately blocking first-run onboarding before the user writes anything.

## Purchase

```text
Premium selected or limit reached
  -> Paywall sheet
  -> Product loading
  -> Purchase
  -> Entitlement confirmation
  -> Premium UI updates only after entitlement is active
```

Rules:

- Purchase cannot require app sign-in first.
- Sign in with Apple can be offered as a continuity benefit, not a pre-purchase
  wall.
- The paywall must include restore and legal/subscription terms access.
- Cancelled or pending purchases must not unlock Premium.
- Local Premium UI cannot authorize Premium generation by itself; the gateway
  remains authoritative.

## Restore

```text
Restore from Paywall or Settings
  -> Store restore / selected entitlement provider restore
  -> Entitlement refresh
  -> Result state
```

Rules:

- Restore should be available from both Paywall and Settings.
- Restore should not require mandatory app sign-in because store ownership is
  tied to the Apple ID.
- After restore succeeds, the app can invite sign-in for continuity.
- No-active-subscription and failure states must be honest and recoverable.

## Sign In With Apple

```text
Settings or Paywall continuity prompt
  -> Sign in with Apple
  -> Supabase Auth exchange
  -> session persisted
  -> app state refresh
```

Rules:

- Sign in with Apple is first-class for native iOS.
- Google sign-in is not part of the initial native direction unless existing
  account continuity requires it.
- Auth loading/finalizing state must prevent duplicate submits.
- Cancellation must not leave the app stuck.
- Sign out clears signed-in state, stale entitlement UI, biometric lock, and
  account-scoped diagnostics.

## Authenticated Gateway Usage

```text
Create
  -> gateway request with bearer token
  -> gateway verifies auth, usage, entitlement, abuse controls
  -> CardResponse or user-safe error
```

Rules:

- Bearer tokens are never logged.
- Raw recipient names, include/avoid/context fields, prompts, and generated
  drafts are never logged.
- Usage and entitlement policy lives behind the gateway/server boundary.

## Saved And History

Recommended native shape:

```text
Saved
  -> user-curated messages
  -> optional History filter later
  -> detail
  -> copy / share / edit / delete
```

Rules:

- Local saved messages can ship before cloud sync.
- History must be either implemented or deliberately excluded from the native
  replacement scope.
- Migration from Flutter local storage requires a tested, format-aware path.

## Settings

```text
Settings
  -> Account
  -> Subscription
  -> Writing preferences
  -> Privacy
  -> Support
  -> Legal
  -> About
```

Rules:

- Settings should look and behave like grouped iOS settings.
- Rows should not claim functionality that is not backed by real code.
- Analytics/crash toggles should exist only if those systems exist.
- Delete account and data export should either work or be hidden/unavailable
  with honest copy.

## Account Switch And Stale State

```text
User A signed in
  -> sign out
  -> User B signs in
```

Rules:

- User B must not inherit User A's entitlement, usage, telemetry, saved account
  state, pending sync, biometric preference, or diagnostics identity.
- Anonymous usage must never be rebound to whichever user signs in next.
- Server state wins over local cache for entitlement and usage.

## Replacement Readiness

Native can replace Flutter only when:

- Create and Results are better on iPhone than the Flutter flow.
- Auth, purchase, restore, usage, entitlement, support, legal, and settings are
  real, not placeholders.
- Existing user continuity is handled.
- TestFlight and physical iPhone evidence pass.
- App Review lessons from the Flutter release are explicitly preserved.
- Rollback to the Flutter production baseline remains possible until native is
  approved.
