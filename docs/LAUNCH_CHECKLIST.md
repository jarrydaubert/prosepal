# Prosepal Launch Checklist

## Pre-Launch Requirements

### App Store Connect

- [ ] **In-App Purchases** - Submit for review
  - `com.prosepal.pro.weekly` - status: READY_TO_SUBMIT
  - `com.prosepal.pro.monthly` - status: READY_TO_SUBMIT  
  - `com.prosepal.pro.yearly` - status: READY_TO_SUBMIT
  - All products must be approved before users can purchase in production

- [ ] **App Review** - Submit app for review
  - Ensure screenshots are up to date
  - App description finalized
  - Privacy policy URL set (prosepal.app/privacy)
  - Support URL set

- [ ] **App Privacy** - Complete privacy nutrition labels
  - Data collection disclosure
  - Third-party SDK disclosures (Firebase, Supabase, RevenueCat)

### Firebase (Optional but Recommended)

- [ ] **GoogleService-Info.plist** - Add to iOS project
  - Download from Firebase Console > Project Settings > iOS app
  - Add to `ios/Runner/` directory
  - Current behavior: Firebase works but logs warnings

### RevenueCat

- [x] SDK configured correctly
- [x] Products linked to App Store Connect
- [x] Offerings configured (default offering with weekly/monthly/yearly)
- [ ] **Production API keys** - Verify using production keys (not sandbox)
- [ ] **Webhook** - Configure server-to-server notifications (optional)

### Supabase

- [x] Authentication configured (Apple, Google, Email)
- [x] Database schema set up
- [ ] **Row Level Security** - Verify RLS policies are production-ready
- [ ] **API Keys** - Ensure using production project (not dev)

### Code/Build

- [x] Bold styling refactor complete
- [x] Biometric opt-in flow implemented
- [x] Auth button consistency
- [ ] **Paywall screen** - Apply bold styling (remaining)
- [ ] **Version/Build number** - Increment for release
- [ ] **Release build** - Test Archive build in Xcode

### Testing Verification

- [x] Sandbox subscriptions working
- [x] Pro status detection working
- [x] Sign in with Apple working
- [x] Google Sign-In working
- [x] Email auth working
- [x] Face ID/Touch ID opt-in working
- [ ] **TestFlight** - Internal testing complete
- [ ] **TestFlight** - External beta testing (optional)

---

## Launch Day

### Immediate Actions

1. **Monitor Crashlytics** - Watch for any crash spikes
2. **Monitor RevenueCat** - Check dashboard for purchases
3. **Check App Store Connect** - Monitor reviews/ratings

### Known Behaviors

- Sandbox subscriptions auto-renew every hour (1 year = 1 hour in sandbox)
- This is normal Apple sandbox behavior, not a bug
- Production subscriptions will renew at actual intervals

### Fixed Issues (Jan 2026)

- **HarmBlockMethod error** - Set `HarmBlockMethod` to `null` in SafetySettings in `ai_service.dart`. This parameter is only supported by Vertex AI, not Google AI.

---

## Logging & Diagnostics

### Production Logging (Firebase Crashlytics)

All critical flows are logged via `Log` service:
- **AI Generation**: Start, success, errors with context
- **Subscriptions**: Init, purchases, restores, errors
- **Usage Tracking**: Sync operations
- **Auth**: Sign-in events

Logs are visible in Firebase Console > Crashlytics > Logs

### User Diagnostic Reports

Users can generate and share diagnostic reports from:
**Settings > Send Feedback > "View report"**

Reports include (privacy-compliant):
- App version & device info
- Auth status (no credentials)
- Subscription status (no payment details)
- Recent error log

Reports do NOT include:
- Personal messages or content
- Payment card info
- Passwords or tokens
- Location data

User must explicitly tap to generate and share (App Store/Play Store compliant).

---

## Post-Launch: Daily Monitoring

### Quick Daily Check (5 mins)

| Dashboard | URL | What to Check |
|-----------|-----|---------------|
| **RevenueCat** | app.revenuecat.com | Revenue, new subscribers, churn |
| **Firebase Crashlytics** | console.firebase.google.com | Crash-free rate, new issues |
| **App Store Connect** | appstoreconnect.apple.com | Downloads, ratings, reviews |

### Weekly Review (15 mins)

