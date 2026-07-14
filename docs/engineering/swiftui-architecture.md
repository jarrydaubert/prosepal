# SwiftUI Architecture Standard

This document defines how ProsePal's native SwiftUI code is organised and how
features evolve. It is a repository-specific standard, not an architecture
acronym. The default is plain SwiftUI views, Observation-backed state, explicit
dependencies, provider-neutral services, and small testable contracts.

The module-level dependency direction remains defined in
[Native architecture](./architecture.md). This document owns the conventions
inside `ProsePalUI` and the seams between UI, domain, services, persistence, and
the app target.

Apple's current guidance underpins the state model: observable data separates
model state from views, local UI state belongs in the view hierarchy, and task
cancellation is cooperative rather than automatic. See
[Managing model data](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app),
[Managing user interface state](https://developer.apple.com/documentation/swiftui/managing-user-interface-state/),
and [`Task.cancel()`](https://developer.apple.com/documentation/swift/task/cancel()).

## Feature and folder organisation

New or extracted UI code uses this shape when the corresponding boundary
exists. Do not create empty folders or one-file directories in anticipation of
future work.

```text
Sources/ProsePalUI/
  AppShell/                 app-root navigation and launch presentation
  Features/
    <Feature>/
      <Feature>View.swift   the feature entry surface
      <Feature>Components.swift  feature-private presentation pieces, if needed
      <Feature>Preview.swift     preview setup, when setup is substantial
  Components/               UI used by at least two independent features
  Styling/                  semantic adaptive tokens and shared surfaces
  Support/                  UIKit/AppKit bridges and other UI infrastructure
```

The existing flat files migrate only when their surface is touched and the
boundary is safe. A feature earns a folder when it has its own user job,
dependencies, state or navigation, preview, and test boundary. A small helper
stays beside its owner. A component moves to `Components/` only after two real
features need the same behaviour and visual contract.

`ProsePalDomain` continues to own stable product data and pure rules.
`ProsePalAPI` continues to own protocols, service implementations, actors,
transport, StoreKit, auth, runtime configuration, and persistence services.
`App` continues to own target-specific dependency composition, lifecycle,
entitlements, and production/staging configuration.

Current extracted feature ownership is intentionally small and concrete:

| Feature | Ownership |
|---|---|
| `Features/Settings/` | Settings shell, truthful static-row presentation, account/subscription entry actions, and deterministic preview setup. Destinations still named in the migration map remain transitional dependencies. |
| `Features/SavedDrafts/` | SwiftData query ownership, local search and disclosure state, list/detail navigation, edit/delete persistence coordination, feature components, and deterministic list/detail previews. The persisted `SavedMomentDraftRecord` and versioned schema remain owned by `ProsePalAPI`. |

Shared empty, hero, and detail-card presentation used by more than one feature
lives in `Components/`. `Support/MomentSharing.swift` owns the pure Copy/Share
presentation and diagnostics policy used by draft surfaces; the views themselves
use SwiftUI `ShareLink`, with no custom activity-controller bridge. Neither owns
feature state or persistence.

## Views and state ownership

Every mutable value has one owner.

| Kind of state | Owner and pattern |
|---|---|
| App-lifetime workflow state | The app root creates an `@Observable` model and stores it in `@State`, as `MomentAppRootView` does for `MomentModel` and `MomentAccountModel`. |
| Shared feature workflow state | A focused `@MainActor @Observable` model owns transitions and side effects; child views receive it explicitly and use `@Bindable` only when they mutate it. |
| SwiftData collection state | The feature surface reads with `@Query` and obtains `modelContext` from the environment. It does not mirror the fetch into another model. |
| Transient presentation state | The narrowest owning view uses private `@State`, `@FocusState`, or a binding: sheet presentation, selection, search text, disclosure, and focus. |
| Pure derived state | A computed property or domain value, with no storage and no side effect. |
| Cross-feature configuration | A small immutable value or an explicitly injected environment dependency, not a global mutable singleton. |

Do not add a view model merely because a view is long. First extract dedicated
subviews and move real state transitions into the existing workflow model or
service. A new presentation model is justified only when multiple views share a
long-lived presentation-specific state machine that is not already domain,
service, persistence, or app state.

Views render observable state and translate gestures into named intent. A view
body must not contain quota policy, routing decisions, persistence rules,
provider behaviour, or non-trivial async workflows. Button actions call a small
method or model intent rather than embedding business logic inline.

## Service and dependency boundaries

- UI generation flows depend on `MessageWritingService`; provider and model
  details remain in `ProsePalAPI` or the gateway.
- Auth, subscription, account maintenance, relationship memory, and export use
  their existing protocols or focused persistence functions. Views do not
  instantiate network, StoreKit, Keychain, or provider clients.
- The app target constructs concrete dependencies once and passes observable
  models into the root UI. Feature views receive the smallest useful model,
  value, binding, or callback rather than a service locator.
- Dependencies used by asynchronous code conform to `Sendable` or are isolated
  by an actor. UI-owned mutable state is main-actor isolated.
- Typed domain or API errors become user-safe state before presentation. Views
  do not inspect HTTP status codes, provider payloads, or raw system errors.

Protocol extraction must follow a real substitution need such as production
versus test, private versus careful generation, or Apple versus fallback
implementation. Do not introduce `Manager`, `Coordinator`, `Helper`, or
`Repository` wrappers that only rename an existing dependency.

## Navigation ownership

`MomentAppRootView` owns onboarding versus app presentation, root tab selection,
deep-link consumption, and sanitized system-surface handoff. Root destinations
use native `TabView` and `NavigationStack` state; there is no parallel navigation
coordinator.

A feature owns destinations, sheets, dialogs, and focus that exist only inside
that feature. It exposes a callback when an action crosses a feature boundary,
such as opening another root tab. The least common ancestor owns state shared by
two destinations. Navigation state must not be duplicated in a model and a
view.

Prefer system navigation and toolbar placements for navigation chrome. Custom
paper-like content remains a feature presentation choice, but custom chrome
must not reimplement platform navigation, focus, or accessibility behaviour.

## Persistence and recovery ownership

SwiftData owns deliberate saved data: Truth Beads, Voice Cards, and saved
drafts. Schema changes go through `RelationshipVaultSchema` and
`RelationshipVaultMigrationPlan`; no view may introduce or mutate an `@Model`
contract without the corresponding versioned migration.

Active draft recovery is a separate, versioned recovery envelope owned by
`MomentDraftRecoveryState`, `MomentDraftRecoveryStoring`, and `MomentModel`. It
must not silently become saved history. The workflow model decides when a state
is recoverable and when stale recovery is cleared; a view only reports user
intent.

Persistence operations that have failure semantics belong in focused functions
or services so success, rollback, cancellation, and error propagation can be
tested without rendering a view. A view may coordinate `modelContext`, but it
must not report success until persistence succeeds.

## Concurrency and cancellation

- A model or service that starts async work owns the task handle and its
  cancellation policy.
- `MomentModel` is the universal owner for initial draft, retry, rewrite, and
  named-adjustment tasks. Views send named intent such as Stop; they never wrap
  generation calls in their own `Task`.
- Meaning-bearing input changes cancel obsolete generation and invalidate late
  results. `MomentModel`'s generation counter is the current pattern for
  suppressing stale completion.
- Child operations use structured concurrency. Cancellation is propagated and
  checked at appropriate suspension or computation boundaries; calling
  `cancel()` alone is not assumed to stop arbitrary work.
- Shared mutable session, auth, key, and persistence state is actor-isolated.
- Views use `.task` or `.task(id:)` only for lifecycle-bound orchestration. A
  detached or unbounded task may not own feature behaviour.
- Timeouts and clocks are injected when timing affects correctness. Tests wait
  on deterministic signals or explicit deadlines, never an unbounded poll.
- Backgrounding, dismissal, retry, and input mutation each have an explicit
  owner for cancellation and late-result suppression.

## Design system and feature components

Shared visual primitives use semantic, adaptive styling from
`MomentVisualTokens`, `MomentBackgrounds`, `MomentSectionChrome`, and related
component files. New user-facing copy uses localization-safe APIs. New colours
are semantic and adaptive.

A feature component may combine product meaning with shared primitives. It
stays in the feature even when visually similar to another surface until the
behavioural contract is genuinely shared. Do not generalise two views merely
because both contain a rounded rectangle.

Shared components accept content, values, bindings, and actions. They do not
reach into `MomentModel`, account state, SwiftData, or provider services unless
that dependency is the component's explicit reason to exist.

## Preview expectations

Every extracted user-facing surface has a compiling `#Preview`. The preview:

- constructs observable owners with deterministic local or mock dependencies;
- uses `RelationshipVaultContainerFactory.makeEphemeral()` when SwiftData is in
  the rendered hierarchy;
- contains no remote request, Keychain, App Store account, or production
  configuration requirement;
- demonstrates a representative state, and adds another named state only when
  it exposes a materially different branch; and
- lives beside the feature, or in `<Feature>Preview.swift` when setup would
  obscure the production view.

Previews are development evidence, not substitutes for behavioural or release
tests.

## Testing expectations

Test the narrowest layer that owns the behaviour:

1. Pure domain and presentation contracts for deterministic transformation and
   copy/state semantics.
2. Service and observable-model tests for async workflows, cancellation,
   persistence, errors, and late-result suppression.
3. View rendering tests for stable composition where they add useful coverage.
4. Identifier-driven UI automation for navigation wiring, system presentation,
   destructive confirmation, accessibility, and other behaviour visible only
   in a running app.
5. Physical-device or TestFlight evidence for Apple runtime, StoreKit, auth,
   accessibility, and system-surface behaviour that cannot be proven locally.

Source inspection is valid for structural facts such as target membership,
entitlements, build phases, or banned dependencies. It is not behavioural proof
that a button is reachable or calls the correct action. When a surface is
extracted, replace its monolith source-string guard with a behavioural contract
or real view/UI coverage in the same change where practical.

The app target owns one deterministic UI-automation composition seam. It is
compiled only in DEBUG and activates only with the explicit UI-testing marker
and a named scenario. Scenarios may substitute ephemeral persistence and
in-memory protocol implementations for auth, writing, subscription, and account
maintenance, but must not add production runtime switches or bypass the view's
real user actions. Stable identifiers name user outcomes and controls; they do
not encode exact copy, layout hierarchy, or transient composer steps.

## Extraction checklist

An incremental extraction is complete only when:

- one named responsibility and its feature-private presentation helpers leave
  the monolith;
- inputs and outputs are explicit, and dependencies still point in the approved
  module direction;
- behaviour, accessibility semantics, localization behaviour, adaptive styling,
  production/staging separation, persistence, and recovery contracts remain
  unchanged unless the task explicitly changes them;
- a compiling preview exists for the extracted user-facing surface;
- meaningful behavioural coverage protects the moved contract;
- obsolete monolith source-string coverage is removed where a stronger seam now
  exists;
- the monolith line-count and source-string-reference ratchets are lowered to
  exact new values;
- the region map and owning documentation are updated; and
- focused tests, the full Swift package, and the app target build pass.

## Anti-patterns

Do not introduce:

- a big-bang rewrite of `MomentExperienceView.swift`;
- a view model for every view or a view model that mirrors `@State`, `@Query`,
  environment values, or an existing observable model;
- monster models, coordinators, managers, helpers, routers, or service locators;
- business rules, persistence success claims, provider decisions, or substantial
  async work inside `body` or inline control actions;
- provider/model names or third-party provider SDKs in `ProsePalUI`;
- parallel sources of truth for navigation, selection, persistence, recovery,
  entitlement, or generation state;
- global mutable state for feature convenience;
- unstructured tasks without a clear owner, cancellation path, and stale-result
  policy;
- source-string tests that claim to prove user behaviour;
- shared abstractions with only one real consumer; or
- file splitting that creates many tiny wrappers without improving ownership,
  testability, previewability, or reason to change.
