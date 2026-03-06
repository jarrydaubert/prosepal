# iOS Release Checklist

## Purpose

Define the required pre-release iOS gates for `P0-07` using deterministic commands and evidence paths.

## Prerequisites

1. Release candidate branch and tag candidate are identified.
2. `.env.local` contains non-placeholder runtime values.
3. Physical iOS device is available for wired validation.
4. App Store Connect release metadata draft is prepared.

## Evidence Location Contract

Use one release folder per cut:

```bash
artifacts/release/<release-tag>/P0-07/
```

Required evidence files:
- `01-version-build.txt`
- `02-flutter-analyze.log`
- `03-flutter-test.log`
- `04-critical-smoke.log`
- `05-wired-ios-summary.md`
- `06-ios-archive.log`
- `07-crashlytics-dsym.txt`
- `08-firebase-appcheck-ai-ios.md`
- `09-revenuecat-entitlement-paywall-ios.md`
- `10-supabase-auth-provider-ios.md`
- `11-app-store-connect-review.md`
- `12-testflight-sanity.md`
- `13-secret-audit.log`
- `14-rollback-plan.md`
- `signoff.md`

## Release Gates

1. Version/build bump recorded.
Command:
```bash
rg '^version:' pubspec.yaml
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -showBuildSettings | rg 'CURRENT_PROJECT_VERSION ='
```
Pass criteria: marketing version from `pubspec.yaml` and build number from Xcode build settings match intended release notes and are recorded in `01-version-build.txt`. Do not rely on literal `Info.plist` values here because this app uses Flutter build-variable substitution (`$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)`).

2. Analyzer gate.
Command:
```bash
flutter analyze | tee artifacts/release/<release-tag>/P0-07/02-flutter-analyze.log
```
Pass criteria: no analyzer errors.

3. Unit/widget test gate.
Command:
```bash
flutter test | tee artifacts/release/<release-tag>/P0-07/03-flutter-test.log
```
Pass criteria: test command exits `0`.

4. Critical smoke gate.
Command:
```bash
./scripts/test_critical_smoke.sh | tee artifacts/release/<release-tag>/P0-07/04-critical-smoke.log
```
Pass criteria: smoke suite exits `0`.

5. Wired iOS smoke/journey evidence.
Command:
```bash
./scripts/run_wired_evidence.sh --suite smoke
```
Pass criteria: latest wired run summary is copied or linked into `05-wired-ios-summary.md`.

6. Scripted iOS archive gate.
Command:
```bash
./scripts/release_preflight.sh ios
./scripts/build_ios.sh | tee artifacts/release/<release-tag>/P0-07/06-ios-archive.log
```
Pass criteria: archive/build path succeeds using scripted flow.

7. Crashlytics dSYM upload verification.
Pass criteria: upload confirmation is captured in `07-crashlytics-dsym.txt` with timestamp and build reference.

8. Firebase App Check and AI generation verification on physical iOS.
Pass criteria: successful generation plus App Check-verified request evidence recorded in `08-firebase-appcheck-ai-ios.md`.

9. RevenueCat entitlement/paywall verification on physical iOS.
Pass criteria: purchase/restore/entitlement checks are recorded in `09-revenuecat-entitlement-paywall-ios.md`.

10. Supabase auth/provider verification on physical iOS.
Pass criteria: Apple/Google sign-in and callback behavior are recorded in `10-supabase-auth-provider-ios.md`.

11. App Store Connect metadata/release notes/screenshots review.
Pass criteria: metadata review outcome and any deltas are recorded in `11-app-store-connect-review.md`.

12. TestFlight sanity pass.
Pass criteria: install + launch + generate + auth + paywall sanity is recorded in `12-testflight-sanity.md`.

13. Git history secret audit.
Command:
```bash
git log --all -- .env.local | tee artifacts/release/<release-tag>/P0-07/13-secret-audit.log
./scripts/security_history_guard.sh | tee -a artifacts/release/<release-tag>/P0-07/13-secret-audit.log
```
Pass criteria: no secret-leak findings blocking release.

14. Rollback path confirmation.
Pass criteria: rollback operator, trigger criteria, and rollback steps are recorded in `14-rollback-plan.md`.

15. Owner sign-off.
Pass criteria: signed approval is recorded in `signoff.md` in the same folder.

## Failure Handling

If any gate fails:
1. Stop release promotion.
2. Attach failing logs/evidence in the same `P0-07` folder.
3. Open/update a backlog item with deterministic fix DoD.
4. Re-run only after fix commit and updated evidence.
