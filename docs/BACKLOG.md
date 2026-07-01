# Backlog

This is the single active open-work tracker for the native iOS direction. The
untracked root `PROSEPAL_BUILD_SPEC.md` from the main checkout has been folded
here so the repo has one source of truth for remaining Moment-path work.

The detailed user-story audit and verification matrix lives in
`docs/FEATURE_STATUS.csv`. Its implementation statuses describe code-complete
feature behavior; this backlog remains authoritative for open implementation,
release, and App Review readiness work.

Codex verification is complete to the local automated/static/simulator scope.
Remaining `[~]` items stay open when they require physical-device behavior,
live Apple/Supabase/App Store or StoreKit sandbox evidence, actual OS
system-surface configuration, or human safety/accessibility review.

Status markers:

- `[x]` implemented in code and backed by evidence.
- `[~]` partially implemented, implemented with important caveats, or present
  as infrastructure without release evidence.
- `[ ]` not implemented in code yet.

Every row must include `-- evidence:`. If there is no code pointer, the item is
not done.

## Active Direction

- App name: ProsePal. "Near" is an internal concept name only.
- Native app path: `prosepal-ios/`.
- Product shape: greenfield native iOS, iOS 26-first, person-first, and centered
  on the Moment Sheet.
- Architecture: one `MessageWritingService` seam with private and careful
  writing lanes.
- Dependencies: Apple-native first. No RevenueCat. No client-direct provider
  SDKs in the UI app.
- Flutter production/reference history is archived at tag
  `flutter-prod-freeze-2026-06-25` and branch
  `legacy/flutter-production-reference`; active `main` is native iOS only.

## 0. Product Principles

- [~] ProsePal helps someone show up for people who matter, not face a generic
  blank page -- evidence: `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`,
  `prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`.
- [x] Person-first entry is the default; occasion taxonomy lives underneath --
  evidence: `MomentInput.personName` in
  `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`,
  `MomentSheetView.personSection` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
- [x] Drafting is explicit and user-controlled once there is enough context --
  evidence: `MomentModel.resetDraftForMomentChange()`,
  `MomentModel.draftNow()`, `MomentModel.startNewMoment()`, and
  `MomentSheetView.draftStartSection` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; tests in
  `prosepal-ios/Tests/ProsePalUITests/MomentModelTests.swift`; PR #83. Typing,
  picker changes, and memory edits clear stale drafts but do not start network
  generation before the user taps `Write draft`.
- [~] Safety and restraint are product behavior, not just server policy --
  evidence: `MomentSafetySignal`, `PressureCheck`, and `MomentInput.requiresCarefulLane`
  in `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`; UI crisis/careful
  sections in `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
  Partial because crisis and pressure detection are still local phrase-list
  heuristics.
- [x] Provider/model names stay out of user-facing UI -- evidence:
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`,
  `prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift`,
  and `providerNamesStayOutOfAppAndUISource()` in
  `prosepal-ios/Tests/ProsePalUITests/NativeGuardrailTests.swift`.

## 1. Surfaces / Information Architecture

- [x] N-IOS-13 Retire legacy island and reconcile docs to the native direction --
  evidence: `ProsePalRootView.swift`, `LegacyComposeModels.swift`,
  `LocalModelStore.swift`, `MessageWritingRouter.swift`,
  `MockMessageWritingClient.swift`, and legacy UI tests are removed in this
  cleanup slice; live coverage moved to `CardContractTests`,
  `MomentAccountModelTests`, `RelationshipVaultTests`,
  `NativeDiagnosticsTests`, and `NativeRuntimeReadinessTests`; `CLAUDE.md`,
  `AGENTS.md`, and `docs/README.md` point new work at `prosepal-ios/`; `swift
  build`, full `swift test`, and reference sweeps pass in this slice.
- [x] N-IOS-15 Promote native iOS to active main and archive Flutter production
  baseline -- evidence: archive tag `flutter-prod-freeze-2026-06-25`, archive
  branch `legacy/flutter-production-reference`, active Flutter app paths
  `android/`, `ios/`, `lib/`, `test/`, `integration_test/`, `test_driver/`,
  `assets/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, and
  `firebase.json` removed from the native branch; docs moved under
  `docs/legacy-flutter/`; active CI rewritten in `.github/workflows/ci.yml`;
  archive refs and native transition branch pushed to GitHub on 2026-06-25; PR
  #75 merged into `main` on 2026-06-25.
- [x] N-IOS-18 Reuse production ProsePal app identity for the native rewrite --
  evidence: tracked native bundle ID is `com.prosepal.prosepal` in
  `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`; URL type name, keychain
  service, and OSLog subsystems use the same product identity; staging/UAT is
  documented as local scheme plus staging Supabase/StoreKit configuration in
  `prosepal-ios/README.md`, `prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md`,
  `docs/DEVOPS.md`, `docs/SERVICE_CONFIG.md`, and
  `docs/SERVICE_ENDPOINTS.md`.
- [~] N-IOS-19 Add side-by-side ProsePal Staging internal UAT app identity --
  evidence: tracked native project has production target `ProsePal` with bundle
  ID `com.prosepal.prosepal` and staging target `ProsePal Staging` with bundle
  ID `com.prosepal.prosepal.staging` in
  `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`; `Info.plist` display name
  and URL scheme are build-setting driven; keychain/log identity derives from
  the app bundle ID; shared
  `prosepal-ios/ProsePal.xcodeproj/xcshareddata/xcschemes/ProsePal Staging.xcscheme`
  contains no secrets and points to `App/ProsePalStaging.storekit`; local scheme
  restore/verify scripts retarget ignored staging schemes to the staging app;
  `xcodebuild -scheme ProsePal -destination id=00008120-0008644C263B401E build`
  signs for the connected iPhone;
  `xcodebuild -scheme "ProsePal Local Staging" -destination id=00008120-0008644C263B401E build`
  previously failed against wildcard profile `iOS Team Provisioning Profile: *`
  without Sign in with Apple, then passed after the staging App ID/profile was
  configured on 2026-06-28. Partial until App Store Connect sandbox/TestFlight
  product strategy, Supabase staging auth settings, and physical-device
  side-by-side install/auth/generation proof are complete.
- [~] N-IOS-16 Harden Supabase public API and linter posture for native release
  -- evidence: Supabase database linter reported `user_usage` GraphQL exposure
  to `authenticated` plus public/signed-in `SECURITY DEFINER` RPC exposure for
  `check_device_free_tier`, `check_rate_limit`, `check_and_increment_usage`, and
  `sync_user_usage` on 2026-06-26; current intentional grants are documented in
  `supabase/migrations/022_lock_down_client_api_privileges.sql`; native repo-side
  hardening is prepared in
  `supabase/migrations/025_harden_native_usage_api_surface.sql`,
  `supabase/functions/generate-card/index.ts`, and
  `scripts/verify_supabase_readonly.sh`, moving generation usage enforcement to a
  service-role gateway path and removing legacy client table/RPC privileges when
  applied. Partial until a human applies guarded staging migrations only, proves
  Supabase linter output is clean or explicitly accepted with rationale, and
  captures staging evidence without touching production.
- [x] App opens into the Moment experience rather than the legacy grouped
  create form -- evidence: `ProsePalNativeApp.body` in
  `prosepal-ios/App/ProsePalNativeApp.swift` constructs `MomentAppRootView`.
- [x] Saved is a local, user-curated library with copy/share/edit/delete -- evidence:
  `SavedMomentDraftRecord` in `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`,
  `SavedMomentDraftsView` and `SavedMomentDraftDetailView` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`, and saved-record
  tests in `prosepal-ios/Tests/ProsePalAPITests/RelationshipVaultTests.swift`.
