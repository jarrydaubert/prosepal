# Test Commands

This file is intentionally concise. Test strategy and policy live in docs.

## Primary References

- [Test Strategy](../docs/TEST_STRATEGY.md)
- [Docs Policy](../docs/DOCS_POLICY.md)
- [Backlog](../docs/BACKLOG.md)

## Commands

```bash
# Analyzer + unit/widget
flutter analyze
./scripts/test_release_preflight.sh
./scripts/test_critical_smoke.sh
flutter test

# Flake audit
./scripts/test_flake_audit.sh

# AI cost/abuse control audit (ops verification)
./scripts/audit_ai_cost_controls.sh

# Local artifact cleanup
./scripts/cleanup.sh --dry-run
./scripts/cleanup.sh

# Integration smoke/e2e
flutter test integration_test/smoke_test.dart -d <device-id>
flutter test integration_test/e2e_test.dart -d <device-id>
./scripts/run_wired_evidence.sh --suite smoke
./scripts/run_wired_evidence.sh --suite full

# Firebase Test Lab critical suite
flutter build apk --debug -t integration_test/ftl_test.dart
cd android && JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home ./gradlew app:assembleAndroidTest -Ptarget=../integration_test/ftl_test.dart
gcloud firebase test android run --type instrumentation --app build/app/outputs/flutter-apk/app-debug.apk --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk --device model=oriole,version=33,locale=en,orientation=portrait --timeout 12m --no-use-orchestrator
```

## Notes

- Prefer simulator/emulator or wired devices for integration runs.
- Use `./scripts/run_wired_evidence.sh` when you need a single artifact bundle with logs and screenshots from wired devices.
- In-test integration screenshots are off by default for stability (`INTEGRATION_CAPTURE_SCREENSHOTS=false`); rely on wired evidence artifacts unless debugging screenshot APIs specifically.
- iOS external screenshot capture is best-effort and depends on local `idevicescreenshot` pairing support.
- Keep unstable tests out of blocking gates until fixed.
