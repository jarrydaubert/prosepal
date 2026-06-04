# ProsePal iOS Native UX Direction

This document defines the intended product shape for the SwiftUI rewrite in
`prosepal-ios/`. It is the UX guardrail before more implementation work happens.

The existing Flutter app remains the production and behavior reference. The
native app must reach functional parity before it can replace production, but it
should not copy Flutter screen-for-screen. Flutter defines what ProsePal does.
Modern iOS design defines how the native app should feel.

## Product Stance

ProsePal iOS is centered on one primary job:

```text
Write a message
```

Everything else supports that job: onboarding, occasion browsing, compose
details, generation mode, results, saved messages, subscription state, account
state, support, and privacy.

The visual direction should be:

- native
- warm
- calm
- premium
- simple
- human
- rooted in the existing ProsePal navy, coral, and white brand palette

The app can feel modern and polished, including strong dark mode support, but it
should not drift into a cyber, neon, or command-console aesthetic. ProsePal helps
people write thoughtful messages for real relationships, including sensitive
moments. The interface should feel like a beautiful writing assistant, not a
model playground.

The Flutter app's visual assets remain valuable brand source material. Reuse the
existing logo, app icon direction, splash artwork, onboarding artwork, and
navy/coral/white palette where they help the native app feel recognizably
ProsePal. Reinterpret the layout with SwiftUI and platform conventions rather
than copying old Flutter screens directly.

## Principles

- Create is the center of the app.
- Full functional parity with Flutter is required before production replacement.
- Do not copy the Flutter home grid or wizard as the visual design.
- Keep the native app gateway-first: collect structured intent, call a stable
  ProsePal-owned message-writing contract, render `CardResponse`, and handle
  loading, retry, usage, timeout, and degraded-generation UX.
- Do not rebuild SwiftUI as a Firebase AI, Vertex AI, or provider-direct client.
- Treat Standard and Premium as product lanes, not model names.
- Do not show provider, SDK, or model names in user-facing UI.
- Use iOS-native patterns: tab bars, navigation stacks, sheets, searchable
  lists, grouped forms, context menus, share sheets, and grouped settings lists.
- Keep onboarding short and useful.
- Let users experience value before showing a paywall when possible.
- Keep visual density comfortable on real phones, not just previews.

## 1. Launch And Startup Routing

The app should rely on the normal iOS launch screen rather than a branded splash
experience that delays every session.

Launch screen:

- ProsePal icon or wordmark
- adaptive calm background
- no marketing copy
- no spinner unless initialization genuinely requires one

Startup routing:

```text
first launch -> onboarding
returning user -> Create
biometric lock enabled -> lock screen
force update -> blocking system screen
initialization failure -> blocking system screen with retry/support path
```

The launch screen is just the door opening. The real product begins at
onboarding or Create.

## 2. Onboarding Flow

Onboarding should be three screens maximum. It should be skippable unless a
future compliance, account, or purchase requirement makes that impossible.

Do not force login during onboarding. Do not show a first-run hard paywall by
default. Let the user write something and see value first.

Recommended onboarding:

1. Write better messages for real moments
   - Birthdays, thank-yous, apologies, sympathy, and awkward moments.
2. Give it the context
   - Choose the occasion, relationship, tone, length, and details.
   - ProsePal turns that into drafts the user can edit.
3. Standard and Premium
   - Standard gives useful free drafts.
   - Premium unlocks enhanced drafts and higher limits.

Primary action:

```text
Start writing
```

## 3. Main Navigation Model

The native app should use a simple tab structure:

```text
Create
Saved
Settings
```

`Create` is the default and primary tab. `Saved` contains saved messages and, if
needed later, generated history as a filter. `Settings` contains account,
subscription, writing preferences, privacy, support, legal, and app metadata.

A fourth tab should only be added when a feature earns persistent navigation.
The likely future candidate is:

```text
Reminders
```

Until reminders/calendar functionality is mature, keep it out of the primary tab
bar.

## 4. Create Screen Structure

The first working screen should help the user start writing immediately.

Recommended shape:

```text
Large title: What are you writing?
Subtitle: Pick an occasion or describe it yourself.

Selected occasion
Browse/search occasions
Popular suggestions
Compose details
Generation mode
Generate
```

Keep:

- big Create focus
- selected occasion card
- Browse occasion sheet
- relationship, tone, and length controls
- include, avoid, and context fields
- Standard and Premium state
- Generate action

Avoid:

- giant occasion grid on the home screen
- dense wizard steps for the default path
- first-screen marketing content
- decorative cards that compete with the writing task

