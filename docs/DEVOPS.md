# DevOps Runbook

## Purpose

Define one canonical, evergreen DevOps runbook for repository security, CI/CD, release execution, and validation.

All DevOps process changes must be documented here in the same change.

## Scope

This runbook covers:
- GitHub repository hardening
- GitHub Actions security and workflow policy
- CI, CodeQL, flaky audit, and release workflows
- Test execution model (local, CI, wired devices, Firebase Test Lab)
- Supabase/Firebase/RevenueCat operational verification
- AI abuse/cost controls and kill-switch handling
- Incident response for leaked keys or suspicious activity

## Operational Baseline

1. Default branch: `main` (protected).
2. Merge model: pull-request only.
3. Required checks on `main`: `Flutter Quality Gate`, `CodeQL`.
4. Primary local quality gate:

```bash
flutter analyze
./scripts/test_release_preflight.sh
./scripts/test_critical_smoke.sh
flutter test --exclude-tags flaky --coverage
./scripts/check_service_coverage.sh coverage/lcov.info
```

5. Canonical operations source: this file (`docs/DEVOPS.md`).

## Repository Security Baseline

Apply and keep the `main` branch policy:
- Pull requests required before merge.
- Required checks: `CodeQL` and `Flutter Quality Gate`.
- Branch must be up to date before merge.
- Force pushes blocked.
- Branch deletion blocked.
- Linear history required.
- Pull-request approvals:
  - single maintainer mode: `0` required approvals
  - multi-maintainer mode: raise to `1+` required approvals

Code scanning policy:
- CodeQL enabled.
- Code scanning gate requires high-severity-or-higher compliance (per repository ruleset).

Actions policy:
- Use selected actions only.
- Use GitHub-owned and verified creators only.
- Pin all actions to full-length commit SHAs.
- Keep default workflow token permission at read-only.
- Do not allow workflows to create or approve pull requests.
- Require approval for all external fork contributions.

Maintenance policy:
- Dependabot enabled for `github-actions` and `pub`.
- Secret scanning and push protection enabled.
- Auto-delete merged branches enabled.

Ruleset verification command:

```bash
gh api repos/jarrydaubert/prosepal/rulesets/13237026
```

## Daily Developer Flow

1. Branch from `main`.
2. Implement changes.
3. Install/update local hooks: `./scripts/setup-hooks.sh`.
4. Run local quality gate.
5. Open PR and wait for required checks.
6. Merge only through PR.

## Commit Attribution Policy

Purpose:
- Prevent accidental co-author trailers from being merged into release history.

Rules:
- `Co-authored-by:` trailers are allowed only when intentional and accurate.
- Any intentional co-author trailer must include `[allow-coauthor]` in the same commit message body.
- Commits with `Co-authored-by:` and no `[allow-coauthor]` fail local `commit-msg` hook and CI.

Commands:

```bash
# Validate a pending commit message file
./scripts/check_commit_attribution.sh --message-file .git/COMMIT_EDITMSG

# Validate a commit range (for PR/self-check)
./scripts/check_commit_attribution.sh --range origin/main..HEAD
```

## Public Repo Secret Safety

Never commit live secrets, API tokens, signing keys, service-account JSON, or private certificates.

Use:
- GitHub Actions secrets/variables for workflow-time values.
- Local `.env` files that are gitignored for developer machines.
- Runtime config with non-secret toggles only.

Automated enforcement:
- CI runs `./scripts/security_history_guard.sh` on every PR/push to `main`.
- The guard blocks merges if any non-example `.env*` file appears in reachable history or if high-risk secret patterns are detected.

Manual verification command:

```bash
./scripts/security_history_guard.sh
```

If a secret/key is exposed:
1. Rotate/revoke the key immediately in provider console.
2. Restrict replacement key by API + app/bundle/package constraints.
3. Remove secret from git history if required by provider policy.
4. Confirm no plaintext secret remains in repo (`git grep` + provider scan).
5. Document incident and follow-up work in `docs/BACKLOG.md`.

## Workflow Inventory

### CI (`.github/workflows/ci.yml`)

Purpose:
- Blocking quality gate for every push/PR to `main`.

