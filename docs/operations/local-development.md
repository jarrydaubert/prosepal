# How to Work Locally

This runbook covers the daily development and validation workflow for the
native SwiftUI app and its Supabase server boundaries.

## Native validation

Run after native code changes:

```bash
git diff --check
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Pass criteria:

- every command exits `0`;
- no test hangs or relies on live services;
- the Xcode build includes the app’s embedded extension targets; and
- `git diff --check` reports no whitespace errors.

## Gateway validation

Run after Edge Function, migration, quota, rate-limit, or idempotency changes:

```bash
deno check supabase/functions/**/*.ts
deno test --allow-env supabase/functions/generate-card/index.test.ts
supabase test db
./scripts/test_gateway_ledger_concurrency.sh
```

Start the local Supabase stack first when the database is unavailable:

```bash
supabase start
```

The pgTAP suite verifies privileges and ledger transitions. The concurrency
script opens separate PostgreSQL sessions and proves that parallel quota and
duplicate-key reservations cannot both enter provider work.

## Repository preflight

Run after repository, workflow, configuration, or documentation changes:

```bash
./scripts/release_preflight.sh native --no-env-file
```

## Xcode schemes

- `ProsePal`: shared production-identity scheme with no embedded secrets.
- `ProsePal Staging`: shared side-by-side staging target and public identity.
- `ProsePal Local Staging`: ignored per-user scheme containing local-only Run
  environment values and optional StoreKit configuration.

Restore the ignored scheme without printing its values:

```bash
./scripts/restore-local-staging-scheme.sh
./scripts/verify-native-staging-plumbing.sh
```

See [Staging](./staging.md) for the environment contract.

## CI

Pull requests and `main` run the repository attribution and secret-history
guards, native preflight, Swift build/tests, simulator build, Edge Function type
checking, and CodeQL for the supported languages. The native job uses an Xcode
26-capable hosted runner because the package requires the iOS 26 SDK and Swift
tools 6.2 or later.

## Test stability

- Blocking tests must use fixed clocks, injected clients, and explicit
  deadlines.
- A potentially flaky test must be tagged and excluded from blocking CI until
  fixed.
- Live provider, StoreKit sandbox, Apple, and remote Supabase checks are release
  evidence, not unit tests.

## Privacy during debugging

Do not print or capture raw recipient details, prompts, generated messages,
tokens, receipts, provider payloads, provider keys, development secrets, or
database URLs containing credentials.

Native OSLog subsystems are:

```text
com.prosepal.prosepal
com.prosepal.prosepal.staging
```

Useful logs contain event names, categories, counts, lane names, status codes,
and latency only.

## Failure handling

- Native compile failure: reproduce with the smallest required command and fix
  source before running broad preflight again.
- Local Supabase failure: check `supabase status`; do not switch to a remote
  project to make a local test pass.
- Toolchain mismatch: verify `xcode-select`, `swift --version`, and the simulator
  SDK before changing package requirements.
- Staging failure: follow [Staging](./staging.md) and verify the explicit project
  target before any mutation.
