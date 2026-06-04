# ProsePal iOS Native Product North Star

This document translates the current Flutter app into the target shape for the
SwiftUI rewrite.

Flutter remains the production behavior reference. SwiftUI is now the product
direction. The goal is not to clone Flutter screens. The goal is to preserve and
improve the product capability, emotional clarity, and proven interaction
behavior in a modern Apple-native app.

## Guiding Position

ProsePal iOS should feel like a calm, warm, premium writing assistant for real
human moments.

The product job is:

```text
Write a message for a real occasion.
```

Everything else supports that job:

- occasion selection
- relationship and tone
- personal context
- spelling preference
- Standard and Premium generation lanes
- generation feedback
- draft selection
- copy/share/save/edit
- saved messages and history
- account, subscription, support, privacy, and legal flows

The native app should be:

- SwiftUI-first
- iOS-first
- gateway-first
- dependency-light
- Apple-native where it matters
- recognizably ProsePal through the navy, coral, white, and warm asset system
- clear enough for emotional/sensitive occasions

It should not be:

- a Flutter screen clone
- a provider SDK client
- a model playground
- a pile of third-party SDKs
- a web form with tabs
- a neon AI console

## Non-Negotiables

- Preserve Flutter functionality before replacing production.
- Improve the experience where native iOS gives us a better pattern.
- Keep Standard and Premium as product lanes, not model names.
- Do not put provider, SDK, or model names in user-facing native UI.
- Do not add Firebase AI, Vertex AI, provider SDKs, analytics, crash reporting,
  RevenueCat, Supabase client code, or Sentry by default.
- The mobile app collects structured intent, calls the ProsePal gateway
  contract, renders `CardResponse`, and handles user-facing states.
- Gateway routing, provider fallback, model choice, abuse control, entitlement
  policy, and prompt/version decisions belong behind the gateway.

## What Flutter Currently Does

These behaviors are the product reference.

| Area | Flutter Behavior | Source |
| --- | --- | --- |
| Startup | Routes deterministically through splash/startup: onboarding, lock, auth restore, init error, or home. | `lib/app/router.dart` |
| Onboarding | Three value-focused pages with existing ProsePal artwork, progress, and deferred paywall/value-first intent. | `lib/features/onboarding/onboarding_screen.dart` |
| Home | Occasion-first surface: header, usage state, search field, full occasion grid. | `lib/features/home/home_screen.dart` |
| Occasion selection | Full catalogue is visible through searchable grid; selecting clears search, dismisses keyboard, and starts generation. | `lib/features/home/widgets/occasion_grid.dart` |
| Keyboard on Home | Search uses text keyboard, word capitalization, Done action, tap-outside dismissal, clear button, and one-shot return-home keyboard dismissal. | `lib/features/home/home_screen.dart`, `lib/shared/utils/keyboard_utils.dart` |
| Generate | Three-step flow: Relationship -> Tone -> Details. Bottom CTA only appears when current step is valid. | `lib/features/generate/generate_screen.dart` |
| Relationship | Full-screen step with list-style selectable relationship tiles. | `lib/features/generate/widgets/relationship_picker.dart` |
| Tone | Two-column tone grid with label and short description. | `lib/features/generate/widgets/tone_selector.dart` |
| Details | Recipient, personal details, length selector, max lengths, text capitalization, scroll padding, tap-outside dismissal. | `lib/features/generate/widgets/details_input.dart` |
| Usage | Free users see remaining count and upgrade affordance; Pro users see compact `PRO` badge. | `lib/shared/components/usage_indicator.dart` |
| Results | Context header, 3 generated options, selectable text, Share secondary, Copy primary, Start Over, Regenerate/Unlock Pro. | `lib/features/results/results_screen.dart` |
| Copy payoff | Copy shows explicit confirmation; first copy triggers celebration and value-boundary paywall timing. | `lib/features/results/results_screen.dart` |
| Regenerate | Regenerate is Pro-gated; free users see Unlock Pro. | `lib/features/results/results_screen.dart` |
| History/Saved | Generation history is auto-saved and browsable; copy/delete are supported. | `lib/features/history/history_screen.dart`, `lib/core/services/history_service.dart` |
| Calendar/reminders | Users can save occasions/reminders and get upcoming occasion behavior. | `lib/features/calendar/`, `lib/core/services/calendar_service.dart` |
| Settings | Account, subscription, spelling, biometric lock, privacy, feedback, legal, support, delete/export flows. | `lib/features/settings/` |

