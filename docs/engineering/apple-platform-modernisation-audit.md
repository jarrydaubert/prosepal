# Apple Platform Modernisation Audit

This audit is the decision record for adopting Apple platform capabilities in
the ProsePal iOS app. It evaluates the shipping source against the stable
toolchain, identifies where Apple framework adoption reduces product or
maintenance risk, and preserves the boundaries that are intentionally
ProsePal-owned. Unresolved implementation work is tracked in
[the backlog](../BACKLOG.md).

## Verdict

Continue incremental feature extraction only as funded behaviour touches a
surface. The module direction, provider-neutral service boundaries, Observation
ownership, SwiftData container, model-owned generation lifecycle, truthful
system sharing, and StoreKit transaction-listener foundation are sound. A new
architecture or a big-bang rewrite would increase risk without addressing the
remaining release-evidence gates.

The highest-value platform work is therefore not visual novelty. It is using
Apple's lifecycle, transaction, transfer, restoration, and test APIs to make
existing product promises deterministic.

## Audit baseline

The source deployment target is iOS 26. The Swift package declares Swift tools
6.2 and `.iOS(.v26)`; Xcode targets declare iOS 26.0 and Swift language mode
6.0.

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

### Retain the implemented stable-toolchain foundations

| Decision | Priority | Functional area |
|---|---:|---|
| Keep the model-owned task and cancellation path; close only evidenced classification gaps. | P0 | Generation cancellation and error classification |
| Keep tri-state entitlement and the existing direct StoreKit Test suite; require executed release evidence. | P0 | Entitlement and StoreKit release evidence |
| Keep authorization-code forwarding, minimal scopes and credential revocation handling. | P0 | Apple account lifecycle |
| Resolve duplicate shortcut providers and qualify the optional surface, or remove it from V1. | P1 | Optional system surfaces |
| Keep truthful `ShareLink` and typed JSON export; verify them on device. | P1 | Sharing and export |
| Simplify conflicting sheet state when its owning feature changes; do not require navigation restoration without a demonstrated need. | P2 | Feature presentation and navigation |

### Stable APIs that need capability or product evidence

| Decision | Gate | Priority |
|---|---|---:|
| Trial `SubscriptionStoreView` inside the extracted paywall while retaining ProsePal marketing content and account-token policy. | Local StoreKit, sandbox/TestFlight, policy-link, accessibility, and account-convergence parity. | P2 |
| Reintroduce voice dictation on `SpeechAnalyzer` with `SpeechTranscriber` and a `DictationTranscriber` fallback, behind its own transcriber protocol. This remains post-v1 only. | Demonstrated demand, plus supported hardware, locale assets, permissions, final-result-on-Stop, offline, and cancellation evidence. | Post-v1 |
| Replace string parameters in App Intents with typed entities or app enums. | The intent remains useful from real Shortcuts, Siri, widget, Control Center, and Action Button surfaces. | P2 |
| Restore navigation paths beyond the root tab. | A stable, non-sensitive, Codable destination model exists for the extracted feature. | P2 |

### Beta or future-only

- Do not adopt iOS 27 App Intents, SwiftData observation, task-shielding, live
  speech-capture helpers, or Private Cloud Compute APIs while the app builds
  with the stable iOS 26 SDK.
