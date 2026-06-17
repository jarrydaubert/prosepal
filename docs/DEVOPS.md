# DevOps Runbook

## Purpose

Define one canonical, evergreen DevOps runbook for repository security, CI/CD,
release execution, and validation.

All DevOps process changes must be documented here in the same change.

## Scope

This runbook covers:
- GitHub repository hardening
- GitHub Actions security and workflow policy
- CI, CodeQL, native iOS checks, Flutter production-reference checks, flaky
  audit, and release workflows
- Test execution model for native iOS, Flutter production-reference work, CI,
  wired devices, and Firebase Test Lab where still relevant
- Supabase staging gateway verification for the native rewrite
- Supabase/Firebase/RevenueCat operational verification for the live Flutter
  production app
- external-service ownership and billing custody verification
- AI abuse/cost controls and kill-switch handling
- Incident response for leaked keys or suspicious activity

## Active Development Modes

| Mode | Scope | Primary gate |
|------|-------|--------------|
| Native iOS rewrite | `prosepal-ios/` SwiftUI app, native staging gateway, native auth/purchase/testing slices | `swift test`, simulator `xcodebuild`, and wired iPhone evidence for auth, purchase, keyboard, and gateway flows |
| Flutter production/reference | Existing Flutter iOS/Android app and live production hotfixes | `flutter analyze`, `flutter test`, and `./scripts/test_critical_smoke.sh` |
| Backend/gateway | Supabase Edge Functions, gateway contract, usage/entitlement policy | Deno function tests and staging smoke commands |

Do not use Flutter production docs or commands as approval to change the native
architecture away from the iOS 26 Moment Sheet direction and its
`MessageWritingService` boundary.

## Operational Baseline

1. Default branch: `main` (protected).
2. Merge model: pull-request only.
3. Required checks on `main`: `Flutter Quality Gate`, `CodeQL`.
4. Primary native iOS local gate when `prosepal-ios/` changes:

