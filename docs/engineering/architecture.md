# Native Architecture

ProsePal is an iOS 26-first SwiftUI application with a Swift package supplying
domain, service, and UI modules. The app target composes concrete Apple and
Supabase clients at the root; feature views depend on provider-neutral
boundaries.

## System map

```text
ProsePal app target
  -> MomentAppRootView
     -> MomentModel
        -> MessageWritingService
           -> FoundationModelsPrivateDraftClient
           -> GatewayCarefulMomentClient
              -> GatewayMessageWritingClient
     -> MomentAccountModel
        -> AuthSessionController / SupabaseAuthClient
        -> AppleAccountLifecycleClient / AppleCredentialStateProviding
        -> StoreKitSubscriptionClient
        -> SupabaseAccountMaintenanceClient
     -> SwiftData relationship vault

Optional entry points
  -> App Intent / Shortcuts
  -> Widget and Control
  -> Share Extension
  -> sanitized Moment launch request
```

Their handoff and trust boundary is documented in
[System surfaces](./system-surfaces.md).

## Module responsibilities

| Module | Responsibility |
|---|---|
| `ProsePalDomain` | Stable product taxonomy, card contracts, text limits, Moment input, draft bundles, pressure feedback, and the extension-safe launch/input handoff contract. |
| `ProsePalAPI` | Generation routing, gateway transport, Foundation Models, auth/session control, StoreKit, runtime configuration, and vault services. |
| `ProsePalUI` | SwiftUI surfaces and observable app models; it does not know provider SDKs or privileged backend details. |
| `App` | Dependency composition, target configuration, entitlements, assets, and application lifecycle. |
| `supabase/functions` | Authenticated server boundaries for generation, account deletion, Apple-token exchange, feedback, and App Store events. |
| `supabase/migrations` | Database policy, quota, entitlement, request-ledger, privilege, and cleanup changes. |

## State ownership

`MomentModel` owns the active Moment, generation state, retry state, current
draft, and draft snapshots. Every initial draft, retry, rewrite, and named
adjustment enters the same retained task lifecycle. Stop/reset,
meaning-bearing input mutation, composer dismissal, app backgrounding, and a
superseding request cancel that task; generation identity suppresses late
results even when a dependency returns after cancellation.

`MomentAccountModel` owns sign-in presentation, current account state, Apple
credential-state reconciliation and revocation events, subscription products,
explicit active/inactive/unknown entitlement state, same-account last-known-good
access, transaction convergence, account-switch invalidation, and
account-maintenance actions. `StoreKitSubscriptionClient` owns StoreKit reads and
deferred transaction delivery; only the account model decides when correlated
delivery is safe to finish.

SwiftData owns Truth Beads, Voice Cards, and deliberately saved drafts. Active
draft recovery is separate so relaunch recovery does not silently turn every
generation into saved history. See [Relationship vault](./relationship-vault.md)
for persistence, migration, export, and prompt-memory rules.

## Dependency rules

- SwiftUI calls `MessageWritingService`, never a provider SDK.
- Product code uses `SubscriptionClient`, `AuthClient`,
  `AppleAccountLifecycleClient`, `AppleCredentialStateProviding`, and
  `AccountMaintenanceClient` protocols so tests can remain deterministic.
- Provider/model details stay behind the gateway or Foundation Models client.
- Privileged Supabase keys stay in Edge Functions and never enter an app
  bundle.
- Runtime failures become typed, user-safe domain errors before reaching views.

## Concurrency and cancellation

The native package uses Swift 6 concurrency. Actor-isolated session, request-key,
and model state serialize shared mutations. `GenerationTimeoutPolicy` applies
per-lane budgets inside one total technical deadline; structured task groups
cancel the losing operation before any eligible fallback begins. Private and
gateway clients check cancellation around memory, request-key, transport, and
response boundaries. The Edge Function combines the incoming request signal
with its provider timeout, stops the fallback-model loop on cancellation, and
finalizes an existing ledger reservation as failed rather than consuming usage.

## Data boundaries

```text
User-entered content
  -> active Moment memory
  -> Foundation Models on device, or sanitized gateway request
  -> optional explicit local save

Operational metadata
  -> privacy-safe OSLog / Edge logs
  -> no raw names, message text, tokens, receipts, or provider payloads
```

