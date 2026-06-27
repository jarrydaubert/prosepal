# ProsePal Docs Index

This folder holds canonical product, engineering, and operations docs for the
native iOS app.

Active direction: native SwiftUI app in `prosepal-ios/`, iOS 26-first,
person-first Moment Sheet, StoreKit 2, Foundation Models, and ProsePal-owned
message-writing/routing boundaries.

Production identity: the native rewrite reuses the existing ProsePal App Store
Connect app and bundle ID `com.prosepal.prosepal`. Staging is UAT via the
local-only Xcode scheme plus staging Supabase/StoreKit configuration, not a
second public ProsePal app.

Side-by-side staging is tracked as the internal `ProsePal Staging` app identity
(`N-IOS-19`) with bundle ID `com.prosepal.prosepal.staging`. The repo has the
target/scheme identity; Apple Developer, App Store Connect, Sign in with Apple,
and Supabase staging setup still need human proof before it is release-grade.

The previous Flutter production app is archived at tag
`flutter-prod-freeze-2026-06-25` and branch
`legacy/flutter-production-reference`.

## Start Here

1. `../AGENTS.md`
   - Repo working rules for agents and automation.
2. `NEXT_RELEASE_BRIEF.md`
   - Shareable native iOS readiness brief.
3. `BACKLOG.md`
   - Single active tracker for open native work.
4. `../prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`
   - Native product, design, AI, StoreKit, and platform direction.
5. `../prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md`
   - Local staging and physical-device proof.
6. `DEVOPS.md`
   - CI, Supabase safety, and release operations.
7. `architecture/AI_GATEWAY_STRATEGY.md`
   - Gateway/model-router strategy and historical reasoning.

## Active Native Docs

- `NEXT_RELEASE_BRIEF.md`
- `BACKLOG.md`
- `DEVOPS.md`
- `DOCS_POLICY.md`
- `PRODUCT_STRATEGY.md`
- `FEATURES.md`
- `USER_JOURNEYS.md`
- `AI_OUTPUT_QUALITY.md`
- `SERVICE_CONFIG.md`
- `SERVICE_ENDPOINTS.md`
- `SECURITY.md`
- `../prosepal-ios/README.md`
- `../prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`
- `../prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md`

## Historical Flutter References

These are not active implementation instructions. They are retained only for
production-reference history, App Review lessons, service ownership context, and
behavioral archaeology:

- `legacy-flutter/ARCHITECTURE.md`
- `legacy-flutter/README.md`
- `legacy-flutter/AI_SYSTEM.md`
- `legacy-flutter/REMOTE_CONFIG.md`
- `legacy-flutter/REMOTE_CONFIG_TEMPLATE.json`
- `legacy-flutter/REMOTE_CONFIG_TEMPLATE.firebase.json`
- `legacy-flutter/REVENUECAT_POLICY.md`
- `legacy-flutter/IDENTITY_MAPPING.md`
- `legacy-flutter/SERVICE_OWNERSHIP_MIGRATION.md`
- `legacy-flutter/SECURITY.md`
- `release-records/`

## Working Rules

1. Keep open work only in `BACKLOG.md`.
2. Keep native release/readiness scope in `NEXT_RELEASE_BRIEF.md`.
3. Keep operational process updates in `DEVOPS.md`.
4. Keep Flutter references clearly historical and outside active implementation
   guidance.
5. Keep this index updated when canonical docs are added, renamed, merged, or
   retired.
