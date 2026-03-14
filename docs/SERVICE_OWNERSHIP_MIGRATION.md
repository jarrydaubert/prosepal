# Service Ownership Migration Runbook

## Purpose

Move operational ownership of production services from personal identities to
business-managed identities while keeping the live app stable.

This runbook covers service ownership, admin access, billing custody, recovery
paths, and runtime verification for:
- Google Cloud / Firebase / Google Play
- Cloudflare
- Supabase
- RevenueCat
- Apple Developer / App Store Connect
- repo/runtime secret custody where service ownership changes require rotation

Use this runbook when:
- moving from a personal Google account to Google Workspace
- preparing the app for sale or handover
- reducing dependency on a personal inbox or personal billing profile

## Prerequisites

1. A Google Workspace admin user for the business domain.
2. Working access to current personal-owner accounts for every provider.
3. Access to the production repo checkout and local release scripts.
4. Current runtime values available from local `.env.local` and provider
   consoles before any transfer.
5. A recovery plan:
   - personal account retained as temporary backup admin
   - 2FA devices available for both personal and business identities
   - current billing methods available for re-entry if providers require it

## Current Repo-Visible Identifiers To Verify

Verify these before changing ownership. They are the current identifiers visible
in the repo and checked-in generated config, not an assumption about current
provider-console state.

| Surface | Identifier | Source |
|---------|------------|--------|
| Firebase project ID | `prosepal-1a24b` | `lib/firebase_options.dart` |
| Firebase sender ID | `530026851718` | `lib/firebase_options.dart` |
| Firebase iOS app ID | `1:530026851718:ios:0dab14080ea6f8be6bd007` | `lib/firebase_options.dart` |
| Firebase Android app ID | `1:530026851718:android:71029bf2c74548436bd007` | `lib/firebase_options.dart` |
| Firebase iOS bundle ID | `com.prosepal.prosepal` | `lib/firebase_options.dart` |
| Firebase storage bucket | `prosepal-1a24b.firebasestorage.app` | `lib/firebase_options.dart` |
| Google Cloud/Firebase org | `jarrydaubert-org` | provider console verification |
| Supabase project ref | `mwoxtqxzunsjmbdqezif` | `docs/LAUNCH_CHECKLIST.md` |
| RevenueCat project path | `projects/a8bf92d5` | `docs/LAUNCH_CHECKLIST.md` |
| Support mailbox | `jarryd@prosepal.app` | `lib/core/config/app_config.dart` |