- [~] Settings covers account, subscription, writing, privacy, support, legal,
  and about -- evidence: `MomentSettingsView` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`,
  `MomentAccountModel` in `prosepal-ios/Sources/ProsePalUI/MomentAccountModel.swift`,
  `docs/FEATURE_STATUS.csv` row `US-040`, and staging screenshots under
  `prosepal-ios/evidence/feature-status/us-040-staging-*.jpg`. Partial because
  account deletion/subscription flows still need full staging/App Review
  evidence.
- [x] Legacy grouped create/results path is retired -- evidence:
  `ProsePalNativeApp.swift` constructs `MomentAppRootView`; the dead grouped
  form source files `ProsePalRootView.swift` and `LegacyComposeModels.swift`
  have been removed; no `ProsePalAppModel`, `MessageDraft`, or `SavedMessage`
  references remain under `prosepal-ios/Sources` or `prosepal-ios/Tests`.

## 2. Moment Experience

- [x] Moment input captures person, relationship, occasion, register, and one
  true thing -- evidence: `MomentInput` in
  `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`; `MomentSheetView`
  sections in `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
- [~] Three registers exist and route by stakes: react, confess, assemble --
  evidence: `MomentRegister` and `requiresCarefulLane` in
  `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`; routing tests in
  `prosepal-ios/Tests/ProsePalAPITests/MessageWritingServiceTests.swift`.
  Partial because "assemble/generate less" is not yet proven with human-reviewed
  output evidence.
- [x] Draft adjustment actions exist for warmer, shorter, and more direct --
  evidence: `DraftAdjustment`, `MessageWritingService.adjust`, and
  `MomentModel.adjust(_:)` in `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`,
  `prosepal-ios/Sources/ProsePalAPI/MessageWritingService.swift`, and
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
- [~] Voice capture for "say the messy thing" exists -- evidence:
  `MomentVoiceCaptureModel`, `MomentVoiceCaptureTranscribing`, and the
  iOS-only `AppleSpeechMomentVoiceTranscriber` in
  `prosepal-ios/Sources/ProsePalUI/MomentVoiceCapture.swift`; the Moment sheet
  mic control and `MomentVoiceCaptureSheet` live in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; microphone and
  speech-recognition permission strings are in `prosepal-ios/App/Info.plist`;
  state coverage lives in
  `prosepal-ios/Tests/ProsePalUITests/MomentVoiceCaptureTests.swift`.
  Partial because simulator proof confirms the UI and unavailable state, while
  successful live speech transcription still needs physical-device evidence.
- [~] Draft actions cover copy, share, save, edit, and send/share handoff --
  evidence: active draft copy/share/save/edit actions live in `MomentSheetView`
  through `copyButton(text:)`, `shareButton(text:)`,
  `updateActiveDraftMessage(_:)`, and the state-driven `MomentActivityView`;
  saved draft edit exists in the saved-detail path; and draft edit tests exist in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift` and
  `prosepal-ios/Tests/ProsePalUITests/MomentModelTests.swift`. Partial because
  an explicit send handoff is not implemented for Moment drafts.
- [x] N-IOS-17 Protect user drafts during AI refinement -- evidence:
  `MomentModel.draftSnapshots`, `previousDraftBundle`, `restorePreviousDraft()`,
  `restoreDraftSnapshot(id:)`, `updateActiveDraftMessage(_:)`,
  `keepCurrentDraftChange()`, `MomentDraftHistorySheet`,
  `MomentDraftRecoveryStore`, and the visible `Undo edit` / `Keep edits` /
  `Undo rewrite` / `Keep rewrite` / `History` actions in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; undo/failure,
  history, restart recovery, and Start over clearing tests in
  `prosepal-ios/Tests/ProsePalUITests/MomentModelTests.swift`; XcodeBuildMCP
  runtime proof reopened `For Recovery Test` with `Draft ready` after app
  relaunch, then Start over returned to the first-entry screen. Local autosave
  persists active drafts across app lifecycle boundaries, substantial AI edits
  create recoverable snapshots, refinement results expose explicit keep/undo,
  accepted rewrites remain recoverable through history, and cancellation/failure
  paths keep current text.
- [x] Draft body reads like correspondence rather than a chat bubble --
  evidence: serif editable draft body in
  `MomentSheetView.draftBody(_:)` inside
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.

## 3. Relationship Memory And Voice

- [x] Manual Truth Beads are implemented -- evidence:
  `RelationshipTruthBeadRecord` in
  `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`; bead UI in
  `MomentMemorySection` inside
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
- [x] Truth Beads can be added, edited, corrected, deleted, and explained --
  evidence: `MomentMemorySection`, `MomentMemoryManagementView`, and
  `MomentTruthBeadEditor` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
- [~] Relationship memory is local SwiftData and not silently inferred --
  evidence: `RelationshipVaultSchema` and `SwiftDataRelationshipMemoryProvider`
  in `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`; model container
  setup in `prosepal-ios/App/ProsePalNativeApp.swift`. Partial because the
  SwiftData store backup/encryption/export posture still needs a dedicated
  privacy review.
- [x] Relationship memory lookups use stable persisted person keys instead of
  in-memory locale-dependent filtering -- evidence:
  `RelationshipTruthBeadRecord`, `RelationshipVoiceCardRecord`, and
  `SavedMomentDraftRecord` persist `normalizedPersonName`;
  `SwiftDataRelationshipMemoryProvider.approvedTruthBeads(for:)` and
  `approvedVoiceCard(for:)` query that key with SwiftData predicates after
  backfilling missing keys; normalization uses `en_US_POSIX` in
  `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`. Covered by
  `RelationshipVaultTests` for case, diacritic, whitespace, and legacy empty-key
  backfill behavior.
- [x] Contacts/Calendar enrichment is not silently active -- evidence: no
  `EventKit` or `Contacts` implementation found under `prosepal-ios/Sources`.
- [x] Voice Card exists as user-approved memory -- evidence:
  `RelationshipVoiceCardRecord` in
  `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`; voice-card UI in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; approved
  voice-card lookup and style-only prompt guard in
  `prosepal-ios/Tests/ProsePalAPITests/RelationshipVaultTests.swift`.
  Spoken voice input is tracked separately as the Moment voice capture feature.

## 4. AI Architecture

- [x] UI depends on `MessageWritingService`, not provider/model details --
  evidence: `prosepal-ios/Sources/ProsePalAPI/MessageWritingService.swift`,
  `MessageWritingServiceFactory` in `prosepal-ios/App/ProsePalNativeApp.swift`.
- [x] Private draft lane uses Foundation Models with typed guided generation --
  evidence: `FoundationModelsPrivateDraftClient`,
  `PrivateDraftContent: @Generable`, and `@Guide` fields in
  `prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift`.
- [x] Private draft lane can read relationship memory through a vault tool --
  evidence: `RelationshipMemoryTool: Tool` in
  `prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift`;
  `SwiftDataRelationshipMemoryProvider` in
  `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`.
- [x] Foundation Models availability is gated at runtime -- evidence:
  `ensureModelAvailable()` and `isDefaultModelAvailable` in
  `prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift`;
  `RuntimeReadinessFactory` in `prosepal-ios/App/ProsePalNativeApp.swift`.
- [~] Take more care lane is operational and decoupled from Premium billing;
  target Apple Private Cloud Compute / AFM Cloud remains future work --
  evidence: `GatewayCarefulMomentClient` requests `.standard` while returning
  product lane `.takeMoreCare` in
  `prosepal-ios/Sources/ProsePalAPI/GatewayCarefulMomentClient.swift`;
  `RoutingMessageWritingService` falls back from careful failure to private
  drafting in `prosepal-ios/Sources/ProsePalAPI/MessageWritingService.swift`;
  tests in `prosepal-ios/Tests/ProsePalAPITests/MessageWritingServiceTests.swift`.
- [x] Router chooses private vs careful by stakes and handles private fallback --
  evidence: `RoutingMessageWritingService` in
  `prosepal-ios/Sources/ProsePalAPI/MessageWritingService.swift`; tests in
  `prosepal-ios/Tests/ProsePalAPITests/MessageWritingServiceTests.swift`.
- [ ] Future `LanguageModel` provider-protocol escape hatch is implemented --
  evidence: no provider-protocol adapter implementation found in
  `prosepal-ios/Sources`.
- [x] Client-side template generation is not part of the Moment service --
  evidence: production factory wires `FoundationModelsPrivateDraftClient` and
  `GatewayCarefulMomentClient` in `prosepal-ios/App/ProsePalNativeApp.swift`;
  test/preview-only drafting uses `MockMomentDraftClient` in
  `prosepal-ios/Sources/ProsePalAPI/MessageWritingService.swift`.

## 5. Safety

- [~] Crisis path redirects rather than drafting -- evidence:
  `String.indicatesCrisisSupportNeed`, `MomentSafetySignal`, and
  `MomentModel.canDraft` in `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`
  and `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; simulator
  evidence in
  `prosepal-ios/evidence/feature-status/us-009-crisis-block-fixed.jpg` and
  `prosepal-ios/evidence/feature-status/us-009-crisis-support-actions.jpg`.
  `ERR-UX-009` fixed the disabled draft card so crisis state explains the safety
  block instead of showing generic missing-context copy. Partial because
  detection is a hardcoded English phrase list, not a model guardrail signal with
  locale awareness.
