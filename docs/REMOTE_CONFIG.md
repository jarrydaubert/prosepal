# Remote Config Runbook

## Purpose

Define the required Firebase Remote Config keys, safe defaults, and rollout rules.

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
