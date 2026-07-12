# ProsePal

ProsePal is a native iOS app for writing thoughtful personal messages. The
active product is the SwiftUI app under `prosepal-ios/`: person-first, iOS
26-first, StoreKit 2, Sign in with Apple, SwiftData, Foundation Models, and a
ProsePal-owned gateway boundary.

The previous Flutter production app is frozen at tag
`flutter-prod-freeze-2026-06-25` and branch
`legacy/flutter-production-reference`. Historical material lives under
[`docs/history/`](docs/history/README.md); do not recreate Flutter sources on
active `main`.

## Documentation

Start with the [documentation index](docs/README.md).

- [Plain-English app guide](docs/guide/app-guide.html)
- [V1 launch contract](docs/product/v1-launch-contract.md)
- [Capabilities](docs/product/capabilities.md)
- [Native architecture](docs/engineering/architecture.md)
- [Getting started](docs/operations/getting-started.md)
- [Backlog](docs/BACKLOG.md)
- [Repository agent contract](AGENTS.md)

## Native quick start

```bash
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Open Xcode from the repository root:

```bash
./scripts/run_ios.sh
```

## Product shape

```text
person -> moment -> what is true -> private draft / take more care
       -> edit or adjust -> copy / share / send / save
```

The native UI depends on `MessageWritingService`, not a provider SDK. Everyday
moments use the private on-device lane where available. Harder moments can use
the careful gateway lane. Subscription state controls paid limits and extras;
it does not control whether sensitive writing receives careful treatment.

## Repository layout

- `prosepal-ios/` — native app, Swift package, Xcode project, and tests.
- `supabase/` — Edge Functions, migrations, pgTAP tests, and local backend
  configuration.
- `docs/` — canonical app documentation and frozen history.
- `design-system/` — web-rendered design source and archived visual directions.
- `scripts/` — validation, staging guards, Xcode helpers, and repository safety.
- `.agents/` and `.claude/` — the small native audit, security, testing, and
  cleanup command set; canonical app knowledge remains in `docs/`.

## Validation

Native:

```bash
git diff --check
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Gateway and database:

```bash
deno check supabase/functions/**/*.ts
deno test --allow-env supabase/functions/generate-card/index.test.ts
supabase test db
./scripts/test_gateway_ledger_concurrency.sh
```

Repository and documentation:

```bash
./scripts/validate_docs.sh
./scripts/release_preflight.sh native --no-env-file
```

See [Local development](docs/operations/local-development.md) for prerequisites
and failure handling.

## Safety rules

- Never commit or print secrets, tokens, receipts, database credentials, or
  personal message content.
- Never expose provider/model names in user-facing native UI.
- Never place a provider or service-role credential in the app bundle.
- Never mutate production Supabase from an agent task without explicit approval
  for the exact operation.
- Use the guarded [staging runbook](docs/operations/staging.md) for remote proof.