## What Flutter Got Right

Flutter's strongest product decisions are not about Flutter itself. They are
about the shape of the task.

### Occasion Comes First

The home screen is not a dashboard. It asks one question:

```text
What's the occasion?
```

That matters. ProsePal is not primarily a chat box. It is a structured writing
assistant for known human moments.

Native should preserve this priority even if the visual treatment changes.

### Search Is Central

Flutter lets users search the full occasion catalogue directly on Home. This
keeps the large catalogue usable without overwhelming the user.

Native should keep full catalogue access fast, searchable, and obvious. It can
use a sheet or in-page search, but it should not hide the catalogue behind
ambiguous chips or repeated selectors.

### Keyboard Handling Is Deliberate

Flutter does not rely on default keyboard behavior alone. It:

- dismisses keyboard on tap outside
- dismisses on submit/editing complete
- gives text fields bottom scroll padding
- sends a one-shot signal to dismiss stale Home search focus after returning
- dismisses keyboard before generation and navigation

Native should match the intentionality, not the exact implementation.

### Results Are The Payoff

Flutter results make the user's next action obvious:

- read the options
- copy the best one
- share if needed
- start over or regenerate

Copy has the visual priority because it is the core activation event.

Native should preserve that hierarchy. Edit and Save are useful, but they should
not make the primary copy/share decision feel busy.

### Value Before Paywall

Flutter has moved toward letting users experience value before monetization
pressure. First meaningful copy is a natural value boundary.

Native should keep this stance unless product strategy explicitly changes.

## Where Native Should Improve

SwiftUI should not copy Flutter screen-for-screen. The native rewrite should
reinterpret the same product capability with Apple-native patterns.

| Flutter Pattern | Native Interpretation |
| --- | --- |
| Home occasion grid | Occasion-first Create surface with native search/browse. A grid can exist where useful, but should not be busy or duplicated. |
| Three-step wizard | Default native flow can be a progressive compose screen. Guided mode can come later for complex messages. |
| Custom cards/buttons everywhere | Use native lists, forms, sheets, toolbars, context menus, `ShareLink`, and grouped settings where they fit. |
| Copy/share only on results cards | Keep Copy primary, Share secondary, and add Edit/Save as thoughtful native secondary actions. |
| Gemini attribution | Remove provider/model attribution from user-facing native UI. |
| Firebase AI client-direct | Use ProsePal gateway only. |
| Flutter persistence/services | Rebuild only the app-owned behavior needed for native, with Apple-native storage where appropriate and backend contracts where required. |

## Native App Shape

Target app flow:

```text
Launch
  -> first launch? onboarding
  -> lock required? biometric lock
  -> otherwise Create

Tabs
  Create
  Saved
  Settings

Create
  -> choose/search occasion
  -> compose intent
  -> generate
  -> drafts/results

Saved
  -> saved messages
  -> saved/history filter later
  -> message detail

Settings
  -> account
  -> subscription
  -> writing preferences
  -> privacy/support/legal
```

Future tab only if earned:

```text
Reminders
```

## Native Create North Star

The Create tab should preserve Flutter's full option set while feeling more
native and calmer. Recipient and relationship context should lead the emotional
shape; occasion still provides the catalogue and message structure.

Recommended structure:

```text
Find the right words
For a card, text, note, or the message you have not quite found yet.

Who is it for?

Selected occasion summary
[Browse occasions]

Compose
- Relationship
- Tone
- Length
- Details to include
- Things to avoid
- Extra context

Generation
- Standard
- Premium
- usage state

[Write message]
```

Avoid duplication. The native Create screen should not show:

```text
Birthday hero
Birthday selector
Birthday chip carousel
```

One clear occasion selection path is enough.

Recommended native approach:

- Keep one selected occasion summary.
- Keep one search/browse affordance.
- Put Most Used and full catalogue inside the occasion picker.
- Remove the visible featured-chip carousel from the main Create screen.
- Keep all Flutter relationship and tone options visible on the Create screen
  or one tap away with no multi-step hunting. The current native direction is
  visible compact choices.