```bash
cd prosepal-ios
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

5. Primary Flutter production/reference local gate when Flutter app code
   changes:

```bash
flutter analyze
./scripts/test_release_preflight.sh
./scripts/test_critical_smoke.sh
flutter test --exclude-tags flaky --coverage
./scripts/check_service_coverage.sh coverage/lcov.info
```

6. Gateway local/staging gate when Supabase generation code or native gateway
   configuration changes:

```bash
deno test --allow-env supabase/functions/generate-card/index.test.ts
./scripts/prosepal-staging-smoke.sh
```

7. Canonical operations source: this file (`docs/DEVOPS.md`).

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
- Exception: GitHub-generated squash merges for Dependabot on `main` may retain
  Dependabot and GitHub noreply co-author trailers when the committer is
  `GitHub <noreply@github.com>`, the subject is a PR squash subject, and the
  generated message still carries Dependabot's signed-off trailer. This covers
  both direct Dependabot PR squash merges and maintainer replacement PRs that
  re-apply Dependabot updates with required native lockfile or CI fixes.

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
- Non-blocking native iOS app job runs `swift test` and a simulator app target
  build from `prosepal-ios/` when that folder changes.
- Non-blocking visual regression companion job runs `./scripts/test_visual_regression.sh` and uploads `visual-regression-diffs` artifact on any diff/failure.
- Non-blocking integration smoke companion job runs `integration_test/smoke_test.dart` on iOS Simulator (`macos-latest`) and uploads `integration-smoke-artifacts`.

Free-tier optimization:
- Docs-only changes use a fast path that skips Flutter install/build/test while still running as a required check.
- `concurrency.cancel-in-progress` prevents duplicate runs on rapid pushes.

### Native iOS App Companion (`.github/workflows/ci.yml` -> `Native iOS App (non-blocking)`)

Purpose:
- Validate the SwiftUI rewrite's package contracts and simulator app build
  without changing the current Flutter production gate.

Policy:
- Runs only when files under `prosepal-ios/` change.
- Uses macOS GitHub-hosted runners and Swift Package Manager.
- Runs `swift test` from `prosepal-ios/`.
- Builds the `ProsePal` iOS simulator app target with `xcodebuild`.
- Remains non-blocking while the native rewrite is R&D. Before any native App
  Store candidate, promote the relevant native build and test checks to blocking
  release gates.
- Must not introduce Firebase AI or provider-specific generation SDK validation
  because the native app targets the ProsePal gateway contract.

### Native AI Gateway And Staging

Purpose:
- Validate the ProsePal-owned `CardRequest` / `CardResponse` contract for the
  SwiftUI rewrite without changing Flutter production AI routing.

Policy:
- Flutter production remains client-direct Firebase AI / Vertex AI until the
  gateway rollout gates in `docs/architecture/AI_GATEWAY_STRATEGY.md` are met.
- The native app must not import provider generation SDKs. It may call a
  ProsePal-owned gateway URL through `GatewayMessageWritingClient`.
- `supabase/functions/generate-card` may run in explicit anonymous staging/dev
  mode for native R&D by setting `GATEWAY_DEV_ALLOW_ANONYMOUS=true`.
- Anonymous staging traffic must be protected with
  `PROSEPAL_DEV_GATEWAY_SECRET` when the function is reachable from devices.
- Native Xcode testing must provide the staging gateway URL and shared dev
  secret through local scheme environment values, not tracked shared schemes.
- Authenticated native gateway requests use the existing Supabase
  `check_and_increment_usage` RPC after a successful, quality-checked
  generation. The RPC enforces caller identity and server entitlement state;
  allowed responses include `CardResponse.usage`, while usage-limit or usage-RPC
  failures return a user-safe error and no generated messages.
- The native app's auth slice is dependency-light: Apple ID-token exchange is
  represented by a narrow REST client, session tokens are stored in Keychain,
  Settings/Paywall use Apple's native `SignInWithAppleButton`, and
  `GatewayMessageWritingClient` receives bearer tokens from the session
  controller.
- Live Sign in with Apple proof requires the Apple capability/provisioning
  profile and Supabase Apple provider to match the native bundle identity.
- Native Premium purchase/restore R&D uses a narrow StoreKit 2 boundary driven
  by local/Xcode product ID configuration. The gateway/server entitlement policy
  remains authoritative for Premium generation.
- Anonymous gateway development mode does not call the authenticated usage RPC
  and must remain staging/local only.
- Provider/model names and keys stay in the Edge Function environment. The
  mobile client receives only product-lane metadata, never provider/model
  details.
- Gateway logs must not include raw prompts, generated messages, secrets,
  tokens, or sensitive user content.

Validation:
- Run `deno test --allow-env supabase/functions/generate-card/index.test.ts`
  after changing the gateway handler.
- Run `swift test` and the native simulator `xcodebuild` command from
  `prosepal-ios/` after changing native gateway wiring.
- Run `./scripts/prosepal-staging-smoke.sh` after changing staging gateway
  configuration or native gateway request headers.

Secret safety:
- Do not touch the production Supabase project from native staging work.
- Do not print or commit provider keys, Supabase service-role keys, dev gateway
  secrets, auth tokens, receipts, local Xcode schemes, or Supabase `.temp`
  state.
- Do not commit local screenshots or evidence under `prosepal-ios/evidence/`.

### Visual Regression Companion (`.github/workflows/ci.yml` → `Visual Regression (non-blocking)`)

Purpose:
- Detect unintended UI drift on core golden baselines without blocking merge velocity.

Policy:
- Runs only when CI detects mobile app, integration-test, Flutter test,
  platform, or Flutter dependency/tooling changes.
- Does not run for docs, workflow-only, backend-only, shell-script-only, or
  other housekeeping changes that do not affect the iOS simulator smoke target.
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
- `integration_test/smoke_test.dart` is intentionally mock-driven through deterministic provider overrides. It should validate launch/home/wizard/settings behavior without depending on live Supabase, RevenueCat, or Firebase AI availability. Use wired evidence runs and `e2e_real_test.dart` when the goal is to validate real backend behavior.

Policy:
- Runs only when CI scope is not docs-only.
- Uses first-party tooling on `macos-latest` with `xcrun simctl` to boot an available iPhone simulator.
- Pre-caches iOS artifacts and runs `pod install` before the smoke command so the smoke step budget is spent on the test, not cold iOS setup.
- Runs `flutter test -d <simulator-udid> integration_test/smoke_test.dart`.
- CI simulator smoke keeps `INTEGRATION_CAPTURE_SCREENSHOTS=false` for stability; use wired evidence runs when screenshot artifacts matter.
- Integration execution step is bounded with `timeout-minutes: 30` to prevent stalled simulator runs from consuming CI concurrency indefinitely while allowing cold Xcode builds enough time to finish.
- The companion job has a `timeout-minutes: 45` outer bound, including simulator boot, dependency prep, test execution, artifact upload, and summary publication.
- CI Flutter version should track the current repo-supported stable toolchain so dependency solving stays aligned between local validation and GitHub Actions.
- Uploads `integration-smoke-artifacts` containing:
  - `artifacts/integration-smoke/smoke.log`
  - any additional smoke diagnostics emitted by the run
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

### Test Design Standard

Every test added to this repo must answer one question first:

- What bug is this test trying to find?

A green result is only meaningful when the test has a credible oracle and a
clear failure mode. Test count, broad click-through coverage, and coverage
percentages are not success metrics by themselves.

Required quality bar for any new or retained test:

1. `Bug-oriented`: the test targets a concrete regression, failure mode, or
   user-risk scenario.
2. `Layer-appropriate`: the test runs at the lowest layer that can detect the
   bug reliably.
3. `Explicit oracle`: pass/fail is tied to the state that actually proves
   correctness, not a vague proxy like "screen still renders".
4. `Actionable failure`: when it fails, the reason identifies the missing
   state, broken transition, or violated contract.
5. `Deterministic`: the test should not depend on optional branches, silent
   skips, or ambient external state unless that dependency is the thing being
   verified.

Backlog/DoD rule for behavior changes:
- A change is not done unless regression protection is defined.
- Preferred outcome: automated coverage at the correct layer.
- If automation is intentionally not added, the PR/backlog item must still
  state the target bug, why that layer is wrong or impractical, the explicit
  pass/fail oracle, and the replacement evidence path.

Reject or rewrite tests that:

- only prove the app did not crash without asserting the intended outcome
- click through long flows without a named bug target
- accept multiple unrelated end states without documenting why
- silently skip core checkpoints with optional `if (exists(...))` logic
- use brittle finders when a stable semantic/key-based finder exists

Preferred review questions for test PRs:

1. What bug would this fail on?
2. Why is this the right layer for that bug?
3. What exact condition proves pass?
4. What exact condition proves fail?
5. If this stayed green, what important regression could still sneak through?

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
- Wired evidence pass/fail is anchored to the test's explicit oracle first. The wrapper still scans logs for hard failure signals, but it keeps a short per-suite allowlist for known handled noise so a user-visible, test-accepted terminal state does not get mislabeled as an evidence failure. Keep any such allowlist narrow, documented, and tied to a concrete journey/test.

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
# Reload your shell after first activation if `patrol` is not found:
#   source ~/.zshrc
patrol doctor
patrol test -t integration_test/<patrol_test_file>.dart
patrol test -t integration_test/patrol_notification_permission_test.dart --clear-permissions
# Physical iOS devices require release mode:
patrol test -t integration_test/patrol_notification_permission_test.dart -d <ios-device-id> --clear-permissions --release
```

