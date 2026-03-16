# Launch Checklist

> Last verified: 2026-02-11

---

## ⚠️ CRITICAL: iOS Release Build Process

**DO NOT** build via Xcode directly or use plain `flutter build ios`. API keys will be missing and the app will grey screen!

### Correct Build Steps:

```bash
# 1. Ensure .env.local exists with all keys
cat .env.local  # Should have SUPABASE_URL, SUPABASE_ANON_KEY, REVENUECAT_IOS_KEY, etc.

# 2. Validate release config preflight (fails on missing/placeholders)
./scripts/release_preflight.sh ios

# 3. Run the build script (passes dart-defines)
./scripts/build_ios.sh

# 4. THEN open Xcode to archive
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

### Why This Matters:
- `dart-define` values (API keys) are baked in at **compile time**
- Running `flutter build ios` without the script = empty config
- Empty config = Supabase skipped = splash screen waits forever = **grey screen**

### Debug vs Release:
| Build Type | Command | Keys Passed? |
|------------|---------|--------------|
| Debug | `./scripts/run_ios.sh` | ✅ Yes |
| Release | `./scripts/build_ios.sh` | ✅ Yes |
| Release | `flutter build ios` | ❌ NO! |
| Release | Xcode Archive directly | ❌ NO! |

**Learned the hard way:** v1.1.0 shipped without keys → grey screen → pulled from App Store.

---

## Current Status

| Platform | Status | Details |
|----------|--------|---------|
| iOS | **LIVE** | v1.1.2 - https://apps.apple.com/app/id6757088726 |
| Android | Blocked | Requires 14-day closed testing with 12+ testers |

---

## iOS Rejection - 2026-01-14 (RESOLVED)

**Submission ID:** `fd10a068-12ca-4dd3-954e-f2b8efd31d5c`
**Review Device:** iPad Air 11-inch (M3)

### Issue 1: Guideline 5.1.1 - Requiring Sign-In Before Purchase ✅ FIXED

**Problem:** App required users to register/sign-in before purchasing subscriptions.

**Fix (Build 29):**
- Restructured paywall so purchase works WITHOUT sign-in
- Auth moved to optional "Sync across devices" section below purchase CTA
- Anonymous users can purchase via RevenueCat `$RCAnonymousID`
- Sign-in only needed to sync subscription across devices

### Issue 2: Guideline 3.1.2 - Missing Terms of Use ✅ FIXED

**Problem:** No Terms of Use (EULA) link in App Store metadata.

**Fix:**
- Added to App Store description: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
- Added Privacy Policy link: `https://www.prosepal.app/privacy.html`

### Issue 3: Guideline 2.3.2 - Paid Features Not Labeled ✅ FIXED

**Problem:** Description referenced paid features without clarifying purchase required.

**Fix:**
- Updated description: "Try your first message FREE! Then unlock unlimited generations with Prosepal Pro"
- Clear distinction between free tier (1 message) and Pro (500/month)

### Resubmission Checklist

| Item | Type | Status |
|------|------|--------|
| Allow anonymous purchases in paywall | Code | ✅ |
| Make sign-in optional (sync benefit only) | Code | ✅ |
| Add Terms of Use link to App Description | Metadata | ✅ |
| Update description with clear free/paid distinction | Metadata | ✅ |
| Fix subscription descriptions (500/month) | Metadata | ✅ |
| Increment build number (29) | Build | ✅ |
| Upload dSYMs to Firebase | Build | ✅ |
| Reply to Apple with fix summary | Submission | ✅ |
| Resubmit for review | Submission | ✅ 2026-01-15 |

---

## Phase 1: Pre-Submission (Backend & Code)

### Supabase ✅ VERIFIED 2026-03-15

**Dashboard:** https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif

**Verification surfaces**
- Provider tooling:
  - Supabase project URL
  - Edge Function deployment status and versions
  - Advisor warnings
- Dashboard-only:
  - Auth providers
  - Auth URL configuration
  - Auth email templates and notification toggles

