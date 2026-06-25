# Remote Config Runbook

> LEGACY (Flutter baseline). This document describes Firebase Remote Config for
> the frozen Flutter production/reference app. Native iOS must not inherit
> Firebase Remote Config by default.

## Purpose

Define the required Firebase Remote Config keys, safe defaults, and rollout rules.

Scope note:

- This is a Flutter production-reference runbook.
- Native iOS must not inherit Firebase Remote Config by default.
- Native runtime configuration should stay explicit through the gateway,
  environment, StoreKit/App Store, or a future approved native config layer.

## Prerequisites

- Firebase project access with Remote Config edit/publish permissions.
- App build that includes current `config_schema_version` handling.

## Source Of Truth

- Template file: `docs/REMOTE_CONFIG_TEMPLATE.json`
- Runtime implementation: `lib/core/services/remote_config_service.dart`

## Required Keys

- `config_schema_version`
- `ai_enabled`
- `paywall_enabled`
- `premium_enabled`
- `ai_model`
- `ai_model_fallback`
- `ai_use_limited_app_check_tokens`
- `force_update_enabled`
- `min_app_version_ios`
- `min_app_version_android`

## Baseline Defaults

- `ai_model`: `gemini-2.5-flash`
- `ai_model_fallback`: `gemini-2.5-flash-lite`

## Model Handling Policy

- Use pinned model IDs only; do not use `latest` aliases in production.
- Keep exactly one primary and one fallback model configured.
- Keep both models in `AiConfig.allowedModelIds` before publishing RC changes.
- Roll out model changes in phases (internal -> small % -> 100%).
- If errors/latency/cost regress, switch `ai_model` back immediately and republish.
- Keep App Check enabled for AI and use limited-use tokens when rollout is complete.

## Remote Config Change Policy

Allowed via Remote Config only:
- switch `ai_model` between already-allowlisted stable model IDs
- switch `ai_model_fallback` between already-allowlisted stable model IDs
- disable or re-enable AI via `ai_enabled`
- roll limited-use App Check tokens on or off via `ai_use_limited_app_check_tokens`
- change minimum supported app versions and paywall/premium kill switches

Requires a new app release:
- adding or removing entries from `AiConfig.allowedModelIds`
- changing the production backend default (`vertex` vs `google`)
- changing the structured response contract or system instruction in a way that old builds would not understand
- relying on preview or `latest` model aliases for production traffic
- changing App Check provider strategy or other build-time Firebase wiring

Rollback order:
1. If behavior or spend is abnormal, set `ai_enabled=false` to stop generation safely.
2. Revert `ai_model` and `ai_model_fallback` to the repo-pinned defaults.
3. If App Check rollout is implicated, revert `ai_use_limited_app_check_tokens` to the last known-good value.
4. Re-enable AI only after the issue is understood and monitored.

## Rules

- Do not store secrets in Remote Config.
- `ai_model` and `ai_model_fallback` must be allowlisted model IDs.
- Keep `config_schema_version` aligned with app expectations.
- Update `docs/REMOTE_CONFIG_TEMPLATE.json` in the same PR as key changes.

## Pass Criteria

- App initializes with template defaults and no runtime errors.
- AI kill switch (`ai_enabled`) blocks generation safely.
- Paywall/premium kill switches block paywall presentation safely.
- Invalid model IDs are rejected and replaced with safe defaults.

## Failure Handling

- If bad config is published, disable affected feature via kill switch.
- Revert to template values and republish.
- Add a backlog item with incident details and prevention action.