Recommended first Patrol pilot:
- `integration_test/patrol_notification_permission_test.dart`
- Covers the native notification-permission dialog that appears after saving the first calendar occasion with reminders enabled.
- Run with `--clear-permissions` so the system dialog is deterministic across repeated local/device runs.
- Verified on tethered iPhone hardware with `patrol_cli 4.2.0`.

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

Supabase 0-60 minute production pulse:
- Purpose: detect a paused, unreachable, degraded, or misrouted production
  Supabase project before users hit auth, API, or edge-function failures.
- Prerequisites: production Supabase dashboard access, production project URL,
  production anon key, and release evidence folder.
- Steps:
  - Confirm the dashboard shows the production project as active, with no
    auth, database, or edge-function incidents.
  - Send read-only API probes to the production URL and require expected
    `2xx`/`401` responses, not DNS failures, timeouts, `5xx`,
    project-paused, or gateway-unreachable errors.
  - Send a read-only Auth health/settings request; do not create users or test
    sign-in during this pulse.
  - Probe deployed edge functions without valid auth and require expected
    `401`/`405` responses instead of timeouts or deployment-not-found errors.
- Pass criteria: dashboard active, API reachable, Auth reachable, and edge
  functions reachable with expected rejection responses.
- Failure handling: capture redacted evidence, pause rollout/monitoring
  sign-off, and escalate to the release owner before continuing.