| Item | Location | Status | Details |
|------|----------|--------|---------|
| Project URL | Project tools / dashboard | ✅ | `https://mwoxtqxzunsjmbdqezif.supabase.co` |
| Security Advisor | Project tools / dashboard | ⚠️ | Warning: leaked password protection is disabled; low-signal while auth remains Apple/Google only |
| Performance Advisor | Project tools / dashboard | ⚠️ | Warning: `public.device_usage` RLS policy re-evaluates auth/current_setting per row |
| Edge Function: delete-user | Edge Functions | ✅ | Active, version `8`, platform JWT verification disabled by config |
| Edge Function: exchange-apple-token | Edge Functions | ✅ | Active, version `6`, platform JWT verification disabled by config |
| Edge Function: revenuecat-webhook | Edge Functions | ✅ | Active, version `7`, platform JWT verification disabled by config |
| Apple provider | Authentication > Providers | ✅ | Enabled; OAuth callback uses Supabase `/auth/v1/callback` |
| Apple OAuth secret | Authentication > Providers | ⚠️ | Secret key rotation required every 6 months |
| Google provider | Authentication > Providers | ✅ | Enabled; `Skip nonce checks` is on for native iOS Google Sign-In compatibility |
| Site URL | Authentication > URL Configuration | ✅ | `https://www.prosepal.app/` |
| Redirect URLs | Authentication > URL Configuration | ✅ | `https://prosepal.app/auth/login-callback`, `https://prosepal.app/auth/reset-callback` |
| Auth email templates | Authentication > Email | ⚠️ | Authentication templates still exist, but social-only sign-in means confirm-signup / magic-link / reset-password flows are expected to stay dormant unless email auth is re-enabled |
| Security notification emails | Authentication > Email | ✅ | Account-change and identity/MFA notification toggles are enabled at project level |
| Custom SMTP | Authentication > Email > SMTP Settings | ✅ | Custom SMTP enabled via Resend |
| Supabase sender address | Authentication > Email > SMTP Settings | ✅ | `jarryd@prosepal.app` |
| Supabase sender name | Authentication > Email > SMTP Settings | ✅ | `Prosepal` |

#### Supabase Auth Email Notes

- Current sign-in UX is Apple + Google only.
- Security notifications are still useful because account email, linked identities, and MFA state can change at the Supabase account layer.
- Keep auth email copy functional and support-oriented; do not rely on stale onboarding or pricing/promotional claims in templates.
- Hosted-template verification and edits are currently dashboard-driven; high-level state is documented here, not full HTML bodies.
- If email/password auth is ever re-enabled, re-verify:
  - confirmation email copy
  - reset-password flow copy
  - magic-link / OTP template behavior

### Resend ✅ VERIFIED 2026-03-15

**Verification surfaces**
- Dashboard-only:
  - domain verification and delivery settings
  - team membership
  - billing email
  - SMTP settings and integrations

| Item | Location | Status | Details |
|------|----------|--------|---------|
| Sending domain | Domains | ✅ | `prosepal.app` verified |
| Domain provider | Domains | ✅ | Cloudflare |
| Region | Domains | ✅ | Ireland (`eu-west-1`) |
| DKIM | Domains > Records | ✅ | Verified |
| SPF / sending records | Domains > Records | ✅ | Sending enabled and verified |
| DMARC record | Domains > Records | ✅ | Present |
| Custom SMTP compatibility | Settings > SMTP | ✅ | `smtp.resend.com`, port `465`, username `resend` |
| Supabase integration | Settings > Integrations | ✅ | Connected for Auth SMTP usage |
| Click tracking | Domains > Configuration | ✅ | Disabled |
| Open tracking | Domains > Configuration | ✅ | Disabled |
| TLS mode | Domains > Configuration | ✅ | `Enforced` |
| Sender mailbox in use | Supabase SMTP settings | ✅ | `jarryd@prosepal.app` |
| Team membership | Settings > Team | ✅ | `jarrydaubert@gmail.com` and `jarryd@prosepal.app` are both admins |
| Billing email | Settings > Billing | ⚠️ | Still `jarrydaubert@gmail.com` |

#### Resend Notes

- Current setup is suitable for transactional auth mail via Supabase.
- Tracking is disabled, which avoids link rewriting and deliverability noise in auth emails.
- Resend is currently used as the SMTP relay for Supabase auth/security mail.
- The in-app feedback screen does not send through Resend yet; it still launches
  the user's mail client via `mailto:` with clipboard fallback.
- Public docs should record sender/domain posture, not API key values or SMTP secrets.

### RevenueCat ✅ VERIFIED 2026-03-15