- [~] Pressure Check provides subtractive feedback -- evidence:
  `PressureCheck.local(messageText:moment:)` in
  `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`; private-lane
  typed fields in `FoundationModelsPrivateDraftClient.swift`; actionable Keep
  draft and Clean up/Make direct controls in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; model tests in
  `prosepal-ios/Tests/ProsePalUITests/MomentModelTests.swift`; simulator
  evidence in
  `prosepal-ios/evidence/feature-status/us-019-pressure-check-controls.jpg`,
  `prosepal-ios/evidence/feature-status/us-019-pressure-check-clean-up-fixed.jpg`,
  and `prosepal-ios/evidence/feature-status/us-019-pressure-check-keep-draft.jpg`.
  `ERR-UX-008` fixed cleanup looping when a local pressure finding persisted
  from the original true detail. Partial because the current detection remains
  local phrase-list heuristics and broader safety copy review is still needed.
- [~] Careful Mode calms sensitive moments -- evidence: `MomentInput.isCarefulMode`
  and `carefulModeSection` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; sensitive
  moments align away from `React` into `Take care`, and sensitive careful-lane
  failure falls back to private drafting in
  `prosepal-ios/Sources/ProsePalAPI/MessageWritingService.swift`. Partial
  because register-specific palette, whitespace, and haptic changes are not
  complete.
- [~] The app avoids therapy/crisis overreach -- evidence: crisis-support copy
  and draft blocking in `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
  Partial pending safety copy review and broader examples.

## 6. OS Surfaces

- [~] App Intents / Siri / Shortcuts can start or resume a Moment --
  evidence: `prosepal-ios/Sources/ProsePalUI/ProsePalAppIntents.swift`,
  `prosepal-ios/App/ProsePalAppShortcuts.swift`. Partial because device evidence
  and shortcut QA are still needed.
- [~] Care Glance WidgetKit widget exists -- evidence:
  `CareGlanceWidget`, `CareGlanceProvider`, and `ProsePalWidgetsBundle` live in
  `prosepal-ios/Widgets/ProsePalWidgets.swift`; `ProsePalWidgets` and
  `ProsePalWidgetsStaging` are WidgetKit app-extension targets embedded in the
  matching production/staging app targets in
  `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`; `Widgets/Info.plist`
  declares `com.apple.widgetkit-extension`; `SystemSurfaceProjectTests` guard
  the target wiring and declarations; the built staging app contains
  `PlugIns/ProsePalWidgetsStaging.appex`. Partial pending actual widget
  gallery/add/tap proof on simulator or device.
- [~] Control Center / Action Button control exists -- evidence:
  `StartMomentControlWidget` uses `ControlWidgetButton` with an
  `OpenURLIntent` handoff to the production or staging Moment URL scheme in
  `prosepal-ios/Widgets/ProsePalWidgets.swift`, inside the WidgetKit extension
  targets; `ProsePalAppIntentsTests` cover the `control_center` deep-link source
  and `SystemSurfaceProjectTests` guard the control declaration. Partial pending
  Control Center / Action Button configuration proof on device.
- [~] Share extension turns outside context into a Moment -- evidence:
  `ProsePalShareExtension` and `ProsePalShareExtensionStaging` are
  share-services app-extension targets embedded in their matching app targets in
  `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`;
  `prosepal-ios/ShareExtension/ShareViewController.swift` reads text/URL share
  items, stores sanitized context in the app-group payload key, and opens the
  production or staging Moment URL scheme based on extension bundle identity;
  `MomentAppRootView` consumes that payload into the Moment detail;
  `SystemSurfaceProjectTests`,
  `ProsePalAppIntentsTests`, and `NativeDiagnosticsTests` guard project wiring,
  payload handling, and metadata-only diagnostics; Safari's source-app share
  sheet shows the `ProsePal` activity in
  `prosepal-ios/evidence/feature-status/us-048-safari-share-sheet-prosepal.jpg`;
  production and staging extension targets now define non-empty
  `CFBundleDisplayName` build settings, and XcodeBuildMCP production build/run
  succeeded after `ERR-INSTALL-001` fixed the empty-display-name install blocker.
  Partial pending tap-through extension UI and app handoff proof on simulator or
  device.
- [ ] System writing/text tooling is explicitly integrated -- evidence: no
  dedicated writing-tools integration found under `prosepal-ios/Sources`.

## 7. Monetization

- [x] Native app uses StoreKit 2 directly, with no RevenueCat dependency --
  evidence: `StoreKitSubscriptionClient` in
  `prosepal-ios/Sources/ProsePalAPI/SubscriptionClient.swift`; no third-party
  dependencies in `prosepal-ios/Package.swift`;
  `nativeDependencyGuardDoesNotIncludeThirdPartyProviderSDKs()` in
  `prosepal-ios/Tests/ProsePalUITests/NativeGuardrailTests.swift`; the active
  Supabase `revenuecat-webhook` function and config entry have been removed from
  the native repo.
- [~] Server entitlement is authoritative through App Store Server
  Notifications V2 JWS and reconciliation -- evidence:
  `supabase/functions/app-store-notifications/index.ts`,
  `supabase/functions/app-store-notifications/index.test.ts`,
  `supabase/functions/app-store-reconcile-entitlement/index.ts`,
  `supabase/functions/app-store-reconcile-entitlement/index.test.ts`,
  `supabase/migrations/023_add_app_store_entitlement_metadata.sql`, and
  `supabase/migrations/024_add_app_store_reconciliation_events.sql`. Partial
  because both functions are deployed and reachable in staging, but staging
  does not yet have Apple root certificates, App Store Server API credentials,
  the reconcile shared secret, or migration-application evidence, so live App
  Store sandbox verification is still outstanding.
- [ ] Premium/extras gateway access is authorized by server entitlement --
  evidence: careful/sensitive drafting is deliberately decoupled from Premium
  billing in `GatewayCarefulMomentClient.swift` and
  `MessageWritingService.swift`; App Store notification ingestion now updates
  `user_entitlements`, but `generate-card` still rejects Premium by design and
  no paid limits/extras gateway policy has been wired.
- [~] Paywall is App Review-oriented: price/period, restore, Terms, Privacy,
  no forced sign-in -- evidence: `MomentPaywallSheet` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`,
  `docs/FEATURE_STATUS.csv` row `US-036`, and
  `prosepal-ios/evidence/feature-status/us-036-staging-product-ids-wired-products-unavailable.jpg`.
  Partial because staging now passes product IDs into the app, but StoreKit
  still returns zero products under the current simulator launch; local StoreKit
  product-serving, TestFlight/sandbox plan-selection, and active restore
  evidence remain outstanding.