| Dashboard | Metrics to Track |
|-----------|------------------|
| **RevenueCat** | MRR, trial conversions, subscription breakdown |
| **Firebase Analytics** | DAU/MAU, session duration, screens/session |
| **Supabase** | Auth users, database size, API requests |

### Key Metrics to Watch

| Metric | Healthy | Warning | Action |
|--------|---------|---------|--------|
| Crash-free rate | >99% | <98% | Fix immediately |
| Trial → Paid conversion | >5% | <2% | Adjust paywall/pricing |
| Day 1 retention | >40% | <20% | Improve onboarding |
| Reviews | 4.5+ stars | <4.0 | Address feedback |

---

## Pricing & Cost Analysis

### Your Revenue (Per User)

| Plan | Price | Apple Cut (30%) | Your Net |
|------|-------|-----------------|----------|
| Weekly | $2.99/wk | $0.90 | **$2.09/wk** |
| Monthly | $4.99/mo | $1.50 | **$3.49/mo** |
| Yearly | $29.99/yr | $9.00 | **$20.99/yr** |

*After Year 1, Apple cut drops to 15% for subscribers*

### Your Costs (Per AI Generation)

| Service | Model | Cost per Request | Notes |
|---------|-------|------------------|-------|
| **Firebase AI (Gemini 2.5 Flash)** | gemini-2.5-flash | ~$0.00 | Free tier covers most usage |
| Gemini 2.5 Flash (if paid) | 1024 output tokens | ~$0.0004 | $0.10/1M input, $0.40/1M output |

**Cost per user session:** ~$0.001 (1 generation = 3 message options)

### 10K Users Overnight Scenario

**Assumptions:**
- 10,000 users
- Each uses 1 free generation
- 10,000 total API calls

| Service | Free Tier Limit | 10K Users Impact | Status |
|---------|-----------------|------------------|--------|
| **Firebase AI (Gemini)** | 1,500 RPD* | 10K requests | OK |
| **Supabase Auth** | 50,000 MAU | 10K users | OK |
| **Supabase Database** | 500MB | ~10MB | OK |
| **RevenueCat** | $2,500 MTR | $0 (free users) | OK |

*RPD = Requests per day. Gemini free tier has stricter limits now (as of Dec 2025).

### When to Upgrade (Trigger Points)

| Service | Free Limit | Upgrade Trigger | Cost |
|---------|------------|-----------------|------|
| **Firebase/Gemini** | ~1,500 RPD | >1,000 users/day active | Pay-as-you-go (~$0.0004/request) |
| **Supabase** | 50K MAU, 500MB | >40K users OR >400MB | $25/mo Pro |
| **RevenueCat** | $2,500 MTR | >$2,500 gross revenue/mo | 1% of revenue above $2.5K |

### Profitability Analysis