- Keep spelling in Settings as a writing preference; do not add it to the
  generation-time tap budget.
- Consider an in-page search field if the Create tab becomes too hidden behind
  a sheet.

## Native Occasion Picker North Star

The picker should make the full Flutter catalogue easy to scan without dumping
forty choices on the first screen.

Use:

- `.searchable`
- grouped `List`
- recent/favorites later
- short user-facing descriptions
- checkmark for current selection
- medium and large sheet detents

The picker should preserve Flutter catalogue coverage and ordering signal:

- Most Used
- Common Life Events
- Milestones
- Life Changes
- Seasonal
- Specific Situations
- Appreciation
- Cultural Holidays
- Pets

## Native Relationship And Tone North Star

Relationship and tone are small enough to be explicit choices, but large enough
that default dropdowns feel lazy.

Native treatment:

- relationship sheet grouped by Personal, Professional, Community
- tone sheet or compact grid with label and short description
- no exposed prompt language
- selected state is obvious
- tap choice dismisses sheet

Flutter's relationship/tone screens are good behavioral references. Native can
keep them as sheets or inline cards depending on final Create density.

## Native Details And Keyboard North Star

The keyboard behavior should feel intentional on-device.

Native requirements:

- active field is never hidden by keyboard
- Write is reachable while typing, preferably in keyboard toolbar
- sticky Write Message does not clash with tab bar
- tap outside dismisses keyboard where the platform supports it cleanly
- submit/done dismisses keyboard
- returning from Results or sheets should not leave stale focus behind
- long context remains bounded and scrollable

Flutter's `scrollPadding` and explicit dismissal are the behavioral reference.
SwiftUI should use:

- `@FocusState`
- `.scrollDismissesKeyboard(.interactively)`
- `.toolbar(placement: .keyboard)`
- `.safeAreaInset`
- enough bottom scroll padding
- field-specific focus management where needed

## Native Results North Star

Results should be the emotional payoff.

Target hierarchy:

```text
Messages for Alex
Birthday - Parent
Heartfelt tone

Option 1
[message]
[Share] [Copy]

Option 2
[message]
[Share] [Copy]

Option 3
[message]
[Share] [Copy]

[Start Over] [Regenerate / Unlock Premium]
```

Native enhancements:

- `Copy` remains the primary action.
- `Share` remains visible and secondary.
- `Edit` and `Save` are available, but should not crowd the primary row.
- Use context menu for secondary actions where appropriate.
- Use `ShareLink`.
- Show explicit copied/saved confirmation.
- Use subtle haptics for copy/save.
- Keep generated text selectable.
- Keep the context header visible enough to orient the user.

The native results screen should not mention provider/model names. It should
show lane-level status only when helpful:

```text
Standard generation
Premium generation
Generation used a backup route. Try again shortly.
```

## Native Saved And History North Star

Flutter separates generated history behavior from saved/useful messages. Native
should simplify without losing capability.

Recommended native model:

- Saved tab is user-curated by default.
- History can become a filter or section inside Saved.
- Message rows show occasion, recipient, preview, and date.
- Detail supports copy, share, edit, delete.
- Local persistence can ship first.
- Cloud sync waits for auth/backend decisions.

Before replacing Flutter production, native must cover whichever history/save
behavior the product keeps.

## Native Calendar And Reminders North Star

Flutter has calendar/reminder capability. Native should not force it into the
first rewrite shape, but it must not be forgotten.

Native treatment:

- defer primary tab until reminders are mature
- use native list/detail patterns
- request notification permission only when user creates a reminder
- support upcoming occasions and last-generated metadata if retained
- consider a future Reminders tab only when the feature is central

## Native Settings North Star

Settings should feel like iOS Settings: grouped, predictable, and quiet.

Recommended sections:

```text
Account
- Sign in with Apple
- Subscription
- Restore purchases

Writing
- Spelling
- Default tone
- Default generation mode

Privacy
- Analytics, only if added
- Crash reports, only if added
- Export data
- Delete account

Support
- Send feedback
- Help
- Terms
- Privacy Policy

About
- Version
- Build
```