**Dashboard:** https://app.revenuecat.com/projects/a8bf92d5/apps

**Verification surfaces**
- Provider tooling / API, if project credentials are available:
  - customer/subscriber state
  - offerings / products / entitlements metadata
  - charts / metrics exports
- Dashboard-only:
  - collaborators / project access
  - billing owner / billing settings
  - some app-store linking and project-level configuration
- No dedicated RevenueCat CLI or MCP path is currently configured in this repo/session.

| Item | Location | Status | Details |
|------|----------|--------|---------|
| iOS app | Apps & providers | ✅ | `Prosepal (App Store)` / RevenueCat App ID `appdc3ae33901` |
| Android app | Apps & providers | ✅ | `Prosepal (Play Store)` / RevenueCat App ID `app4a84d9d5ff` |
| Web app config | Apps & providers | ✅ | No web configuration / no public web API keys configured |
| iOS Products | Product catalog > Products | ⚠️ | `com.prosepal.pro.weekly`, `.monthly`, `.yearly` - "Ready to Submit" in App Store Connect |
| Android Products | Product catalog > Products | ✅ | `com.prosepal.pro.weekly:weekly`, `.monthly:monthly`, `.yearly:yearly` - Published |
| Entitlement | Product catalog > Entitlements | ✅ | `pro` entitlement with 2 products |
| Offering | Product catalog > Offerings | ✅ | `default` offering with 3 packages |
| Secret API keys | API Keys | ✅ | No secret API keys configured |
| SDK API keys | API Keys | ✅ | Public SDK keys exist for `Test Store`, `Prosepal (App Store)`, and `Prosepal (Play Store)` |
| Test Store | Apps & providers | ✅ | Sandbox testing configured with project test API key |
| Webhooks | Integrations > Webhooks | ✅ | `Supabase Entitlements Sync` active against the Supabase `revenuecat-webhook` function |
| Webhook environments | Integrations > Webhooks | ✅ | Sends both Production and Sandbox events |
| Webhook scope | Integrations > Webhooks | ✅ | `All apps` / `All events` |
| Webhook delivery | Integrations > Webhooks | ✅ | Recent deliveries show `Sent` status |
| Scheduled data exports | Integrations | ✅ | Not configured |
| Sandbox entitlement access | Project settings > General | ✅ | `Anybody` |
| App User ID transfer behavior | Project settings > General | ✅ | `Transfer to new App User ID` |
| RevenueCat-hosted web domain | Project settings > Domains | ✅ | RevenueCat default domain in use; no custom domain configured |
| Workspace admin access | Project settings > Collaborators | ✅ | `jarryd@prosepal.app` accepted as `Administrator` |
| Personal owner access | Project settings > Collaborators | ✅ | `jarrydaubert@gmail.com` remains `Owner` |

#### RevenueCat Notes

- App runtime uses the RevenueCat mobile SDK directly; backend sync flows through the deployed `revenuecat-webhook` Supabase function.
- Provider API access can help validate customer state and catalog configuration, but billing posture still requires dashboard verification.
- Current project is native-store only. RevenueCat-hosted domains are only relevant if the app adopts RevenueCat web billing / hosted web funnels later.

### Firebase ✅ VERIFIED 2026-03-15

**Console:** https://console.firebase.google.com/project/prosepal-1a24b

