# Apple Platform Modernisation Audit

This audit is the decision record for adopting Apple platform capabilities in
the native ProsePal app. It evaluates the shipping source against the stable
toolchain, identifies where native framework adoption reduces product or
maintenance risk, and preserves the boundaries that are intentionally
ProsePal-owned. Unresolved implementation work is tracked in
[the backlog](../BACKLOG.md).

## Verdict

Continue the incremental SwiftUI migration. The module direction, provider-
neutral service boundaries, Observation ownership, SwiftData container, and
StoreKit transaction-listener foundation are sound. A new architecture or a
big-bang rewrite would increase risk without addressing the release-critical
gaps.

Before broadening the migration, complete a correctness slice around four
boundaries:

1. make `MomentModel` the only owner of generation tasks and cancellation;
2. complete Sign in with Apple and StoreKit account-integrity behaviour;
3. replace simulated sharing destinations with truthful system presentation;
4. add executable StoreKit and release-critical UI coverage, followed by real
   device evidence for Apple-owned surfaces.

The highest-value platform work is therefore not visual novelty. It is using
Apple's lifecycle, transaction, transfer, restoration, and test APIs to make
existing product promises deterministic.

## Audit baseline

The source deployment target is iOS 26. The Swift package declares Swift tools
6.2 and `.iOS(.v26)`; Xcode targets declare iOS 26.0 and Swift language mode
6.0. The stable toolchain observed for this audit is Xcode 26.6 (build 17F113),
Apple Swift 6.3.3, and the iOS Simulator 26.5 SDK.

Recommendations are limited to APIs available in that stable toolchain.
Documentation for iOS 27, Xcode 27, and APIs labelled Beta is evidence for
future investigation only, not an implementation dependency.

Priorities used below are:

- **P0** — release integrity, privacy, data loss, billing, or uncontrolled work;
- **P1** — safe modernization that materially improves reliability or
  verifiability;
- **P2** — adopt when its owning feature is extracted or device evidence shows
  a need;
- **P3** — future or beta-dependent exploration.

## Decision summary

### Safe to adopt with the stable toolchain

| Decision | Priority | Owning backlog scope |
|---|---:|---|
| Route every draft, retry, and rewrite through one model-owned task handle and cooperative cancellation path. | P0 | Native v1 core flow |
| Preserve an explicit unknown/error entitlement state instead of converting every StoreKit read failure to inactive. Add direct StoreKit Test coverage. | P0 | Auth, payments, and account integrity |
| Forward the Apple authorization code, remove unused identity scopes, and handle credential revocation. | P0 | Auth, payments, and account integrity |
| Keep one `AppShortcutsProvider` and verify extracted metadata from a production-like build. | P1 | Optional system surfaces |
| Replace destination-labelled `ShareLink` controls with one truthful system share action; use `Transferable` for the JSON export. | P1 | Native v1 core flow |
| Model mutually exclusive sheets as one presentation value while extracting their owning features; restore lightweight root/navigation state. | P1 | Root navigation and incremental decomposition |

### Stable APIs that need capability or product evidence

| Decision | Gate | Priority |
|---|---|---:|
| Trial `SubscriptionStoreView` inside the extracted paywall while retaining ProsePal marketing content and account-token policy. | Local StoreKit, sandbox/TestFlight, policy-link, accessibility, and account-convergence parity. | P2 |
| Trial `SpeechAnalyzer` with `SpeechTranscriber` and `DictationTranscriber` fallback behind the existing protocol. | Supported hardware, locale assets, permissions, final-result, offline, and cancellation evidence. | P2 |
| Replace string parameters in App Intents with typed entities or app enums. | The intent remains useful from real Shortcuts, Siri, widget, Control Center, and Action Button surfaces. | P2 |
| Restore navigation paths beyond the root tab. | A stable, non-sensitive, Codable destination model exists for the extracted feature. | P2 |

### Beta or future-only

- Do not adopt iOS 27 App Intents, SwiftData observation, task-shielding, live
  speech-capture helpers, or Private Cloud Compute APIs while the app builds
  with the stable iOS 26 SDK.
- Revisit the provider-neutral Private Cloud Compute experiment only through
  the existing `MessageWritingService` gate after the SDK and entitlement path
  stabilize.

