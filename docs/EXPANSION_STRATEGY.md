# Expansion Strategy

> Future plans: app features, marketing pivots, and B2B opportunities.
> **Last Updated**: January 20, 2026

---

## Kill List (Removed from Plans)

These items sounded good but would waste time/resources for a solo dev:

| Item | Why Killed |
|------|------------|
| **Partner SDK / Moonpig Integration** | 0% Year 1 success. They'll build internally or use OpenAI. |
| **Retail QR Code Pilots** | Insane user friction. People Google in the aisle, not download apps. |
| **TikTok 3x/Week Grind** | Burnout risk. Low intent-to-install for utility apps. |
| **RevenueCat Team Plans** | Support nightmare. Promo codes don't scale for seat management. |
| **Complex B2B Features** | Defer until validated demand from inbound. |

---

## App Roadmap

### P0: UK Spelling Localization

Critical for the UK market (7x more valuable per capita than US).

| Task | Details |
|------|---------|
| **Detection** | Read device locale (en-GB, en-US) - NO location permission needed |
| **Fallback** | Ask in onboarding: "Mom or Mum?" with flag icons |
| **Application** | Inject spelling preference into AI prompt |
| **Settings** | Toggle to override in Settings |

**Spelling differences:**
- Mom/Mum, favorite/favourite, color/colour, organize/organise

**Effort:** 2-4 hours

### P1: Occasion Calendar + Reminders

Solves the "episodic retention" problem - gives users reasons to return.

| Component | Details |
|-----------|---------|
| **Save from Generation** | After copy, prompt "Save to Calendar?" with date picker |
| **Manual Add** | Calendar screen has [+ Add Occasion] button |
| **Calendar View** | Month view + upcoming list (next 30 days) |
| **Edit/Delete** | Manage saved occasions |
| **Reminders** | Local push notification 7 days before |
| **Deep Link** | Tap notification → pre-filled generation screen |

**Recurring vs One-Time:**

| Occasion | Recurring? | Extra Field |
|----------|------------|-------------|
| Birthday | ✅ Yearly | Birth year (optional) → "Mom's 65th Birthday" |
| Anniversary | ✅ Yearly | Start year (optional) → "40th Anniversary" |
| Wedding, Baby Shower, Graduation, Retirement | ❌ One-time | None |
| Sympathy, Thank You, Get Well | ❌ No date | Immediate use |

**Anniversary = Joint by Default:**
- Person field is freeform: "Mom & Dad", "Sam & Joe", "The Smiths"
- One message for the couple

**Effort:** 3-4 days

### Onboarding Updates

Two new screens to add:

| Screen | Purpose | Elements |
|--------|---------|----------|
| **Notifications** | Permission request | Bell icon, "Never miss an important date", Allow/Maybe Later buttons |
| **Spelling** | UK/US preference | Flag icons, "Mom vs Mum" choice, no permission needed |

---

## Risk Mitigation: Lessons from Failed Startups

### Similar Failed Companies

| Company | Model | Why They Failed |
|---------|-------|-----------------|
| **Chirply** | On-demand greeting cards | No sustainable revenue, relied on hype |
| **YourQuote** | Content sharing for writers | Couldn't monetize community, platform dissolved |
| **WriteWith** | Collaborative writing | Lost to free alternatives (Google Docs) |

### Risk Factors That Apply to Prosepal

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Free tool competition** | High | ChatGPT could add greeting card templates. Our moat is UX convenience, not capability. |
| **Standalone app fragility** | Medium | Single app rejection = 0 revenue. Diversify to web, B2B. |
| **Thin defensibility** | Medium | Low barrier to entry. Build brand + distribution before copycats. |
| **No revenue path** | Low | ✅ Already addressed - paywall after 1 free gen |

### What NOT to Copy

1. **Chase disruption without revenue** - Always have paying customers, not just users
2. **Ignore free alternatives** - Monitor ChatGPT capabilities monthly
3. **Over-rely on community** - We're utility-first, not social platform

### Safer Pivot Options (If Consumer Stalls)

| Pivot | Effort | Revenue Potential | Timeline |
|-------|--------|-------------------|----------|
| B2B team plans | Low | Medium | Month 6+ |
| E-commerce integration (Moonpig plugin) | Medium | High | Month 9+ |
| API-as-a-service | High | Medium | Month 12+ |

**Trigger to pivot:** If MRR plateaus below $2K for 3+ months after Month 6.

---

## B2B Strategy (Simplified)

### Target: Executive Assistants (Not HR Teams)

**Why EAs, not HR:**
- Single-user buyer (no seat management needed)
- Have corporate cards (easy purchase)
- Clear recurring need (CEO's cards all year)
- Don't need "Team Plans" - just Pro subscription

**Their Pain:**
- CEO needs 200 holiday cards signed
- 50+ birthday cards per month
- Client thank-yous that don't sound templated

**How to Reach Them:**
- "For Teams/EA" landing page capturing inbound interest
- Target keywords: "executive assistant tools", "write cards for boss"
- No complex features needed - just market the Pro plan to them

### Inbound Capture (Now)

| Action | Effort | Purpose |
|--------|--------|---------|
| Add "For Teams" link in app Settings | 1 hour | Route to Typeform |
| Add "Business Inquiries" on website footer | 30 min | Email capture |
| Track "business", "team", "assistant" in support | 0 | Signal detection |

**Form Questions:**
1. Company name
2. Your role (EA, HR, Sales, Other)
3. How many cards do you write per month?
4. Email
5. "What would make Prosepal useful for your work?"

**What Signals Tell You:**

| Signal | Action |
|--------|--------|
| 0 submissions in 3 months | B2B demand weak - stay consumer |
| 5-10 submissions | Schedule discovery calls |
| 20+ submissions | Consider bulk features |

### Future B2B Features (Only If Validated)

Don't build until you have 10+ paying business users asking for these:

| Feature | Trigger |
|---------|---------|
| CSV Bulk Import | Multiple EAs requesting |
| Corporate tones | Demand from enterprise |
| Team billing | 3+ companies asking |

**Rule:** Validate with inbound demand before writing code.

---

## Prioritization Summary

| Priority | Focus |
|----------|-------|
| **#1** | Consumer growth (current) |
| **#2** | UK market (spelling + dates) |
| **#3** | Retention (Calendar + Reminders) |
| **#4** | SEO pages (20 high-intent) |
| **#5** | EA inbound capture |

**Everything else is killed or deferred until $5K+ MRR.**

---

*Last updated: January 20, 2026*