- [~] Account deletion exists once account creation exists -- evidence:
  `SupabaseAccountMaintenanceClient` in
  `prosepal-ios/Sources/ProsePalAPI/AccountMaintenanceClient.swift`,
  `supabase/functions/delete-user/index.ts`, and settings UI in
  `MomentSettingsView`; local SwiftData vault wipe is wired through
  `RelationshipVaultLocalDataEraser` and covered in
  `prosepal-ios/Tests/ProsePalUITests/MomentAccountModelTests.swift`.
  Partial pending full App Review/account-provider evidence.
- [~] Restore, identity/account switch, and entitlement convergence are covered --
  evidence: restore/local entitlement code in
  `prosepal-ios/Sources/ProsePalAPI/SubscriptionClient.swift`; signed-in
  purchases attach StoreKit `appAccountToken` from
  `prosepal-ios/App/ProsePalNativeApp.swift`; account/purchase tests in
  `prosepal-ios/Tests/ProsePalUITests/MomentAccountModelTests.swift`; server
  reconciliation path in
  `supabase/functions/app-store-reconcile-entitlement/index.ts`. Partial
  because sandbox reconciliation has not been proven against real App Store
  Server API responses, anonymous-purchase convergence still needs policy, and
  Google-to-Apple continuity relies on Supabase Auth identity linking behavior
  rather than a native manual link flow. Supabase documents automatic identity
  linking for matching email addresses and separate manual/native-ID-token
  linking for different-email cases:
  <https://supabase.com/docs/guides/auth/auth-identity-linking>. DoD: prove an
  existing Google-authenticated subscribed user can sign in with Apple and keep
  the same Supabase user/entitlement for both shared-email and Hide My Email or
  private-relay cases, or add an explicit account-linking/recovery flow.
- [ ] StoreKit `appAccountToken` mapping remains money-correct and server-aligned
  -- evidence: `SubscriptionClientFactory` only passes an `appAccountToken` when
  the current Supabase auth user id parses as a UUID in
  `prosepal-ios/App/ProsePalNativeApp.swift`; App Store notification and
  reconciliation functions treat UUID `appAccountToken` as the Supabase
  `user_entitlements.user_id` in
  `supabase/functions/app-store-notifications/index.ts`,
  `supabase/functions/app-store-reconcile-entitlement/index.ts`, and
  `supabase/migrations/009_create_user_entitlements.sql`. DoD: keep the current
  nil-if-not-UUID behavior unless a server-side mapping table/flow is designed;
  do not introduce a deterministic hashed UUID fallback in the client without
  proving entitlement convergence, account switch behavior, and unknown-user
  handling against staging App Store sandbox events.

## 8. Design

