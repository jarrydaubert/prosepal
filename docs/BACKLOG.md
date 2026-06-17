# Backlog

Only open work items live here.

Active product direction:

- `prosepal-ios/` is the active native iOS product path.
- The native direction is greenfield, iOS 26-first, person-first, and centered
  on the Moment Sheet.
- The existing Flutter app remains in the repository, but it is not the native
  UX source of truth. Flutter work belongs here only when it protects live
  production, supports backend ownership, or provides explicit replacement
  evidence.

## Rules

- No status updates, progress notes, or completed work.
- No placeholder rows for work that is not part of the active native direction.
- Every item must include a clear, testable Definition of Done.
- If an item changes runtime behavior, its Definition of Done must name the
  regression protection: automated coverage at the right layer, or an explicit
  replacement evidence path with a named bug target and oracle.
- When an item is complete, remove it from this file in the same change set.

## Global Definition Of Done

Every backlog item is complete only when all conditions below are true:

1. Outcome is delivered exactly as written.
2. Regression protection is added or explicitly justified.
3. Relevant deterministic validation passes.
4. Evidence is attached through logs, screenshots, CI run IDs, release
   artifacts, or a named manual evidence path.
5. The completed item is removed from this file.

## Active Priority Order

1. `N-IOS-01` Moment Sheet foundation
2. `N-IOS-02` Private draft lane
3. `N-IOS-03` Take more care lane
4. `N-IOS-04` Relationship vault, Truth Beads, and Voice Card
5. `N-IOS-05` Careful Mode, Pressure Check, and crisis path
6. `N-IOS-06` Out-of-app native surfaces
7. `N-IOS-07` StoreKit 2 and server entitlement
8. `N-IOS-08` Sign in with Apple, account, deletion, and export
9. `N-IOS-09` Saved, settings, privacy, support, and legal
10. `N-IOS-10` Native iOS 26 CI, TestFlight, and release evidence
11. `N-IOS-11` Privacy-safe diagnostics and observability
12. `N-IOS-12` Legacy grouped-form removal

## Native iOS Release Gates

