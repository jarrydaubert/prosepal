# Launch Checklist

> Last verified: 2026-01-10

---

## Phase 1: Pre-Submission (Backend & Code)

### Supabase ✅ VERIFIED 2026-01-10

**Dashboard:** https://supabase.com/dashboard/project/mwoxtqxzunsjmbdqezif

| Item | Location | Status | Details |
|------|----------|--------|---------|
| Security Advisor | Database > Tools > Security Advisor | ✅ | 0 errors, 0 warnings |
| Email provider | Authentication > Sign In / Providers > Email | ✅ | Enabled, 8 char min, lowercase+uppercase+digits+symbols required |
| Apple provider | Authentication > Sign In / Providers > Apple | ✅ | Client IDs: `com.prosepal.prosepal,com.prosepal.auth`, Secret key set |
| Google provider | Authentication > Sign In / Providers > Google | ✅ | Client ID: `530092651798-n8u4cl643qkj8dhhkl496gd5elbmlk.apps.googleusercontent.com` |
| Site URL | Authentication > URL Configuration | ✅ | `https://www.prosepal.app/` |
| Redirect URLs | Authentication > URL Configuration | ✅ | `https://prosepal.app/auth/login-callback`, `https://prosepal.app/auth/reset-callback` |
| Edge Function: delete-user | Edge Functions | ✅ | `https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/delete-user` (6 deployments) |
| Edge Function: exchange-apple-token | Edge Functions | ✅ | `https://mwoxtqxzunsjmbdqezif.supabase.co/functions/v1/exchange-apple-token` (3 deployments) |
| Leaked password protection | Authentication > Sign In / Providers > Email | ⚠️ | OFF - Requires Pro plan, not blocking |

### RevenueCat ✅ VERIFIED 2026-01-10

**Dashboard:** https://app.revenuecat.com/projects/a8bf92d5/apps

| Item | Location | Status | Details |
|------|----------|--------|---------|
| iOS app | Apps & Projects | ✅ | Prosepal (App Store) configured |
| Android app | Apps & Projects | ✅ | Prosepal (Play Store) configured |
| iOS Products | Product catalog > Products | ⚠️ | `com.prosepal.pro.weekly`, `.monthly`, `.yearly` - "Ready to Submit" in App Store Connect |
| Android Products | Product catalog > Products | ✅ | `com.prosepal.pro.weekly:weekly`, `.monthly:monthly`, `.yearly:yearly` - Published |
| Entitlement | Product catalog > Entitlements | ✅ | `pro` entitlement with 2 products |
| Offering | Product catalog > Offerings | ✅ | `default` offering with 3 packages |
| SDK API Keys | API Keys | ✅ | Keys for App Store + Play Store |
| Test Store | Apps & Projects | ✅ | Sandbox testing configured |

### Firebase ✅ VERIFIED 2026-01-10

**Console:** https://console.firebase.google.com/project/prosepal-cda84

| Item | Location | Status | Details |
|------|----------|--------|---------|
| App Check | Build > App Check | ✅ | Firebase AI Logic in Monitoring mode (enforce after launch) |
| Remote Config: `ai_model` | Run > Remote Config | ✅ | `gemini-2.5-flash` |
| Remote Config: `ai_model_fallback` | Run > Remote Config | ✅ | `gemini-2.5-flash-lite` |
| Remote Config: `min_app_version_ios` | Run > Remote Config | ✅ | `1.0.0` |
| Remote Config: `min_app_version_android` | Run > Remote Config | ✅ | `1.0.0` |
| Crashlytics | Run > Crashlytics | ✅ | Enabled, 100% crash-free |
| Analytics | Analytics Dashboard | ✅ | Enabled, collecting data |

### Code ✅ VERIFIED 2026-01-10

| Item | Status | Notes |
|------|--------|-------|
| App Attest environment | ✅ | Changed to `production` |
| 628 tests passing | ✅ | All pass |
| 0 warnings in lib/ | ✅ | Only info-level items |
| Pre-commit hook | ✅ | Auto format + analyze |

---

## Phase 2: Store Submission

### Pre-Build ⏳ PENDING

- [ ] Increment version/build in `pubspec.yaml`
- [ ] Final `flutter test` pass
- [ ] Final `flutter analyze lib/` pass

### iOS Build & Upload ⏳ PENDING

```bash
./scripts/build_ios.sh
```

- [ ] iOS Archive built successfully
- [ ] dSYM files saved from `build/debug-info/`
- [ ] Upload to App Store Connect via Xcode or Transporter
- [ ] Upload dSYMs to Firebase Crashlytics

### Android Build & Upload ⏳ PENDING

```bash
./scripts/build_android.sh
```

- [ ] Android AAB built successfully
- [ ] Upload to Google Play Console > Internal Testing

### App Store Connect ⏳ PARTIALLY VERIFIED 2026-01-10

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
| Screenshots | Version 1.0 | ⚠️ | 5 screenshots uploaded - **UPDATE: Paywall changed to bottom sheet** |
| Build | Version 1.0 | ❌ | Not uploaded - run `./scripts/build_ios.sh` |
| IAPs linked to version | Version 1.0 | ✅ | All 3 subscriptions linked |
| Submit for Review | Version 1.0 | ⏳ | After above items complete |

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
| IAP Review Screenshots | ⚠️ | **UPDATE: Paywall changed to bottom sheet with inline auth** |
| Localization description | ✅ | Says "500 messages per month" - correct (Pro limit is 500/month) |
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

### Manual Testing (Before Submission) ⏳ PENDING

- [ ] TestFlight: Fresh install → Onboard → Generate → Purchase → Restore
- [ ] TestFlight: Sign out clears everything
- [ ] TestFlight: Delete account works
- [ ] Play Store Internal: Same flows as above

---

## Phase 3: Post-Approval

### After App Store Approval

- [x] Apple ID `6757088726` added to `review_service.dart` and `settings_screen.dart`
- [ ] Verify in-app review prompt works in production
- [ ] **Add App Store badge to landing page** (prosepal-web)
  - Use official Apple badge: https://developer.apple.com/app-store/marketing/guidelines/
  - Link to: `https://apps.apple.com/app/prosepal/id6757088726`
  - Add "Android Coming Soon" placeholder badge

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

| Issue | Severity |
|-------|----------|
| 3 failed biometrics shows generic error | Medium |
| Supabase session persists after reinstall | Low |

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
