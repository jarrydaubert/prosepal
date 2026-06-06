# Service Configuration Runbook

## Purpose

Provide one reproducible configuration runbook for external services.

There are two different service contexts:

- native iOS staging/rewrite services;
- Flutter production/reference services.

Use this before release builds and when onboarding a new environment.

## Prerequisites

1. Access to the provider consoles for the context being changed:
   - Supabase dashboard for native staging/gateway or Flutter production
   - App Store Connect for native StoreKit/App Store product work
   - RevenueCat dashboard when preserving Flutter entitlement continuity
   - Firebase console only for Flutter production/reference work
2. Local repo checkout with scripts available.
3. A local env file copied from `.env.example` to `.env.local`.
4. GitHub Actions secret access for release workflow configuration.

## Native iOS Staging Configuration

Native staging configuration must not touch production.

Required local Xcode environment names:

- `PROSEPAL_GATEWAY_URL`
- `PROSEPAL_DEV_GATEWAY_SECRET`
- `PROSEPAL_SUPABASE_URL` or `SUPABASE_URL`
- `PROSEPAL_SUPABASE_ANON_KEY` or `SUPABASE_ANON_KEY`
- `PROSEPAL_PREMIUM_PRODUCT_IDS`
- `PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID`

Required Supabase staging secrets by name:

- `PROSEPAL_DEV_GATEWAY_SECRET`
- provider API key secret for the gateway provider
- `PROSEPAL_AI_PROVIDER`
- `PROSEPAL_AI_PROVIDER_BASE_URL`
- `PROSEPAL_AI_PROVIDER_MODEL`
- `PROSEPAL_AI_PROVIDER_FALLBACK_MODELS`
- `PROSEPAL_AI_PROVIDER_JSON_MODE`

Additional staging secrets/config may be required before full auth, feedback,
purchase, and entitlement testing:

- Apple Sign-In/Supabase Auth provider configuration
- `REVENUECAT_WEBHOOK_SECRET`, if RevenueCat continuity is selected
- Resend feedback relay secrets, if direct feedback is enabled

Validation:

```bash
./scripts/prosepal-staging-smoke.sh
cd prosepal-ios
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Pass criteria:

- valid staging gateway request returns three drafts;
- no-secret or invalid-secret gateway request fails closed;
- provider/model fields are not exposed to the client response;
- no local Xcode scheme secrets, Supabase `.temp`, screenshots, receipts, or
  evidence files are committed.

## Flutter Production Reference Configuration

Use this section only for Flutter production changes or live production
maintenance.

## Commands And Steps

### 1) Configure Runtime Keys

Create local runtime config:

```bash
cp .env.example .env.local
```

Set required keys in `.env.local`:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `REVENUECAT_IOS_KEY`
- `REVENUECAT_ANDROID_KEY`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`

For CI release runs, mirror these values in GitHub Actions secrets with the same names.

### 2) Validate Key Completeness And Non-Placeholder Values

Run deterministic preflight checks:

```bash
./scripts/release_preflight.sh ios
./scripts/release_preflight.sh android
./scripts/release_preflight.sh all
./scripts/test_release_preflight.sh
```

### 3) Configure Supabase

In Supabase Console:
1. Confirm project URL/API values match `.env.local` values.
2. Confirm social auth providers required by app policy are enabled:
   - Apple
   - Google
3. Confirm approved callback URLs are present.
4. Confirm required edge functions exist:
   - `delete-user`
   - `exchange-apple-token`
   - `send-feedback`
   - `revenuecat-webhook`
5. If direct in-app feedback is enabled for the release, confirm function secrets
   are configured:
   - `RESEND_API_KEY`
   - `FEEDBACK_TO_EMAIL`
   - `FEEDBACK_FROM_EMAIL`

Optional script-assisted verification:

```bash
SUPABASE_DB_URL="postgresql://..." ./scripts/verify_supabase_readonly.sh
```

### 4) Configure RevenueCat

In RevenueCat Console:
1. Confirm iOS and Android app entries exist for the project.
2. Confirm product identifiers are present and mapped to entitlement `pro`.
3. Confirm offering `default` contains expected package mappings.
4. Confirm SDK API keys match values in `.env.local` and CI secrets.
5. Confirm restore behavior policy and identity mapping align with:
   - `docs/REVENUECAT_POLICY.md`
   - `docs/IDENTITY_MAPPING.md`

### 5) Configure Firebase

In Firebase Console:
1. Confirm iOS bundle ID and Android package match app IDs.
2. Confirm App Check posture is configured for release policy.
3. Confirm Remote Config contains required AI keys:
   - `ai_model`
   - `ai_model_fallback`
   - `ai_enabled`
4. Confirm Crashlytics and Analytics are enabled.

### 6) Validate End-To-End Runtime Wiring

Run baseline validation:

```bash
flutter analyze
flutter test
./scripts/test_critical_smoke.sh
./scripts/run_wired_evidence.sh --suite smoke
```

## Pass Criteria

Configuration is considered valid only when all are true:

1. `release_preflight` passes for `ios`, `android`, and `all`.
2. `test_release_preflight` passes.
3. Supabase verification checks pass (manual + script-assisted where used).
4. RevenueCat entitlement/offering/key mapping is confirmed in console.
5. Firebase App Check + Remote Config + analytics/crash services are confirmed.
6. Analyzer/tests/smoke/wired evidence run successfully with configured keys.
7. Any release-scoped edge functions are deployed to production with required
   secrets present; for `send-feedback`, direct in-app submission must not 404
   due to a missing function deployment.

## Failure Handling And Escalation

If a step fails:

1. Capture failing command output and provider-console evidence.
2. Classify failure source:
   - local key/config
   - CI secret mismatch
   - provider policy/permission issue
   - service outage
3. Apply targeted remediation:
   - update `.env.local` and/or CI secrets
   - correct provider-side config
   - re-run preflight and validation commands
4. If unresolved, follow service-specific triage in `docs/DEVOPS.md` and track unresolved work in `docs/BACKLOG.md`.