**Break-even per user:**
- Cost per 3 generations: ~$0.001
- Weekly sub revenue: $2.09 net
- **Margin: 99.95%** (you're fine!)

**At 10K paying weekly subs:**
- Gross: $29,900/week
- Apple cut: $8,970
- Your net: **$20,930/week**
- AI costs: ~$20-50/week
- **Profit: ~$20,880/week**

### Scaling Costs Projection

| Monthly Active Users | Gemini Cost | Supabase | RevenueCat | Total |
|---------------------|-------------|----------|------------|-------|
| 1,000 | $0 | $0 | $0 | **$0** |
| 10,000 | $0-50 | $0 | $0 | **$0-50** |
| 50,000 | $100-200 | $25 | ~$50* | **$175-275** |
| 100,000 | $300-500 | $25-50 | ~$200* | **$525-750** |

*RevenueCat cost assumes 5% conversion, avg $4/mo

---

## Competitive Analysis: Prosepal vs Direct AI

### The "Just Use ChatGPT" Problem

A user could pay $20/mo for ChatGPT Plus and ask:
> "Write a get well message for my sick granny"

**Why would they pay $2.99/week for Prosepal instead?**

### Head-to-Head Comparison

| Factor | ChatGPT/Gemini Direct | Prosepal |
|--------|----------------------|----------|
| **Price** | $20/mo (ChatGPT) or $0 (Gemini free) | $2.99/wk or $4.99/mo |
| **Time to message** | 30-60 seconds (type prompt, wait, copy) | **10 seconds** (3 taps) |
| **Prompt engineering** | User must figure it out | **Done for you** |
| **Output quality** | Hit or miss, generic | **Tuned for occasions** |
| **Mobile experience** | Clunky (browser/app switching) | **Native, one-handed** |
| **Context** | User explains everything | **Pre-built personas** |
| **Consistency** | Varies wildly | **Reliable 3 options** |

### Prosepal's USP (Unique Selling Points)

1. **Speed** - Standing in card aisle? 10 seconds vs 2 minutes
2. **No prompt crafting** - Users don't know how to prompt well
3. **Curated output** - 3 polished options, not a wall of text
4. **Purpose-built** - Occasions, relationships, tones pre-configured
5. **Mobile-first** - One-handed, offline-ready UI
6. **No AI subscription needed** - $2.99 vs $20/mo for casual users

### Target User Psychology

| User Type | Why They Won't Use ChatGPT | Why Prosepal Wins |
|-----------|---------------------------|-------------------|
| **Card aisle panic** | No time to open ChatGPT, think of prompt | 3 taps, done |
| **Non-technical** | "I don't know how to use AI" | Simple UI, no learning curve |
| **Occasional sender** | Won't pay $20/mo for 2 cards/year | $2.99 one-time or weekly |
| **Perfectionist** | Spends 20 mins tweaking prompts | 3 curated options, pick one |

### Pricing Justification

**ChatGPT Plus: $20/mo**
- General purpose, user does all the work
- Overkill for greeting cards

**Gemini Free: $0**
- Rate limited, inconsistent
- User must prompt correctly
- Clunky mobile experience

**Prosepal: $2.99/week or $4.99/mo**
- **Value prop:** "Coffee money for perfect words"
- For users who send 1-2 cards/month
- No AI knowledge required
- Faster than DIY prompting

### Competitive Moat

1. **UX optimization** - We've tuned prompts for months, user gets it in 10 seconds
2. **Occasion database** - 20+ occasions with relationship/tone combos
3. **Mobile-native** - Not a ChatGPT wrapper, built for the use case
4. **Emotional positioning** - "Never stare at a blank card again"

### When Users WILL Use ChatGPT Instead

- Power users who already pay for ChatGPT
- People who want very long messages
- Users who want to heavily customize/iterate

**That's fine** - they're not our target market. We target:
- Casual card senders (2-10/year)
- Non-technical users
- "Card aisle panic" impulse

---

## User Scenario Audit (Free Token & Subscription)

### Free Tier Scenarios

| Scenario | Protection | Status |
|----------|------------|--------|
| **User uses 1 free token** | Local count incremented, synced to Supabase | ✅ |
| **User deletes & reinstalls app** | On sign-in, `syncFromServer()` restores usage from Supabase | ✅ |
| **User tries to get free token without account** | Can use 1 free locally, but reinstall resets UNTIL they sign in | ⚠️ Minor |
| **User signs in after using free token** | Local usage pushed to server, persists across installs | ✅ |
| **User creates new account to reset** | New Supabase user = new usage record (acceptable - new email required) | ✅ |
| **User tries to generate with 0 remaining** | Button changes to "Upgrade to Continue" → paywall | ✅ |

### Subscription Scenarios

| Scenario | Handling | Status |
|----------|----------|--------|
| **User subscribes (weekly/monthly/yearly)** | RevenueCat `customerInfo` updates, `isProProvider` returns true | ✅ |
| **User cancels subscription** | RevenueCat entitlement expires at period end, `isProProvider` → false | ✅ |
| **User's subscription expires** | Same as cancel - entitlement removed, falls back to free tier | ✅ |
| **User deletes app & reinstalls (with active sub)** | `restorePurchases()` or auto-restore via StoreKit, entitlement restored | ✅ |
| **User signs in on new device** | `identifyUser()` links RevenueCat, purchases auto-restore | ✅ |
| **User downgrades (yearly → monthly)** | RevenueCat handles, new entitlement at period end | ✅ |
| **User requests refund** | Apple/Google revokes, RevenueCat updates entitlement | ✅ |

### Edge Cases & Protections

| Edge Case | Protection |
|-----------|------------|
| **Race condition: generate while checking** | Button disabled during generation (`isGenerating` state) |
| **Offline usage check** | Local SharedPreferences always available; server sync is async |
| **Server sync fails** | Local cache is source of truth for UX; logs error, continues |
| **RevenueCat not initialized** | `isProProvider` returns false (safe default) |
| **Anonymous → signed in user** | `identifyUser()` merges purchases, `syncFromServer()` merges usage |

### Known Minor Gap

**Anonymous free token abuse:**
- User can use 1 free token without signing in
- Delete app → reinstall → get another free token
- This resets ONLY if they never sign in

**Why it's acceptable:**
- Friction: Must reinstall app each time (annoying)
- Value: 1 free token = ~$0.001 cost
- Mitigation: On sign-in, server usage is restored
- Most abusers won't bother for 1 message

**Future mitigation (if needed):**
- Require sign-in before first generation
- Device fingerprinting (privacy concerns)
- IP-based rate limiting (backend)

### Code Verification

```
Usage Flow:
1. User taps Generate
2. `remainingGenerationsProvider` checks `isProProvider` 
3. If pro: uses `getRemainingProMonthly()` (500/mo)
4. If free: uses `getRemainingFree()` (1 lifetime)
5. If remaining > 0: button enabled, calls `_generate()`
6. After success: `recordGeneration()` updates local + server
7. On sign-in: `syncFromServer()` takes MAX(local, server)
```

---

### Cost Optimization Tips

1. **Cache common prompts** - Same occasion+relationship = cached response
2. **Rate limit free tier** - Currently 1 free use, can increase later if revenue allows
3. **Batch requests** - Gemini supports batch API for lower costs
4. **Monitor daily** - Set up Firebase billing alerts

---

## Free Tier Limits Reference

### Firebase AI (Gemini via Google AI)

| Limit | Gemini 2.5 Flash | Notes |
|-------|------------------|-------|
| Requests/min | 15 RPM | Per project |
| Requests/day | ~1,500 RPD | Varies, check quotas |
| Tokens/min | 250,000 TPM | Generous |
| Context window | 1M tokens | Huge |

**Warning:** Google reduced free tier significantly in Dec 2025. Monitor usage!

### Supabase Free Tier

| Resource | Limit |
|----------|-------|
| Database | 500MB |
| Auth users | 50,000 MAU |
| Storage | 1GB |
| Edge Functions | 500K/month |
| Bandwidth | 5GB |
| Projects | 2 active |

**Note:** Free projects pause after 7 days inactivity

### RevenueCat Free Tier

| Resource | Limit |
|----------|-------|
| MTR | $2,500/month |
| Features | All included |
| After limit | 1% of revenue above $2.5K |

---

## Emergency Playbook

### If Gemini Rate Limited (429 errors)

1. Check Firebase Console > AI Logic > Quotas
2. Enable billing if not already
3. Request quota increase (takes 24-48h)
4. Temporary: Reduce free tier to 1-2 uses

### If Supabase Paused

1. Log into Supabase dashboard
2. Click "Restore project"
3. Consider upgrading to Pro ($25/mo) to prevent pausing

### If RevenueCat Issues

1. Check dashboard for webhook failures
2. Verify API keys are production (not sandbox)
3. Contact support@revenuecat.com

---

## Post-Launch Checklist

### Week 1
- [ ] Monitor crash-free rate daily
- [ ] Respond to App Store reviews
- [ ] Check RevenueCat for first purchases
- [ ] Verify production API calls working

### Month 1
- [ ] Analyze trial → paid conversion rate
- [ ] Review top user feedback themes
- [ ] Check Gemini usage vs quotas
- [ ] Plan v1.1 update with bug fixes

### Quarter 1
- [ ] Full metrics review
- [ ] Decide: double down or pivot
- [ ] Consider Apple Search Ads if >50 trials/week
- [ ] Update ASO keywords based on data

---

## Environment Variables / Secrets

Ensure these are set correctly for production:

| Service | Location | Notes |
|---------|----------|-------|
| Supabase URL | `lib/core/config/` | Production project URL |
| Supabase Anon Key | `lib/core/config/` | Production anon key |
| RevenueCat API Key | `lib/core/config/` | iOS production key |
| Firebase | `ios/Runner/GoogleService-Info.plist` | Production project |

---

## Contacts / Resources

- **App Store Connect**: https://appstoreconnect.apple.com
- **RevenueCat Dashboard**: https://app.revenuecat.com
- **Firebase Console**: https://console.firebase.google.com
- **Supabase Dashboard**: https://supabase.com/dashboard

---

*Last updated: January 2026*
