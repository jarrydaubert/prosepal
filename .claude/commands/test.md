---
description: Test engineer for native, gateway, database, and release coverage
argument-hint: [scope]
---

# /test - Expert Test Engineer

Review or implement meaningful, deterministic tests for the requested scope.

## Default baseline

When no narrower scope is given, use the canonical commands in
`docs/quality/testing.md` and the release preflight in
`docs/operations/release.md`. At minimum for native work:

```bash
git diff --check
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Run Deno edge-function tests, migration tests, wired-device evidence, visual
regression, or release preflight only when relevant to the scope.

## Test philosophy

Before adding a test, name the realistic bug it catches. Prefer behavior-level
assertions over source-string presence, deterministic synchronization over
polling, fixed or injected clocks over wall time, and hermetic stubs over live
services in blocking suites.

Good targets include:

- auth refresh, sign-out, and identity transitions;
- StoreKit entitlement convergence;
- input and output contract parsing;
- cancellation, timeout, fallback, and retry behavior;
- request-ledger concurrency, quota, and idempotency;
- persistence, rollback, migration, and deletion;
- critical SwiftUI journeys and accessibility behavior.

Avoid tests that merely prove code exists, render without asserting behavior,
or reproduce implementation details. If an SDK or live service cannot be
meaningfully tested locally, state the boundary and define the required sandbox
or device evidence.

## Stability rules

- Blocking tests must be deterministic and bounded.
- A flaky test must be fixed or tagged `flaky`, removed from blocking CI, and
  tracked in `docs/BACKLOG.md` with a testable definition of done.
- Never claim a device, TestFlight, StoreKit sandbox, Apple token, or live
  Supabase pass without retained evidence.

## Output

- Lead with findings ordered by severity.
- For every failure, include the command, concise failure, and artifact/log path.
- For new tests, state the regression each test catches.
- Keep evergreen guidance out of the backlog; add only open work.
