# Service Configuration Runbook

## Purpose

Provide one reproducible configuration runbook for required external services:
- Supabase
- RevenueCat
- Firebase (AI/App Check/Analytics/Crashlytics)

Use this before release builds and when onboarding a new environment.

## Prerequisites

1. Access to project provider consoles:
   - Supabase project dashboard
   - RevenueCat project dashboard
   - Firebase project console
2. Local repo checkout with scripts available.
3. A local env file copied from `.env.example` to `.env.local`.
4. GitHub Actions secret access for release workflow configuration.

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
   - `revenuecat-webhook`

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
