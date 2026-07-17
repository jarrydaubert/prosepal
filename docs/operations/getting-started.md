# Getting Started

This tutorial takes a new contributor from a clean checkout to a successful
native build and test run.

## What you need

- macOS with Xcode 26 and the iOS 26 simulator SDK.
- Swift 6.2 or later.
- Git.
- Deno and the Supabase CLI when changing Edge Functions or migrations.
- Docker Desktop for local Supabase database tests.

No staging secret is required for the local native build and unit tests.

## 1. Open the repository

```bash
cd /path/to/prosepal
git status --short
```

Read [AGENTS.md](../../AGENTS.md) before changing code. Existing working-tree
changes belong to their author; do not discard or restage them casually.

## 2. Build the native package

```bash
cd prosepal-ios
swift build
```

A successful command ends with `Build complete!`.

## 3. Run the native tests

```bash
swift test
```

The repository uses both XCTest and Swift Testing. The command must exit `0`;
do not encode a test count into documentation because the suite evolves.

## 4. Compile the app target

```bash
xcodebuild \
  -project ProsePal.xcodeproj \
  -target ProsePal \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  build
```

This verifies the app plus its embedded widget/control and Share Extension
targets without requiring a signing identity.

## 5. Open Xcode

From the repository root:

```bash
./scripts/run_ios.sh
```

Use the shared `ProsePal` scheme for ordinary local work. Staging configuration
is deliberately separate; follow [Staging](./staging.md) before using it.

## What you built

You now have a locally compiled Swift package, a passing test suite, and an iOS
simulator build of the native ProsePal target. Continue with:

- [Local development](./local-development.md)
- [Native architecture](../engineering/architecture.md)
- [Testing](../quality/testing.md)

## Troubleshooting

If the toolchain cannot parse `Package.swift`, confirm the selected Xcode and
Swift versions:

```bash
xcode-select -p
swift --version
xcodebuild -version
```

If Xcode reports signing errors during the command above, confirm
`CODE_SIGNING_ALLOWED=NO` is present. Physical-device signing is covered by the
staging runbook.