Runtime keys that must be preserved or re-issued during migration:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `REVENUECAT_IOS_KEY`
- `REVENUECAT_ANDROID_KEY`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`

## Commands And Steps

### 1) Capture A Production Inventory Before Changing Ownership

In each provider console, record:
- current owner/admin users
- billing owner and billing account name
- recovery email / backup admin path
- project/app identifiers
- OAuth client IDs, API keys, webhook endpoints, and bundle/package bindings

Local references:

```bash
sed -n '1,120p' lib/firebase_options.dart
sed -n '1,120p' .env.example
sed -n '100,220p' docs/LAUNCH_CHECKLIST.md
```

Do not rotate or delete anything until the current production identifiers are
captured.

### 2) Migrate Google Cloud / Firebase / Google Play By Adding Access First

Prefer adding the Workspace user to the existing production project before
creating replacement projects.

In Google Cloud Console for the production project:
1. Confirm the project ID matches `prosepal-1a24b`.
2. Prefer granting organization-level access first if the project is governed
   by a Google Cloud organization policy.
3. If project-level `Owner` assignment is blocked by org policy, grant the
   Workspace admin user:
   - organization role: `Organization Administrator`
   - project roles: `Firebase Admin`, `Project IAM Admin`,
     `Service Usage Admin`, `OAuth Config Editor (beta)`
4. Confirm the project sits under the intended organization; if it is under
   `No organization`, move it into the business-controlled org before treating
   the migration as complete.
5. Attach or confirm the intended billing account.
6. In Firebase, confirm the iOS and Android apps still match:
   - `com.prosepal.prosepal`
   - `1:530026851718:ios:0dab14080ea6f8be6bd007`
   - `1:530026851718:android:71029bf2c74548436bd007`
7. In `APIs & Services > Credentials`, record the Google OAuth web and iOS
   client IDs currently used by the app.
8. In Google Auth Platform, verify the OAuth branding contact fields use the
   business mailbox rather than a personal Gmail account.

Do not create a new Firebase project unless you explicitly intend to reissue
all Firebase app config, App Check bindings, OAuth config, Remote Config, and
Crashlytics history.

### 2a) Check Google Play Account Type Before Assuming A Testing Exemption

Google Cloud / Firebase ownership cleanup does not change Google Play developer
account type.

Before planning around Android production access:
1. Check whether the Play Console developer account is `Personal` or
   `Organization`.
2. If it is `Personal`, do not assume a business email or Workspace admin setup
   changes the testing requirement.
3. If `Organization` conversion is desired, verify the account can satisfy the
   required organization-verification inputs before proceeding:
   - D-U-N-S number
   - developer profile phone and email
   - Google contact phone and email
   - any supporting organization document requested during verification
4. Prefer changing the existing Play account type over creating a second Play
   account unless there is a clear transfer plan.

### 3) Move Domain/DNS Custody To A Business-Controlled Cloudflare Account

The domain is the root dependency for mail, app-site links, support addresses,
and public web verification records.

Preferred sequence:
1. Create or designate the business-controlled Cloudflare account.
2. Add the business identity with the highest required admin role.
3. Move the zone to the business-controlled account if Cloudflare account
   ownership is still personal.
4. Re-verify:
   - MX records for Google Workspace
   - SPF, DKIM, DMARC
   - any app-link / verification TXT or CNAME records
   - site records for `prosepal.app` and `www.prosepal.app`

### 4) Transfer Supabase Ownership Without Replacing The Project

Preferred approach:
1. Invite the business identity into the existing Supabase organization/project.
2. Promote it to admin/owner.
3. Move billing custody if applicable.
4. Verify the existing project ref and URLs remain unchanged.
5. Verify social auth provider credentials, callback URLs, and Edge Functions.

The app should keep using the same `SUPABASE_URL` and project unless a full
backend migration is intentionally planned.

### 5) Transfer RevenueCat Ownership And Billing

Preferred approach:
1. Invite the business identity to the existing RevenueCat project.
2. Promote it to the highest required admin/owner role.
3. Move billing and webhook-operating custody.
4. Verify products, entitlements, offering mappings, and app-store bindings are
   unchanged.

Do not create a new RevenueCat project for this migration unless you are also
planning a product/catalog rebuild.

### 6) Normalize Public And Admin Mailboxes

Recommended mailbox model:
- admin login: `jarryd@prosepal.app`
- public support alias: `support@prosepal.app`
- billing/admin aliases or groups: `billing@prosepal.app`, `admin@prosepal.app`

Use role-based aliases/groups for public-facing contacts so a later sale or
handover does not depend on a named personal mailbox.

### 7) Rotate Secrets And Recovery Paths After Ownership Moves

After each provider transfer, review and rotate as needed:
- API keys
- OAuth client secrets
- webhook secrets
- service-account keys
- recovery emails
- 2FA devices / passkeys

Update local and CI/runtime configuration only after replacement values are
confirmed valid.

### 8) Re-Verify Runtime Wiring

Run the baseline validation set after any config or credential change:

```bash
flutter analyze
flutter test
./scripts/test_critical_smoke.sh
./scripts/release_preflight.sh all
```

Then verify on physical devices:
1. Apple sign-in works.
2. Google sign-in works.
3. RevenueCat offerings load.
4. Existing subscription state resolves correctly.
5. Crashlytics/Analytics events continue to flow.
6. Firebase Remote Config fetch succeeds.

## Pass Criteria

Migration is complete only when all are true:

1. Business identity is the primary owner/admin for Google, Cloudflare,
   Supabase, and RevenueCat.
2. Personal identity is no longer the only owner on any production service.
3. Billing custody and recovery paths no longer depend on the personal inbox as
   the sole admin route.
4. Runtime identifiers still match the production app configuration, or any
   intentional replacements are applied and verified.
5. Analyzer/tests/smoke/preflight commands pass after any key changes.
6. Manual provider-console checks confirm auth, purchases, crash reporting, and
   Remote Config still function in production.

## Failure Handling And Escalation

If any service transfer fails:

1. Stop before rotating or deleting the old owner.
2. Capture evidence:
   - console screenshots
   - project/app IDs
   - failing step text
   - current owner/admin list
3. Keep the personal identity as backup admin until the replacement path is
   verified.
4. If runtime behavior changes, re-run:

```bash
flutter analyze
flutter test
./scripts/test_critical_smoke.sh
```

5. If a provider requires a new project rather than owner transfer, treat that
   as a full migration with explicit app-config regeneration, credential
   rotation, and post-cutover verification before removing the old project.

## References

- `docs/SERVICE_CONFIG.md`
- `docs/LAUNCH_CHECKLIST.md`
- `docs/DEVOPS.md`
- `docs/IDENTITY_MAPPING.md`
- `lib/firebase_options.dart`
- `lib/core/config/app_config.dart`
