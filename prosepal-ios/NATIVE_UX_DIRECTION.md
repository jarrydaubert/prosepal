# ProsePal iOS Native UX Direction

This document defines the product shape for the SwiftUI rewrite in `prosepal-ios/`.
It is the UX guardrail before more implementation work happens.

## Product Stance

ProsePal iOS should be a modern, calm, task-focused iPhone app centered on one
primary job:

```text
Write a message
```

The existing Flutter app remains the production and behavior reference. The
SwiftUI app must reach functional parity before it can replace production, but
it should not clone Flutter screen-for-screen. Flutter defines what the product
does. Native iOS design defines how the new app should feel.

## Principles

- Create is the center of the app.
- Full functional parity with Flutter is required before production replacement.
- Do not copy the Flutter home grid or wizard as the visual design.
- Use iOS-native patterns: tab bars, navigation stacks, sheets, searchable lists,
  grouped forms, context menus, share sheets, and system settings-style lists.
- Keep onboarding short and useful.
- Let users experience value before showing a paywall when possible.
- Treat Standard and Premium as product lanes, not model names.
- Do not show provider, SDK, or model names in user-facing UI.
- Keep the mobile app gateway-first. The client collects structured intent,
  calls a ProsePal-owned contract, renders `CardResponse`, and handles loading,
  retry, usage, timeout, and degraded-generation states.
- Do not rebuild the SwiftUI app as a Firebase AI, Vertex AI, or provider-direct
  client.

## 1. App Navigation Model

The native app should use a simple tab structure:

```text
Create
Saved
Settings
```

`Create` is the default and primary tab. `Saved` contains saved messages and, if
needed later, generated history as a filter. `Settings` contains account,
subscription, writing preferences, privacy, support, legal, and app metadata.

A fourth tab should only be added when the feature earns persistent navigation.
The likely future candidate is:

```text
Reminders
```

Until reminders/calendar functionality is mature, keep it out of the primary tab
bar.

## 2. Launch And Onboarding Flow

The app should rely on the normal iOS launch screen rather than a branded splash
experience that delays every session.

Launch routing:

```text
first launch -> onboarding
returning user -> Create
locked user -> biometric lock screen, if enabled later
force update or initialization error -> blocking system screen
```

The launch screen should be simple:

- ProsePal wordmark or icon
- calm background
- no spinner unless initialization genuinely requires one

Onboarding should be at most three screens and should be skippable unless a
future required compliance, account, or purchase step makes that impossible.

Suggested onboarding:

1. What ProsePal does
   - "Write better messages for real moments."
   - Examples: birthdays, thank-yous, apologies, sympathy, and awkward moments.
2. How it works
   - Collect occasion, relationship, tone, length, and details.
   - Return drafts that can be copied, edited, saved, or shared.
3. Standard and Premium
   - Standard gives useful drafts and free usage.
   - Premium unlocks enhanced generation, higher limits, and better support for
     harder messages.

Do not force login during onboarding unless the product later requires it.

## 3. Paywall Placement

The paywall should not be the default first experience after onboarding. For the
R&D and portfolio-first direction, the app should prove value first.

Good paywall triggers:

- user taps Premium generation
- user hits a free daily limit
- user regenerates beyond a free allowance
- user selects a future Premium-only capability
- user opens subscription management from Settings

Paywall copy should describe durable value:

- Premium generation
- better drafts for harder messages
- higher generation limits
- priority generation, if supported by the gateway and entitlement policy
- saved/cloud features, only if actually implemented

Do not mention model names or providers.

## 4. Create And Compose Flow

The first screen in the app should help the user begin writing immediately.

Create screen shape:

```text
Large title: What are you writing?
Subtitle: Pick an occasion or describe it yourself.

Search or choose occasion
Popular suggestions
Recent or favorites, later
Continue into compose
```

The compose experience should be a single progressive screen, not a rigid
multi-step wizard by default.

Recommended form structure:

```text
Occasion
Recipient
Relationship
Tone
Length
Details to include
Things to avoid
Spelling / locale preference
Generation mode

Generate message
```

Use native controls:

- searchable sheets for large taxonomies
- segmented controls for compact option sets
- menus or pickers for medium option sets
- grouped `Form` or custom grouped sections for editable details
- sticky bottom action when it improves reachability

Complex guided mode can come later as an optional sheet or alternate flow.

## 5. Occasion Catalogue Treatment

The full Flutter occasion catalogue should exist in the native domain layer.
It should not be shown as a giant grid or forty visible chips on the default
screen.

