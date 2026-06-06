# AI System

## Purpose

Document the Flutter production AI runtime design in ProsePal so the repo shows
clear LLM engineering judgment instead of a vague "calls Gemini" story.

This document is evergreen. Open work belongs in `docs/BACKLOG.md`.

For the active native iOS direction, use:

- `docs/architecture/AI_GATEWAY_STRATEGY.md`
- `prosepal-ios/ARCHITECTURE.md`
- `prosepal-ios/NATIVE_PRODUCT_NORTH_STAR.md`

The native SwiftUI app must remain gateway-first and must not use Firebase AI,
Vertex AI, or provider SDKs directly.

## Runtime Architecture

Primary implementation:
- Flutter client calls Firebase AI SDK
- production default backend is `Vertex AI`
- optional debug override can force the Google Developer API path

Runtime source:
- `lib/core/services/ai_service.dart`
- `lib/core/services/remote_config_service.dart`

## Model Strategy

The app does not rely on floating `latest` aliases.

Pinned defaults:
- primary: `gemini-2.5-flash`
- fallback: `gemini-2.5-flash-lite`

Remote Config controls:
- `ai_model`
- `ai_model_fallback`
- `ai_enabled`
- `ai_use_limited_app_check_tokens`
- `config_schema_version`

Guardrails:
- model IDs are validated against `AiConfig.allowedModelIds`
- invalid or empty Remote Config values fall back to repo-defined defaults
- kill switch exists for AI availability

Remote control boundaries:
- Remote Config may switch only between already-allowlisted stable model IDs.
- Remote Config may disable AI or toggle limited-use App Check tokens for runtime containment.
- Changes to the allowlist, backend default, or structured-response contract require a new app release.

## Response Contract

Generation expects structured JSON, not arbitrary prose blobs.

Current contract:
- top-level object with `messages`
- each message contains `text`
- system instruction enforces the "3 message" shape

Why:
- deterministic parsing
- smaller UI-facing error surface
- easier regression testing

## Failure Taxonomy

The AI path uses typed failure classification so user-facing behavior and
debugging are not driven by ad-hoc string handling in the UI.

Primary exception types:
- `AiNetworkException`
- `AiRateLimitException`
- `AiContentBlockedException`
- `AiUnavailableException`
- `AiEmptyResponseException`
- `AiParseException`
- `AiTruncationException`
- `AiServiceException`

Important classified error codes:
- `CLIENT_APP_BLOCKED`
- `APP_CHECK_FAILED`
- `CONTENT_BLOCKED`
- `MODEL_NOT_FOUND`
- `RATE_LIMIT`
- `TIMEOUT`

Why this matters:
- configuration failures must not be confused with safety blocks
- App Check failures must not be misreported as generic network errors
- model fallback must remain explicit and testable

## Fallback Behavior

Fallback is a real runtime path, not a comment.

Current behavior:
- primary model is attempted first
- model-not-found or unavailable paths can trigger fallback model use
- fallback switching is explicit and logged

Expected outcome:
- if the primary model is temporarily unavailable, the app should still have a
  deterministic recovery path instead of failing as a generic unknown error

## App Check And Runtime Controls

AI requests are expected to run with:
- Firebase App Check enabled
- Remote Config kill switches available
- optional limited-use App Check token rollout controlled remotely

Operational triage is documented in:
- `docs/DEVOPS.md`
- `docs/REMOTE_CONFIG.md`

## Diagnostics

The in-app support report should expose the active AI runtime without leaking
secrets.

Current diagnostic report includes:
- backend
- Vertex location when relevant
- primary model
- fallback model
- allowlist status
- AI enabled state
- limited-use App Check token mode
- config schema version
- built-in triage labels for key AI failure classes

Production AI failure telemetry is intentionally narrower than the support
report: release Crashlytics logs keep backend label, model slot
(`primary`/`fallback`/`custom`), retryability, and classified error bucket, but
do not keep provider URLs, project/resource paths, or exact model IDs.

Implementation:
- `lib/core/services/diagnostic_service.dart`

## Deterministic Evidence Paths

No-device evidence:

```bash
flutter test test/services/diagnostic_service_test.dart
flutter test test/services/ai_service_test.dart --plain-name "classifies Firebase client application blocked"
flutter test test/services/ai_service_test.dart --plain-name "keeps safety-filter blocks as CONTENT_BLOCKED"
flutter test test/services/ai_service_test.dart --plain-name "classifies firebase_app_check platform error as APP_CHECK_FAILED"
flutter test test/services/ai_service_test.dart --plain-name "classifies \"404\" as MODEL_NOT_FOUND"
```

These commands prove:
- config/client-block failures are separated from safety blocks
- App Check failures are classified explicitly
- App Check verification failures stay distinct from `CLIENT_APP_BLOCKED`
- model-unavailable behavior remains part of the tested contract

Real-device evidence:
- use wired-device runs for release confidence
- use Firebase Test Lab for Android cloud-device evidence
- use Patrol only when native/system UI is the actual risk

See:
- `docs/DEVOPS.md`
- `docs/AI_OUTPUT_QUALITY.md`
- `README.md`
