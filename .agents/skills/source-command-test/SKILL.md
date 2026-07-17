---
name: source-command-test
description: Test engineer for native, gateway, database, and release coverage
---

# Source Command Test

Use this skill when the user asks to run the migrated source command `test`.

Review or implement meaningful, deterministic tests for the requested scope.
Use the canonical commands in `docs/quality/testing.md` and the release gates in
`docs/operations/release.md`.

For native work, the baseline is:

```bash
git diff --check
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Run Deno, migration, wired-device, visual-regression, or release-preflight
checks when relevant. Before adding a test, name the realistic bug it catches.
Prefer behavior-level assertions, deterministic synchronization, injected
clocks, and hermetic stubs. Avoid source-string existence tests and tests that
only prove a view renders.

Critical targets include auth transitions, StoreKit convergence, contract
parsing, cancellation/timeouts/fallback, request-ledger concurrency,
persistence/rollback/migration/deletion, and critical SwiftUI accessibility
journeys.

Blocking tests must be deterministic and bounded. Fix or tag flaky tests with
`flaky`, remove them from blocking CI, and track the fix in `docs/BACKLOG.md`.
Never claim live-device, TestFlight, StoreKit, Apple, or Supabase proof without
retained evidence.

Lead with findings by severity. For every failure include the command, concise
failure, and artifact path. For every new test state the regression it catches.