Do not show internal runtime language in normal UI. Developer diagnostics can
live behind a debug-only surface later.

## Dependency Philosophy

No dependency hostages.

Default to:

- Swift
- SwiftUI
- Swift Concurrency
- Foundation
- URLSession
- Swift Package Manager
- Apple platform APIs

Use Apple-native features when they improve the product and fit the deployment
target:

- `NavigationStack`
- `.searchable`
- sheets and detents
- `ShareLink`
- context menus
- `@FocusState`
- native haptics
- `UserDefaults` for small local state
- SwiftData only when local persistence needs a real model layer
- AppIntents only when shortcuts become product-relevant
- StoreKit only if direct App Store subscription handling is chosen

Evaluate third-party dependencies only when they earn their keep:

- RevenueCat may stay initially for entitlement continuity.
- Supabase may stay for backend/auth/data if it remains the product backend.
- Firebase should not be carried forward by default.
- Firebase AI / Vertex AI client-direct is not part of the native target.
- Provider SDKs do not belong in the client.
- Analytics/crash tooling requires a clear privacy and operational rationale.

## Gateway Contract Philosophy

The native app depends on message-writing capability, not a provider.

Target architecture:

```text
SwiftUI client
-> ProsePal API / Edge Function
-> request verification
-> auth and abuse controls
-> entitlement and usage policy
-> AI Gateway / Model Router
-> provider adapters
-> Standard, Premium, local, or template lane as backend policy
```

Client responsibilities:

- collect structured intent
- send `CardRequest`
- render `CardResponse`
- handle loading, timeout, retry, usage limits, and degraded states
- never log sensitive user content
- never expose provider/model names

Gateway responsibilities:

- provider choice
- fallback routing
- prompt construction
- output validation
- entitlement enforcement
- abuse controls
- provider secrets
- model/version experimentation

## Current Native Drift To Correct

The current native prototype is promising, but this drift should be corrected:

- Create duplicates occasion selection through hero, selector row, and chip
  carousel.
- Results expose many actions equally; Copy should regain primary hierarchy.
- Native Create is form-forward; Flutter proves occasion-first matters.
- Keyboard behavior is improved but should be treated as a core test oracle.
- Settings copy is cleaner, but full auth/subscription/privacy behavior is not
  there yet.

The next native UI implementation slice should remove occasion duplication and
reshape Create around a single occasion-first path.

## Review Oracles

Use these as pass/fail checks for native UI work:

- First launch reaches onboarding.
- Returning launch reaches Create.
- Occasion selection is obvious within the first screen.
- Full occasion catalogue is searchable.
- Selecting an occasion clears search/focus and moves the user forward.
- Relationship and tone are easy to change.
- Active text fields remain visible with keyboard open.
- Write remains reachable without covering active fields.
- Write calls the gateway when `PROSEPAL_GATEWAY_URL` is configured.
- Results show 3 drafts.
- Copy is the most obvious per-draft action.
- Share remains available.
- Edit and Save remain available without crowding Copy.
- Start Over returns to Create/Home without stale keyboard focus.
- Regenerate/Premium boundaries are product-lane based, not provider based.
- No provider/model names appear in user-facing UI.
- No raw prompt or user card content is logged.

## Near-Term Native Direction

The next few native PRs should move in this order:

1. Create occasion-first cleanup
   - remove main-screen occasion chip duplication
   - keep one selected occasion summary
   - make search/browse the primary catalogue path
   - preserve full catalogue in the picker

2. Results hierarchy pass
   - restore Copy as primary
   - keep Share secondary
   - move Edit/Save into secondary/context actions where appropriate
   - add a stronger context header
   - add bottom Start Over + Regenerate/Unlock lane action

3. Keyboard/device oracle pass
   - add explicit focus dismissal checks
   - test home/create return focus
   - validate on tethered iPhone
   - capture screenshots for keyboard-open fields and results actions

4. Saved/history decision pass
   - decide Saved-only, History-only, or Saved with History filter
   - implement local persistence behavior that maps to the chosen product model

5. Entitlement/auth/subscription slice
   - keep dependency-light until the boundary is chosen
   - prefer Sign in with Apple first
   - evaluate RevenueCat only for entitlement continuity
   - keep gateway in charge of usage policy