See [Data and privacy](./data-and-privacy.md) for retention and storage details.

## Evolution rules

- Add SwiftData model changes through `RelationshipVaultSchema` and
  `RelationshipVaultMigrationPlan`.
- Extract a touched SwiftUI surface when its boundary is safe; do not replace
  the main Moment view in one untestable refactor.
- Add behaviour behind an injectable boundary and deterministic tests.
- Keep optional system surfaces subordinate to the core app launch path.

## Code-organization principles

File size is a signal, not an architecture rule. Split code when a region has a
different owner, reason to change, dependency set, or test boundary. Do not split
small helpers merely to satisfy a line-count target.

For SwiftUI in this repository:

- observable models own state transitions, cancellation, persistence
  coordination, and service calls;
- views render state and send user intent back to those models;
- a feature surface that can be named, previewed, tested, or changed
  independently belongs in its own file;
- feature-private helpers stay beside their feature unless multiple features
  genuinely share the abstraction;
- dependency direction remains `App -> ProsePalUI -> ProsePalAPI / ProsePalDomain`;
  extraction must not introduce provider knowledge into the UI; and
- refactors are behaviour-preserving and incremental, with tests moved from
  source-string checks to behavioural or view coverage as seams become
  available.

This favours cohesive feature files over both a monolith and a directory full of
one-line wrapper types. The review question is “can one change be understood and
verified locally?”, not “is this file below an arbitrary number of lines?”

## `MomentExperienceView.swift` region map

`prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift` is transitional. It
currently contains several independently changing surfaces and should shrink as
those surfaces are touched; it is not the desired long-term module boundary.

The map names the owning file for extracted regions and the remaining landmarks
inside the monolith:

| Region | Owning file and symbols |
|---|---|
| Draft workflow and relaunch recovery | `Features/Moment/MomentModel.swift`: `MomentModel`, its retained generation task, request state, cancellation identity, snapshot coordination, and diagnostics orchestration; `Features/Moment/MomentDraftRecovery.swift`: versioned recovery state, storage protocol, no-op store, and `UserDefaults` store; `MomentDraftUnavailableNotice.swift`: typed unavailable reason and presentation contract; `ProsePalAPI/MessageWritingService.swift`: writing-service boundary and routing behaviour |
| Active-draft action presentation | `MomentExperienceView.swift`: visible Copy, `ShareLink`, and Save actions on the reviewed draft; `Support/MomentSharing.swift`: shared action, accessibility-identifier, and diagnostics policy |
| App-root navigation and welcome state | `MomentAppRootView.swift`: `MomentAppRootView`, `MomentRootTabs`, `MomentRootTab`, `MomentWelcomeState` |
| Core Moment composer and generated-draft experience | `MomentExperienceView.swift`: `MomentSheetView`, including loading, retry, refusal, revision, pressure feedback, memory controls, copy/share/save, and draft history; `MomentGuidedComposerLayout.swift`: the type-erased guided-composer layout and numbered step shell |
| Relationship and occasion pickers | `MomentExperienceView.swift`: `MomentRelationshipPickerSheet`, `MomentOccasionPickerSheet`, and their row types |
| Saved Drafts feature | `Features/SavedDrafts/`: `SavedMomentDraftsView`, `SavedDraftLibrarySearch`, `SavedMomentDraftLibraryCard`, `SavedMomentDraftDetailView`, persistence functions, native text `ShareLink`, and deterministic previews; `Components/`: shared empty/detail presentation; `Support/MomentSharing.swift`: shared truthful action contract; `ProsePalAPI/RelationshipVault.swift`: persisted `SavedMomentDraftRecord` and schema ownership |
| Relationship-memory library and detail | `MomentExperienceView.swift`: `RelationshipMemoryVaultView`, `RelationshipMemoryDetailView`, `RelationshipVoiceCardDetailView`; shared empty/detail presentation is in `Components/` |
| Settings shell and static presentation components | `Features/Settings/MomentSettingsView.swift`, `MomentSettingsComponents.swift`, and `MomentSettingsPreview.swift`: `MomentSettingsView`, truthful static-row descriptors, feature presentation components, and deterministic preview setup |
| Privacy, export, and authentication | `MomentExperienceView.swift`: `MomentPrivacyDataView`, `MomentLocalDataExportView`; `Features/Settings/MomentLocalDataExport.swift`: typed JSON `Transferable`, named-file creation, and temporary-file cleanup; `MomentAppleSignInControl.swift`: system Apple authorization presentation and native credential forwarding |
| Paywall and subscription plan presentation | `Features/Paywall/MomentPaywallSheet.swift`, `MomentPaywallPreview.swift`, `MomentPlanDetailView.swift`, and `MomentPlanDetailPreview.swift`: `MomentPaywallSheet`, `MomentPlanDetailView`, their presentation contracts and feature-private rows, local sheet presentation state, and deterministic previews; StoreKit, entitlement, product loading, purchase, restore, and `appAccountToken` logic stays in `MomentAccountModel` and `ProsePalAPI/SubscriptionClient.swift` |