- [ ] UI execution plan is staged and reviewable -- evidence:
  `prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md` sets the product direction
  for an iOS 26-first, person-first Moment Sheet; current implementation lives
  primarily in `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`;
  XcodeBuildMCP staging run confirms the current first viewport is the intended
  person-first Moment flow. Plan:
  1. Extract stable visual primitives without behavior changes: Moment surfaces,
     hero/header, section labels, input rows, action rails, badges, and
     reduce-transparency fallbacks should become small SwiftUI components or
     focused files while keeping `MomentModel` state ownership unchanged.
  2. Tighten first-viewport and keyboard behavior: person input, committed
     person header, active setup, bottom rail clearance, and tab visibility must
     stay stable across standard text, accessibility Dynamic Type, keyboard
     focus, iPad widths, Increase Contrast, Reduce Motion, and Reduce
     Transparency.
  3. Refine the draft workspace: opaque paper-like draft content remains the
     primary reading surface; copy/share/save/edit/adjust/history actions stay
     nearby without covering text; pressure-check and crisis states remain clear
     safety surfaces, not decorative cards.
  4. Normalize presentation state: replace clusters of boolean sheets with
     enum/item-driven sheet presentation where it reduces state ambiguity, and
     keep sheets responsible for their own dismissal/actions unless parent state
     must change.
  5. Keep Liquid Glass restrained: apply native iOS 26 glass only to
     navigation/control layers, use `GlassEffectContainer` when grouped glass
     elements coexist, mark only interactive controls as interactive, and keep
     writing content opaque and readable.
  6. Bring Settings and Paywall into the same visual system: dense, native,
     App-Review-safe rows; no marketing landing-page treatment; loading,
     unavailable, restore, legal, and support states remain explicit.
  7. Review system entry handoffs visually: App Intent, widget, Control Center,
     and share-extension deep links should land in a recognisable Moment state
     without provider copy or raw shared text in the URL.
  8. Finish accessibility review as product behavior: VoiceOver order and
     labels, Switch Control reachability, Reduce Motion, Reduce Transparency,
     Increase Contrast, Dynamic Type, keyboard, safe-area, and iPad layout are
     acceptance gates, not polish tasks.
  Review loop for each UI slice: apply SwiftUI state-ownership and sheet-routing
  checks; apply Liquid Glass availability/composition/modifier-order checks;
  build/run `ProsePal Staging` with XcodeBuildMCP; capture `snapshot_ui` for the
  touched screens; run relevant package tests plus `swift build`/`swift test`;
  update this backlog item or its child items with evidence. Partial because the
  plan exists, but execution remains open.
  The design system now lives in-repo at `design-system/`. Outstanding
  canonical-kit gaps: `06` dedicated generation state; `14`/`15` free/pro plan
  detail screens; `17` custom share/insert sheet; `18` copied toast; `19`
  offline banner/state; `20` generation-error full state; `21` quota-reached
  state; remaining stock detail/edit forms for relationship memory and saved
  drafts; full token parity for the in-repo color/radius/elevation/glass
  system; and final
  Dynamic Type/VoiceOver/Switch Control/physical-device review.
  Slice 1 evidence: visual primitives were extracted from
  `MomentExperienceView` into focused SwiftUI files
  (`MomentVisualTokens`, `MomentSymbolBadge`, `MomentIdentityCard`,
  `MomentBackgrounds`, `MomentViewModifiers`, `MomentSectionChrome`,
  `MomentRegisterSelector`); `swift build` and `swift test` passed; XcodeBuildMCP
  `ProsePal Staging` build/run passed on `iPhone 17` with
  `--prosepal-use-mock-writing-service`; `snapshot_ui` still exposes the
  person-first first viewport controls and tabs; screenshot captured at
  `/var/folders/w7/smr7zw112q55_g41ntxk4bjw0000gn/T/screenshot_optimized_b85d2b2b-655d-400d-bde8-eee035ba72db.jpg`.
  Slice 2 evidence: first-viewport setup now uses one `Moment setup` card for
  person, relationship, and moment selection; selection rows carry private/care
  accent state consistently in both initial and active setup layouts; `swift
  build` and `swift test` passed; XcodeBuildMCP `ProsePal Staging` build/run
  passed on `iPhone 17`; `snapshot_ui` confirmed reachable person,
  relationship, moment, and tab controls in private and care states; screenshots
  captured at
  `/var/folders/w7/smr7zw112q55_g41ntxk4bjw0000gn/T/screenshot_optimized_2e076346-9c9c-4be2-9306-43deacc358b2.jpg`
  and
  `/var/folders/w7/smr7zw112q55_g41ntxk4bjw0000gn/T/screenshot_optimized_89225015-31cd-4d01-bd7b-0666d735e25f.jpg`.
  Corrective Slice 3 evidence: realigned the visual tokens and first viewport
  against `design-system/readme.md` and
  the canonical `design-system/ui_kits/prosepal/`
  direction: warm cream paper/wash, ink text, deeper clay accent, sage as a
  supporting care/voice hue, light paper chrome, and no dark hero-card treatment
  on the first viewport. `swift build` and `swift test` passed; XcodeBuildMCP
  `ProsePal Staging` build/run passed on `iPhone 17`; `snapshot_ui` confirmed
  the person, relationship, moment, and tab controls remain reachable; screenshot
  captured at
  `/var/folders/w7/smr7zw112q55_g41ntxk4bjw0000gn/T/screenshot_optimized_b92b9fed-f58f-4be8-9d43-69400ec84ad8.jpg`.
  Slice 4 evidence: introduced the canonical writing-page primitive
  `MomentWritingPageSurface` for the active note and draft body: opaque cream
  paper, clay margin rule, faint ruled lines for note capture, serif writing
  text, and page-local mic/word-count/`Help me write` footer action. The active
  setup state now collapses to relationship/moment/register controls once the
  person is committed, and root chrome now reads `Today`, `Write`, and `Drafts`
  to better match the in-repo ProsePal kit while keeping the existing
  person-first flow. `swift build` and `swift test` passed; XcodeBuildMCP
  `ProsePal Staging` build/run passed on `iPhone 17` with
  `--prosepal-use-mock-writing-service`; `snapshot_ui` confirmed the active
  `The note`, mic, `Help me write`, generated `Your draft`, and copy/share/save
  controls remain reachable. Screenshots captured at
  `/var/folders/w7/smr7zw112q55_g41ntxk4bjw0000gn/T/screenshot_optimized_866a2f33-ecfc-4d5d-bc3a-ced19d1a1214.jpg`,
  `/var/folders/w7/smr7zw112q55_g41ntxk4bjw0000gn/T/screenshot_optimized_77ca4a57-d73d-4f63-8213-a81c17b4e440.jpg`,
  and
  `/var/folders/w7/smr7zw112q55_g41ntxk4bjw0000gn/T/screenshot_optimized_44e3ee11-0d03-4392-bbf6-96823378d33a.jpg`.
  Slice 5 evidence: performed a first-screen visual QA pass against rendered
  `05 · The page` from the in-repo ProsePal design-system kit, with local
  screenshots and metrics saved under
  `prosepal-ios/evidence/ui-design-qa/first-screen/`. The native first screen
  now uses fixed custom serif `Today` chrome, paper-first entry/active surfaces,
  tone controls directly beneath the writing page, compact context metadata,
  a floating dock-style control, and a corrected ruled-paper
  background that no longer drives page height. The visible `Next` action now
  commits the person without leaving keyboard accessory chrome on the clean
  active screen, while keyboard Return still advances into the note field.
  `swift build` and `swift test` passed; XcodeBuildMCP `ProsePal Staging`
  build/run passed on `iPhone 17`; `snapshot_ui` confirmed entry, active note,
  tone, context, dock, draft, and copy/share/save controls remain reachable.
  Latest comparison screenshots:
  `prosepal-ios/evidence/ui-design-qa/first-screen/01-reference-the-page-phone.png`,
  `prosepal-ios/evidence/ui-design-qa/first-screen/08-simulator-entry-after-fixed-top.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/first-screen/10-simulator-active-after-tone-order.jpg`.
  Slice 6 evidence: performed a draft-result visual QA pass against rendered
  `07 · Draft result` from the in-repo ProsePal design-system kit, with local
  screenshots and metrics saved under
  `prosepal-ios/evidence/ui-design-qa/draft-result/`. The generated state now
  branches into a result-first layout instead of leading with the source editor:
  compact `Today`/`A draft` chrome, a clean unruled draft card with italic tone
  label, variant dots, `Still unmistakably you`, inline `Copy`/`Another`/`Keep
  this` actions, a margin note, and a compact bottom refine rail. The source
  editor remains reachable through `Today` without destroying the generated
  draft. `swift build` and `swift test` passed; XcodeBuildMCP `ProsePal Staging`
  build/run passed on `iPhone 17` with
  `--prosepal-use-mock-writing-service`; `snapshot_ui` confirmed draft text,
  copy, rewrite, keep, margin note, and refine actions remain reachable.
  Latest comparison screenshots:
  `prosepal-ios/evidence/ui-design-qa/draft-result/01-reference-draft-result-phone.png`,
  `prosepal-ios/evidence/ui-design-qa/draft-result/02-simulator-draft-before.jpg`,
  `prosepal-ios/evidence/ui-design-qa/draft-result/03-simulator-draft-body-before.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/draft-result/04-simulator-draft-after.jpg`.
  Slice 7 evidence: performed a Revise visual QA pass against rendered
  `08 · Revise` from the in-repo ProsePal design-system kit, with local
  screenshots and metrics saved under `prosepal-ios/evidence/ui-design-qa/revise/`.
  The generated draft now has a dedicated Revise shell instead of only direct
  text editing inside the result card: compact `Revise` chrome, segmented
  `Draft`/`Changes`/`Original` controls, a ruled active editing page, replacement
  suggestion chips, revision tone chips using the existing `Warmer`/`Shorter`/
  `Direct` domain actions, and a bottom `Keep this draft` command. `swift build`
  and `swift test` passed; XcodeBuildMCP `ProsePal Staging` build/run passed on
  `iPhone 17` with `--prosepal-use-mock-writing-service`; `snapshot_ui` confirmed
  the revise shell targets and `Done` returned to the draft result without
  destroying the active draft. Latest comparison screenshots:
  `prosepal-ios/evidence/ui-design-qa/revise/01-reference-revise-phone.png`,
  `prosepal-ios/evidence/ui-design-qa/revise/02-simulator-revise-before.jpg`,
  `prosepal-ios/evidence/ui-design-qa/revise/03-simulator-revise-after.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/revise/04-simulator-revise-after-tightened.jpg`.
  Slice 8 evidence: performed a Drafts library visual QA pass against the
  rendered Drafts screen from the in-repo ProsePal design-system kit, with local
  screenshots and metrics saved under
  `prosepal-ios/evidence/ui-design-qa/drafts-library/`. The saved-drafts screen
  now uses custom large-serif Drafts chrome, top search toggle, `All`/`Kept`/
  `Used`/`Drafts` filter chips, cream saved-draft cards with occasion icon,
  subtitle, `Kept` badge, serif excerpt, and relative saved time. This replaces
  the prior standard `List` shell whose `.searchable` field collided with the
  floating dock. `swift build` and `swift test` passed; XcodeBuildMCP
  `ProsePal Staging` build/run passed on `iPhone 17` with
  `--prosepal-use-mock-writing-service`; `snapshot_ui` confirmed the Drafts
  title, search toggle, filters, saved card, badge, and root dock remain
  reachable. Latest comparison screenshots:
  `prosepal-ios/evidence/ui-design-qa/drafts-library/01-reference-drafts-phone.png`,
  `prosepal-ios/evidence/ui-design-qa/drafts-library/02-simulator-drafts-before.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/drafts-library/03-simulator-drafts-after.jpg`.
  Slice 9 evidence: performed a Version history visual QA pass against the
  rendered `10 · Version history` screen from the in-repo ProsePal design-system
  kit, with local screenshots saved under
  `prosepal-ios/evidence/ui-design-qa/version-history/`. Draft history now opens
  as a full-screen iOS cover instead of a medium bottom sheet, and uses the kit
  timeline anatomy: compact `Draft`/`Version history` chrome, left timeline
  rail, clay current node, cream version cards, a `Showing now` marker,
  three-line serif excerpts, and explicit `Restore` actions. The result-first
  refine rail now surfaces `History` first once recoverable draft snapshots
  exist. `swift build` and `swift test` passed; XcodeBuildMCP `ProsePal Staging`
  build/run passed on `iPhone 17` with `--prosepal-use-mock-writing-service`;
  `snapshot_ui` confirmed the History chip, current timeline item, recoverable
  snapshots, `Restore`, and `Back to draft`, and a restore action dismissed the
  cover and reverted the active draft. Latest comparison screenshots:
  `prosepal-ios/evidence/ui-design-qa/version-history/01-reference-version-history-phone.png`,
  `prosepal-ios/evidence/ui-design-qa/version-history/02-simulator-version-history-medium-before.jpg`,
  `prosepal-ios/evidence/ui-design-qa/version-history/03-simulator-version-history-fullscreen-after.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/version-history/04-simulator-version-history-after-tightened.jpg`.
  Slice 10 evidence: performed an Empty library visual QA pass against rendered
  `11 · Empty library` from the in-repo ProsePal design-system kit, with local
  screenshots saved under `prosepal-ios/evidence/ui-design-qa/drafts-empty/`.
  The first-run Drafts screen now suppresses search and filter chrome, uses a
  centered unframed empty state with the kit copy (`Nothing here yet` and
  `Every message you shape with ProsePal lands here — ready to revisit, reuse,
  or refine.`), and exposes a clay `Write your first` command that returns to the
  Moment tab. Filter/search empty states keep the existing shared empty card so
  relationship-memory empty states are not restyled by accident. `swift build`
  and `swift test` passed; XcodeBuildMCP `ProsePal Staging` build/run passed on
  `iPhone 17` with `--prosepal-use-mock-writing-service` after uninstalling only
  the staging bundle to verify a clean empty library; `snapshot_ui` confirmed the
  empty title, copy, CTA, dock, and return-to-Moment action remain reachable.
  Latest comparison screenshots:
  `prosepal-ios/evidence/ui-design-qa/drafts-empty/01-reference-empty-library-phone.png`,
  `prosepal-ios/evidence/ui-design-qa/drafts-empty/02-simulator-empty-library-after.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/drafts-empty/03-simulator-empty-library-after-lowered.jpg`.
  Slice 11 evidence: performed a Settings visual QA pass against rendered
  `12 · Settings` from the in-repo ProsePal design-system kit, with local
  screenshots saved under `prosepal-ios/evidence/ui-design-qa/settings/`, and
  revisited the first-screen hierarchy from `05 · The page`. Settings now uses
  custom large-serif chrome, a profile card, compact Writing/Privacy/Subscription
  groups, no overlapping root dock, and preserves restore purchases below the
  first Subscription group. The Moment entry and active-note first viewports now
  keep relationship/moment context below the primary writing viewport instead of
  competing with the page and tone controls; a swipe still reaches context and
  relationship-memory controls. `swift build` and `swift test` passed;
  XcodeBuildMCP
  `ProsePal Staging` build/run passed on `iPhone 17` with
  `--prosepal-use-mock-writing-service`; `snapshot_ui` confirmed entry, active
  note, settings, context, and memory controls remain reachable. Latest
  comparison screenshots:
  `prosepal-ios/evidence/ui-design-qa/settings/01-reference-settings-phone.png`,
  `prosepal-ios/evidence/ui-design-qa/settings/02-simulator-settings-after-dock-fix.jpg`,
  `prosepal-ios/evidence/ui-design-qa/first-screen/11-simulator-entry-after-context-below-fold.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/first-screen/12-simulator-active-after-context-below-fold.jpg`.
  Slice 12 evidence: performed a Paywall visual-system pass against the in-repo
  ProsePal design-system Paywall source in
  `design-system/ui_kits/prosepal/screens-3.jsx`,
  with local simulator evidence saved under
  `prosepal-ios/evidence/ui-design-qa/paywall/`. The paywall now uses custom
  close/restore chrome instead of a system `Premium` navigation title, an italic
  serif promise (`A room of your own.`), a single cream feature panel, kit-aligned
  unavailable/retry and plan-row surfaces, App Review-visible restore, account
  sign-in, and Terms/Privacy links. `swift build` and `swift test` passed;
  XcodeBuildMCP
  `ProsePal Staging` build/run passed on `iPhone 17` with
  `--prosepal-use-mock-writing-service`; `snapshot_ui` confirmed the real
  unavailable StoreKit state still exposes Retry, Restore, Continue with Apple,
  Terms, and Privacy. Latest simulator screenshot:
  `prosepal-ios/evidence/ui-design-qa/paywall/02-simulator-paywall-unavailable-after.jpg`.
  Slice 13 evidence: performed a Privacy & data visual-system pass against the
  in-repo ProsePal design-system `Privacy` source in
  `design-system/ui_kits/prosepal/screens-3.jsx`,
  with local simulator evidence saved under
  `prosepal-ios/evidence/ui-design-qa/privacy-data/`. Settings now opens a real
  Privacy & data overview before export: custom Settings back chrome, trust note,
  Controls rows for on-device drafts and metadata-only diagnostics, Your data
  rows for export and confirmed local delete, and a Privacy Policy link. The
  existing JSON export remains reachable as a second-level screen, and the local
  delete action uses the existing `RelationshipVaultLocalDataEraser` behind a
  confirmation dialog. `swift build` and `swift test` passed; XcodeBuildMCP
  `ProsePal Staging` build/run passed on `iPhone 17` with
  `--prosepal-use-mock-writing-service`;
  `snapshot_ui` confirmed Privacy & data, export, delete confirmation, and
  Privacy Policy controls remain reachable. A follow-up spacing pass increased
  trust-note and row padding after simulator review showed the first version was
  too bunched. Export detail now uses the same custom paper/card visual system
  rather than a stock `List`; simulator review covered both top and scrolled
  states so rows do not slide under the status/Dynamic Island area. Latest
  simulator screenshots:
  `prosepal-ios/evidence/ui-design-qa/privacy-data/03-simulator-privacy-data-after-padding.jpg`,
  `prosepal-ios/evidence/ui-design-qa/privacy-data/export-detail/01-export-detail-top.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/privacy-data/export-detail/02-export-detail-scrolled.jpg`.
  Slice 14 evidence: performed an onboarding visual-system pass against rendered
  `01`-`04` from the in-repo ProsePal design-system source in
  `design-system/ui_kits/prosepal/screens-1.jsx`, with local simulator evidence
  saved under `prosepal-ios/evidence/ui-design-qa/onboarding/`. The old single
  dark welcome screen is replaced by a four-panel first-run flow with top
  progress dots, centered crest/title/body composition, kit copy for Welcome,
  How it works, Privacy promise, and Ready, and fixed footer actions. The
  primary action advances through panels; the first-panel account shortcut and
  final-panel Maybe later action complete onboarding through the existing
  `MomentWelcomeState` persistence. `swift build` and `swift test` passed;
  XcodeBuildMCP `ProsePal Staging` build/run passed on `iPhone 17` with
  `--prosepal-use-mock-writing-service`; the staging simulator app was
  uninstalled/reinstalled to verify true first-run behavior; `snapshot_ui`
  confirmed all four panels and footer targets, and final completion landed on
  the Moment `Today` screen. Latest simulator screenshots:
  `prosepal-ios/evidence/ui-design-qa/onboarding/01-simulator-welcome.jpg`,
  `prosepal-ios/evidence/ui-design-qa/onboarding/02-simulator-how-it-works.jpg`,
  `prosepal-ios/evidence/ui-design-qa/onboarding/03-simulator-privacy.jpg`,
  and
  `prosepal-ios/evidence/ui-design-qa/onboarding/04-simulator-ready.jpg`.
