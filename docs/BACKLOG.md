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
- Flutter remains in the repository as production/reference history, but it is
  not the native UX source of truth.

## 0. Product Principles

- [~] ProsePal helps someone show up for people who matter, not face a generic
  blank page -- evidence: `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`,
  `prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`.
- [x] Person-first entry is the default; occasion taxonomy lives underneath --
  evidence: `MomentInput.personName` in
  `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`,
  `MomentSheetView.personSection` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
- [~] A plausible draft appears once there is enough context, without a visible
  old-style Generate button -- evidence: `MomentModel.scheduleDraft()` and
  `MomentSheetView.draftSection` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  availability, timeout, and careful-lane states can still leave the user in an
  error/loading state.
- [~] Safety and restraint are product behavior, not just server policy --
  evidence: `MomentSafetySignal`, `PressureCheck`, and `MomentInput.requiresCarefulLane`
  in `prosepal-ios/Sources/ProsePalDomain/MomentModels.swift`; UI crisis/careful
  sections in `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`.
  Partial because crisis and pressure detection are still local phrase-list
  heuristics.
- [~] Provider/model names stay out of user-facing UI -- evidence:
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`,
  `prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift`.
  Partial because one user-safe unavailable message currently names Apple
  Intelligence.

## 1. Surfaces / Information Architecture

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
  `MomentAccountModel` in `prosepal-ios/Sources/ProsePalUI/MomentAccountModel.swift`.
  Partial because support/legal are mostly surfaced through paywall links rather
  than a mature settings layout.
- [~] Legacy grouped create/results path is retired -- evidence:
  `ProsePalNativeApp.swift` no longer references `ProsePalRootView`, but
  `prosepal-ios/Sources/ProsePalUI/ProsePalRootView.swift`,
  `prosepal-ios/Sources/ProsePalUI/LegacyComposeModels.swift`, and several
  `prosepal-ios/Tests/ProsePalUITests/*` tests still compile against
  `ProsePalAppModel`, `MessageDraft`, and `SavedMessage`.

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
  SwiftData store backup/encryption posture is not separately hardened; only
  local model directories currently set `isExcludedFromBackup` in
  `prosepal-ios/Sources/ProsePalAPI/LocalModelStore.swift`.
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
  `ensureModelAvailable()` in
  `prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift`.
- [ ] Take more care lane uses Apple Private Cloud Compute / AFM Cloud --
  evidence: current careful lane is `GatewayCarefulMomentClient` in
  `prosepal-ios/Sources/ProsePalAPI/GatewayCarefulMomentClient.swift`, wired by
  `MessageWritingServiceFactory` in `prosepal-ios/App/ProsePalNativeApp.swift`.
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
  `MockMessageWritingClient` is limited to tests/previews in
  `prosepal-ios/Sources/ProsePalAPI/MockMessageWritingClient.swift`.

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
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  register-specific palette, whitespace, and haptic changes are not complete.
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
  dependencies in `prosepal-ios/Package.swift`.
- [ ] Server entitlement is authoritative through App Store Server
  Notifications V2 JWS and reconciliation -- evidence: no
  `app-store-notifications`, `AppStoreServer`, or JWS verification function
  found under `supabase/functions`; existing webhook is
  `supabase/functions/revenuecat-webhook/index.ts`.
- [ ] Premium/careful gateway access is authorized by server entitlement --
  evidence: native careful client sends `.premium` in
  `prosepal-ios/Sources/ProsePalAPI/GatewayCarefulMomentClient.swift`, while
  `supabase/functions/generate-card/index.ts` still rejects `requested_lane === "premium"`
  as `premium_unavailable`.
- [~] Paywall is App Review-oriented: price/period, restore, Terms, Privacy,
  no forced sign-in -- evidence: `MomentPaywallSheet` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial because
  StoreKit product loading/sandbox evidence is not captured in the tracker.
- [~] Account deletion exists once account creation exists -- evidence:
  `SupabaseAccountMaintenanceClient` in
  `prosepal-ios/Sources/ProsePalAPI/AccountMaintenanceClient.swift`,
  `supabase/functions/delete-user/index.ts`, and settings UI in
  `MomentSettingsView`. Partial pending full App Review/account-provider
  evidence.
- [~] Restore, identity/account switch, and entitlement convergence are covered --
  evidence: restore/local entitlement code in
  `prosepal-ios/Sources/ProsePalAPI/SubscriptionClient.swift`; account/purchase
  tests in `prosepal-ios/Tests/ProsePalUITests/AuthPurchaseFlowTests.swift`.
  Partial because server reconciliation is not implemented.

## 8. Design

- [~] iOS 26-first Liquid Glass direction is in code -- evidence:
  iOS 26 deployment target in `prosepal-ios/Package.swift` and
  `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`; control-layer styling in
  `MomentGlassModifier` and `momentControlBarSurface` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  Xcode 26/device visual verification.
- [~] Opaque paper-like content sits beneath floating controls -- evidence:
  `MomentDraftCard`, `MomentPanel`, and background styles in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  visual and accessibility audit.
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
  in `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`. Partial because legacy
  UI code still uses older `ObservableObject` patterns.
- [~] View models use `@Observable`, not `ObservableObject` -- evidence:
  `MomentModel` and `MomentAccountModel` in `prosepal-ios/Sources/ProsePalUI`.
  Partial because legacy `ProsePalAppModel: ObservableObject` remains in
  `prosepal-ios/Sources/ProsePalUI/ProsePalRootView.swift`.
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
- [~] Monolith UI has been split for the new flow -- evidence:
  Moment-specific files exist under `prosepal-ios/Sources/ProsePalUI`, but
  `prosepal-ios/Sources/ProsePalUI/ProsePalRootView.swift` remains a compiled
  legacy monolith.

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
  evidence: SwiftData records in `RelationshipVault.swift`; delete/export flows
  in `MomentSettingsView`; local model backup exclusion in `LocalModelStore`.
  Partial because SwiftData vault backup/encryption/deletion semantics need a
  dedicated privacy review.

## 11. Quality Gates / Acceptance

- [~] Acceptance demo exists: open, person, moment, one true thing, draft,
  adjust, copy/share/save -- evidence: `MomentAppRootView`, `MomentSheetView`,
  `MomentActionRail`, and `MomentModel` in
  `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`. Partial pending
  physical-device evidence after the latest tracker pass.
- [ ] Device spike confirms private-lane quality, latency, and escalation
  threshold for grief/apology -- evidence: no committed evidence artifact found
  for this spike.
- [~] Tests cover routing, safety, entitlement, and typed generation contracts --
  evidence: routing/safety tests in
  `prosepal-ios/Tests/ProsePalAPITests/MessageWritingServiceTests.swift`,
  entitlement tests in `prosepal-ios/Tests/ProsePalUITests/AuthPurchaseFlowTests.swift`.
  Partial because `@Generable` output-contract/device behavior is not covered
  with wired evidence.
- [ ] Exit criteria for deleting legacy grouped form are satisfied -- evidence:
  `ProsePalRootView.swift`, `LegacyComposeModels.swift`, and legacy UI tests
  still exist and compile.

## 12. Explicit Non-Goals For V1

- [x] No image generation in v1 -- evidence: no image-generation dependency or
  image model client in `prosepal-ios/Package.swift` or `prosepal-ios/Sources`.
- [x] No third-party model/provider SDK dependency in v1 -- evidence:
  `prosepal-ios/Package.swift` has no package dependencies.
- [x] No social, physical cards, custom keyboard, Live Activities, CloudKit sync,
  automatic memory inference, or voice cloning in v1 -- evidence: no matching
  targets or frameworks found under `prosepal-ios`.

## Top Open Work

1. Replace the careful lane's legacy Supabase `.premium` path with the agreed
   Apple-native careful/PCC direction, or explicitly revise the spec if that API
   is not available enough for this branch yet.
2. Implement server-side StoreKit entitlement ownership through App Store Server
   Notifications V2/JWS and reconciliation.
3. Add Care Glance widget, Control Center/Action Button control, and Share
   extension surfaces.
4. Harden crisis/pressure handling beyond local English phrase lists and add
   locale-aware/model-guarded evidence.
5. Remove the legacy grouped-form monolith and migrate/delete stale tests once
   the Moment path owns the required behavior.

## Flutter Production Work

Add Flutter work here only when needed for a production hotfix, production
security issue, live service ownership requirement, or explicit replacement
evidence. The Flutter screens and interaction model are not the native iOS
design source of truth.
