# ProsePal Docs Index

This folder holds canonical product, engineering, and operations docs for the
mobile app repository.

Active direction: native iOS SwiftUI rewrite in `prosepal-ios/`.

The Flutter app remains the live production/reference implementation. Flutter
docs are still useful where they describe production operations or lessons the
native rewrite must preserve, but they are not the active product direction
unless explicitly named by `docs/BACKLOG.md`.

## Start Here

1. `../AGENTS.md`
   - Repo working rules for agents and automation.
2. `NEXT_RELEASE_BRIEF.md`
   - Shareable native iOS readiness brief.
3. `BACKLOG.md`
   - Open native work only, with Definition of Done.
4. `DEVOPS.md`
   - Validation, CI, release operations, and service runbooks.
5. `../prosepal-ios/NATIVE_PRODUCT_NORTH_STAR.md`
   - Product/UX bridge from Flutter behavior to native iOS shape.
6. `../prosepal-ios/REWRITE_PLAN.md`
   - Detailed native delivery gates and scenario matrix.
7. `architecture/AI_GATEWAY_STRATEGY.md`
   - Long-term AI gateway and model-router direction.

## Native iOS Docs

- `../prosepal-ios/README.md`
  - Native app setup and module overview.
- `../prosepal-ios/NATIVE_UX_DIRECTION.md`
  - Native navigation, onboarding, create, results, settings, paywall, and
    parity direction.
- `../prosepal-ios/ARCHITECTURE.md`
  - Native AI architecture, Standard/Premium routing, and local-model direction.
- `../prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md`
  - Tethered-device debug runbook for native auth, purchase, restore, and
    gateway legs.
- `../prosepal-ios/MIGRATION_NOTES.md`
  - Native replacement and legacy Flutter data migration considerations.

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