Steps:
- Commit attribution guard (`./scripts/check_commit_attribution.sh`) for PR/push commit ranges.
- Secret history guard (`./scripts/security_history_guard.sh`) to block dotenv/history leaks.
- Release preflight tests (`./scripts/test_release_preflight.sh`).
- Deno static validation for Supabase edge functions (`deno check`).
- Flutter analyze.
- Launch/auth color parity guard (`./scripts/check_launch_color_parity.sh`) to prevent iOS/Android/Flutter splash/background drift.
- Critical smoke tests, including deterministic AI service parsing/error-classification coverage.
- Unit/widget test suite with flaky tests excluded.
- Service coverage gate.
- Debug bundle build sanity check.
- Non-blocking visual regression companion job runs `./scripts/test_visual_regression.sh` and uploads `visual-regression-diffs` artifact on any diff/failure.
- Non-blocking integration smoke companion job runs `integration_test/smoke_test.dart` on iOS Simulator (`macos-latest`) and uploads `integration-smoke-artifacts`.

Free-tier optimization:
- Docs-only changes use a fast path that skips Flutter install/build/test while still running as a required check.
- `concurrency.cancel-in-progress` prevents duplicate runs on rapid pushes.

### Visual Regression Companion (`.github/workflows/ci.yml` → `Visual Regression (non-blocking)`)

Purpose:
- Detect unintended UI drift on core golden baselines without blocking merge velocity.

Policy:
- Runs only when CI scope is not docs-only.
- Uses `./scripts/test_visual_regression.sh`.
- Uploads `visual-regression-diffs` artifact (from `test/widgets/goldens/failures/**`) on every run.
- Publishes `GITHUB_STEP_SUMMARY` guidance with local baseline update command:
  - `./scripts/test_visual_regression.sh --update`

### Integration Smoke Companion (`.github/workflows/ci.yml` → `Integration Smoke (non-blocking)`)

Purpose:
- Run `integration_test/smoke_test.dart` in CI on a deterministic non-blocking target and publish evidence artifacts.

Harness selection:
- Checked-in suites under `integration_test/` currently use Flutter's standard `integration_test` harness, so CI and local smoke use `flutter test`.
- Use Patrol CLI only for tests that explicitly adopt Patrol APIs/native automation (for example `patrolTest(...)` or `$.native` interactions). In that case, install `patrol_cli`, run `patrol doctor`, and execute via `patrol test`.

Policy:
- Runs only when CI scope is not docs-only.
- Uses first-party tooling on `macos-latest` with `xcrun simctl` to boot an available iPhone simulator.
- Runs `flutter test -d <simulator-udid> integration_test/smoke_test.dart`.
- Integration execution step is bounded with `timeout-minutes: 12` to prevent stalled simulator runs from consuming CI concurrency indefinitely.
- CI Flutter version should track the current repo-supported stable toolchain so dependency solving stays aligned between local validation and GitHub Actions.
- Uploads `integration-smoke-artifacts` containing:
  - `artifacts/integration-smoke/smoke.log`
  - `integration_test/screenshots/**` (when produced)
- Publishes `GITHUB_STEP_SUMMARY` with pass/fail outcome and target details.

Pass/fail semantics:
- This job is non-blocking (`continue-on-error: true`) so it does not block merge.
- Any failure must be triaged and either fixed immediately or tracked in `docs/BACKLOG.md` with deterministic DoD before release cut.

### CodeQL (`.github/workflows/codeql.yml`)

Purpose:
- Required static security scanning for workflow/code-security configuration.

Policy:
- Keep enabled on push/PR to `main`.
- Keep scheduled scan enabled for drift detection.
- Scan languages:
  - `actions` for workflow/pipeline risk
  - `javascript-typescript` for Supabase edge functions and TS attack surface

### Flaky Audit (`.github/workflows/flaky-test-audit.yml`)

Purpose:
- Non-blocking repeated-run audit to detect order-dependent and intermittent failures.

Policy:
- Flaky tests must be tagged `flaky` and excluded from blocking CI until fixed.
- Every quarantined flaky test must have a backlog item with clear fix criteria.
- Flaky tag convention:

```dart
testWidgets(
  'example flaky case',
  (tester) async {
    // test body
  },
  tags: ['flaky'],
);
```

### Release (`.github/workflows/release.yml`)

Purpose:
- Manual semantic release creation with annotated tags and GitHub Release notes.