## 5. Occasion Picker And Catalogue Treatment

The full Flutter occasion catalogue should exist in the native domain layer.
It should not be shown as a giant grid or forty visible chips on the default
Create screen.

Native treatment:

- search-first occasion picker
- grouped sections
- popular suggestions on Create
- recent and favorites later
- "Something else" free-text option later

Suggested picker structure:

```text
Search occasions

Most Used
Birthday
Thank You
Sympathy
Wedding
Christmas

Common Life Events
Get Well
Congratulations
New Baby
New Job
Sorry / Apology

Family
Mother's Day
Father's Day
Anniversary

Seasonal
Christmas
New Year
Valentine's Day

Other
Something else
```

The picker should support quick scanning, clear labels, and short helper copy
where useful.

## 6. Compose Form Behavior

The compose experience should be a single progressive screen by default, not a
rigid multi-step wizard.

Recommended form structure:

```text
Occasion
Who is it for?
Relationship
Tone
Length
Details to include
Things to avoid
Context
Spelling / locale preference
Generation mode
```

Use native controls:

- searchable sheets for large taxonomies
- segmented controls for compact option sets
- menus or pickers for medium option sets
- grouped sections for editable details
- clear helper text only where it reduces uncertainty

Complex guided mode can come later as an optional sheet or alternate flow.

## 7. Keyboard And Generate Button Behavior

The Generate action must never collide with the keyboard, the tab bar, or input
fields on real devices.

Preferred behavior:

- Generate appears only on the Create tab.
- When the keyboard is hidden, Generate can be a sticky bottom action.
- When the keyboard is visible, Generate either moves cleanly above the keyboard
  or becomes a keyboard toolbar action.
- The tab bar remains stable and lower priority than the compose task.
- Text fields must remain scrollable above the keyboard.

The bottom area should not feel like tab bar plus giant action button plus
keyboard are all fighting for the same space.

## 8. Results Experience

Results are the product payoff and should feel polished.

Results shape:

```text
Drafts
Pick one to copy, edit, save, or share.

Draft 1
Draft 2
Draft 3
```

Each draft should support:

- copy
- share
- save
- edit
- context menu actions
- copy/save confirmation
- subtle haptic feedback where appropriate

Refinement actions should be available after generation:

- regenerate
- change tone
- make shorter
- make warmer
- start over

Fallback or degraded generation should be explained plainly without provider
details:

```text
Simple draft used this time. You can retry shortly.
```

Runtime generation should be gateway-or-unavailable. Tests and previews may use
mock responses, but the native app should not generate fake/template drafts when
the gateway is not configured.

## 9. Saved And History Structure

`Saved` should be a native library-style list, not a dashboard.

List shape:

```text
Saved
Search saved messages
Recent / occasion / recipient filters
Rows with recipient, occasion, preview, and date
```

Detail shape:

```text
Full message
Copy
Share
Edit
Delete
Metadata
```

Preferred v1 distinction:

- Saved means user-curated messages.
- History means all generated drafts and can live behind a filter if added.

Local saved messages can ship before cloud sync. Cloud sync belongs behind auth
and backend decisions.

## 10. Settings, Account, Subscription, Privacy, And Support

Settings should use a classic grouped iOS settings layout. It should feel
boring in the best way: predictable, scannable, and mature.

Recommended sections:

```text
Account
- Sign in with Apple
- Subscription
- Restore purchases

Writing
- Default spelling
- Default tone
- Default generation mode

Privacy
- Analytics, if added later
- Crash reports, if added later
- Export data
- Delete account

Support
- Send feedback
- Help
- Terms
- Privacy Policy

About
- Version
- Runtime
- Gateway contract version
```

Spelling and generation mode must be separate settings. A spelling row should
not open or imply generation controls.

Do not add analytics, crash reporting, Firebase, Supabase, RevenueCat, Sentry,
or provider SDKs just because the old app has related infrastructure. Each
external dependency needs a product reason.

## 11. Standard And Premium UI Treatment

Standard and Premium are product lanes.

Create treatment:

```text
Generation mode
[Standard] [Premium]
```

Free user usage copy:

```text
2 of 3 Standard generations left today
```

Premium user copy:

```text
Premium generation active
```

If Premium is locked, tapping it should open the paywall sheet. The UI should
describe enhanced generation and limits, not providers or models.

Usage state must come from one source of truth. Create and Settings must not
display contradictory counts.

Fallback copy:

```text
Enhanced generation was unavailable. We used Standard this time.
```

## 12. Paywall Triggers And Placement

The paywall should be contextual, not shoved in front of users before they have
experienced the core value.