Native treatment:

- search-first occasion picker
- grouped sections
- popular suggestions on the Create screen
- recent and favorites later
- "Something else" free-text option later

Suggested groups:

- Popular
- Life events
- Milestones
- Seasonal
- Appreciation
- Cultural holidays
- Pets
- Work and school
- Hard moments

The search sheet should support quick scanning, clear labels, and short helper
copy where useful.

## 6. Results Experience

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
details.

## 7. Saved And History Experience

`Saved` should be a native list, not a dashboard.

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

The preferred v1 distinction:

- Saved means user-curated messages.
- History means all generated drafts and can live behind a filter if added.

Local saved messages can ship before cloud sync. Cloud sync belongs behind auth
and backend decisions.

## 8. Settings, Account, Subscription, And Legal

Settings should use a classic grouped iOS settings layout.

Suggested sections:

```text
Account
- Sign in with Apple
- Subscription
- Restore purchases

Writing
- Default spelling
- Default tone
- Saved messages behavior

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
- Native rewrite status
- Gateway contract version
```

Do not add analytics, crash reporting, Firebase, Supabase, RevenueCat, Sentry, or
provider SDKs just because the old app has related infrastructure. Each external
dependency needs a product reason.

## 9. Calendar And Reminders

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

## 10. Standard And Premium UI Treatment

Standard and Premium are product lanes.

Create screen treatment:

```text
Generation mode
[Standard] [Premium]
```

For free users:

```text
2 of 3 Standard generations left today
```

For Premium users:

```text
Premium generation active
```

If Premium is locked, tapping it should open the paywall sheet. The UI should
describe enhanced generation and limits, not providers or models.

Fallback copy:

```text
Enhanced generation was unavailable. We used Standard this time.
```

## 11. Loading, Retry, Timeout, And Degraded States

Generation should have explicit state handling:

- idle
- validating intent
- generating
- retrying
- succeeded
- usage limited
- timed out
- degraded to template or Standard
- failed

The user-facing message should be calm and actionable:

- try again
- edit details
- use Standard
- view saved draft
- contact support from Settings when appropriate

The client should not expose provider names, model names, raw backend errors, or
sensitive request content in logs or UI.

## 12. Intentional Differences From Flutter

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

## 13. Full-Parity Checklist

Required before replacing Flutter production:

- Full occasion catalogue
- Relationship taxonomy
- Tone taxonomy
- Length behavior and naming
- Spelling and locale preferences
- Recipient and personal detail capture
- Include and avoid detail fields
- Standard generation lane
- Premium generation lane
- Usage limits and entitlement-aware UI
- Retry, timeout, and degraded-generation UX
- Three-draft results flow
- Copy, share, edit, save, and regenerate actions
- Saved messages
- History decision: separate list or Saved filter
- Local persistence
- Auth strategy, likely Sign in with Apple first
- Subscription strategy, likely RevenueCat initially only if it earns continuity
- Backend/gateway contract
- Gateway request verification, auth, abuse controls, entitlement policy, and
  model router integration
- Account deletion and data export
- Legal and support surfaces
- App Store/TestFlight configuration
- Migration plan from Flutter production
- Native CI and deterministic test coverage

## Recommended PR Sequence

### PR 1: Native Create Experience

Scope:

- full native domain catalogue
- searchable and grouped occasion picker
- aligned relationship, tone, length, and spelling models
- calm progressive compose form
- fake/template gateway output respecting the expanded intent
- domain and request-construction tests

Exit criteria:

- `swift test` passes
- Xcode simulator build passes
- updated create-flow screenshots captured
- no Flutter app changes
- no real provider SDKs added

### PR 2: Results Polish And Local Saved Messages

Scope:

- polished draft cards
- copy/share/save/edit actions
- local saved-message store
- Saved tab list and detail
- confirmation states and basic haptics

Exit criteria:

- save, open, copy, share, and delete flows work locally
- unit tests cover saved-message model behavior
- screenshots cover results and saved flows

### PR 3: Usage, Paywall Placeholder, And Gateway Boundary

Scope:

- usage-limit state model
- Premium selection and paywall placeholder sheet
- retry, timeout, and degraded state UI
- gateway contract docs and client boundary hardening
- no real subscription SDK yet unless explicitly chosen

Exit criteria:

- all generation states are representable in UI
- no provider names in UI
- gateway contract remains provider-agnostic
- tests cover state transitions and request policy mapping
