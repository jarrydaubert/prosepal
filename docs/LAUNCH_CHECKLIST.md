# Launch Checklist

## Pre-Launch

### App Store Connect
- Submit IAP products for review
- App privacy nutrition labels
- Screenshots and store listing
- Privacy policy URL (prosepal.app/privacy)
- Add App Store ID to code after approval

### Google Play Console
- Upload AAB to Internal Testing
- Store listing (screenshots, description)
- Privacy policy URL
- Submit for review

### RevenueCat
- Verify production API keys
- Webhook (optional)

### Supabase
- RLS policies production-ready
- `delete-user` Edge Function deployed
- Database Linter: 0 errors (check Dashboard > Database > Linter)
- Performance Advisor: Review slow queries (check Dashboard > Database > Performance)
- Auth > Enable "Leaked password protection"

### Code
- iOS Archive built
- Version/build incremented

### Testing
- TestFlight internal testing
- Play Store internal testing
- Manual test: Sign in → Purchase → Restore
- Manual test: Sign out clears everything
- Manual test: Delete account flow

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