| Item | Location | Status | Details |
|------|----------|--------|---------|
| Live Firebase project | Project settings > General | ✅ | `Prosepal` / `prosepal-1a24b` |
| Google Cloud parent org | Project settings > General | ✅ | `jarrydaubert-org` |
| Public-facing name | Project settings > General | ✅ | `Prosepal` |
| Support email | Project settings > General | ✅ | `jarryd@prosepal.app` |
| Android app registration | Project settings > General | ✅ | `prosepal (android)` / `com.prosepal.prosepal` |
| iOS app registration | Project settings > General | ✅ | `prosepal (ios)` / `com.prosepal.prosepal` |
| App Check for Firebase AI Logic | App Check > APIs | ✅ | Enforced with 100% verified / 0% unverified requests |
| Firebase Cloud Messaging API (V1) | Project settings > Cloud Messaging | ✅ | Enabled |
| Cloud Messaging API (Legacy) | Project settings > Cloud Messaging | ✅ | Disabled |
| Analytics integration | Project settings > Integration | ✅ | Google Analytics enabled |
| Google Play integration | Project settings > Integration | ⚠️ | No matching Play app currently linked |
| Firebase service-data sharing | Project settings > Data privacy | ✅ | Non-Firebase Google service-data option enabled |
| Workspace admin access | Project settings > Users and permissions | ✅ | `jarryd@prosepal.app` has Firebase admin access |
| Personal backup access | Project settings > Users and permissions | ✅ | `jarrydaubert@gmail.com` remains owner/backstop access |
| Project alerts | Project settings > Alerts | ✅ | Project-level alerts enabled |
| App Distribution alerts | Project settings > Alerts | ✅ | New tester device + tester feedback alerts enabled |
| Authentication alerts | Project settings > Alerts | ✅ | Phone Auth plan-limit alert enabled |
| Firestore alerts | Project settings > Alerts | ✅ | Insecure rules + expiring rules alerts enabled |
| Crashlytics alerts | Project settings > Alerts | ✅ | Trending, regressions, and missing dSYM email alerts configured |
| Live Remote Config template | `firebase remoteconfig:get -P prosepal-1a24b` | ✅ | All expected production keys are now published in version `3` |

**Public repo note:** Do not record raw certificate fingerprints, service-account
details, recovery codes, or other secret-adjacent console values here. Keep
those in private operations notes only.

**Remote Config note:** The live template now includes the expected production
keys used by [remote_config_service.dart](/Users/jarrydaubert/Desktop/prosepal/lib/core/services/remote_config_service.dart),
including AI model selection, kill switches, App Check token behavior, schema
version, and minimum app versions.

### Code ✅ VERIFIED 2026-01-10

| Item | Status | Notes |
|------|--------|-------|
| App Attest environment | ✅ | Changed to `production` |
| 626 tests passing | ✅ | All pass |
| 0 warnings in lib/ | ✅ | Only info-level items |
| Pre-commit hook | ✅ | Auto format + analyze |

---

## Phase 2: Store Submission

### iOS ✅ LIVE (Build 31)

**Build History:**
- Build 27: ❌ Rejected 2026-01-14 (missing 5.1.1/3.1.2/2.3.2 fixes)
- Build 29: ✅ Submitted 2026-01-15 (all fixes applied)
- Build 31: ✅ Live on App Store 2026-01-16

**Build 29 Includes:**
- 5.1.1 fix: Paywall restructure (purchase without sign-in)
- Server-side Pro verification (RevenueCat webhook)
- iPad paywall optimization
- Auth/paywall UX improvements

**Metadata Updates:**
- Terms of Use link added to description
- Privacy Policy link added to description  
- "Try your first message FREE!" clarification
- Subscription descriptions updated (500/month)
- New paywall screenshots uploaded

**dSYMs:** ✅ Uploaded to Firebase Crashlytics

### Android ⏳ BLOCKED

Requires 14-day closed testing with 12+ opted-in testers before production access.

### App Store Connect ✅ VERIFIED 2026-01-15

**Console:** https://appstoreconnect.apple.com

| Item | Location | Status | Details |
|------|----------|--------|---------|
| Bundle ID | App Information | ✅ | `com.prosepal.prosepal` |
| App name & subtitle | App Information | ✅ | Prosepal / The right words, right now |
| Category | App Information | ✅ | Lifestyle / Utilities |
| Age Rating | App Information | ✅ | 4+ |
| Privacy policy URL | App Privacy | ✅ | `https://www.prosepal.app/privacy.html` |
| Privacy nutrition labels | App Privacy | ✅ | 5 data types declared, published 13 days ago |
| Support URL | Version 1.0 | ✅ | `https://www.prosepal.app/support.html` |
| Marketing URL | Version 1.0 | ✅ | `https://www.prosepal.app` |
| App description | Version 1.0 | ✅ | Complete with subscription disclosure |
| Keywords | Version 1.0 | ✅ | greeting card, message, AI writer, etc. |
| Test account | App Review | ✅ | appreview@prosepal.app |
| Review notes | App Review | ✅ | Step-by-step testing instructions |
| RevenueCat webhooks | App Information | ✅ | Production + Sandbox URLs configured |
| Copyright | Version 1.0 | ✅ | 2026 |
| Screenshots | Version 1.0 | ✅ | 5 screenshots uploaded |
| Build | Version 1.0 | ✅ | Build 29 selected |
| IAPs linked to version | Version 1.0 | ✅ | All 3 subscriptions linked |
| Submit for Review | Version 1.0 | ✅ | Submitted 2026-01-15 |