### Intentionally ProsePal-owned

- `MessageWritingService`, routing, fallback policy, validation, pressure
  feedback, request identity, and safe diagnostics remain custom because they
  express product, cost, privacy, and provider-neutral contracts.
- The Moment Sheet's paper-like content treatment and semantic visual tokens
  remain custom. System navigation, presentation, sharing, commerce, and auth
  controls should surround that content where they improve platform behaviour.
- Active-draft recovery remains separate from SwiftData so a crash-recovery
  mechanism cannot silently become saved relationship history.
- Review-before-send, sanitized system-surface handoff, relationship-memory
  approval, export, deletion, and server entitlement reconciliation remain
  ProsePal policies even when system APIs provide their presentation.
- The share extension remains a custom extension because it sanitizes incoming
  text and URLs and requires an explicit preview before opening the app.

## Findings

### A-01 — SwiftUI composition and file boundaries

**Priority and decision:** P1, refactor incrementally; do not replace the view
hierarchy wholesale.

**Minimum/toolchain:** no deployment-target increase; use the existing stable
Xcode 26 and iOS 26 target.

**Source and behaviour:**
`prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift` still owns
`MomentModel`, voice capture presentation, the active composer, relationship
memory, plan, privacy/export, Apple sign-in, and paywall regions. Saved Drafts,
Settings, root navigation, generating state, and guided-composer layout already
demonstrate the desired feature-file pattern. The architecture region map and
the shrink-only guardrails make ownership explicit.

**Apple pattern and availability:** SwiftUI view composition, `NavigationStack`,
toolbars, previews, and Observation are stable well below the iOS 26 target.
This is a cohesion change, not a framework migration.

**Benefit, risk, dependencies, and evidence:** Extracting one complete feature
at a time gives each surface a preview, behavioural seam, and system chrome
without changing provider boundaries. A big-bang split risks state duplication,
presentation regressions, and source-string tests that pass while behaviour
breaks. Each extraction requires package tests, app compilation, its preview,
identifier-driven UI coverage, and the architecture map update.

### A-02 — Observation, state ownership, and dependency injection

**Priority and decision:** keep; no migration work is justified.

**Minimum/toolchain:** Observation and `@Bindable` require iOS 17; the app
already requires iOS 26.

**Source and behaviour:** `MomentModel`, `MomentAccountModel`, and
`MomentWelcomeState` are `@MainActor @Observable` reference models. The app root
stores owned instances in `@State`, child views use `@Bindable` only where
bindings are needed, and service dependencies are `@ObservationIgnored` protocol
values. `ProsePalNativeApp` is the composition root for network, auth, StoreKit,
vault, and generation clients. Views do not instantiate provider clients.

