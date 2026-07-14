# Launch Lessons Reference

## Purpose

Preserve launch and App Review lessons from the Flutter production app so the
native iOS rewrite does not repeat them.

This is not the active native release checklist. Active native work lives in:

- [`../product/v1-launch-contract.md`](../product/v1-launch-contract.md)
- [`../BACKLOG.md`](../BACKLOG.md)
- [`../operations/release.md`](../operations/release.md)

## Lesson 1: Build Configuration Must Be Explicit

Flutter shipped a grey-screen release when release-time configuration was
missing from the build path.

Native translation:

- release/TestFlight builds must have an explicit staging or production
  configuration strategy;
- required public config must be validated before archive or at app launch;
- secrets must never be checked into shared Xcode schemes or source;
- missing generation/auth/purchase config should produce a user-safe unavailable
  state, not a blank screen;
- release evidence must name which gateway environment the build targets without
  exposing secret values.

## Lesson 2: Purchase Must Not Require App Sign-In First

Apple previously rejected the Flutter app because users had to register/sign in
before purchasing a subscription.

Native translation:

- the native paywall must allow purchase without mandatory app account creation;
- Sign in with Apple can be offered as a sync/restore/account-continuity benefit;
- restore must be available from Paywall and Settings;
- free and paid capability must be described plainly;
- subscription terms, privacy policy, and Apple's standard EULA path must be
  available from the relevant App Store metadata and in-app surfaces.

## Lesson 3: Free And Paid Capability Must Be Clear

Native copy should explain product behaviour, not providers:

- Private Draft for ordinary moments where on-device writing is available
- automatic careful gateway treatment for sensitive moments
- the paid plan's actual limits and benefits
- restore purchases

Avoid:

- provider names
- model names
- “perfect message” promises
- unclear paid-feature wording

## Lesson 4: Production Services Are Reference, Not Native Defaults

The archived Flutter app used production Firebase, Supabase, RevenueCat, Remote
Config, Analytics, Crashlytics, App Check, and provider-specific AI routing.

Native translation:

- preserve service ownership and user-continuity lessons;
- do not blindly carry every SDK into the native app;
- use Supabase where it supports the gateway/auth/backend direction;
- use StoreKit 2 for the native app; RevenueCat is archive context only;
- keep Firebase AI / Vertex AI client-direct out of the native app.

## Lesson 5: Evidence Beats Assumption

Native launch readiness needs evidence for the legs that cannot be trusted from
unit tests alone:

- physical iPhone launch and first-run flow;
- staging gateway generation;
- Sign in with Apple;
- purchase, cancel, pending, and restore;
- entitlement convergence;
- settings/support/legal surfaces;
- TestFlight install and smoke.

## When Archived Flutter Production Needs Inspection

Use tag `flutter-prod-freeze-2026-06-25` or branch
`legacy/flutter-production-reference`. Do not recreate Flutter files on active
`main`.