Use these symbols as navigation anchors rather than durable line numbers. When a
task changes one region, prefer extracting that complete region and its private
helpers instead of moving unrelated code or attempting a big-bang rewrite.

## Apple service and system-surface ownership

| Boundary | Owner |
|---|---|
| Account and entitlement presentation state | `ProsePalUI/MomentAccountModel.swift`: auth presentation, product selection, entitlement convergence, transaction-update coordination, and account maintenance |
| StoreKit 2 client | `ProsePalAPI/SubscriptionClient.swift`: products, verified transactions and renewal status, purchase, tri-state current entitlement, ownership, retired-product policy, user-triggered restore, update stream, and deferred finish actions; `AppStoreKitTests/StoreKitSubscriptionClientStoreKitTests.swift`: app-hosted direct StoreKit Test scenarios |
| Authentication and session | `ProsePalAPI/AuthSession.swift`, `SupabaseAuthClient.swift`, `AppleAccountLifecycleClient.swift`, and `AppleCredentialState.swift`: Keychain session, refresh serialization, nonce support, authenticated authorization-code forwarding, Apple credential-state checks, and revocation events |
| Shared launch/input contract | `ProsePalDomain/MomentHandoff.swift`: the canonical `MomentLaunchRequest`, launch/shared stores, `MomentDeepLink` routing, source allowlist, sanitisation, and `MomentHandoffEnvironment` production/staging policy — linked by the app, Share Extension, and widget targets |
| App Intent surfaces | `ProsePalUI/ProsePalAppIntents.swift`: `StartMomentIntent`, `ProsePalAppShortcuts`, and package shortcut metadata that consume the shared contract |
| App-target shortcut registration | `App/ProsePalAppShortcuts.swift`: app shortcut provider metadata |
| Widget and Control | `Widgets/ProsePalWidgets.swift`: staging-aware widget/control identifiers and app-opening URLs |
| Incoming system share | `ShareExtension/ShareViewController.swift`: provider loading, sanitization, preview, app-group handoff, and extension completion |
| Outgoing draft share | Active and saved draft views use SwiftUI `ShareLink` with plain transferable text; `ProsePalUI/Support/MomentSharing.swift` owns their destination-neutral action and diagnostics policy |
| Voice transcription | Not in v1. Dictation was removed on 2026-07-14 along with its microphone and speech-recognition usage descriptions; no executable requests either permission. Reintroduction is a post-v1 backlog item owned by its own file and transcriber protocol. |

Stable-toolchain adoption decisions and evidence gates for these owners are in
the [Apple platform modernisation audit](./apple-platform-modernisation-audit.md).

## Source map

- `prosepal-ios/App/ProsePalNativeApp.swift`
- `prosepal-ios/Sources/ProsePalDomain/`
- `prosepal-ios/Sources/ProsePalAPI/`
- `prosepal-ios/Sources/ProsePalUI/`
- `supabase/functions/`
- `supabase/migrations/`

Historical design rationale remains in
[Native 2026 technical direction](../history/architecture/native-2026-technical-direction.md).

SwiftUI feature organisation, state ownership, navigation, preview, testing,
and extraction conventions are defined in the
[SwiftUI architecture standard](./swiftui-architecture.md).