**Apple pattern and availability:** Observation and `@Bindable` are available
from iOS 17 and are the native pattern for the iOS 26 target. Apple's
[Observation](https://developer.apple.com/documentation/observation),
[`Bindable`](https://developer.apple.com/documentation/swiftui/bindable), and
[model-data guidance](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
match the implemented ownership.

**Benefit, risk, dependencies, and evidence:** This arrangement supplies a
single source of truth, precise invalidation, and deterministic injected tests.
Moving app-lifetime models into implicit global environment values would hide
dependencies and is not an improvement. Continue using environment values for
Apple-owned contextual state such as `modelContext`, dismissal, scene phase,
accessibility settings, and focus.

### A-03 — Navigation, sheets, alerts, and restoration

**Priority and decision:** P1, refactor while extracting the owning features.

**Minimum/toolchain:** `NavigationStack` requires iOS 16 and `SceneStorage` is
older; neither changes the iOS 26 minimum.

**Source and behaviour:** `MomentAppRootView` uses a typed root-tab enum and one
`NavigationStack` per tab, but root selection and destination paths are not
restored. `MomentSheetView` holds multiple independent Boolean and optional
sheet states for pickers, paywall, voice, draft use, history, and memory detail.
SwiftUI normally serializes presentations, but independent flags permit
conflicting intents and make dismissal behaviour difficult to test. Alerts and
destructive confirmations are otherwise state-driven and use system roles.

**Apple pattern and availability:** Use an enum or identifiable presentation
model with `sheet(item:)`, and typed values with `navigationDestination`. Store
only lightweight, non-sensitive selection in `@SceneStorage`; persist a Codable
navigation path only after destinations have stable identifiers. These APIs are
available below iOS 26. Apple's
[navigation-stack guidance](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack)
and [state-restoration sample](https://developer.apple.com/documentation/swiftui/restoring-your-app-s-state-with-swiftui)
define the pattern and warn against sensitive scene storage.

**Benefit, risk, dependencies, and evidence:** One presentation state makes
mutual exclusion explicit and removes invalid-presentation races. Restoration
improves continuity, but storing draft text in scene state would duplicate a
sensitive recovery boundary and is prohibited. Evidence requires relaunch tests
for root selection and navigation, plus compact, regular-width, keyboard, and
VoiceOver UI coverage.

### A-04 — Structured concurrency, cancellation, and actors

**Priority and decision:** P0, refactor before more composer migration.

**Minimum/toolchain:** no deployment-target increase; use stable Swift
concurrency in the installed Swift 6 toolchain.

**Source and behaviour:** `MomentModel` now owns the retained task for every
initial draft, retry, rewrite, adjustment, and Take More Care request. Views send
named synchronous intents instead of creating generation tasks. Stop/reset,
every meaning-bearing input mutation, composer dismissal, app backgrounding,
and superseding work cancel the same handle; a generation identity rejects late
completion from dependencies that do not finish immediately.

`RoutingMessageWritingService` checks cancellation before every fallback and
applies per-lane budgets inside one total technical deadline. The Foundation
Models and gateway clients check cancellation around their expensive
boundaries. `generate-card` combines the incoming request signal with the
provider timeout, stops its fallback-model loop, and marks an existing request-
ledger reservation failed when the client cancels.

`AuthSessionController`, request-key persistence, and SwiftData lookup use actor
isolation appropriately. The StoreKit update listener retains and terminates
its task. These should remain.

**Apple pattern and availability:** Keep task creation at the model boundary,
retain the handle, cancel it on every meaning-bearing mutation, dismissal, and
background transition, and propagate cancellation through transport and
Foundation Models clients. Swift task cancellation is stable and cooperative;
Apple's [`Task.cancel()` documentation](https://developer.apple.com/documentation/swift/task/cancel%28%29)
notes that discarded handles cannot later be cancelled and operations must
cooperate.

**Benefit, risk, dependencies, and evidence:** The implementation prevents
untracked UI work and makes Stop/background semantics deterministic. Model
tests cover every entry point, lifecycle cancellation cause, meaning-bearing
field, retry supersession, late-result suppression, and total deadline. Service
tests deliberately translate cancellation into a fallback-eligible error and
prove no fallback starts; Edge tests prove an aborted provider attempt does not
advance to another model and releases its ledger reservation. Cancellation is
still cooperative: an already accepted remote request may continue if the Edge
runtime or upstream provider ignores its abort signal.

### A-05 — SwiftData schema, queries, and migrations

**Priority and decision:** keep the implementation; gate every schema change on
an explicit new schema version and migration test.

**Minimum/toolchain:** SwiftData requires iOS 17; the versioned schema continues
to build against the stable iOS 26 SDK.

**Source and behaviour:** `RelationshipVault.swift` defines three `@Model`
types, `RelationshipVaultSchemaV1`, `RelationshipVaultMigrationPlan`, an
explicit Application Support store excluded from backup, an honest ephemeral
fallback, key repair, export, and erasure. SwiftUI uses `@Query` with the
environment `modelContext`; asynchronous prompt-memory lookup creates an
isolated context behind an actor. Save/delete helpers now roll back failed
mutations.

**Apple pattern and availability:** SwiftData, `VersionedSchema`,
`SchemaMigrationPlan`, `MigrationStage`, `@Query`, and model-context isolation
are available for the iOS 26 target. Apple's
[`VersionedSchema`](https://developer.apple.com/documentation/swiftdata/versionedschema)
and [migration-plan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)
contracts require each released schema and its transition to remain explicit.

**Benefit, risk, dependencies, and evidence:** No replacement database or
repository layer is warranted. The material future risk is mutating model types
referenced by V1 instead of freezing the released shape and adding V2. Before
shipping any schema change, test an actual V1 store fixture through lightweight
or custom migration, key repair, export, deletion, and persistent/ephemeral
failure paths.

### A-06 — StoreKit entitlement and subscription status

**Priority and decision:** P0, refactor the entitlement result model and add
subscription-status handling needed by product and server convergence.

**Minimum/toolchain:** subscription status requires iOS 17 and the per-product
entitlement sequence requires iOS 18.4; both are below the iOS 26 minimum.

**Source and behaviour:** `StoreKitSubscriptionClient.currentEntitlement()`
iterates `Transaction.currentEntitlements`, classifies the transaction's product
ID before treating verification failure as relevant, and returns an
active/inactive value. An unverified transaction outside ProsePal's configured
product set is ignored; an unverified configured transaction still fails
closed. `MomentAccountModel` converts any entitlement-read failure into inactive
and locks Premium. This still conflates “not entitled” with “StoreKit could not
establish state” and can produce a transient false downgrade. The app does not
model renewal state, billing retry, grace, revocation, or Family Sharing service
selection.

**Apple pattern and availability:** Keep verified StoreKit 2 transactions, but
iterate configured IDs with `Transaction.currentEntitlements(for:)` or filter
verification results without letting an unrelated product abort the scan.
Represent active, inactive, and unknown/error separately. Use
`Product.SubscriptionInfo.Status` and verified `RenewalInfo` when the UI or
server needs renewal truth, granting the highest entitled service across
statuses. The per-product sequence is available from iOS 18.4 and subscription
status from iOS 17, both below the deployment target. See Apple's
[`currentEntitlements`](https://developer.apple.com/documentation/storekit/transaction/currententitlements),
[`currentEntitlements(for:)`](https://developer.apple.com/documentation/storekit/transaction/currententitlements%28for%3A%29),
and [renewal-state](https://developer.apple.com/documentation/storekit/product/subscriptioninfo/renewalstate)
contracts.

**Benefit, risk, dependencies, and evidence:** The product-first ordering avoids
an unrelated transaction aborting the entitlement scan while preserving
verification failure as a security signal for configured products. The wider
entitlement-state redesign still depends on an explicit product policy for
billing retry, grace, Family Sharing, retired IDs, anonymous purchases, and
server authority. StoreKit Test and sandbox evidence must cover active, expired,
grace, billing retry, revoked/refunded, unverified, Family Sharing, missing
products, and transient store failure.

### A-07 — StoreKit transaction lifecycle, restore, ownership, and tests

**Priority and decision:** keep the lifecycle foundation; P0 to prove it with
direct StoreKit tests and end-to-end account reconciliation.

**Minimum/toolchain:** StoreKit 2 requires iOS 15 and StoreKit Test requires an
Xcode-hosted test environment; the existing Xcode 26/iOS 26 setup exceeds both.

**Source and behaviour:** The client uses `Product.products`, verified purchase
results, `Transaction.updates`, `Transaction.currentEntitlements`, and an
explicit user-triggered `AppStore.sync()` restore. A successful purchase is
finished only after entitlement convergence; verified update transactions are
finished only after `MomentAccountModel` refresh succeeds. Pending and cancelled
results remain distinct. The update stream cancels its listener on termination.
`appAccountToken` is supplied only when a signed-in Supabase identifier parses
as a UUID.

The local `.storekit` configuration contains the three products and is attached
to the staging scheme, while package tests exercise the injected
`SubscriptionClient` model contract only. There is no direct
`StoreKitSubscriptionClient`/`SKTestSession` test target. Server notification,
reconciliation, anonymous-purchase convergence, and account switching still
need sandbox/TestFlight proof.

**Apple pattern and availability:** The implemented finish and restore sequence
matches StoreKit 2. Apple states that `finish()` follows delivery and that
`AppStore.sync()` should run only after an explicit user action. Use
[StoreKit Test and `SKTestSession`](https://developer.apple.com/documentation/storekittest)
to automate renewals, Ask to Buy, interruptions, failures, refunds, and
transaction updates. See also [`AppStore.sync()`](https://developer.apple.com/documentation/storekit/appstore/sync%28%29)
and [`appAccountToken`](https://developer.apple.com/documentation/storekit/product/purchaseoption/appaccounttoken%28_%3A%29).

**Benefit, risk, dependencies, and evidence:** Automated StoreKit scenarios
protect the most failure-prone lifecycle without making sandbox state a CI
dependency. Server reconciliation remains required because device entitlement
and ProsePal account ownership are different identities. Evidence must include
local StoreKit automation, sandbox/TestFlight purchase and restore without app
login, transaction updates, server notification/reconciliation, and account
switching.

### A-08 — System StoreKit views and paywall controls

**Priority and decision:** P2, evaluate during paywall extraction; do not block
the correctness work on a visual replacement.

**Minimum/toolchain:** `SubscriptionStoreView` requires iOS 17; no availability
branch is needed for the iOS 26 target.

**Source and behaviour:** `MomentPaywallSheet` is a custom SwiftUI paywall. It
preserves ProsePal marketing, runtime readiness, account notices, and the
injected subscription client, but manually formats duration strings and labels
product rows. This creates localization and disclosure risk. StoreKit remains
the source of display name and price.

**Apple pattern and availability:** `SubscriptionStoreView` is available from
iOS 17 and provides localized subscription information, purchase controls, and
policy links while allowing custom marketing content. See Apple's
[`SubscriptionStoreView`](https://developer.apple.com/documentation/storekit/subscriptionstoreview)
guidance.

**Benefit, risk, dependencies, and evidence:** System controls can reduce
commerce UI, localization, accessibility, and policy-link maintenance. They are
not automatically safer if they bypass `appAccountToken`, entitlement
convergence, existing diagnostics, or product hierarchy. Prototype inside the
extracted feature and adopt only after local StoreKit, sandbox/TestFlight,
accessibility, cancellation, restore, policy-link, and account-ownership parity.

### A-09 — Sign in with Apple lifecycle

**Priority and decision:** P0 implementation complete to deterministic local
scope; sandbox/TestFlight revocation and deletion proof remains a release gate.

**Minimum/toolchain:** the required AuthenticationServices client APIs are
available below iOS 26; server token exchange has no client OS constraint.

**Source and behaviour:** `MomentAppleSignInControl` uses the system
`SignInWithAppleButton`, a cryptographic nonce, and Supabase ID-token exchange.
It requests no unused contact scopes and passes the identity token, one-time
authorization code, and opaque Apple user ID into `MomentAccountModel`. The
model authenticates through Supabase, forwards the code only to
`SupabaseAppleAccountLifecycleClient` with the returned bearer token, and stores
the session only after the server confirms revocation material is durable.
`AuthSession` retains the opaque Apple user ID in Keychain across refresh.
`SystemAppleCredentialStateProvider` observes
`credentialRevokedNotification` and performs bounded `getCredentialState`
checks. Revoked, not-found, and transferred states clear account state without
erasing unrelated local writing.

`exchange-apple-token` validates server configuration, the authenticated
Supabase user’s Apple identity, Apple token-response issuer/audience/subject and
expiry, and the credential upsert. It stores only Apple’s refresh token behind a
service-role-only table. `delete-user` treats Apple revocation and every app-data
cleanup as required, leaves the auth account and credential available on
failure, and relies on the auth-user foreign-key cascade only after successful
deletion. Native and server operations have bounded timeouts; cancellable Apple
and database work also receives the parent abort signal.

**Apple pattern and availability:** Request only consumed scopes. Securely send
the identity token and one-time authorization code to the server; validate the
grant and retain only the revocation material required for account deletion.
Observe credential revocation and re-check stored Apple credential state,
reverting the client to signed out without deleting unrelated local drafts.
AuthenticationServices supports these APIs below iOS 26. Apple's
[TN3194](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple),
[`credentialRevokedNotification`](https://developer.apple.com/documentation/authenticationservices/asauthorizationappleidprovider/credentialrevokednotification),
and [token-revocation endpoint](https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens)
define the lifecycle.

**Benefit, risk, dependencies, and evidence:** Deterministic native and Edge
Function tests cover first and repeat login, code forwarding, missing and
malformed results, identity mismatch, Apple/server/database failure, all stable
credential states, revocation notification, deletion revocation, partial
cleanup, retry, timeout cancellation, and logging hygiene. This is not evidence
that the deployed Apple client-secret configuration, sandbox token exchange,
system revocation notification, or TestFlight deletion works; those external
proofs remain in the release backlog.

### A-10 — App Intents, Shortcuts, widgets, and controls

**Priority and decision:** P1 to consolidate shortcut registration; keep the
URL/handoff design until system-surface evidence passes; P2 for typed entities.

**Minimum/toolchain:** App Intents requires iOS 16 and Control widgets require
iOS 18; the existing implementations compile in the stable iOS 26 SDK. Exclude
APIs exposed only by the iOS 27 beta SDK.

**Source and behaviour:** `ProsePalAppIntents.swift` defines the typed launch
request, sanitized stores, deep-link parser, `StartMomentIntent`, and a public
`ProsePalAppShortcuts`. The app target separately defines
`ProsePalNativeAppShortcuts` with the same shortcut metadata. Apple recommends
one provider per app. Widgets and the Control use staging-aware sanitized URLs;
the intent stores a launch request and dynamically foregrounds the app. These
routes prepare the Moment but do not generate or send text outside the app.

**Apple pattern and availability:** Retain one app-target
`AppShortcutsProvider`, keeping shared intent and handoff domain types in the
package. `supportedModes` is appropriate for a navigation intent on the iOS 26
toolchain. If evidence justifies richer parameters, use `AppEnum` for the
occasion and an `AppEntity`/query for non-sensitive stable people identifiers,
not raw relationship memory. Apple's WWDC25
[App Intents guidance](https://developer.apple.com/videos/play/wwdc2025/244/)
states that an app should define a single provider; the
[`supportedModes` documentation](https://developer.apple.com/documentation/appintents/appintent/supportedmodes)
defines foreground behaviour.

**Benefit, risk, dependencies, and evidence:** Consolidation removes ambiguous
metadata extraction with little product risk. Replacing URLs with direct intent
buttons is optional: URLs are simple and currently preserve review-before-send.
Validate actual Shortcuts, Siri, Home Screen widget, Control Center/Action
Button, cold launch, staging identity, and metadata extraction. Do not adopt the
newer beta execution-target or schema APIs with Xcode 26.

### A-11 — Share extension and optional-system-surface boundary

**Priority and decision:** keep the custom extension; P0 release evidence.

**Minimum/toolchain:** no deployment-target or toolchain change; retain the
existing UIKit extension in the stable iOS 26 project.

**Source and behaviour:** `ShareViewController` accepts text or URL providers,
normalizes and limits content, previews the result, stores it in the app group,
and opens a staging-aware deep link. The app consumes and deletes the payload,
then applies it as Moment context. Widget, control, intent, and share routes all
remain subordinate to the core app and require review before generation or
sending.

**Apple pattern and availability:** A UIKit share extension is a legitimate
system extension boundary. No SwiftUI or App Intent replacement materially
improves the trust model. Shared sanitization constants should remain aligned,
and every extension executable must carry its own applicable privacy
declarations.

**Benefit, risk, dependencies, and evidence:** The custom preview protects the
product's person-first workflow. The risk is lifecycle behaviour that source-
string and unit tests cannot prove: provider loading, extension memory/time,
app-group identity, cold launch, and completion. Capture physical-device or
TestFlight evidence and remove an optional target from v1 if it cannot pass
without destabilizing the app.

### A-12 — Sharing, `Transferable`, and export

**Priority and decision:** P1, replace simulated destinations and generic UIKit
bridges with system-native transfer types.

**Minimum/toolchain:** `ShareLink` and `Transferable` require iOS 16; both are
unconditional at the iOS 26 minimum.

**Source and behaviour:** `MomentDraftUseSheet` displays Messages, Mail, Notes,
and More tiles, but every tile is the same `ShareLink` for a string. `ShareLink`
chooses activities through the system and cannot guarantee the labelled
destination, so the UI and diagnostics overstate what was selected.
`SavedMomentDraftDetailView` uses `MomentShareSheet`, an `[Any]` wrapper around
`UIActivityViewController`, for a plain string. Local-data export prepares JSON
and a filename but exposes only Copy JSON even though the exporter can write a
file.

**Apple pattern and availability:** Present one truthful `ShareLink` for draft
text. Make a small `Transferable` export value with `FileRepresentation` or
`DataRepresentation` and a JSON content type, then share the named export file.
Plain strings already conform to `Transferable`, so the saved-draft UIKit bridge
can be removed. `ShareLink` and `Transferable` are available from iOS 16. See
Apple's [`ShareLink`](https://developer.apple.com/documentation/swiftui/sharelink)
documentation.

**Benefit, risk, dependencies, and evidence:** This removes misleading product
claims, UIKit type erasure, and clipboard-only export while preserving the
system activity sheet and review-before-send. Sharing must never imply that a
message was sent. Test cancellation, copy/save/share diagnostics, exported file
name/content, temporary-file cleanup, accessibility, and Messages/Mail/Notes
availability on a device.

### A-13 — Speech and dictation

**Priority and decision:** keep the protocol boundary; P1 to prove/fix final
result on Stop, P2 for a `SpeechAnalyzer` implementation.

**Minimum/toolchain:** `SpeechAnalyzer` and its stable transcriber modules
require iOS 26 and the stable Xcode 26 SDK; do not use beta-only live-capture
helpers.

**Source and behaviour:** `MomentVoiceCapture` isolates speech behind
`MomentVoiceCaptureTranscribing`, requires on-device recognition, uses explicit
speech and microphone permission, and never treats voice as an automatic send.
The `SFSpeechRecognizer` implementation calls `endAudio()` and `finish()`, then
immediately clears the recognition task and transcript callback. A person-
initiated Stop can therefore discard a final result that arrives after audio
ends; the model marks capture finished immediately. Unit tests cover model state
with a stub but not this live finalization sequence.

**Apple pattern and availability:** Separate graceful finish from cancellation,
await or callback the final transcript with a bounded completion policy, and
reserve immediate teardown for reset/cancel. `SpeechAnalyzer`,
`SpeechTranscriber`, asset inventory, and `DictationTranscriber` fallback are
stable iOS 26 APIs; current Apple documentation also lists newer live-capture
helpers as Beta, so use `AVAudioEngine` input with the stable analyzer APIs if
prototyping. See the [Speech framework](https://developer.apple.com/documentation/speech/)
and [`SpeechAnalyzer`](https://developer.apple.com/documentation/speech/speechanalyzer).

**Benefit, risk, dependencies, and evidence:** A bounded graceful finish avoids
lost last words. The analyzer can improve modern concurrency and result
handling, but asset download, hardware, and locale support can reduce
availability. Test volatile/final results, Stop versus Cancel, locale and asset
fallback, interruption, offline behaviour, permissions, backgrounding, and
supported devices before replacing the existing path.

### A-14 — Previews, XCTest, Swift Testing, and UI automation

**Priority and decision:** P0 for release-critical UI and StoreKit automation;
keep the mixed test frameworks.

**Minimum/toolchain:** `#Preview` requires Xcode 15, Swift Testing is supported
by the package's Swift 6 toolchain, and StoreKit Test requires Xcode 12 or later;
the installed Xcode 26 toolchain satisfies all three.

**Source and behaviour:** Root navigation, onboarding, generating, guided
composer, Settings, and Saved Drafts have deterministic `#Preview` coverage.
Paywall, privacy/export, voice sheet, relationship-memory detail, and other
monolith regions do not have independently compiling previews. Package tests
mix Swift Testing and XCTest appropriately for deterministic model and service
boundaries. There is no app UI-test target or direct StoreKit Test suite.
Several source-string tests temporarily assert navigation and system-surface
wiring; one currently pins the misleading destination-labelled sharing UI.

**Apple pattern and availability:** Keep Swift Testing for value/model tests and
XCTest where app-hosted, UI, performance, or StoreKit Test integration requires
it. Add an Xcode UI-test target with stable accessibility identifiers and an
app-hosted StoreKit integration target using `SKTestSession`. Require a
deterministic preview whenever a user-facing region is extracted. SwiftUI's
[accessibility fundamentals](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals)
and [StoreKit Test](https://developer.apple.com/documentation/storekittest)
support these layers.

**Benefit, risk, dependencies, and evidence:** Executable coverage proves what
source text cannot: presentation, focus, dismissal, restoration, system
dialogs, and accessibility sizes. UI tests must remain narrow and deterministic;
Apple-account, sandbox, provider, and physical-device behaviour stays in
release evidence rather than blocking unit CI.

### A-15 — Accessibility, localization, and semantic styling

**Priority and decision:** P0 for release-flow accessibility evidence; keep
semantic styling; defer full Dark Mode and additional languages to the approved
post-v1 scope.

**Minimum/toolchain:** no deployment-target increase; use APIs available in the
stable iOS 26 SwiftUI SDK and a String Catalog supported by current Xcode.

**Source and behaviour:** The app has semantic visual tokens, many accessibility
labels and identifiers, Dynamic Type branches, system control roles, Reduce
Motion/Transparency handling, and an accessibility standard. Root and welcome
surfaces force light appearance. No String Catalog or translated string resource
exists; SwiftUI/localized literals are extractable, but computed commerce and
duration copy includes manual English formatting. Multiple custom bars and
fixed presentation heights still require accessibility-size device proof.

**Apple pattern and availability:** Continue using system controls, semantic
styles, text styles, scalable layouts, accessibility actions/values, focus, and
system toolbars around custom content. Introduce a String Catalog before adding
a language, and remove manual StoreKit period copy in favour of StoreKit/system
presentation. Apple's [SwiftUI accessibility guidance](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals)
is available across the deployment target.

**Benefit, risk, dependencies, and evidence:** The existing visual identity is
not a reason to custom-build system behaviour. Do not add new light-only or
fixed-size surfaces. Evidence requires VoiceOver, Voice Control, Dynamic Type,
contrast, keyboard/focus, Reduce Motion, Reduce Transparency, compact and
regular widths, and localized commerce disclosure before enabling those
capabilities.

### A-16 — Privacy manifests and release requirements

**Priority and decision:** keep the manifests; P0 archive and App Store evidence.

**Minimum/toolchain:** no deployment-target increase; privacy manifests are a
bundle and submission requirement supported by the stable Xcode 26 toolchain.

**Source and behaviour:** The app and share-extension executables contain
`PrivacyInfo.xcprivacy` files declaring their UserDefaults required-reason use;
the Xcode project embeds the production and staging variants. The widget does
not call a covered required-reason API in its source. App usage descriptions
cover microphone and speech recognition. Tests validate manifest content and
project embedding. Data/privacy docs prohibit sensitive logs and define local
export/deletion boundaries.

**Apple pattern and availability:** Re-audit each executable and embedded SDK
whenever code or dependencies change. The bundle containing an executable that
uses a covered API must include an accurate declaration. Apple's
[required-reason API guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
defines this per-bundle requirement.

**Benefit, risk, dependencies, and evidence:** Source manifests are necessary
but do not prove App Store privacy answers, archive aggregation, provider data
terms, or reachable policy/export/deletion UI. Preserve an archive privacy
report, verify App Privacy answers and production provider terms, exercise
permissions, export, and deletion, and confirm no app or extension logs names,
message text, tokens, receipts, or shared payloads.

## Platform adoption sequence

### Phase 0 — correctness before migration breadth

1. Introduce explicit StoreKit entitlement unknown/status handling and direct
   StoreKit Test automation; prove server/account convergence separately.
2. Replace misleading share destinations and add a file-based transferable
   export.
3. Prove graceful voice finalization and add the release-critical UI-test target.

### Phase 1 — extract around the corrected boundaries

Extract relationship memory, plan/paywall, privacy/export, auth, voice/share,
and composer regions only as their funded behaviour is touched. Each extraction
gets one owner, a deterministic preview, behavioural or view coverage, system
toolbar/presentation conventions, and a corresponding region-map update.

### Phase 2 — evidence-gated native surfaces

Trial `SubscriptionStoreView`, `SpeechAnalyzer`, typed App Intent parameters,
and deeper navigation restoration inside their extracted features. Adopt only
when behaviour, privacy, account ownership, accessibility, and device evidence
meet or exceed the existing path.

### Phase 3 — future platform experiments

Use a separate provider-neutral experiment for iOS 27 capabilities. Beta APIs
must not enter production architecture merely because documentation is public.

## Recommended next implementation goal

Make StoreKit entitlement uncertainty explicit and add direct StoreKit Test
automation, then prove account/entitlement convergence in sandbox and
TestFlight. The Sign in with Apple lifecycle is complete to local deterministic
scope; release still requires external environment evidence, not another native
architecture change.
