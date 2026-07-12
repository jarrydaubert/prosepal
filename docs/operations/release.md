# Native Release

This runbook covers archive, TestFlight, and App Store release work for the
native iOS app.

## Prerequisites

- The [v1 launch contract](../product/v1-launch-contract.md) is approved.
- Relevant [backlog](../BACKLOG.md) release gates are complete or deliberately
  removed from the candidate.
- A physical iPhone and human-owned App Store sandbox account are available.
- The archive target and public remote configuration are approved.
- Release evidence has a private destination following
  [Release evidence](../quality/release-evidence.md).

## Production identity

The native rewrite uses the existing ProsePal App Store Connect app and bundle
ID:

```text
com.prosepal.prosepal
```

Production subscription identifiers are:

```text
com.prosepal.pro.yearly
com.prosepal.pro.monthly
com.prosepal.pro.weekly
```

The side-by-side staging identity is internal UAT, not a replacement public
listing.

## Archive configuration

Archive builds do not inherit Xcode Run environment variables. Public gateway
and Supabase values enter `Info.plist` through build settings. The archive
validation phase must reject:

- missing gateway URL, Supabase URL, or publishable key;
- non-HTTPS remote URLs;
- production/staging target contamination;
- development gateway secrets; and
- service-role or provider credentials.

Inspect the finished archive to prove the approved public values are present
and privileged values are absent.

## Required local gates

```bash
git diff --check
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
cd ..
./scripts/release_preflight.sh native --no-env-file
```

Run the gateway database and Edge Function gates when the candidate includes
those changes; see [Local development](./local-development.md).

## Device and TestFlight acceptance

Evidence must cover:

- install, launch, welcome, and first Moment;
- keyboard, voice-input availability, private/careful drafting, retry, copy,
  share/send, save, and deletion;
- Sign in with Apple success, cancellation, refresh, sign-out, and account
  deletion;
- StoreKit product loading, purchase, cancellation, pending when reproducible,
  restore, transaction update, and entitlement convergence;
- App Store server notification and reconciliation behaviour;
- Settings, support, privacy, legal, and subscription terms;
- accessibility on the supported release-device matrix;
- optional system surfaces included in the candidate; and
- archive secret and configuration inspection.

## Failure handling

Stop promotion when a required gate fails. Record privacy-safe evidence, create
or update one backlog item with a deterministic definition of done, fix the
cause, and rerun the affected gate. Do not reinterpret a local StoreKit or
simulator result as live sandbox evidence.

## Rollback

Before native replacement is approved, keep the archived Flutter tag and branch
available as production-reference context:

- tag `flutter-prod-freeze-2026-06-25`
- branch `legacy/flutter-production-reference`

Rollback is a deliberate App Store release decision, not a reason to recreate
Flutter sources on active `main`.

## Related documentation

- [Release evidence](../quality/release-evidence.md)
- [Staging](./staging.md)
- [Subscriptions](../engineering/subscriptions.md)
- [App Review lessons](../history/app-review-lessons.md)