**Subscriptions (Monetization > Subscriptions):**

| Item | Status | Details |
|------|--------|---------|
| Subscription Group "Pro" | ✅ | ID: 21870306, 3 subscriptions |
| Billing Grace Period | ✅ | 3 days, All Renewals |
| Streamlined Purchasing | ✅ | Turned On |
| Pro Weekly (`com.prosepal.pro.weekly`) | ✅ | 1 week, matches RevenueCat |
| Pro Monthly (`com.prosepal.pro.monthly`) | ✅ | 1 month, matches RevenueCat |
| Pro Yearly (`com.prosepal.pro.yearly`) | ✅ | 1 year, matches RevenueCat |
| Availability | ✅ | All countries |
| IAP Review Screenshots | ✅ | Updated with new paywall (logged out view) |
| Localization description | ✅ | Updated to "500 messages per month" |
| Subscription Group Display Name | ✅ | Changed to "Pro" (was "Pro Weekly") |
| Family Sharing | ➖ | OFF - enable post-revenue |

### Google Play Console ⏳ IN PROGRESS

**Console:** https://play.google.com/console

**Setup Progress:** 10 of 14 complete

**Store Listing:**

| Item | Status | Details |
|------|--------|---------|
| App name | ✅ | "Prosepal - Card Message Writer" (30/30 chars) |
| Short description | ✅ | "AI greeting card messages. Birthday, wedding, sympathy & more" (61/80) |
| Full description | ✅ | Complete with features, "500 generations per month" |
| App icon | ✅ | 512x512 uploaded |
| Feature graphic | ✅ | 1024x500 uploaded |
| Phone screenshots | ✅ | 5 screenshots uploaded |
| 7-inch tablet screenshots | ✅ | 5 screenshots uploaded |
| 10-inch tablet screenshots | ✅ | 5 screenshots uploaded |

**App Content (Policy > App content):**

| Item | Status |
|------|--------|
| Privacy policy | ✅ |
| App access | ✅ |
| Ads declaration | ✅ |
| Content rating | ✅ |
| Target audience | ✅ |
| Data safety | ✅ |
| Government apps | ✅ |
| Financial features | ✅ |
| Health | ✅ |

**Data Safety Details (verified matches app):**

| Category | Declared | Source |
|----------|----------|--------|
| Name, Email, User IDs | ✅ | Supabase auth |
| Purchase history | ✅ | RevenueCat |
| App interactions | ✅ | Firebase Analytics |
| Crash logs, Diagnostics | ✅ | Firebase Crashlytics |
| Device IDs | ✅ | Fingerprinting (fraud prevention) |
| Location | ❌ None | Correct - not collected |
| Data encrypted in transit | ✅ | HTTPS everywhere |
| Delete account URL | ✅ | `https://www.prosepal.app/support.html` |

**Testing & Release:**

| Item | Status | Details |
|------|--------|---------|
| Internal testing | ✅ | Active |
| Closed testing | ❌ | Not started |
| Production access | ⏳ | Blocked until closed test complete |

**⚠️ IMPORTANT: Production Access Requirements**

Google requires closed testing before production release:
1. Publish a closed testing release
2. Have **12+ testers opted-in** (currently 0)
3. Run closed test for **14+ days**

**Subscriptions (Monetize > Subscriptions):**

| Product | ID | Status | Details |
|---------|-----|--------|---------|
| Pro Weekly | `com.prosepal.pro.weekly` | ✅ Active | 174 countries, USD $2.99 |
| Pro Monthly | `com.prosepal.pro.monthly` | ✅ Active | 174 countries |
| Pro Yearly | `com.prosepal.pro.yearly` | ✅ Active | 174 countries |

- Grace period: 3 days ✅
- Account hold: 57 days (auto) ✅
- Resubscribe: Allow ✅
- Product IDs match RevenueCat ✅

### Manual Testing ✅ DONE

Tested via TestFlight before submission:
- Fresh install → Onboard → Generate → Purchase → Restore
- Sign out clears everything
- Delete account works