- [~] N-IOS-14 Native visual system and Moment rail/content discipline --
  evidence: `MomentSheetView.momentContent(viewportHeight:)`,
  `draftStartSection`, `shouldShowTabRail`, and `startNewMoment()` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  XcodeBuildMCP simulator evidence covers the explicit `Mira Audit` active
  compose path and rail avoidance, plus the custom Relationship memory vault
  empty/populated overview states under
  `prosepal-ios/evidence/ui-design-qa/memory-vault/`. The populated row was
  seeded through the normal mock Moment flow and verified to navigate into the
  existing detail form. Physical-device, Dynamic Type, VoiceOver, Switch
  Control, and remaining detail-form polish remain.
- [~] iOS 26-first Liquid Glass direction is in code -- evidence:
  iOS 26 deployment target in `prosepal-ios/Package.swift` and
  `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`; control-layer styling in
  `momentControlBarSurface()` and navigation/control color-scheme modifiers in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  Xcode 26/device visual verification.
- [~] Opaque paper-like content sits beneath floating controls -- evidence:
  `MomentCardBackground`, `MomentSymbolBadge`, `MomentBottomRailClearance`,
  `MomentSheetView.momentContent(viewportHeight:)`, and active first-viewport
  rail/content gating in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  physical-device and accessibility audit.
