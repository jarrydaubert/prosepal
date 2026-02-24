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

# Integration smoke/e2e
flutter test integration_test/smoke_test.dart -d <device-id>
flutter test integration_test/e2e_test.dart -d <device-id>

# Firebase Test Lab critical suite
flutter build apk --debug -t integration_test/ftl_test.dart
cd android && JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home ./gradlew app:assembleAndroidTest -Ptarget=../integration_test/ftl_test.dart
gcloud firebase test android run --type instrumentation --app build/app/outputs/flutter-apk/app-debug.apk --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk --device model=oriole,version=33,locale=en,orientation=portrait --timeout 12m --no-use-orchestrator
```

## Notes

- Prefer simulator/emulator or wired devices for integration runs.
- Keep unstable tests out of blocking gates until fixed.
