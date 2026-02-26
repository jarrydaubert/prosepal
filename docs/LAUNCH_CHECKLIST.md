# Launch Checklist

> Last verified: 2026-01-10

## Pre-Launch

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

### RevenueCat ⏳ PENDING

- [ ] iOS app configured
- [ ] Android app configured
- [ ] Products set up (Weekly, Monthly, Yearly)
- [ ] `pro` entitlement exists
- [ ] Production API keys verified

### Firebase ⏳ PENDING

- [ ] App Check enabled (iOS + Android)
- [ ] Remote Config parameters set
- [ ] Crashlytics enabled
- [ ] Analytics enabled

### App Store Connect ⏳ PENDING

- [ ] IAP products submitted for review
- [ ] App privacy nutrition labels filled
- [ ] Screenshots uploaded
- [ ] Privacy policy URL: `prosepal.app/privacy`
- [ ] App Store ID added to code (after approval)

### Google Play Console ⏳ PENDING

- [ ] AAB uploaded to Internal Testing
- [ ] Store listing complete
- [ ] Privacy policy URL set
- [ ] Submit for review

### Code ✅ VERIFIED 2026-01-10

| Item | Status | Notes |
|------|--------|-------|
| App Attest environment | ✅ | Changed to `production` |
| 628 tests passing | ✅ | All pass |
| 0 warnings in lib/ | ✅ | Only info-level items |
| Pre-commit hook | ✅ | Auto format + analyze |

### Code ⏳ PENDING

- [ ] Version/build number incremented
- [ ] iOS Archive built (`./scripts/build_ios.sh`)
- [ ] Android AAB built (`./scripts/build_android.sh`)

### Manual Testing ⏳ PENDING

- [ ] TestFlight: Sign in → Generate → Purchase → Restore
- [ ] Play Store Internal: Same flow
- [ ] Sign out clears everything
- [ ] Delete account works

---

## Launch Day

1. Monitor Crashlytics for crash spikes
2. Monitor RevenueCat for purchases
3. Check store reviews

---

## Post-Launch Monitoring

### Daily
- RevenueCat: Revenue, new subs, churn
- Crashlytics: Crash-free rate, new issues
- Store: Downloads, ratings, reviews

### Health Thresholds
| Metric | Healthy | Warning |
|--------|---------|---------|
| Crash-free rate | >99% | <98% |
| Trial → Paid | >5% | <2% |
| Day 1 retention | >40% | <20% |
| Reviews | 4.5+ | <4.0 |

---

## Cost Reference

### Revenue (Per User)
| Plan | Price | Apple Cut | Net |
|------|-------|-----------|-----|
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

| Issue | Action |
|-------|--------|
| Gemini rate limited (429) | Check quotas, enable billing |
| Supabase paused | Restore in dashboard |
| RevenueCat issues | Check webhook failures, verify keys |
