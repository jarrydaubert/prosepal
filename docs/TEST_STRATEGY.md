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
./scripts/test_flake_audit.sh
flutter test integration_test/smoke_test.dart -d <device-id>
flutter test integration_test/e2e_test.dart -d <device-id>
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
- Run flake audit workflow on schedule.
- Store artifacts for failures (logs, reports, screenshots if available).

## Release Validation Requirements

- Integration smoke on iOS simulator and Android emulator.
- Critical integration suite on one wired iOS physical device and one wired Android physical device.
- Android Firebase Test Lab critical suite run.
- Supabase verification runbook execution.
- AI cost/abuse runbook execution (`docs/AI_COST_ABUSE_RUNBOOK.md`).

## Flaky Test Policy

- A flaky test is non-blocking only after quarantine.
- Quarantined tests must have a backlog item with an owner and clear fix criteria.
- Blocking gate uses the trusted critical-smoke suite only.

## Failure Handling

- Repro locally with the same command and target device class.
- Capture logs and attach to backlog item.
- If gate fails in release candidate stage, stop release promotion until resolved or explicitly waived.

## References

- [BACKLOG.md](./BACKLOG.md)
- [SUPABASE_TESTS.md](./SUPABASE_TESTS.md)
- [NEXT_RELEASE_BRIEF.md](./NEXT_RELEASE_BRIEF.md)
