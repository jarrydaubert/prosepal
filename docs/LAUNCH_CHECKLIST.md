# Launch Lessons Reference

## Purpose

Preserve launch and App Review lessons from the Flutter production app so the
native iOS rewrite does not repeat them.

This is not the active native release checklist. Active native work lives in:

- `docs/NEXT_RELEASE_BRIEF.md`
- `docs/BACKLOG.md`
- `docs/IOS_RELEASE_CHECKLIST.md`

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

Native copy should explain product lanes, not providers:

- Standard generation
- Premium generation
- enhanced drafts
- higher limits
- restore purchases

Avoid:

- provider names
- model names
- “perfect message” promises
- unclear paid-feature wording

## Lesson 4: Production Services Are Reference, Not Native Defaults

The live Flutter app uses production Firebase, Supabase, RevenueCat, Remote
Config, Analytics, Crashlytics, App Check, and provider-specific AI routing.

Native translation:

- preserve service ownership and user-continuity lessons;
- do not blindly carry every SDK into the native app;
- use Supabase where it supports the gateway/auth/backend direction;
- decide RevenueCat versus StoreKit 2 deliberately before production
  replacement;
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

## When Flutter Production Needs A Hotfix

Use Flutter production-reference operations in `docs/DEVOPS.md` and add any
new Flutter production work to `docs/BACKLOG.md` only when it is required to
protect the live app.