Rules:
- Tags must be `vMAJOR.MINOR.PATCH` (SemVer).
- Use workflow dispatch only.
- No ad-hoc production tags.
- Release workflow blocks before tag creation when required runtime config
  secrets are missing or placeholder-like by running:
  `./scripts/release_preflight.sh all --no-env-file`
  with GitHub Actions secrets mapped to:
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUECAT_IOS_KEY`,
  `REVENUECAT_ANDROID_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`.

## Dependabot Policy

Keep update load safe for free-tier CI minutes:
- Group updates per ecosystem.
- Keep low open PR limits to prevent CI queue spam.
- Prioritize security and CI/tooling updates.

## Test And Validation Model

### Local Baseline

```bash
flutter analyze
./scripts/test_release_preflight.sh
deno check supabase/functions/**/*.ts
./scripts/check_commit_attribution.sh --range origin/main..HEAD
./scripts/check_launch_color_parity.sh
./scripts/test_critical_smoke.sh
# Critical smoke currently includes:
# - app lifecycle
# - app config
# - AI service parsing/error-classification
# - home/generate/results/settings widget smoke
flutter test --exclude-tags flaky --coverage
./scripts/check_service_coverage.sh coverage/lcov.info
./scripts/test_flake_audit.sh
./scripts/test_visual_regression.sh
./scripts/cleanup.sh --dry-run
```

### Device Reset

For a clean local/device reset before fresh installs:

```bash
./scripts/reset_devices.sh
```

This cleans local generated artifacts and uninstalls the app from the first
tethered Android and iOS devices it finds. Keep interactive device runs in
separate terminals so each platform retains its own logs and hot reload/restart
controls:

```bash
./scripts/run_ios.sh
./scripts/run_android.sh
```

### Integration And Device Validation

Use wired-device evidence for release confidence:

```bash
./scripts/run_wired_evidence.sh --suite smoke
./scripts/run_wired_evidence.sh --suite full
```

Wired evidence runtime config:
- `run_wired_evidence.sh` automatically passes `--dart-define-from-file=.env.local` when that file exists.
- Override with `--dart-define-file <path>` for alternate environments.
- Use `--no-dart-define-file` to run without dart-define injection.

Firebase Test Lab deterministic critical suite:

```bash
flutter build apk --debug -t integration_test/ftl_test.dart
cd android && JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home ./gradlew app:assembleAndroidTest -Ptarget=../integration_test/ftl_test.dart
gcloud firebase test android run --type instrumentation --app build/app/outputs/flutter-apk/app-debug.apk --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk --device model=oriole,version=33,locale=en,orientation=portrait --timeout 12m --no-use-orchestrator
```

Real backend E2E:

```bash
flutter test integration_test/e2e_real_test.dart -d <android-device-id> --dart-define=REVENUECAT_USE_TEST_STORE=true
```

Patrol-native/system UI automation:

```bash
dart pub global activate patrol_cli
patrol doctor
patrol test -t integration_test/<patrol_test_file>.dart
```

### iOS CocoaPods Recovery

Use this when iOS dependency resolution fails with lock mismatches (for example `Firebase/CoreOnly` or `PurchasesHybridCommon*`):

```bash
flutter clean
flutter pub get
cd ios
pod update PurchasesHybridCommon PurchasesHybridCommonUI
pod install --repo-update
```

If dependency versions changed, commit the resulting `ios/Podfile.lock` update in the same PR.

### Operational Verification

Supabase read-only verification:

```bash
SUPABASE_DB_URL="postgresql://..." ./scripts/verify_supabase_readonly.sh
```

AI cost/abuse controls:

```bash
./scripts/audit_ai_cost_controls.sh
```

Supabase verification (manual + script-assisted):
- Required table presence for usage/entitlement/rate-limit/auth-adjacent tables.
- Required RPC/function presence for entitlement, usage, and rate-limit paths.
- RLS enabled with user-scoped policy checks on protected tables.
- Critical RPC behavior verified:
  - entitlement lookup
  - check/increment usage
  - rate-limit checks
  - device free-tier checks
  - sync monotonicity protection
- Edge function behavior verified:
  - `delete-user` rejects invalid auth and completes cleanup path
  - `exchange-apple-token` fails safe on invalid/missing auth context
  - `revenuecat-webhook` enforces secret and safely ignores invalid payloads

AI abuse/cost verification (manual + script-assisted):
- Firebase AI keys restricted to required API targets.
- Platform app restrictions verified (iOS bundle ID, Android package/SHA).
- App Check enforced for production.
- Rate limits and quotas match policy.
- Budget alerts configured (warning + critical).
- Kill-switch drill passes (`ai_enabled=false` then recovery).

### Startup Phase Telemetry And Budgets

Startup reliability is validated from structured logs emitted by splash routing:
- `Startup phase telemetry` (per phase)
- `Startup routing summary` (terminal outcome)

The same fields are emitted to Firebase Analytics events for queryability:
- `startup_phase`
- `startup_routing_summary`

Phases and budgets:
- `init`: max `12000ms` (wait for critical init readiness)
- `identity`: budget `4000ms` (auth + biometric checks)
- `entitlements`: budget `3000ms` (anonymous Pro restore check; authenticated path is marked `authenticated_skipped`)
- `routing`: max `10000ms` (initial route resolution timeout/fallback budget)

Required telemetry fields:
- Per-phase: `phase`, `durationMs`, `budgetMs`, `timedOut`, `outcome`
- Final summary: `resolvedRoute`, `usedFallback`, `fallbackReason`, `initPhaseOutcome`, `identityPhaseMs/outcome`, `entitlementsPhaseMs/outcome`

Analytics parameter keys:
- `startup_phase`: `phase`, `duration_ms`, `budget_ms`, `timed_out`, `outcome`
- `startup_routing_summary`: `init_wait_ms`, `splash_hold_ms`, `route_resolution_ms`, `init_phase_outcome`, `identity_phase_ms`, `identity_phase_outcome`, `entitlements_phase_ms`, `entitlements_phase_outcome`, `used_fallback`, `fallback_reason`, `resolved_route`

Triage policy:
- Investigate any `timedOut=true` phase on release-candidate builds.
- Investigate repeated `usedFallback=true` startup summaries for the same route path or device cohort.
- Treat `/onboarding` fallback for previously onboarded users as regression unless an explicit init error is present.

### Firebase AI iOS client-block triage (`client application <empty> are blocked`)

Use this deterministic sequence before changing runtime code:

1. Verify runtime app identity in logs:
  - `firebaseProjectId` matches expected project.
  - `firebaseAppId`/`apiKey` are non-empty and from `GoogleService-Info.plist`.
2. Verify Firebase app registration:
  - iOS app bundle ID in Firebase is exactly `com.prosepal.prosepal`.
3. Verify GCP API key posture:
  - `iOS key (auto created by Firebase)` has iOS app restriction for `com.prosepal.prosepal`.
  - API targets include `firebasevertexai.googleapis.com`.
  - `Gemini Developer API key (auto created by Firebase)` is restricted to `generativelanguage.googleapis.com`.
4. Verify App Check posture:
  - Firebase AI Logic receives verified requests.
  - If testing debug builds, valid debug token is registered.
  - If enforcement is enabled, ensure debug token/provider setup is valid for test devices.
5. Verify API/service enablement:
  - `firebasevertexai.googleapis.com` and `generativelanguage.googleapis.com` are enabled.
6. Verify Remote Config inputs:
  - `ai_enabled=true`
  - `ai_model` and `ai_model_fallback` are in allowlist.
  - `ai_use_limited_app_check_tokens` rollout value is intentional and documented.
7. Isolate restriction root cause:
  - Run once with Vertex backend path:
    - `./scripts/run_ios.sh --dart-define=AI_BACKEND=vertex`
  - Run once with Google Developer backend path:
    - `./scripts/run_ios.sh --dart-define=AI_BACKEND=google`
  - If only Google path fails with `client application <empty> are blocked`, keep Vertex as production default and track Google path as a provider/configuration issue.
  - Temporarily set iOS key application restriction to `None` (keep API restrictions intact), retest, then immediately restore intended restriction policy.
8. If issue persists after all checks:
  - Capture wired-device evidence logs and open/append a backlog item with exact provider, key ID, and request classification evidence.

Pass criteria:
- Required checks are green.
- Wired evidence captured for iOS and Android.
- FTL critical suite passes.
- Supabase and AI control audits complete with no unresolved release blockers.

### Firebase AI Android App Check triage (`App attestation failed`)

Use this sequence when Vertex/Google AI calls fail with:
`[firebase_app_check/unknown] ... code: 403 body: App attestation failed.`

1. Confirm debug provider is active in app logs:
  - `androidProvider=AndroidDebugProvider` for debug builds.
2. Capture the current debug token from device logs:
  - `./scripts/run_android.sh`
  - Copy token from: `DebugAppCheckProvider ... Enter this debug secret into the allow list ...`
3. Register token in Firebase Console:
  - Firebase Console → App Check → Apps → Android app → Manage debug tokens → Add token.
4. Verify package/signature posture:
  - Firebase Android app package matches `com.prosepal.prosepal`.
  - SHA-256 fingerprints in Firebase app config include active signing cert(s) for the running build.
5. Verify App Check API status:
  - App Check dashboard shows verified requests for Firebase AI Logic.
  - Enforcement mode aligns with current test phase (Monitoring or Enforced).
6. Re-run wired Android generation:
  - `./scripts/run_android.sh --dart-define=AI_BACKEND=vertex`
7. If it still fails:
  - Collect log evidence with token redaction.
  - Record failure mode and config snapshot in release evidence and backlog.

## AI Cost/Abuse Control Policy

Required runtime controls:
- App Check enabled for Firebase AI requests.
- Remote Config kill switches present: `ai_enabled`, `paywall_enabled`, `premium_enabled`.
- Model allowlist validation enforced.
- Server-side and client-side rate limiting both active.
- Budget alerts configured with warning + critical thresholds.

Incident containment:
1. Disable AI via Remote Config (`ai_enabled=false`) if abuse/cost spike is detected.
2. Verify key restriction posture and rate-limit effectiveness.
3. Re-enable progressively after stability validation.
4. Track remediation actions in `docs/BACKLOG.md`.

## Rollback And Recovery

### Runtime rollback (no app-store review required)
1. Disable AI via `ai_enabled=false`.
2. Disable premium/paywall surface if required via `premium_enabled=false` and/or `paywall_enabled=false`.
3. Verify graceful fallback UX and error messaging.
4. Re-enable in stages after root-cause mitigation.

### Mobile release rollback (store-level)
1. Stop phased rollout or remove affected build from distribution tracks.
2. Promote last known-good release while hotfix is prepared.
3. If issue is config-only, prefer runtime rollback first; if binary-level, ship patched build.
4. Record incident timeline, blast radius, and user impact in release evidence.

### Code and release rollback (GitHub)
1. Create hotfix branch from last known-good commit/tag.
2. Apply minimal fix and run required checks.
3. Publish new semantic patch release (`vX.Y.Z+1`) through release workflow.
4. Keep bad tag immutable; do not delete history in public repo.

## Release Execution

Create production release via `Release` workflow:
- Input `version` without leading `v`.
- Workflow creates annotated `vX.Y.Z` tag.
- Workflow publishes GitHub Release notes with category mapping from `.github/release.yml`.

For iOS releases, upload dSYMs from the final submitted `.xcarchive` after App Store Connect upload completes:

```bash
./ios/Pods/FirebaseCrashlytics/upload-symbols \
  -d \
  -gsp ./ios/Runner/GoogleService-Info.plist \
  -p ios \
  "$HOME/Library/Developer/Xcode/Archives/<yyyy-mm-dd>/<Archive Name>.xcarchive/dSYMs"
