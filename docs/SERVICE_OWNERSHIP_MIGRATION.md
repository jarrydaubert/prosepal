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

## Current Google / Firebase Ownership State

Current verified Google/Firebase production state:
- live Firebase project remains `prosepal-1a24b`
- live project is still under Google Cloud org `jarrydaubert-org`
- Workspace org `prosepal.app` exists separately in Google Cloud
- Firebase public support email is `jarryd@prosepal.app`
- Workspace identity `jarryd@prosepal.app` has production Firebase admin access
- personal Gmail remains in place as backup owner/admin access
- App Check enforcement is enabled for Firebase AI Logic
- Firebase project alerts are enabled for App Distribution, Authentication,
  Firestore, and Crashlytics
- Google Analytics is enabled in Firebase
- live Remote Config now publishes the expected production keys used by the app
- Google Play is not currently linked through the Firebase integration tile

Current verified Supabase production state:
- production project remains `mwoxtqxzunsjmbdqezif`
- Apple and Google auth providers are enabled
- auth email delivery uses custom SMTP with sender address
  `jarryd@prosepal.app`
- hosted auth email templates and notification toggles are configured in the
  dashboard
- Workspace/business identity `jarryd@prosepal.app` has been added with
  admin-level access

Current verified Resend production state:
- sending domain `prosepal.app` is verified
- domain provider is Cloudflare
- SMTP sender path is configured for `jarryd@prosepal.app`
- Supabase integration is connected for SMTP-backed auth delivery
- click tracking and open tracking are disabled
- Workspace/business identity `jarryd@prosepal.app` has been added as admin
- billing email is still personal Gmail

Current verified RevenueCat production state:
- project remains `Prosepal`
- native app configs exist for App Store and Play Store
- no web app configuration is currently in use
- Supabase entitlement sync webhook is active for both Production and Sandbox
- webhook scope is `All apps` / `All events`
- recent webhook deliveries report successful send status
- Workspace/business identity `jarryd@prosepal.app` has been added as an
  `Administrator`
- personal Gmail remains `Owner`
- RevenueCat-hosted web domain remains on the default RevenueCat domain because
  the current project does not use RevenueCat-hosted web billing
- team-wide 2FA enforcement is available but not yet enabled because the
  Workspace admin currently has 2FA disabled

Public-repo constraint:
- document provider ownership, project IDs, and high-level settings
- do not store raw cert fingerprints, recovery details, service-account
  inventories, or other secret-adjacent console values in this repo

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

Agent note:
- when verifying live provider state, prefer the provider SDK, CLI, or API over
  manual console inspection where possible
- use console screenshots as supporting evidence or when provider tooling cannot
  expose the needed state cleanly
- this applies across providers used by Prosepal, including Firebase,
  Google Cloud, Supabase, RevenueCat, GitHub, and similar admin surfaces
- for config-style resources, prefer machine-readable exports because they are
  easier to diff, safer to summarize, and less error-prone than screenshots

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

Current verified state:
- Firebase support email: `jarryd@prosepal.app`
- Google Auth branding developer contact has been moved to the app/domain
  mailbox

### 4) Treat Google Play Separately From Google/Firebase

Google Cloud / Firebase ownership cleanup does not change Google Play developer
account type.

Before planning around Android production access:
1. check whether the Play Console account is `Personal` or `Organization`
2. do not assume a Workspace identity or business-domain email changes the
   tester requirement by itself
3. if organization conversion is considered, verify the account can satisfy the
   required organization-verification inputs before proceeding

Current verified state:
- Play Console developer account type is `Personal`

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

Current next ownership actions:
- Resend: move billing email off personal Gmail
- RevenueCat: decide whether to enable team-wide 2FA after the Workspace admin
  has 2FA enabled
- RevenueCat: review billing/account ownership path
- Cloudflare: confirm whether the zone remains in the personal account or has
  already been transferred

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