| ID | Item | Definition of Done |
|----|------|--------------------|
| `N-IOS-01` | Moment Sheet foundation | The native app opens into a person-first Moment Sheet rather than the grouped Create form. The flow captures person, relationship, moment, one true thing, tone/register, and delivery intent with no provider/model language. The old occasion catalogue is available underneath the moment selection without becoming the home screen. The Moment Sheet is implemented in split SwiftUI files with `@Observable` state and a `MessageWritingService` boundary. DoD requires Swift tests for moment state transitions, request construction, and surface entry points; simulator build; and physical iPhone evidence for one-handed layout, keyboard behavior, Dynamic Type, and copy/share/send controls. |
| `N-IOS-02` | Private draft lane | Everyday moments can produce a private draft through the native on-device generation path when available. Foundation Models availability is checked at runtime, typed output is used where supported, and unavailable devices receive an honest state without fake template generation. The draft can be adjusted with warmer, shorter, and more direct actions through the same service boundary. DoD requires real-device quality evidence, capability/unavailable tests, privacy-safe diagnostics, and no raw content logging. |
| `N-IOS-03` | Take more care lane | Harder or sensitive moments can escalate through the careful lane without exposing provider/model names. The staging gateway remains usable for cloud/careful testing, invalid/no secret fails closed, provider/model fields are not exposed to the client, and raw prompt/card/generated content is not logged. DoD requires `./scripts/prosepal-staging-smoke.sh`, gateway response mapping tests, timeout/cancel/retry tests, and physical iPhone evidence for escalation and recovery states. |
| `N-IOS-04` | Relationship vault, Truth Beads, and Voice Card | SwiftData stores user-approved relationship memory, Truth Beads, and Voice Card preferences locally. Memory can be added, edited, corrected, deleted, and explained through "why am I seeing this?" affordances. Contacts/Calendar enrichment remains off by default and cannot silently infer memory. DoD requires model tests, deletion/export behavior, privacy review, and device evidence for edit/delete/correction flows. |
| `N-IOS-05` | Careful Mode, Pressure Check, and crisis path | Sensitive moments use a calmer interaction mode, subtractive Pressure Check feedback, and crisis redirection where appropriate. The app generates less for grief, apology, estrangement, or crisis-adjacent input and preserves more of the user's own words. No guilt mechanics, streaks, relationship scores, or grief nudges are introduced. DoD requires safety copy review, classifier/typed-output tests where applicable, human-reviewed examples, and accessibility evidence. |
| `N-IOS-06` | Out-of-app native surfaces | App Intents, Siri/Shortcuts, WidgetKit, Control Center controls, and Share extension routes can create or resume a Moment Sheet without exposing private text in logs or widget surfaces. Gestures and OS surfaces are accelerators; every action also has an accessible visible control in app. DoD requires extension tests where available, manual device evidence for each OS surface, privacy review, and fallback behavior for unavailable capabilities. |
| `N-IOS-07` | StoreKit 2 and server entitlement | The native app uses StoreKit 2 for product loading, purchase, restore, pending, cancellation, and local transaction state. Server entitlement remains authoritative for careful/Premium gateway access through App Store Server Notifications V2 and reconciliation. Purchase is not blocked behind mandatory app sign-in, and paywall price, period, Terms, and Privacy are review-safe. DoD requires StoreKit local and sandbox evidence, server entitlement tests, App Review copy/legal verification, and no RevenueCat dependency. |
| `N-IOS-08` | Sign in with Apple, account, deletion, and export | Sign in with Apple works on a physical iPhone through the configured staging auth provider. Signed-in state persists, clears on sign out, and cannot be faked. Account deletion and data export are available once account creation is available. A new user never inherits another user's entitlement, usage, telemetry, saved account state, or pending sync state. DoD requires unit tests for success/cancel/failure/relaunch/sign-out/account-switch paths, wired iPhone evidence, and no token/content exposure. |
| `N-IOS-09` | Saved, settings, privacy, support, and legal | Saved is explicitly user-curated unless a separate history decision is approved. Settings covers Account, Subscription, Restore, Writing preferences, Privacy, Support, Legal, About, data export, and delete account in native iOS patterns. Support/feedback never attaches message content unless the user explicitly chooses it. DoD requires Swift tests for state, wired iPhone screenshots, legal-link verification, and diagnostic payload review. |
| `N-IOS-10` | Native iOS 26 CI, TestFlight, and release evidence | Native Swift tests and simulator builds become the correct blocking gates before TestFlight or release-candidate work. The release evidence path captures version/build, Swift tests, simulator build, physical iPhone smoke, gateway config summary with no secrets, auth evidence, purchase/restore evidence, App Store Connect review, TestFlight sanity, secret audit, rollback plan, and owner sign-off. DoD requires workflow updates, `docs/DEVOPS.md` updates, and a dry-run evidence bundle. |
| `N-IOS-11` | Privacy-safe diagnostics and observability | Diagnostics cover launch, Moment Sheet, private draft, take-more-care, auth, purchase, restore, support, settings, OS surfaces, and gateway legs without logging raw recipient names, include/avoid/context fields, prompt text, generated drafts, tokens, receipts, provider payloads, provider keys, or provider/model IDs. Any analytics/crash SDK decision requires an ADR and privacy rationale before adding a dependency. DoD requires event schema review, redaction tests where applicable, device-console evidence, and updated diagnostics docs. |
| `N-IOS-12` | Legacy grouped-form removal | Once the Moment Sheet covers the core loop, the grouped Create/Results scaffolding is removed rather than maintained as a fallback product. Reusable catalogue, gateway, StoreKit, auth, saved-message, and diagnostics foundations are retained where they fit the new architecture. DoD requires no active navigation path to the legacy grouped form, no stale docs pointing to it, simulator build, Swift tests, and physical iPhone smoke of the replacement flow. |

## Flutter Production Work

Add Flutter work here only when needed for a production hotfix, production
security issue, live service ownership requirement, or explicit replacement
evidence. The Flutter screens and interaction model are not the native iOS
design source of truth.