---

## Phase 3: Post-Approval

### iOS - LIVE 2026-01-16

**App Store**: https://apps.apple.com/app/id6757088726
**Landing Page**: https://www.prosepal.app

- [x] Apple ID `6757088726` added to `review_service.dart` and `settings_screen.dart`
- [ ] Verify in-app review prompt works in production
- [x] **Deploy landing page with App Store badge** (prosepal-web) - Deployed 2026-01-16

### After Play Store Approval

- [ ] Verify production app works
- [ ] Check RevenueCat shows real purchases

### Firebase App Check (Optional)

- [ ] Switch from "Monitoring" to "Enforced" after 1 week of clean data
- [ ] Location: Firebase Console > App Check > Firebase AI Logic > Enforce

---

## Phase 4: Launch Day

### Monitoring

1. **Crashlytics** - Watch for crash spikes (target: >99% crash-free)
2. **RevenueCat** - Verify purchases flowing through
3. **Supabase** - Check for auth errors in logs
4. **Store Reviews** - Respond to early reviews quickly

### If Issues Arise

| Issue | Action |
|-------|--------|
| Crash spike | Check Crashlytics, hotfix if critical |
| Purchases failing | Check RevenueCat webhook logs |
| Auth errors | Check Supabase logs, verify providers |
| AI not working | Check Firebase AI quotas, verify API key |

---

## Phase 5: Post-Launch (Ongoing)

### Daily Checks (First Week)

- RevenueCat: Revenue, new subs, churn
- Crashlytics: Crash-free rate, new issues
- Store: Downloads, ratings, reviews

### Health Thresholds

| Metric | Healthy | Warning | Action |
|--------|---------|---------|--------|
| Crash-free rate | >99% | <98% | Hotfix |
| Trial → Paid | >5% | <2% | Review paywall |
| Day 1 retention | >40% | <20% | Review onboarding |
| Reviews | 4.5+ | <4.0 | Address feedback |

### Weekly

- Review user feedback
- Check for pending Apple/Google policy updates
- Monitor API costs

---

## Reference

### Manual Test Flows

| Flow | Steps |
|------|-------|
| Fresh Install | Launch → Onboard → Home → Generate (1 free) → Results |
| Anon Upgrade | Upgrade → Auth → Sign In → Paywall → Purchase → Home |
| Logged Upgrade | Upgrade → Paywall → Purchase → Home |
| Sign Out | Settings → Confirm → Clears all → Home (anon) |
| Delete Account | Settings → Delete → Confirm → Type DELETE → Clears all → Onboarding |

### Sandbox Renewal Rates

| Duration | Sandbox Time |
|----------|--------------|
| 1 week | 3 min |
| 1 month | 5 min |
| 1 year | 1 hour |

Max 12 renewals per day in sandbox.

### Known Limitations

| Issue | Severity | Notes |
|-------|----------|-------|
| Device fingerprint continuity can still break if secure storage is cleared | Medium | iOS now persists the app fingerprint in Keychain; legacy installs tied to old `identifierForVendor` records may still need cleanup/migration evidence |
| 3 failed biometrics shows generic error | Medium | |
| Supabase session persists after reinstall | Low | |
| USD shown in sandbox | Low | TestFlight shows USD, production shows localized currency |

### Cost (Per User)

| Plan | Price | Apple/Google Cut | Net |
|------|-------|------------------|-----|
| Weekly | $2.99/wk | $0.90 | $2.09 |
| Monthly | $4.99/mo | $1.50 | $3.49 |
| Yearly | $29.99/yr | $9.00 | $20.99 |

### API Cost

- Gemini: ~$0.0004 per generation
- 10K generations = $4

### Free Tier Limits

| Service | Limit |
|---------|-------|
| Firebase AI | ~1,500 RPD |
| Supabase | 50K MAU, 500MB |
| RevenueCat | $2,500 MTR |

---

## Emergency Playbook

| Issue | Immediate Action |
|-------|------------------|
| Gemini 429 (rate limited) | Firebase Console > Quotas > Increase or enable billing |
| Supabase paused | Dashboard > Restore project |
| RevenueCat purchases failing | Check webhook logs, verify API keys |
| Auth completely broken | Check Supabase status page, verify provider config |
| Force update needed | Update `min_app_version_*` in Remote Config, publish |
