# ProsePal Docs Index

This folder holds canonical product, engineering, and operations docs for the
mobile app repository.

Active direction: native iOS SwiftUI rewrite in `prosepal-ios/`.

Flutter docs are still useful where they describe production operations or
service ownership, but Flutter screens are not the active native product
direction unless explicitly named by `docs/BACKLOG.md`.

## Start Here

1. `../AGENTS.md`
   - Repo working rules for agents and automation.
2. `NEXT_RELEASE_BRIEF.md`
   - Shareable native iOS readiness brief.
3. `BACKLOG.md`
   - Open native work only, with Definition of Done.
4. `DEVOPS.md`
   - Validation, CI, release operations, and service runbooks.
5. `../prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`
   - Native product, design, and technical direction.
6. `../prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md`
   - Local staging and physical-device proof.
7. `architecture/AI_GATEWAY_STRATEGY.md`
   - Cloud/careful gateway and model-router direction.

## Native iOS Docs

- `../prosepal-ios/README.md`
  - Native app setup and module overview.
- `../prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`
  - Native Moment Sheet, iOS 26, AI, design, StoreKit, and safety direction.
- `../prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md`
  - Tethered-device debug runbook for native auth, purchase, restore, and
    gateway legs.

## Production Reference Docs

These describe the live Flutter app, production operations, or existing service
ownership. Use them as reference material, not as the native implementation
target.

- `ARCHITECTURE.md`
  - Flutter production architecture reference.
- `AI_SYSTEM.md`
  - Flutter production Firebase AI runtime reference.
- `REMOTE_CONFIG.md`
  - Flutter production Firebase Remote Config policy.
- `SERVICE_CONFIG.md`
  - External service setup, split between native staging and Flutter
    production-reference needs.
- `SERVICE_ENDPOINTS.md`
  - SDK/API surfaces used by Flutter production and native staging.
- `SERVICE_OWNERSHIP_MIGRATION.md`
  - Production service custody and billing ownership runbook.
- `REVENUECAT_POLICY.md`
  - Existing RevenueCat entitlement continuity policy.
- `IDENTITY_MAPPING.md`
  - Identity mapping rules to preserve across auth/subscription work.
- `SECURITY.md`
  - Security and privacy posture.

## Product Reference Docs

- `PRODUCT_STRATEGY.md`
  - High-level product positioning and decision rules.
- `FEATURES.md`
  - Functional parity inventory.
- `USER_JOURNEYS.md`
  - Native journey policy derived from Flutter lessons.
- `RELATIONSHIP_ASSISTANT_VISION.md`
  - Longer-term product framing.
- `AI_OUTPUT_QUALITY.md`
  - Quality rubric and synthetic scenario matrix for generated messages.

## Historical Records

- `release-records/`
  - Past release/evidence records. These are not active backlog or release
    instructions.
- `settings-mockups.html`
  - Historical mockup/reference asset.

## Working Rules

1. Keep open work only in `BACKLOG.md`.
2. Keep native release/readiness scope in `NEXT_RELEASE_BRIEF.md`.
3. Keep operational process updates in `DEVOPS.md`.
4. Keep Flutter production docs clearly labeled as reference when they are not
   active native rewrite instructions.
5. Keep this index updated when canonical docs are added, renamed, merged, or
   retired.