- [~] Register-aware palette and haptics exist -- evidence:
  `MomentRegisterSelector`, register-aware `MomentCardBackground` styling, and
  careful-mode surface colors in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  grief/sensitive haptic policy is not fully evidenced.
- [~] Accessibility is treated as architecture -- evidence: visible controls,
  labels, Dynamic Type-friendly SwiftUI, selectable text, and the accessibility
  Dynamic Type first-entry header/tab-rail behavior plus inline draft actions at
  accessibility text sizes in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; AX-XXXL plus
  Increase Contrast before/after evidence lives in
  `prosepal-ios/evidence/feature-status/us-053-accessibility-large-text-overlap-before.jpg`
  and
  `prosepal-ios/evidence/feature-status/us-053-accessibility-large-text-fixed.jpg`;
  generated draft and rewrite action evidence lives in
  `prosepal-ios/evidence/feature-status/us-053-accessibility-inline-actions-fixed.jpg`
  and
  `prosepal-ios/evidence/feature-status/us-053-accessibility-inline-rewrite-actions-fixed.jpg`;
  forced Reduce Transparency evidence lives in
  `prosepal-ios/evidence/feature-status/us-053-reduce-transparency-first-entry.jpg`
  and
  `prosepal-ios/evidence/feature-status/us-053-reduce-transparency-action-rail.jpg`.
  Partial pending VoiceOver, Switch Control, broader AX-size flow, and
  physical-device evidence.

