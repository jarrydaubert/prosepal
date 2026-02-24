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
flutter test

# Flake audit
./scripts/test_flake_audit.sh

# Integration smoke/e2e
flutter test integration_test/smoke_test.dart -d <device-id>
flutter test integration_test/e2e_test.dart -d <device-id>
```

## Notes

- Prefer simulator/emulator or wired devices for integration runs.
- Keep unstable tests out of blocking gates until fixed.