Good triggers:

- user taps Premium generation
- user hits a free daily limit
- user regenerates beyond a free allowance
- user selects a future Premium-only capability
- user opens subscription management from Settings

Bad trigger:

- immediately after onboarding before the user has written anything

Paywall copy should describe durable value:

- Premium generation
- enhanced drafts for harder messages
- higher generation limits
- priority generation, if supported by the gateway and entitlement policy
- saved/cloud features, only if actually implemented

Do not mention model names or providers. Do not overpromise perfect messages.

## 13. Loading, Retry, Timeout, And Degraded States

Generation should have explicit state handling:

- idle
- validating intent
- generating
- retrying
- succeeded
- usage limited
- timed out
- degraded by the gateway/router
- failed

The user-facing message should be calm and actionable:

- try again
- edit details
- use Standard
- view saved draft
- contact support from Settings when appropriate

The client should not expose provider names, model names, raw backend errors, or
sensitive request content in logs or UI.

## 14. Calendar And Reminders Native Treatment

Calendar/reminders should be deferred visually until the core Create, Results,
Saved, and Settings loops are strong.

Production replacement still requires deciding how to cover any Flutter reminder
or occasion-tracking behavior. Native treatment should be:

- optional Reminders tab only when mature
- upcoming occasions list
- add/edit occasion
- remind me controls
- system notification permission only at the moment it is needed

Track reminders as a parity requirement, not as a v1 navigation default.

## 15. Intentional Differences From Flutter

The SwiftUI app should intentionally differ from Flutter in these ways:

- no old-style splash before every session
- no forced first-run paywall by default
- no huge home occasion grid as the main screen
- no screen-for-screen wizard clone
- no Firebase AI or Vertex AI client-direct generation path
- no provider/model names in user-facing UI
- native searchable sheets for large catalogues
- native settings list rather than custom dashboard styling
- saved messages as a focused list
- paywall presented at value boundaries

The Flutter app remains the source for product capabilities, catalogue coverage,
and existing behavior until native replacement is ready.

## 16. Full-Parity Checklist

Required before replacing Flutter production:

- launch routing
- lightweight onboarding
- full occasion catalogue
- relationship taxonomy
- tone taxonomy
- length behavior and naming
- spelling and locale preferences
- recipient and personal detail capture
- include and avoid detail fields
- Standard generation lane
- Premium generation lane
- usage limits and entitlement-aware UI
- contextual paywall journey
- retry, timeout, and degraded-generation UX
- three-draft results flow
- copy, share, edit, save, and regenerate actions
- saved messages
- history decision: separate list or Saved filter
- local persistence
- keyboard-safe Generate action
- native grouped Settings structure
- auth strategy, likely Sign in with Apple first
- subscription strategy, likely RevenueCat initially only if it earns continuity
- backend/gateway contract
- gateway request verification, auth, abuse controls, entitlement policy, and
  model router integration
- account deletion and data export
- legal and support surfaces
- App Store/TestFlight configuration
- migration plan from Flutter production
- native CI and deterministic test coverage

## Recommended PR Sequence

### PR 1: Native UX Direction

Scope:

- codify launch/startup routing
- codify onboarding shape
- codify tab structure
- codify Create, occasion picker, compose, results, Saved, Settings, and paywall
  direction
- capture intentional differences from Flutter
- capture full-parity checklist

Exit criteria:

- UX direction doc reviewed
- no feature implementation mixed into the direction PR

### PR 2: Native UX Hardening

Scope:

- fix keyboard and Generate-button overlap
- separate spelling from generation settings
- mature Settings into a grouped iOS settings structure
- improve occasion picker grouping and most-used treatment
- ensure Create and Settings read usage from one source of truth

Exit criteria:

- device run shows no keyboard/action overlap
- Settings sections are clear and native
- Create and Settings usage counts match
- `swift test` passes
- iPhone simulator or device build passes

### PR 3: Launch, Onboarding, And Paywall Journey

Scope:

- first-launch route state
- lightweight onboarding
- contextual paywall trigger hooks
- no forced login or first-run hard paywall
- no real subscription SDK unless explicitly chosen

Exit criteria:

- first launch routes to onboarding
- returning launch routes to Create
- Premium and limit boundaries open the placeholder paywall
- no provider/model names in UI

### PR 4: Results And Saved Refinement

Scope:

- richer results actions
- tone/length refinement actions
- saved-message filters
- clearer degraded-generation state
- gateway-backed output quality iteration

Exit criteria:

- result cards support the expected native actions
- Saved behaves like a library-style iOS list
- degraded/retry states remain provider-agnostic
