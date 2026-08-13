# How to Release ProsePal for iOS

This runbook covers archive, TestFlight, and App Store release work for the iOS
app.

## Prerequisites

- The [v1 launch contract](../product/v1-launch-contract.md) is approved.
- Relevant [backlog](../BACKLOG.md) release gates are complete or deliberately
  removed from the candidate.
- A physical iPhone and human-owned App Store sandbox account are available.
- The archive target and public remote configuration are approved.
- Release evidence has a private destination following
  [Release evidence](../quality/release-evidence.md).

## Production identity

ProsePal uses the existing App Store Connect app and bundle ID:

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

## Privacy qualification

Use [Data and privacy](../engineering/data-and-privacy.md) as the canonical
engineering map for generation routes, storage, retention, export, and deletion.
Before candidate promotion, confirm that the implemented online-writing
permission, public policy and support routes, App Store event-retention policy,
in-app controls, privacy manifests, and App Store Connect declarations agree
with that map and the release build. The ordered owner decisions and evidence
requirements remain in the privacy programme in [BACKLOG.md](../BACKLOG.md);
unresolved mandatory gates block release rather than being inferred from source.

## Device and TestFlight acceptance

Before device acceptance, run the complete deterministic simulator UI suite:

```bash
./scripts/run_native_ui_tests.sh full
```

The pull-request workflow runs the smaller durable smoke class; the weekly and
manual workflow run the full target. A passing simulator suite does not replace
the external evidence below.

Evidence must cover:

- install, launch, welcome, and first Moment;
- keyboard, private/careful drafting, retry, copy,
  share/send, save, and deletion;
- Sign in with Apple success, cancellation, refresh, sign-out, and account
  deletion;
- StoreKit product loading, purchase, cancellation, pending when reproducible,
  restore, transaction update, and entitlement convergence;
- delayed network-backed actions acknowledging taps, preventing duplicate
  submission, preserving user work, exposing accessible progress, and reaching
  an honest confirmed, retryable, or indeterminate outcome;
- App Store server notification and reconciliation behaviour;
- Settings, support, privacy, legal, and subscription terms;
- Plan, Paywall, StoreKit metadata, and App Store listing consistently promise
  higher limits rather than unlimited or unapproved quantified usage;
- accessibility on the supported release-device matrix;
- optional system surfaces included in the candidate; and
- archive secret and configuration inspection.

Before sandbox/TestFlight promotion, run the app-hosted direct client suite from
the shared staging scheme:

```bash
./scripts/run_storekit_release_gate.sh
```

The wrapper selects the direct StoreKit scenario class, records an xcresult, and
requires the expected scenario count with zero failed and zero skipped tests.
Only an actually caught `NSError` whose domain is `SKInternalErrorDomain` and
whose code is `3` is labelled as the known Apple-runtime skip. That skip still
blocks promotion. A successful probe returning no products—or missing, extra,
or incorrect product IDs—fails setup without inferring an error diagnosis.

## Failure handling

Stop promotion when a required gate fails. Record privacy-safe evidence, create
or update one backlog item with a deterministic definition of done, fix the
cause, and rerun the affected gate. Do not reinterpret a local StoreKit or
simulator result as live sandbox evidence.

## Rollback

Keep the archived Flutter tag and branch available as production-reference
context:

- tag `flutter-prod-freeze-2026-06-25`
- branch `legacy/flutter-production-reference`

Rollback is a deliberate App Store release decision, not a reason to recreate
Flutter sources on active `main`.

## Related documentation

- [Release evidence](../quality/release-evidence.md)
- [Staging](./staging.md)
- [Subscriptions](../engineering/subscriptions.md)
- [App Review lessons](../history/app-review-lessons.md)
