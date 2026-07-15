# Testing

ProsePal separates deterministic blocking tests from live release evidence. A
unit test must not need a provider, Keychain, App Store account, remote Supabase
project, or wall-clock race to pass.

## Test layers

| Layer | Purpose | Command or location |
|---|---|---|
| Swift package | Domain, API, concurrency, persistence, account, StoreKit, and observable-model behaviour | `cd prosepal-ios && swift test` |
| App-hosted StoreKit | Real `StoreKitSubscriptionClient` against the local `.storekit` configuration, with xcresult count enforcement | `./scripts/run_storekit_release_gate.sh` |
| Native UI smoke | Durable first-run, navigation, generation-state, account, subscription-presentation, persistence, sharing/export, and accessibility-size journeys | `./scripts/run_native_ui_tests.sh smoke` |
| Native UI full | The smoke journeys plus destructive failure states, saved-draft reopening, generic share/export presentation, and generation-error recovery | `./scripts/run_native_ui_tests.sh full` |
| Xcode simulator build | App target and embedded extension compilation | `xcodebuild ... CODE_SIGNING_ALLOWED=NO build` |
| Edge Function | Handler validation, auth rejection, provider-call suppression, Apple account lifecycle, ledger outcomes, and logging hygiene | discover every `supabase/functions/**/*.test.ts` file and run them together with `deno test --allow-env` |
| Database | Privileges, quota, idempotency, transition, retention, and cleanup contracts | `supabase test db` |
| Database concurrency | Real parallel advisory-lock and uniqueness behaviour | `./scripts/test_gateway_ledger_concurrency.sh` |
| Release preflight | Repository policy, configuration, documentation, and workflow checks | `./scripts/release_preflight.sh native --no-env-file` |
| Device/TestFlight | Apple, network, accessibility, system-surface, and sandbox behaviour | Private release evidence |

## Native gate

```bash
git diff --check
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

The app-hosted StoreKit suite is a release gate rather than a deterministic
package gate. Its harness skips only when a caught `NSError` is exactly
`SKInternalErrorDomain` code `3`; the skip explains the observed Apple runtime
failure but never passes the release gate. A successful product probe must
return exactly the configured product IDs. An empty, missing, extra, or wrong
result is a setup failure and is never diagnosed as an Apple runtime error.
The release wrapper parses the xcresult and passes only when every expected
scenario ran, with zero failures and zero skips.

## Gateway gate

```bash
deno check supabase/functions/**/*.ts
find supabase/functions -name '*.test.ts' -exec deno test --allow-env {} +
supabase test db
./scripts/test_gateway_ledger_concurrency.sh
```

## Determinism rules

- Inject clocks, timeouts, clients, persistence, and StoreKit transaction
  boundaries.
- Use explicit deadlines for asynchronous waits; a regression must fail rather
  than hang the runner.
- Assert expensive side effects did not occur after auth, secret, quota,
  validation, or idempotency rejection.
- Test concurrency outcomes without requiring a particular task interleaving.
- Keep live provider calls, Apple sandbox state, and physical-device behaviour
  outside blocking unit tests.
- Tag a known flaky test and remove it from blocking CI until fixed; track the
  repair in the backlog.

## UI coverage

`ProsePalNativeUITests` drives the Staging app through a DEBUG-only launch seam.
The explicit `--prosepal-ui-testing` marker selects an isolated SwiftData store,
in-memory auth, a no-op active-draft recovery store, mock subscriptions and
writing, and named account-deletion outcomes. Without that marker, normal
production and staging composition is unchanged. Tests locate outcomes by
stable accessibility identifiers rather than exact prose or view hierarchy.

Pull requests that touch the native app run the durable smoke class. The weekly
schedule and manual full run execute the whole target. These simulator journeys
prove app wiring and presentation only: live Apple authorization, StoreKit
sandbox products and transactions, provider output, system share destinations,
VoiceOver, and physical-device behaviour remain release evidence.

Network-backed UI journeys use deterministic delayed success, failure, and
indeterminate outcomes. Their behavioural contract is immediate acknowledgement,
an honest accessible in-progress value, duplicate-action prevention, preserved
user input, and a confirmed success, failure, retry, or indeterminate outcome as
appropriate. Tests reject invented percentage progress and completion shown
before the injected boundary responds. They assert stable action and outcome
semantics rather than exact prose, timing, layout, or view hierarchy.

Generation UI coverage is intentionally shallow. It proves typed input can
start work, the existing Stop control is reachable, successful output is
visible and editable, and offline or failed generation returns an honest retry.
Prompt quality, provider behaviour, streaming, and future composer structure
belong to their owning test or release-evidence layers.

Source-string tests may temporarily guard a surface that is otherwise
unreachable from package tests. Replace them with behavioural or view-level
coverage when that surface is extracted; do not let tests permanently pin the
main SwiftUI monolith.

## Failure handling

Fix the narrowest failing layer first. Do not make a deterministic test more
permissive merely because a remote or simulator check is unreliable. Remote
failures belong in release evidence with environment, time, and privacy-safe
outcome, never with credentials or user content.
