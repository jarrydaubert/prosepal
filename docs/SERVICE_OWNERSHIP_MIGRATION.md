# Service Ownership Migration Runbook

## Purpose

Move operational ownership of production services from personal identities to
business-managed identities while keeping the live app stable.

This runbook is about control, recovery, and clean service boundaries. It is
not a runtime replatforming plan.

## Scope

This runbook covers:
- Google Cloud / Firebase / Google Auth Platform / Google Play
- Cloudflare / DNS
- Supabase
- RevenueCat
- app-facing contact mailboxes
- recovery and admin ownership

## Current Production Identifiers

These are the production identifiers currently visible in the repo and verified
in provider consoles.

| Surface | Identifier | Source |
|---------|------------|--------|
| Firebase project ID | `prosepal-1a24b` | `lib/firebase_options.dart` |
| Firebase sender ID | `530026851718` | `lib/firebase_options.dart` |
| Firebase iOS app ID | `1:530026851718:ios:0dab14080ea6f8be6bd007` | `lib/firebase_options.dart` |
| Firebase Android app ID | `1:530026851718:android:71029bf2c74548436bd007` | `lib/firebase_options.dart` |
| Firebase iOS bundle ID | `com.prosepal.prosepal` | `lib/firebase_options.dart` |
| Firebase storage bucket | `prosepal-1a24b.firebasestorage.app` | `lib/firebase_options.dart` |
| Verified live Google Cloud org | `jarrydaubert-org` | provider console verification |
| Workspace org visible in console | `prosepal.app` | provider console verification |
| Supabase project ref | `mwoxtqxzunsjmbdqezif` | `docs/LAUNCH_CHECKLIST.md` |
| RevenueCat project path | `projects/a8bf92d5` | `docs/LAUNCH_CHECKLIST.md` |
| App support mailbox in code | `jarryd@prosepal.app` | `lib/core/config/app_config.dart` |

## Working Rule

For live Prosepal, preserve the existing production runtime stack wherever
possible.

Preferred order:
1. migrate ownership and admin access
2. normalize public contact details
3. verify runtime behavior
4. only consider project/org moves or service replacement if ownership transfer
   is insufficient

Do not clone production services just to improve admin cleanliness.

## Commands And Steps

### 1) Keep The Live Google Project As The Production Source Of Truth

Treat this as the only live Google/Firebase project:
- `Prosepal`
- project ID `prosepal-1a24b`

Do not use these for live production unless there is an explicit migration plan:
- `friendly-art-490215-e8`
- `flowing-castle-490219-h2`

### 2) Grant Business-Identity Access To The Existing Production Project

Preferred approach:
1. keep the live project where it is
2. add the Workspace identity to the existing project
3. avoid creating a parallel production project

If organization policy blocks project-level `Owner`, grant:
- organization role: `Organization Administrator`
- project roles:
  - `Firebase Admin`
  - `Project IAM Admin`
  - `Service Usage Admin`
  - `OAuth Config Editor (beta)`

This provides operational control without forcing a production replatform.

### 3) Normalize Google/Firebase Public Contact Fields

In Google Auth Platform / Firebase:
1. ensure the live project is accessible from the Workspace identity
2. move public support/developer contact fields away from personal Gmail
3. use the app/domain mailbox instead

Current desired direction:
- app/domain mailbox for support and admin contact
- personal Gmail only as backup/recovery

### 4) Treat Google Play Separately From Google/Firebase

Google Cloud / Firebase ownership cleanup does not change Google Play developer
account type.

Before planning around Android production access:
1. check whether the Play Console account is `Personal` or `Organization`
2. do not assume a Workspace identity or business-domain email changes the
   tester requirement by itself
3. if organization conversion is considered, verify the account can satisfy the
   required organization-verification inputs before proceeding

### 5) Move Other Production Services By Ownership First

For each of the following, prefer ownership/admin transfer before considering
replacement:
- Cloudflare
- Supabase
- RevenueCat

Preferred approach:
1. invite the business identity into the existing project/org/account
2. promote it to the highest required admin role
3. move app-facing contact mailboxes to the business/domain mailbox
4. keep personal identity only as backup until the new path is verified

### 6) Re-Verify Runtime Wiring After Any Credential Or Ownership Change

Run the baseline validation set after any config or credential change:

```bash
flutter analyze
flutter test
./scripts/test_critical_smoke.sh
./scripts/release_preflight.sh all
```

Then verify on physical devices:
1. Apple sign-in works
2. Google sign-in works
3. RevenueCat offerings load
4. existing subscription state resolves correctly
5. Crashlytics/Analytics continue to flow
6. Firebase Remote Config fetch succeeds

## Pass Criteria

The migration is complete only when all are true:

1. the Workspace/business identity can fully administer the live production
   stack
2. personal Gmail is no longer the primary public/admin identity for production
   services
3. the live app continues using the intended production runtime stack
4. app-facing support/admin contact paths use the app/domain mailbox
5. relevant validation commands pass after any config changes
6. provider-console checks confirm auth, purchases, crash reporting, and
   configuration still function

## Failure Handling

If any service transfer fails:
1. stop before deleting or demoting the personal account
2. capture provider-console evidence
3. keep the personal account as backup admin until the replacement path is
   verified
4. do not create a replacement production project impulsively
5. if a true project move is required, treat it as a separate migration with
   explicit cutover planning

## References

- `docs/APP_OPERATING_STANDARD.md`
- `docs/LAUNCH_CHECKLIST.md`
- `docs/DEVOPS.md`
- `docs/BACKLOG.md`
- `lib/firebase_options.dart`
- `lib/core/config/app_config.dart`
