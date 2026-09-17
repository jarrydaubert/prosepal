# Architecture boundaries

SOURCE OF TRUTH for exact behaviour: source/tests. [BACKLOG](BACKLOG.md) owns
known defects and intended changes; this file records structural boundaries.

## Application and dependencies

- CURRENT: one SwiftUI iOS app in `prosepal-ios/`, targeting iOS 26, Swift tools
  6.2+. Verify exact build constraints in `prosepal-ios/Package.swift` and the
  Xcode project before changing them. There is no second app or migration underway.
- Production uses the existing App Store Connect app and `com.prosepal.prosepal`.
  Staging is internal UAT; target/configuration identities are in RUNBOOK.
- `Native*` names are historical residue, not evidence of a second implementation.
  Do not rename them opportunistically.
- `App` composes concrete dependencies. `ProsePalDomain` has pure product types
  and contracts. `ProsePalAPI` depends on Domain. `ProsePalUI` depends on API/Domain.
  API/Domain MUST NOT depend on UI.
- Provider, network, StoreKit, Keychain, Supabase, persistence schemas and
  persistence-service implementations stay outside `ProsePalUI`.
- No Firebase AI/Vertex/Gemini direct-client, RevenueCat or third-party provider
  SDK dependency by default. Provider details stay below the writing boundary.

## State owners

| State/boundary | Owner and source anchor |
|---|---|
| Dependency composition/lifecycle | [ProsePalNativeApp](../prosepal-ios/App/ProsePalNativeApp.swift) |
| Root navigation/welcome/handoffs | [MomentAppRootView](../prosepal-ios/Sources/ProsePalUI/MomentAppRootView.swift) |
| Active Moment, draft/history, generation lifecycle | [MomentModel](../prosepal-ios/Sources/ProsePalUI/Features/Moment/MomentModel.swift) |
| Versioned active-draft recovery | [MomentDraftRecovery](../prosepal-ios/Sources/ProsePalUI/Features/Moment/MomentDraftRecovery.swift), coordinated by MomentModel |
| Account/entitlement presentation and convergence | [MomentAccountModel](../prosepal-ios/Sources/ProsePalUI/MomentAccountModel.swift) |
| Session persistence/refresh | [AuthSessionController](../prosepal-ios/Sources/ProsePalAPI/AuthSession.swift), [KeychainAuthSessionStore](../prosepal-ios/Sources/ProsePalAPI/KeychainAuthSessionStore.swift) |
| StoreKit reads/transaction delivery | [StoreKitSubscriptionClient](../prosepal-ios/Sources/ProsePalAPI/SubscriptionClient.swift) |
| SwiftData vault/schema/export/erasure | [RelationshipVault](../prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift) |
| Shared extension-safe launch contract | [MomentHandoff](../prosepal-ios/Sources/ProsePalDomain/MomentHandoff.swift) |

Every mutable value has one owner. Views render state and send intent to the
existing owner; do not create parallel workflow/navigation/entitlement models.
Transient sheets, focus, search and disclosure belong to the narrowest view.
App-lifetime observable models are retained by the root. Shared async mutations
are actor-isolated; UI-owned mutations are main-actor isolated.

## Writing and server boundary

- UI calls [MessageWritingService](../prosepal-ios/Sources/ProsePalAPI/MessageWritingService.swift).
  MomentModel owns the retained generation task and stale-result identity;
  views MUST NOT start an independent generation lifecycle.
- [FoundationModelsPrivateDraftClient](../prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift)
  owns on-device model/prompt work and approved-memory lookup.
- [GatewayCarefulMomentClient](../prosepal-ios/Sources/ProsePalAPI/GatewayCarefulMomentClient.swift)
  adapts Moment intent; [GatewayMessageWritingClient](../prosepal-ios/Sources/ProsePalAPI/GatewayMessageWritingClient.swift)
  owns HTTP transport to the ProsePal gateway.
- [OnlineWritingPermissionStore](../prosepal-ios/Sources/ProsePalAPI/OnlineWritingPermissionStore.swift)
  is the single app-composition-owned online permission store. Preserve the
  writing-service gate before online operations, including fallback/adjustment.
- [CardModels](../prosepal-ios/Sources/ProsePalDomain/CardModels.swift) and
  [TextInputPolicy](../prosepal-ios/Sources/ProsePalDomain/TextInputPolicy.swift)
  own Swift wire types/text policy; [generate-card](../supabase/functions/generate-card/index.ts)
  and its tests own server parsing. Cross-language field/enum/version/text-limit
  changes MUST update both sides and their contract tests; preserve existing replay.
- Keep app-authored directives distinct from quoted user material. Boundary
  validation, secret handling and quota/cost controls remain justified protections.
- Provider credentials and privileged Supabase clients exist only server-side.
  Database migrations/tests own SQL privileges, entitlement and ledger semantics.
  Local StoreKit access cannot confer server entitlement merely through a UI flag.
- DO NOT INFER a deployed OpenRouter/provider binding from a compatible endpoint.
  W-8 reopens provider orchestration/quality machinery; W-2 reopens candidate
  count. Neither current filters nor fallback loops are preferred future architecture.
- Inspect owning source/tests for exact routing, refusal, retry and timeout policy;
  do not reproduce it in narrative docs.

## Persistence and feature changes

- SwiftData stores approved relationship memory and deliberately saved drafts.
  Active recovery is separate; generation MUST NOT silently insert saved history.
- Schema changes require a new `VersionedSchema` and explicit migration stage in
  `RelationshipVaultMigrationPlan`; preserve released schemas and test migration.
- A feature reads SwiftData through `@Query`/environment `modelContext`; do not
  mirror collection state into a second model. Views may coordinate modelContext;
  failure/rollback semantics belong in focused, testable persistence functions.
- Local data is device-owned; account switching must not silently reassign it.
  Vault erasure, account deletion, sign-out and subscription cancellation remain
  distinct actions. Inspect their sources and I-2/S-1 for scope/retention defects.
- In-memory fallback is not durable storage. W-7 owns misleading save success;
  I-2 owns misleading route/privacy presentation. Do not assume those are fixed.
- Extract only a region materially touched by the task. Feature-private helpers
  stay beside the feature; share components only after real independent consumers.
- Prefer SwiftUI/Observation, explicit injection and system navigation. New models,
  managers, coordinators, routers or service locators need demonstrated ownership.
- Extracted UI gets deterministic representative previews and behavioural seams;
  preserve cancellation, recovery and accessibility contracts and existing ratchets.
  Use localization-safe copy and semantic adaptive styling.
- Optional system surfaces prepare sanitized input only; the main app owns review,
  writing/account state and sending decisions. Qualify them or omit them from release.

## Historical context

The previous Flutter production app is available at tag
`flutter-prod-freeze-2026-06-25` and branch `legacy/flutter-production-reference`.
Use Git only when historical behaviour, App Review or update-install context is
needed. MUST NOT recreate Flutter files on main or treat archived strategy as a spec.
