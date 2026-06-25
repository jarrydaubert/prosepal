# ProsePal

ProsePal is a native iOS app for writing thoughtful personal messages.

The active product is the SwiftUI rebuild in [`prosepal-ios/`](prosepal-ios/):
iOS 26-first, person-first, StoreKit 2, Sign in with Apple, SwiftData,
Foundation Models, and a ProsePal-owned `MessageWritingService` boundary.

The previous Flutter production app has been archived at:

- tag: `flutter-prod-freeze-2026-06-25`
- branch: `legacy/flutter-production-reference`

Do not recreate Flutter files on `main`. Use the archive only for historical
behavior, release lessons, App Review context, or emergency production-reference
inspection.

## Start Here

- [`AGENTS.md`](AGENTS.md) - canonical repo rules for agents and automation.
- [`docs/NEXT_RELEASE_BRIEF.md`](docs/NEXT_RELEASE_BRIEF.md) - native readiness
  scope and release gates.
- [`docs/BACKLOG.md`](docs/BACKLOG.md) - single active tracker for open work.
- [`prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md`](prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md)
  - native product, design, AI, StoreKit, and platform direction.
- [`prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md`](prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md)
  - local staging and physical-device proof.
- [`docs/DEVOPS.md`](docs/DEVOPS.md) - CI, Supabase safety, and release
  operations.

## Native Quick Start

```bash
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Open the native Xcode project:

```bash
./scripts/run_ios.sh
```

Or directly:

```bash
open prosepal-ios/ProsePal.xcodeproj
```

## Product Direction

The app is centered on the Moment Sheet:

```text
person -> moment -> what is true -> private draft / take more care -> copy/share/save/send
```

Non-negotiables:

- no provider/model names in user-facing UI
- no Firebase AI / Vertex AI / Gemini-direct native client path
- no RevenueCat dependency in the native app
- no raw user content, prompts, drafts, tokens, receipts, or provider payloads
  in logs
- no Supabase production deploys, migrations, or secret changes from agent
  tasks

## Architecture

The UI depends on `MessageWritingService`, not a provider SDK.

```text
SwiftUI Moment experience
  -> MomentModel
  -> MessageWritingService
      -> private draft client
      -> careful cloud/gateway client
      -> mock client for tests/previews
```

Everyday moments should use the private/on-device lane where the device supports
it. Harder or more sensitive moments use the careful lane behind ProsePal-owned
policy and routing. Billing/Premium remains separate from safety routing.

## Repo Layout

- `prosepal-ios/` - active native app, Xcode project, Swift package, tests.
- `supabase/` - staging gateway, App Store notification/reconciliation
  functions, migrations, and local Supabase docs.
- `docs/` - active native docs, backlog, runbooks, and historical records.
- `scripts/` - native validation, Xcode opener, Supabase staging safety, and
  repo safety scripts.

## Validation

For native code changes:

```bash
git diff --check
cd prosepal-ios
swift build
swift test --quiet
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

For Supabase function code:

```bash
deno check supabase/functions/**/*.ts
```

For staging gateway smoke tests, use the guarded script and local-only secret
setup documented in [`prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md`](prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md).

## Supabase Safety

Known project refs:

- staging: `llolwgqphwnhbiqewmcq`
- production: `mwoxtqxzunsjmbdqezif`

Never commit `supabase/.temp/` or `supabase/.branches/`. Never run production
migrations from this repo. Staging migrations are human-gated and must use the
guarded flow in [`scripts/supabase-staging.sh`](scripts/supabase-staging.sh).

## Documentation Rules

Open work belongs only in [`docs/BACKLOG.md`](docs/BACKLOG.md). Evergreen docs
should describe current decisions and stable runbooks, not stale TODOs.
