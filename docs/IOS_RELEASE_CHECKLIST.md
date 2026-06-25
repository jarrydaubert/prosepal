# Native iOS Release Checklist

## Purpose

Define the required gates for native iOS TestFlight and release-candidate work.

This checklist applies to `prosepal-ios/`. The previous Flutter production app
is archived at tag `flutter-prod-freeze-2026-06-25` and branch
`legacy/flutter-production-reference`.

## Prerequisites

1. Native release objective is approved in `docs/NEXT_RELEASE_BRIEF.md`.
2. Relevant native backlog gates in `docs/BACKLOG.md` are complete or explicitly
   scoped out of the candidate.
3. Physical iPhone is available for wired validation.
4. Staging or production gateway target is selected without committing secrets.
5. App Store Connect strategy is approved: bundle ID, listing, product IDs,
   subscription terms, privacy policy, and rollback path.

## Evidence Folder Contract

Use one evidence folder per native cut:

```text
artifacts/release/<release-tag>/native-ios/
```

Required evidence files:

- `01-version-build.txt`
- `02-swift-test.log`
- `03-xcodebuild-simulator.log`
- `04-wired-iphone-smoke.md`
- `05-gateway-config-summary.md`
- `06-auth-sign-in-with-apple.md`
- `07-purchase-restore-entitlement.md`
- `08-settings-support-legal.md`
- `09-app-store-connect-review.md`
- `10-testflight-sanity.md`
- `11-secret-audit.log`
- `12-rollback-plan.md`
- `signoff.md`

## Gates

| Gate | Pass Criteria |
|------|---------------|
| Version/build | Version and build values match the intended candidate and are recorded. |
| Swift tests | `cd prosepal-ios && swift test` exits `0`. |
| Simulator build | `cd prosepal-ios && xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` exits `0`. |
| Wired iPhone smoke | Launch, welcome, Moment, keyboard, private/careful drafting states, copy, share, save, Saved, and Settings are exercised on device. |
| Gateway config | The build targets the intended gateway environment; no provider keys, model IDs, dev secrets, or auth tokens are committed or printed. |
| Auth | Sign in with Apple succeeds, cancellation/failure is safe, sign-out clears state, and authenticated gateway token wiring is verified without logging tokens. |
| Purchase/restore | Purchase is available without mandatory app sign-in, restore works from Paywall and Settings, entitlement state is reconciled, and Premium gateway access remains server-authorized. |
| Settings/support/legal | Account, subscription, writing preferences, privacy, support, legal, and about surfaces are present and honest. |
| App Store Connect | Bundle ID/listing/product/subscription/privacy decisions are reviewed against App Review lessons. |
| TestFlight | Install, launch, generate, auth, paywall, restore, settings, and support sanity pass from TestFlight. |
| Secret audit | Git status and repository scans show no local schemes, Supabase `.temp`, secrets, tokens, receipts, screenshots, evidence, or model binaries committed. |
| Rollback | Rollback to the archived Flutter production baseline is documented until native replacement is approved. |

## Failure Handling

If any gate fails:

1. Stop release promotion.
2. Attach the failing evidence to the release evidence folder.
3. Add or update a native backlog item with a deterministic Definition of Done.
4. Re-run only after a fix commit and updated evidence.
