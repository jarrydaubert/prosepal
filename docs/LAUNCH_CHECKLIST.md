# Launch Checklist

## Pre-Launch

### App Store Connect
- [ ] Submit IAP products for review
- [ ] App privacy nutrition labels complete
- [ ] Screenshots finalized
- [ ] Privacy policy URL set (prosepal.app/privacy)

### RevenueCat
- [ ] Production API keys (not sandbox)
- [ ] Webhook configured (optional)

### Supabase
- [ ] RLS policies production-ready
- [ ] Using production project (not dev)

### Code
- [ ] Paywall bold styling applied
- [ ] Version/build number incremented
- [ ] Release build tested (Xcode Archive)

### Testing
- [ ] TestFlight internal testing complete
- [ ] All manual tests passed (see TESTING.md)

---

## Launch Day

1. Monitor Crashlytics for crash spikes
2. Monitor RevenueCat for purchases
3. Check App Store Connect for reviews

---

## Post-Launch Monitoring

### Daily (5 mins)
| Dashboard | Check |
|-----------|-------|
| RevenueCat | Revenue, new subs, churn |
| Crashlytics | Crash-free rate, new issues |
| App Store Connect | Downloads, ratings, reviews |

### Weekly
| Dashboard | Metrics |
|-----------|---------|
| RevenueCat | MRR, trial conversions |
| Firebase Analytics | DAU/MAU, session duration |

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
- Gemini 2.5 Flash: ~$0.0004 per generation
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
| Gemini rate limited (429) | Check quotas, enable billing, request increase |
| Supabase paused | Restore in dashboard, consider Pro ($25/mo) |
| RevenueCat issues | Check webhook failures, verify production keys |
