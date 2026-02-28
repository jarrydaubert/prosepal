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
3. Run local quality gate.
4. Open PR and wait for required checks.
5. Merge only through PR.

## Public Repo Secret Safety

Never commit live secrets, API tokens, signing keys, service-account JSON, or private certificates.

Use:
- GitHub Actions secrets/variables for workflow-time values.
- Local `.env` files that are gitignored for developer machines.
- Runtime config with non-secret toggles only.

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
- Release preflight tests (`./scripts/test_release_preflight.sh`).
- Deno static validation for Supabase edge functions (`deno check`).
- Flutter analyze.
- Critical smoke tests.
- Unit/widget test suite with flaky tests excluded.
- Service coverage gate.
- Debug bundle build sanity check.

Free-tier optimization:
- Docs-only changes use a fast path that skips Flutter install/build/test while still running as a required check.
- `concurrency.cancel-in-progress` prevents duplicate runs on rapid pushes.

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
./scripts/test_critical_smoke.sh
flutter test --exclude-tags flaky --coverage
./scripts/check_service_coverage.sh coverage/lcov.info
./scripts/test_flake_audit.sh
./scripts/test_visual_regression.sh
./scripts/cleanup.sh --dry-run
```

### Integration And Device Validation

Use wired-device evidence for release confidence:

```bash
./scripts/run_wired_evidence.sh --suite smoke
./scripts/run_wired_evidence.sh --suite full
```

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

Pass criteria:
- Required checks are green.
- Wired evidence captured for iOS and Android.
- FTL critical suite passes.
- Supabase and AI control audits complete with no unresolved release blockers.

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