- Evidence: record command output or dashboard screenshots in the release pulse
  bundle, with tokens, project secrets, and user content redacted.

AI cost/abuse controls:

```bash
./scripts/audit_ai_cost_controls.sh --repo-only
./scripts/audit_ai_cost_controls.sh
```

- `--repo-only` validates the checked-in Remote Config templates, required AI
  control keys, kill-switch defaults, and pinned model defaults without live
  cloud access.
- The full command additionally audits live GCP/Firebase service enablement,
  key restrictions, and billing-budget posture for the active project.

Supabase verification (manual + script-assisted):
- Required table presence for usage/entitlement/rate-limit/auth-adjacent tables.
- Required RPC/function presence for entitlement, usage, and rate-limit paths.
- RLS enabled with user-scoped policy checks on protected tables.
- Client role privileges checked against the expected API surface:
  anonymous users must not have direct table reads; signed-in users may keep the
  direct `user_usage` read required by app sign-in sync; SECURITY DEFINER
  functions must not retain PostgreSQL's default `PUBLIC` execute grant.
- Critical RPC behavior verified:
  - entitlement lookup
  - check/increment usage
  - rate-limit checks
  - device free-tier checks
  - sync monotonicity protection
- Edge function behavior verified:
  - `delete-user` rejects invalid auth and completes cleanup path
  - `exchange-apple-token` fails safe on invalid/missing auth context
  - `send-feedback` requires authenticated app sessions and fails safe when delivery is unavailable
  - `revenuecat-webhook` enforces secret and safely ignores invalid payloads

### In-app feedback delivery

Primary delivery path:
- The app submits feedback through the authenticated Supabase Edge Function `send-feedback`.
- The edge function relays mail through Resend to the support inbox without exposing any Resend secret to the client.
- Manual copy/share fallback remains available in-app when direct delivery fails or the user is signed out.