- Revisit the provider-neutral Private Cloud Compute experiment only through
  the existing `MessageWritingService` gate after the SDK and entitlement path
  stabilize. Apple documents a real [iOS 27 PCC model](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute),
  with Apple Intelligence device/region availability, network dependence and
  daily user quotas distinct from ProsePal Premium. It cannot cover iOS 26 or
  devices ineligible for Apple Intelligence. [Eligibility](https://developer.apple.com/private-cloud-compute/)
  requires Small Business Program membership, download eligibility and a managed
  entitlement. Check [Apple releases](https://developer.apple.com/news/releases/)
  before adopting; an API appearing in documentation does not make its SDK
  stable or the developer eligible.

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
`prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift` still owns the
active composer, composer memory controls, and privacy/export regions.
`Features/RelationshipMemory/` owns the library, both editors and rollback-safe
persistence seams; these are not pending extraction work.
`Features/Moment/` owns `MomentModel` and active-draft recovery, while Saved
Drafts, Settings, Paywall and plan presentation, root navigation, generating
state, and guided-composer layout demonstrate the desired feature-file pattern.
The architecture region map and shrink-only guardrails make ownership explicit.

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
sheet states for pickers, paywall, draft use, history, and memory detail.
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

**Priority and decision:** P0 boundary; keep the current model-owned lifecycle.

**Minimum/toolchain:** no deployment-target increase; use stable Swift
concurrency in the installed Swift 6 toolchain.

**Source and behaviour:** `MomentModel` now owns the retained task for every
initial draft, retry, rewrite, and named-adjustment request. Views send
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
isolated context behind an actor. Extracted edit/delete helpers roll back
failed mutations; composer insertion paths catch save failures without rollback.

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

**Priority and decision:** implemented locally. Keep the explicit entitlement
state model and prove it against StoreKit sandbox, TestFlight, and the server
authority before release.

**Minimum/toolchain:** subscription status requires iOS 17 and the per-product
entitlement sequence requires iOS 18.4; both are below the iOS 26 minimum.

**Source and behaviour:** `StoreKitSubscriptionClient.currentEntitlement()`
queries each configured or explicitly retired product with
`Transaction.currentEntitlements(for:)`, then combines verified transaction and
subscription-status evidence into `active`, `confirmedInactive`, or `unknown`.
Unrelated products never enter the scan. Unverified, ownership-mismatched, or
unavailable StoreKit state fails closed as `unknown`; it is not re-labelled as a
confirmed expiry. Subscribed and grace-period states are active. Billing retry,
expiry, and revocation are inactive.

`MomentAccountModel` treats this as a same-account state machine. Unknown never
creates Premium. A transient unknown state may retain previously verified active
entitlement for the same account, while confirmed inactivity or an account
identity change clears it. An entitlement linked to a different valid
`appAccountToken` cannot cross an account switch. Unlinked StoreKit purchases
remain usable locally so purchase does not require ProsePal sign-in; server-side
paid capabilities still require separate reconciliation.

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
an unrelated transaction aborting the scan while preserving verification and
ownership failures as security signals for ProsePal products. Deterministic
package tests cover the state and last-known-good rules. The app-hosted
`ProsePalStoreKitTests` target owns direct `SKTestSession` scenarios for products,
purchase, Ask to Buy, restore, renewal states, expiry, refund, retired IDs,
ownership, and updates. A skipped direct StoreKit scenario is not release proof;
the entire suite must execute on a working Apple runtime, followed by
sandbox/TestFlight and server-reconciliation evidence. Family Sharing is not
enabled in the local product configuration and must be proved only if enabled
for the App Store products.

### A-07 — StoreKit transaction lifecycle, restore, ownership, and tests

**Priority and decision:** lifecycle implementation and the direct test target
are in place. Sandbox/TestFlight and server convergence remain release gates.

**Minimum/toolchain:** StoreKit 2 requires iOS 15 and StoreKit Test requires an
Xcode-hosted test environment; the existing Xcode 26/iOS 26 setup exceeds both.

**Source and behaviour:** The client uses `Product.products`, verified purchase
results, `Transaction.updates`, per-product current entitlements, subscription
status, and an explicit user-triggered `AppStore.sync()` restore. Purchase and
update transactions carry deferred delivery handles. `MomentAccountModel`
finishes them only after the same product, compatible owner, and expected grant
or removal have converged. Verification, ownership, store-read, or correlation
failure leaves the transaction unfinished so StoreKit can redeliver it. Pending
and cancelled results remain distinct, and the update stream cancels its
listener on termination. `appAccountToken` is supplied only when a signed-in
Supabase identifier parses as a UUID.

The staging `.storekit` configuration contains the three configured products
plus one test-only retired product. `ProsePalStoreKitTests` is an app-hosted
XCTest target linked to the real `StoreKitSubscriptionClient` and StoreKit Test.
The app host suppresses its normal root lifecycle only while XCTest injection is
active, preventing launch-time entitlement reads from racing `SKTestSession`.

**Apple pattern and availability:** The implemented finish and restore sequence
matches StoreKit 2. Apple states that `finish()` follows delivery and that
`AppStore.sync()` should run only after an explicit user action. Use
[StoreKit Test and `SKTestSession`](https://developer.apple.com/documentation/storekittest)
to automate renewals, Ask to Buy, interruptions, failures, refunds, and
transaction updates. See also [`AppStore.sync()`](https://developer.apple.com/documentation/storekit/appstore/sync%28%29)
and [`appAccountToken`](https://developer.apple.com/documentation/storekit/product/purchaseoption/appaccounttoken%28_%3A%29).

**Benefit, risk, dependencies, and evidence:** Automated StoreKit scenarios
protect the most failure-prone lifecycle without making sandbox state a CI
dependency. The harness labels a scenario as skipped only after catching the
precise known Apple runtime `NSError` (`SKInternalErrorDomain`, code `3`); it
does not infer that diagnosis from a successful empty product lookup. Empty,
missing, extra, or incorrect configured products fail setup. The xcresult gate
requires every expected scenario to pass with zero failures and zero skips, so
an observed runtime skip remains incomplete release evidence. Server
reconciliation remains required because device entitlement and ProsePal account
ownership are different identities. Evidence must include an executed direct
StoreKit suite, sandbox/TestFlight purchase and restore without app login,
transaction updates, server notification/reconciliation, and account switching.

### A-08 — System StoreKit views and paywall controls

**Priority and decision:** P2, evaluate inside the extracted paywall feature; do
not block correctness work on a visual replacement.

**Minimum/toolchain:** `SubscriptionStoreView` requires iOS 17; no availability
branch is needed for the iOS 26 target.

**Source and behaviour:** `MomentPaywallSheet` is a custom SwiftUI paywall. It
preserves ProsePal marketing, runtime readiness and the injected subscription
client, but does not render the shared account notice in the open sheet. It
manually formats duration strings and labels
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
cleanup as required. A failure before final auth deletion starts leaves the auth
account available for retry even when earlier idempotent cleanup completed. The
final Supabase deletion uses an abort-bound HTTP transport, but an unconfirmed
result after dispatch is reported as indeterminate because remote commit may
still occur. Confirmed and already-deleted results converge on success, with the
credential row removed by the auth-user foreign-key cascade. Native and server
operations have bounded timeouts; cancellable Apple and database work also
receives the parent abort signal.

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
cleanup, pre-final timeout, late deletion after an indeterminate response,
already-deleted convergence, retry, and logging hygiene. This is not evidence
that the deployed Apple client-secret configuration, sandbox token exchange,
system revocation notification, or TestFlight deletion works; those behaviours
require external release evidence.

### A-10 — App Intents, Shortcuts, widgets, and controls

**Priority and decision:** P1 to consolidate shortcut registration; keep the
URL/handoff design until system-surface evidence passes; P2 for typed entities.

**Minimum/toolchain:** App Intents requires iOS 16 and Control widgets require
iOS 18; the existing implementations compile in the stable iOS 26 SDK. Exclude
APIs exposed only by the iOS 27 beta SDK.

**Source and behaviour:** `ProsePalDomain/MomentHandoff.swift` owns the typed
launch request, sanitized stores and deep-link parser.
`ProsePalAppIntents.swift` defines `StartMomentIntent` and a public
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

**Priority and decision:** P1, keep truthful system sharing and typed export;
physical-device chooser evidence remains a release gate.

**Source and behaviour:** Active and saved drafts expose one Copy action and one
SwiftUI `ShareLink` for the reviewed plain-text draft. No destination-labelled
controls or custom activity-controller bridge exists. Opening or cancelling the
system chooser records no destination or successful send. Only completed Copy
remains eligible for generic action diagnostics.

Local-data export uses a typed `MomentLocalDataExport: Transferable` with a
JSON `FileRepresentation`. It preserves the generated filename and the exact
encoded bytes, writes into a dedicated temporary directory, cleans stale files
before a new transfer and when leaving the export screen, and retains Copy JSON
as a separate action. Behavioral tests cover the two-action contract, exact
clipboard text, cancellation telemetry policy, saved-draft parity, stable
accessibility identifiers, exported filename/content, and temporary cleanup.
The negative diagnostics guard prevents destination or send claims from
returning. A physical iPhone must still prove that active text, saved text, and
the named JSON file reach the system activity sheet and remain available after
cancellation.

**Minimum/toolchain:** `ShareLink` and `Transferable` require iOS 16; both are
unconditional at the iOS 26 minimum.

**Apple pattern and availability:** Present one truthful `ShareLink` for draft
text. Make a small `Transferable` export value with `FileRepresentation` or
`DataRepresentation` and a JSON content type, then share the named export file.
Plain strings already conform to `Transferable`, so no saved-draft UIKit bridge
is required. `ShareLink` and `Transferable` are available from iOS 16. See
Apple's [`ShareLink`](https://developer.apple.com/documentation/swiftui/sharelink)
documentation.

**Benefit, risk, dependencies, and evidence:** This avoids misleading product
claims, UIKit type erasure, and clipboard-only export while preserving the
system activity sheet and review-before-send. Sharing must never imply that a
message was sent. Test cancellation, copy/save/share diagnostics, exported file
name/content, temporary-file cleanup, accessibility, and system activity-sheet
presentation on a device.

### A-13 — Speech and dictation

**Priority and decision:** Post-v1 only. Reintroduce voice input only after
demonstrated demand and behind its own transcriber protocol and source boundary.

**Minimum/toolchain:** `SpeechAnalyzer` and its stable transcriber modules
require iOS 26 and the stable Xcode 26 SDK; do not use beta-only live-capture
helpers.

**Source and behaviour:** Voice dictation is absent from the app. No executable
requests microphone or speech-recognition permission, and the app declares
neither usage description.

**Apple pattern and availability:** A future implementation must separate
graceful finish from cancellation, await or callback the final transcript with
a bounded completion policy, and reserve immediate teardown for reset/cancel.
`SpeechAnalyzer`,
`SpeechTranscriber`, asset inventory, and `DictationTranscriber` fallback are
stable iOS 26 APIs; current Apple documentation also lists newer live-capture
helpers as Beta, so use `AVAudioEngine` input with the stable analyzer APIs if
prototyping. See the [Speech framework](https://developer.apple.com/documentation/speech/)
and [`SpeechAnalyzer`](https://developer.apple.com/documentation/speech/speechanalyzer).

**Benefit, risk, dependencies, and evidence:** A bounded graceful finish avoids
lost last words, but asset download, hardware, and locale support can reduce
availability. Test volatile/final results, Stop versus Cancel, locale and asset
fallback, interruption, offline behaviour, permissions, backgrounding, and
supported devices before shipping a new path.

### A-14 — Previews, XCTest, Swift Testing, and UI automation

**Priority and decision:** P0 for release-critical UI and StoreKit automation;
keep the mixed test frameworks.

**Minimum/toolchain:** `#Preview` requires Xcode 15, Swift Testing is supported
by the package's Swift 6 toolchain, and StoreKit Test requires Xcode 12 or later;
the installed Xcode 26 toolchain satisfies all three.

**Source and behaviour:** Root navigation, onboarding, generating, guided
composer, Settings, Saved Drafts, Paywall, and plan detail have deterministic
`#Preview` coverage. Relationship-memory library/detail also have feature-owned
previews. Privacy/export and other monolith regions lack independent feature
previews. Package tests mix Swift Testing and XCTest appropriately for model and service
boundaries. `ProsePalStoreKitTests` directly exercises the real subscription
client through StoreKit Test; a successful probe returning no configured products
is a setup failure, not an inferred Apple-runtime skip. An earlier empty-product result is not
evidence that every newer runtime has the same issue or that Apple fixed it;
release evidence requires an actual run on the release toolchain. Several
source-string tests temporarily assert navigation and system-surface wiring.
Sharing has behavioral action, telemetry-policy, accessibility-contract, and
export-file tests plus a negative diagnostics invariant.

**Apple pattern and availability:** Keep Swift Testing for value/model tests and
XCTest where app-hosted, UI, performance, or StoreKit Test integration requires
it. Keep the Xcode UI-test target identifier-driven and the app-hosted StoreKit
integration target based on `SKTestSession`. Require a deterministic preview
whenever a user-facing region is extracted. SwiftUI's
[accessibility fundamentals](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals)
and [StoreKit Test](https://developer.apple.com/documentation/storekittest)
support these layers.

**Benefit, risk, dependencies, and evidence:** `ProsePalNativeUITests` uses
stable identifiers and a DEBUG-only deterministic composition seam for durable
first-run, navigation, generation-state, account, subscription-presentation,
persistence, sharing/export, and accessibility-size journeys. Pull requests run
the smoke class; scheduled and manual workflows run the full target. This
executable coverage proves what source text cannot: presentation, dismissal,
restoration, destructive outcomes, and accessibility-size navigation. Delayed
auth, subscription, generation, and account-maintenance scenarios additionally
prove immediate acknowledgement, accessible indeterminate progress, duplicate
prevention, preserved input, and confirmed or retryable outcomes without
pinning volatile layout. It stays deliberately shallow around generation and
does not claim live Apple-account, sandbox, provider, generic share-destination,
VoiceOver, or physical-device evidence.

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
not call a covered required-reason API in its source. The app declares no
microphone or speech-recognition usage description, and no executable requests
either permission; App Store privacy
answers must not claim them. Tests validate manifest content and
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

### Phase 1 — incremental feature extraction

Extract remaining privacy/export and composer regions only as their funded
behaviour is touched. Do not repeat completed library, sharing or model work, or
make deletion of the monolith a release gate. Each extraction
gets one owner, a deterministic preview, behavioural or view coverage, system
toolbar/presentation conventions, and a corresponding region-map update.

### Phase 2 — evidence-gated platform surfaces

Consider `SubscriptionStoreView`, typed App Intent parameters or deeper navigation
restoration only for a demonstrated product or maintenance need, not because a
new API exists. Prefer existing system keyboard input before commissioning an
app-owned speech pipeline. Adopt only
when behaviour, privacy, account ownership, accessibility, and device evidence
meet or exceed the existing path.

### Phase 3 — future platform experiments

Use a separate provider-neutral experiment for iOS 27 capabilities. Beta APIs
must not enter production architecture merely because documentation is public.
