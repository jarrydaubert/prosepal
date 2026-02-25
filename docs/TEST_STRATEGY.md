# Test Strategy

## Purpose

Define a stable testing approach for local development, CI, and release gating.

## Layers

- Unit tests: service, model, and pure logic verification.
- Widget tests: screen/component behavior verification without device dependency.
- Integration tests: end-to-end journeys on simulator/emulator and physical devices.
- Backend verification: Supabase SQL/RPC/RLS and edge-function checks.

## Local Commands

```bash
flutter analyze
./scripts/test_critical_smoke.sh
flutter test
flutter test --exclude-tags flaky --coverage
./scripts/check_service_coverage.sh coverage/lcov.info
./scripts/test_flake_audit.sh
./scripts/test_visual_regression.sh
SUPABASE_DB_URL="postgresql://..." ./scripts/verify_supabase_readonly.sh
./scripts/cleanup.sh --dry-run
flutter test integration_test/smoke_test.dart -d <device-id>
flutter test integration_test/e2e_test.dart -d <device-id>
flutter test integration_test/e2e_real_test.dart -d <android-device-id> --dart-define=REVENUECAT_USE_TEST_STORE=true
./scripts/run_wired_evidence.sh --suite smoke
./scripts/run_wired_evidence.sh --suite full
flutter build apk --debug -t integration_test/ftl_test.dart
cd android && JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home ./gradlew app:assembleAndroidTest -Ptarget=../integration_test/ftl_test.dart
gcloud firebase test android run --type instrumentation --app build/app/outputs/flutter-apk/app-debug.apk --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk --device model=oriole,version=33,locale=en,orientation=portrait --timeout 12m --no-use-orchestrator
```

`integration_test/ftl_test.dart` is the deterministic Test Lab critical suite entrypoint.

## CI Requirements

- Run analyzer.
- Run release-config preflight tests.
- Run the critical smoke suite.
- Run unit/widget suites.
- Exclude tests tagged `flaky` from blocking CI runs.
- Enforce minimum line coverage for `lib/core/services/` with `./scripts/check_service_coverage.sh` (`MIN_COVERAGE=35` baseline; ratchet upward as coverage improves).
- Run flake audit workflow on schedule.
- Store artifacts for failures (logs, reports, screenshots if available).
- Keep critical-screen visual regression guard green via `./scripts/test_visual_regression.sh`.

## Release Validation Requirements

- Integration smoke on iOS simulator and Android emulator.
- Critical integration suite on one wired iOS physical device and one wired Android physical device.
- Capture wired evidence artifacts via `./scripts/run_wired_evidence.sh` and attach `artifacts/wired/<run-id>/SUMMARY.md`.
- Keep integration-framework screenshots disabled by default (`INTEGRATION_CAPTURE_SCREENSHOTS=false`) to avoid platform screenshot flake; use wired artifact screenshots/logs as release evidence.
- iOS external screenshot capture in wired evidence is best-effort and may be unavailable if `idevicescreenshot` cannot pair with the connected device.
- Android Firebase Test Lab critical suite run.
- Real E2E suite (`integration_test/e2e_real_test.dart`) run at least once per release candidate on wired Android with `REVENUECAT_USE_TEST_STORE=true`.
- Supabase verification runbook execution.
- AI cost/abuse runbook execution (`docs/AI_COST_ABUSE_RUNBOOK.md`).
- Identity mapping QA flow execution (`docs/IDENTITY_MAPPING.md`).

## Flaky Test Policy

- A flaky test is non-blocking only after quarantine.
- Quarantined tests must have a backlog item with an owner and clear fix criteria.
- Blocking gate uses the trusted critical-smoke suite only.
- Mark flaky tests with an explicit tag:

```dart
testWidgets(
  'example flaky case',
  (tester) async {
    // test body
  },
  tags: ['flaky'],
);
```

- Run all quarantined tests locally with:

```bash
flutter test --tags flaky
```

## Failure Handling

- Repro locally with the same command and target device class.
- Capture logs and attach to backlog item.
- If gate fails in release candidate stage, stop release promotion until resolved or explicitly waived.
- For golden failures, inspect image diffs under `test/failures/`.

## References

- [BACKLOG.md](./BACKLOG.md)
- [IDENTITY_MAPPING.md](./IDENTITY_MAPPING.md)
- [SUPABASE_TESTS.md](./SUPABASE_TESTS.md)
- [NEXT_RELEASE_BRIEF.md](./NEXT_RELEASE_BRIEF.md)