Required secrets/config:
- `RESEND_API_KEY`
- `FEEDBACK_TO_EMAIL`
- `FEEDBACK_FROM_EMAIL`
- Existing `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- `supabase/config.toml` must keep `[functions.send-feedback] verify_jwt = false`
  because the function verifies user auth internally via the passed Bearer token.

Deployment command:

```bash
supabase functions deploy send-feedback --project-ref mwoxtqxzunsjmbdqezif
```

Operator checks:
- Confirm the function is deployed to the production Supabase project and returns `401` for missing/invalid auth instead of accepting anonymous requests.
- Confirm the deployed function is using the current `supabase/config.toml` setting
  with `verify_jwt = false`; otherwise the gateway can reject valid app sessions
  before the function code runs with `401 Invalid JWT`.
- Confirm Resend sender domain posture still matches policy: verified domain, DKIM/SPF healthy, tracking disabled, TLS enforced.
- Confirm `FEEDBACK_TO_EMAIL` routes to the active support inbox and `FEEDBACK_FROM_EMAIL` is an approved sender on the verified domain.
- Confirm at least one production-configured submission reaches the Workspace inbox without opening the device mail client.

Failure handling:
1. If the app shows the manual fallback sheet, verify whether the failure was auth-related or delivery-related.
2. Check Supabase function logs for `send-feedback` and confirm whether the request reached the function.
3. If the function reached Resend but delivery failed, inspect Resend activity/logs and sender-domain status before changing app code.
4. If delivery cannot be restored quickly, keep the manual copy/share fallback as the temporary support path and track the outage/remediation in release evidence or `docs/BACKLOG.md` as appropriate.

### Generation charge semantics

Canonical rule:
- Usage is consumed only after the app has a user-presentable AI result.
- AI failures must not consume usage. This includes network errors, rate limits, App Check/configuration blocks, parse/empty-response failures, and service-unavailable failures.
- Post-success side effects such as history save or review-prompt evaluation must not discard a successful result after usage has been consumed.
- If authenticated charge verification cannot be completed after AI success, the app fails closed: no charge is recorded and the result is not shown.

Operational interpretation:
- Authenticated sessions charge through `check_and_increment_usage` only after AI success.
- Anonymous sessions record usage locally only after AI success, then sync asynchronously.
- Generate and regenerate must follow the same rule; neither surface is allowed to "pre-charge" before the AI result exists.

AI abuse/cost verification (manual + script-assisted):
- Firebase AI keys restricted to required API targets.
- Platform app restrictions verified (iOS bundle ID, Android package/SHA).
- App Check enforced for production.
- Anonymous free-tier device verification fails closed when fingerprint/server verification is unavailable.
- Rate limits and quotas match policy.
- Budget alerts configured (warning + critical).
- Kill-switch drill passes (`ai_enabled=false` then recovery).

Remote Config vs release decision policy:
- Allowed via Remote Config:
  - switching `ai_model` or `ai_model_fallback` between already-allowlisted stable model IDs
  - toggling `ai_enabled`
  - toggling `ai_use_limited_app_check_tokens`
  - toggling `paywall_enabled` / `premium_enabled` for runtime containment
- Requires a new app release:
  - any change to `AiConfig.allowedModelIds`
  - any move to preview or `latest` aliases for production traffic
  - any change to the production backend default (`vertex` vs `google`)
  - any change that would alter the AI response contract older builds expect

Containment model:
- Authoritative runtime containment:
  - `ai_enabled=false` immediately disables generation on next config fetch / app launch
  - Remote Config model allowlist rejection falls back to repo-pinned defaults instead of trusting unknown IDs
  - anonymous device-verification failures block free generation rather than failing open
- Advisory automated containment:
  - client/server rate limits and budget alerts are early-warning controls, not proof that production is safe to leave enabled during an incident
  - treat repeated `RATE_LIMIT`, `CLIENT_APP_BLOCKED`, `APP_CHECK_FAILED`, or abnormal spend alerts as triggers to evaluate `ai_enabled=false`

Kill-switch drill evidence policy:
1. Capture the active config snapshot before the drill.
2. Publish `ai_enabled=false`.
3. Verify the app reaches the expected disabled-AI user path without exposing raw provider failures.
4. Restore the prior config and verify normal generation recovery.
5. Store the drill artifact or run reference with release evidence; do not rely on memory or console history alone.

### Startup Phase Telemetry And Budgets

Startup reliability is validated from structured logs emitted by splash routing:
- `Startup phase telemetry` for `pre_init` (pre-`runApp()` bootstrap) and post-splash phases
- `Startup phase telemetry` (per phase)
- `Startup routing summary` (terminal outcome)

The same fields are emitted to Firebase Analytics events for queryability:
- `startup_phase`
- `startup_routing_summary`

Phases and budgets:
- `pre_init`: max `4000ms` (pre-`runApp()` Firebase bootstrap budget; app must still reach Flutter if this times out or fails)
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
- Treat any `pre_init` timeout/failure as distinct from splash `init` timeout. The required behavior is: native splash ends, Flutter mounts, and startup reaches the init error surface or later splash routing within budget instead of hanging before `runApp()`.
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

### AI runtime diagnostics and no-device evidence

The in-app diagnostic report should make the active AI runtime legible without
revealing secrets. Review the `AI Runtime` section for:

- backend (`vertexAI` or `googleAI`)
- primary model
- fallback model
- allowlist status
- App Check token mode
- config schema version
- built-in triage labels for:
  - `CLIENT_APP_BLOCKED`
  - `APP_CHECK_FAILED`
  - `CONTENT_BLOCKED`
  - `MODEL_NOT_FOUND`

Release-mode Crashlytics AI failure telemetry should keep only the fields needed
to triage behavior:

- backend label (`vertexAI` or `googleAI`)
- model slot (`primary`, `fallback`, or `custom`) rather than exact model ID
- classified error bucket (`CLIENT_APP_BLOCKED`, `APP_CHECK_FAILED`, etc.)
- retryability / attempt count

Release logs must not emit provider URLs, exact model identifiers, or
project/resource paths for AI failures. Exact model IDs belong in the in-app
diagnostic report and local debug logs, not production failure telemetry.

Deterministic no-device evidence paths:

```bash
flutter test test/services/diagnostic_service_test.dart
flutter test test/services/ai_service_test.dart --plain-name "classifies Firebase client application blocked"
flutter test test/services/ai_service_test.dart --plain-name "keeps safety-filter blocks as CONTENT_BLOCKED"
flutter test test/services/ai_service_test.dart --plain-name "classifies firebase_app_check platform error as APP_CHECK_FAILED"
flutter test test/services/ai_service_test.dart --plain-name "classifies \"404\" as MODEL_NOT_FOUND"
flutter test test/services/ai_service_test.dart --plain-name "sanitizes Firebase AI telemetry for release logging"
flutter test test/services/ai_service_test.dart --plain-name "sanitizes general exception telemetry but keeps user-facing bucket"
```

Use these when you need to prove:

- app-configuration/client-block failures are distinguished from safety blocks
- App Check failures are classified separately from generic network errors
- App Check verification failures bucket to `APP_CHECK_FAILED`, while
  `client application <empty>` / API-key restriction failures bucket to
  `CLIENT_APP_BLOCKED`
- fallback-model behavior remains an explicit runtime concern, not hidden logic

### Firebase AI Android App Check triage (`App attestation failed`)

Use this sequence when Vertex/Google AI calls fail with:
`[firebase_app_check/unknown] ... code: 403 body: App attestation failed.`

1. Confirm debug provider is active in app logs:
  - `androidProvider=AndroidDebugProvider` for debug builds.
2. Prefer a pinned debug token for repeated wired runs:
  - Add `FIREBASE_APP_CHECK_ANDROID_DEBUG_TOKEN=<registered-token>` to `.env.local`.
  - `./scripts/run_android.sh` and `run_wired_evidence.sh` will pass it through automatically.
3. If no pinned token is configured, capture the current debug token from device logs:
  - `./scripts/run_android.sh`
  - Copy token from: `DebugAppCheckProvider ... Enter this debug secret into the allow list ...`
  - `run_wired_evidence.sh` redacts the token in saved Android logcat artifacts; use a direct attached run when you need to read the raw token locally for console registration.
4. Register token in Firebase Console:
  - Firebase Console → App Check → Apps → Android app → Manage debug tokens → Add token.
5. Verify package/signature posture:
  - Firebase Android app package matches `com.prosepal.prosepal`.
  - SHA-256 fingerprints in Firebase app config include active signing cert(s) for the running build.
6. Verify App Check API status:
  - App Check dashboard shows verified requests for Firebase AI Logic.
  - Enforcement mode aligns with current test phase (Monitoring or Enforced).
7. Re-run wired Android generation:
  - `./scripts/run_android.sh --dart-define=AI_BACKEND=vertex`
8. If it still fails:
  - Collect log evidence with token redaction.
  - Record failure mode and config snapshot in release evidence and backlog.

## AI Cost/Abuse Control Policy

Required runtime controls:
- App Check enabled for Firebase AI requests.
- Remote Config kill switches present: `ai_enabled`, `paywall_enabled`, `premium_enabled`.
- Model allowlist validation enforced.
- Server-side and client-side rate limiting both active.
- Anonymous free-tier access requires a successful device-verification check; verification failures must block free generation rather than falling back to local-only allowance.
- Budget alerts configured with warning + critical thresholds.

Incident containment:
1. Disable AI via Remote Config (`ai_enabled=false`) if abuse/cost spike is detected.
2. Verify key restriction posture and rate-limit effectiveness.
3. Re-enable progressively after stability validation.
4. Track remediation actions in `docs/BACKLOG.md`.

Operator note:
- Budget-alert thresholds, notification destinations, and human response ownership still need live-console verification/evidence from the business-managed admin path. The repo can enforce policy wording and audit commands, but it cannot prove alert delivery by itself.

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

## Related References

- `docs/BACKLOG.md` (open work only)
- `docs/DOCS_POLICY.md` (documentation rules)
- `docs/IDENTITY_MAPPING.md` (auth/subscription/telemetry identity consistency)