## 9. Platform And Engineering

- [~] Swift 6 and strict-concurrency direction are active -- evidence:
  `swift-tools-version: 6.2` in `prosepal-ios/Package.swift`; `SWIFT_VERSION = 6.0`
  in `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`. Partial pending
  strict-concurrency audit under Xcode 26/device builds.
- [x] View models use `@Observable`, not `ObservableObject` -- evidence:
  `MomentModel` and `MomentAccountModel` in `prosepal-ios/Sources/ProsePalUI`;
  no `ObservableObject` references remain under `prosepal-ios/Sources`.
- [~] SwiftData and Swift Testing are used for new native code -- evidence:
  `RelationshipVault.swift`, `MomentModelTests.swift`,
  `MessageWritingServiceTests.swift`, and `RelationshipVaultTests.swift`.
  Partial because some legacy tests still use XCTest.
- [x] Package has zero third-party dependencies -- evidence:
  `prosepal-ios/Package.swift` and
  `nativeDependencyGuardDoesNotIncludeThirdPartyProviderSDKs()` in
  `prosepal-ios/Tests/ProsePalUITests/NativeGuardrailTests.swift`.
- [x] Native target is iOS 26-first -- evidence:
  `platforms: [.iOS(.v26)]` in `prosepal-ios/Package.swift` and
  `IPHONEOS_DEPLOYMENT_TARGET = 26.0` in
  `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`.
- [x] Monolith UI has been split for the new flow -- evidence:
  Moment-specific files exist under `prosepal-ios/Sources/ProsePalUI`, and the
  legacy compiled monolith `ProsePalRootView.swift` has been removed.

## 10. Privacy And Telemetry

- [~] Private lane avoids sending message text off device -- evidence:
  `FoundationModelsPrivateDraftClient` in
  `prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift`.
  Partial because careful lane still uses the Supabase gateway rather than
  Private Cloud Compute.
- [x] Client diagnostics are metadata-only -- evidence:
  `NativeDiagnosticsLogger` in
  `prosepal-ios/Sources/ProsePalUI/NativeDiagnosticsLogger.swift`; tests in
  `prosepal-ios/Tests/ProsePalUITests/NativeDiagnosticsTests.swift`.
- [~] Vault storage, deletion, export, and backup behavior are privacy-reviewed --
  evidence: SwiftData records and backup-excluded Application Support store
  location plus local JSON export snapshot/writer in
  `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`, app container
  wiring in `prosepal-ios/App/ProsePalNativeApp.swift`, and filesystem coverage
  in
  `prosepal-ios/Tests/ProsePalAPITests/RelationshipVaultTests.swift`.
  Partial because any stronger at-rest encryption decision still needs dedicated
  product/security review.
- [x] Local vault export provides a working in-app export destination -- evidence:
  `RelationshipVaultExporter` creates a JSON export; `MomentLocalDataExportView`
  shows counts, filename, JSON preview, and Copy JSON in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; XcodeBuildMCP
  simulator proof shows the Export screen and `xcrun simctl pbpaste` verified
  copied JSON with `schemaVersion`, `savedDrafts`, `truthBeads`, and
  `voiceCards`. Exporter tests prove user data is included without internal
  lookup keys.
- [x] Relationship vault failure and erase paths are release-resilient --
  evidence: `RelationshipVaultContainerFactory.makePersistentOrEphemeral()`
  falls back to an ephemeral vault instead of crashing when the persistent store
  cannot open; `RelationshipVaultLocalDataEraser.eraseAll(in:)` creates its own
  context from a `ModelContainer`/vault result and removes dedicated vault store
  files when erasing from fallback mode; account deletion awaits that async erase
  boundary in `MomentAccountModel` wiring. Covered by
  `RelationshipVaultTests` for unavailable persistent store fallback, non-empty
  container erase, and fallback store-file cleanup.

## 11. Quality Gates / Acceptance

- [~] Acceptance demo exists: open, person, moment, one true thing, write draft,
  adjust, copy/share/save -- evidence: `MomentAppRootView`, `MomentSheetView`,
  `MomentActivityView`, and `MomentModel` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  physical-device evidence after the latest Moment rail/content-gating pass and
  private-lane quality/latency evidence.
- [ ] Device spike confirms private-lane quality, latency, and escalation
  threshold for grief/apology -- evidence: no committed evidence artifact found
  for this spike.
- [~] Tests cover routing, safety, entitlement, and typed generation contracts --
  evidence: routing/safety tests in
  `prosepal-ios/Tests/ProsePalAPITests/MessageWritingServiceTests.swift`,
  entitlement/account tests in
  `prosepal-ios/Tests/ProsePalUITests/MomentAccountModelTests.swift`.
  Partial because `@Generable` output-contract/device behavior is not covered
  with wired evidence.
- [x] Exit criteria for deleting legacy grouped form are satisfied -- evidence:
  `ProsePalRootView.swift`, `LegacyComposeModels.swift`, and legacy grouped-form
  tests have been removed; live behavior is covered by Moment/domain/API tests.

## 12. Explicit Non-Goals For V1

- [x] No image generation in v1 -- evidence: no image-generation dependency or
  image model client in `prosepal-ios/Package.swift` or `prosepal-ios/Sources`.
- [x] No third-party model/provider SDK dependency in v1 -- evidence:
  `prosepal-ios/Package.swift` has no package dependencies, and
  `nativeDependencyGuardDoesNotIncludeThirdPartyProviderSDKs()` in
  `prosepal-ios/Tests/ProsePalUITests/NativeGuardrailTests.swift` fails on
  provider SDK drift in the native package, project, app, or source tree.
- [x] No social, physical cards, custom keyboard, Live Activities, CloudKit sync,
  automatic memory inference, or voice cloning in v1 -- evidence: no matching
  targets or frameworks found under `prosepal-ios`.

## Top Open Work

1. Verify the latest Moment visual/rail/content-gating pass on a physical device
   and complete Dynamic Type, VoiceOver, Reduce Transparency, Increase Contrast,
   Add detail focus, and paywall hierarchy polish.
2. Swap the now-working standard-gateway careful lane to the agreed Apple-native
   careful/PCC direction when that API path is ready.
3. Configure Apple App Store Server secrets in staging, apply App Store
   entitlement migrations to staging, then capture sandbox notification and
   reconciliation evidence.
4. Finish external Apple/Supabase setup and device proof for side-by-side
   `ProsePal Staging`.
5. Complete widget/control/share-extension system-surface QA from actual system
   surfaces on simulator or device.
6. Harden crisis/pressure handling beyond local English phrase lists and add
   locale-aware/model-guarded evidence.
7. Complete vault privacy work for any stronger at-rest encryption decision.

## Archived Flutter Reference Work

Add Flutter/archive work here only when needed for an explicit archive
inspection, production incident investigation, service ownership requirement, or
native replacement evidence. Use tag `flutter-prod-freeze-2026-06-25` or branch
`legacy/flutter-production-reference`. Do not recreate Flutter files on active
`main`.
