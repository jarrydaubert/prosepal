# Backlog

This is the single active tracker for the native iOS direction. The untracked
root `PROSEPAL_BUILD_SPEC.md` from the main checkout has been folded here so
the repo has one source of truth for the Moment path.

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
  and `89d2963`.

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
- [~] Saved is a local, user-curated library with copy/share/delete -- evidence:
  `SavedMomentDraftRecord` in `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`,
  `MomentSavedView` and `MomentSavedDetailView` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  edit is not present in the Moment saved detail.
- [~] Settings covers account, subscription, writing, privacy, support, legal,
  and about -- evidence: `MomentSettingsView` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`,
  `MomentAccountModel` in `prosepal-ios/Sources/ProsePalUI/MomentAccountModel.swift`,
  and `89d2963`. Partial because export remains a support path and account
  deletion/subscription flows still need full staging/App Review evidence.
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
- [ ] Voice capture for "say the messy thing" exists -- evidence: no `Speech`,
  `SFSpeech`, `AVAudio`, or `AVFoundation` implementation found under
  `prosepal-ios/Sources`.
- [~] Draft actions cover copy, share, save, edit, and send/share handoff --
  evidence: copy/share/save exist in `MomentActionRail` and saved detail actions
  in `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial
  because edit and an explicit send handoff are not implemented for Moment drafts.
- [~] N-IOS-17 Protect user drafts during AI refinement -- evidence:
  `MomentModel.previousDraftBundle`, `restorePreviousDraft()`, and the visible
  `Undo rewrite` action in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`; undo/failure
  tests in `prosepal-ios/Tests/ProsePalUITests/MomentModelTests.swift`. Partial
  because full accept/reject, version history, and autosave for user-authored
  editable draft text are not implemented yet. DoD: local autosave preserves the
  user's current words, substantial AI edits create a recoverable snapshot,
  refinement results require explicit accept or keep-original behavior before
  replacing user text, undo remains available after acceptance, and tests cover
  cancellation/failure without text loss.
- [x] Draft body reads like correspondence rather than a chat bubble --
  evidence: serif draft body and `textSelection(.enabled)` in
  `MomentDraftCard` inside `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.

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
- [x] Contacts/Calendar enrichment is not silently active -- evidence: no
  `EventKit` or `Contacts` implementation found under `prosepal-ios/Sources`.
- [~] Voice Card exists as user-approved memory -- evidence:
  `RelationshipVoiceCardRecord` in
  `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`; voice-card UI in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  learning from edits is not implemented.

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
  and `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial
  because detection is a hardcoded English phrase list, not a model guardrail
  signal with locale awareness.
- [~] Pressure Check provides subtractive feedback -- evidence:
  `PressureCheck.local(for:)` in
  `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`; private-lane
  typed fields in `FoundationModelsPrivateDraftClient.swift`. Partial because
  user-facing accept/keep/clean flows are not fully developed.
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
- [ ] Care Glance WidgetKit widget exists -- evidence: no `WidgetKit`,
  `WidgetBundle`, widget extension target, or `NSExtension` entry found under
  `prosepal-ios`.
- [ ] Control Center / Action Button control exists -- evidence: no
  `ControlWidget` or control extension target found under `prosepal-ios`.
- [ ] Share extension turns outside context into a Moment -- evidence: no share
  extension or `NSExtension` entry found under `prosepal-ios`.
- [ ] System writing/text tooling is explicitly integrated -- evidence: no
  dedicated writing-tools integration found under `prosepal-ios/Sources`.

## 7. Monetization

- [x] Native app uses StoreKit 2 directly, with no RevenueCat dependency --
  evidence: `StoreKitSubscriptionClient` in
  `prosepal-ios/Sources/ProsePalAPI/SubscriptionClient.swift`; no third-party
  dependencies in `prosepal-ios/Package.swift`; the active Supabase
  `revenuecat-webhook` function and config entry have been removed from the
  native repo.
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
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  StoreKit product loading/sandbox evidence is not captured in the tracker.
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

## 8. Design

- [~] N-IOS-14 Native visual system and Moment rail/content discipline --
  evidence: `MomentSheetView.momentContent(viewportHeight:)`,
  `shouldShowSecondaryMomentPanels`, `draftStartSection`, `shouldShowTabRail`,
  and `startNewMoment()` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  XcodeBuildMCP simulator evidence covers the explicit `Mira Audit` active
  compose path and rail avoidance, but physical-device, Dynamic Type,
  VoiceOver, Reduce Transparency, and paywall/input follow-up polish remain.
- [~] iOS 26-first Liquid Glass direction is in code -- evidence:
  iOS 26 deployment target in `prosepal-ios/Package.swift` and
  `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`; control-layer styling in
  `MomentGlassModifier` and `momentControlBarSurface` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  Xcode 26/device visual verification.
- [~] Opaque paper-like content sits beneath floating controls -- evidence:
  `MomentDraftCard`, `MomentPanel`, `MomentCardBackground`, `MomentSymbolBadge`,
  and active first-viewport rail/content gating in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  physical-device and accessibility audit.
- [~] Register-aware palette and haptics exist -- evidence:
  `MomentPalette` and `MomentHaptics` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  grief/sensitive haptic suppression is not fully evidenced.
- [~] Accessibility is treated as architecture -- evidence: visible controls,
  labels, Dynamic Type-friendly SwiftUI, and selectable text in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  VoiceOver, Switch Control, Reduce Transparency, Increase Contrast, and AX-size
  device evidence.

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
  `prosepal-ios/Package.swift`.
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
  location in `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`, app
  container wiring in `prosepal-ios/App/ProsePalNativeApp.swift`, and filesystem
  coverage in
  `prosepal-ios/Tests/ProsePalAPITests/RelationshipVaultTests.swift`.
  Partial because export and any stronger at-rest encryption decision still need
  dedicated product/security review.

## 11. Quality Gates / Acceptance

- [~] Acceptance demo exists: open, person, moment, one true thing, write draft,
  adjust, copy/share/save -- evidence: `MomentAppRootView`, `MomentSheetView`,
  `MomentActionRail`, and `MomentModel` in
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
  `prosepal-ios/Package.swift` has no package dependencies.
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
5. Add Care Glance widget, Control Center/Action Button control, and Share
   extension surfaces.
6. Harden crisis/pressure handling beyond local English phrase lists and add
   locale-aware/model-guarded evidence.
7. Complete vault privacy work for export and any stronger at-rest encryption
   decision.

## Archived Flutter Reference Work

Add Flutter/archive work here only when needed for an explicit archive
inspection, production incident investigation, service ownership requirement, or
native replacement evidence. Use tag `flutter-prod-freeze-2026-06-25` or branch
`legacy/flutter-production-reference`. Do not recreate Flutter files on active
`main`.