```

Notes:
- Use the exact archive that was submitted to App Store Connect.
- `build/debug-info/ios` is still required for Flutter obfuscation symbolication, but it is not a substitute for archive dSYM upload.
- Firebase SDK internal frameworks can emit invalid/empty dSYM warnings during upload; treat those as non-blocking if the uploader still finishes with `Successfully uploaded Crashlytics symbols`.

## Monthly Governance Review

Run once per month (or after major GitHub-policy changes):

```bash
gh api repos/jarrydaubert/prosepal/rulesets/13237026
gh run list --workflow "CI" --branch main --limit 10
gh run list --workflow "CodeQL" --branch main --limit 10
```

Verify:
- Required check names still match repository rules.
- Ruleset still enforces PR-only, no force-push, no branch deletion, and linear history.
- Actions security posture is unchanged (selected actions, pinned SHAs, read-only token default, external contributor approval).
- Dependabot remains enabled for `pub` and `github-actions` with bounded open PR counts.

## Definition Of Done For DevOps Changes

A DevOps change is complete only when:
- This runbook is updated.
- Required workflows pass.
- Any new scripts/steps are reproducible from command line.
- Security impact is documented.
- Open issues are tracked in `docs/BACKLOG.md` (not in evergreen docs).

## Proposed Improvements (External Review)

Planned DevOps improvements for external review are tracked in `docs/BACKLOG.md` and currently include:
- `P1-10` Monthly governance audit automation with run-ID evidence and trend fields.
- `P1-11` Automated semantic release flow from `main` merges.
- `P1-12` Troubleshooting playbooks (API outage, stale evidence, token rotation, rollback).
- `P1-13` Scoped Dependabot auto-merge pilot for low-risk updates.
- `P1-14` Structured `GITHUB_STEP_SUMMARY` output for key workflows.
- `P1-15` CI dependency caching optimization with measured runtime impact.
- `P1-16` Deterministic artifact controls for reproducibility.
- `P1-17` Deployment safety guardrails verification and rollback path validation.

## Related References

- `docs/BACKLOG.md` (open work only)
- `docs/DOCS_POLICY.md` (documentation rules)
- `docs/IDENTITY_MAPPING.md` (auth/subscription/telemetry identity consistency)
