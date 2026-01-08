# Expansion Strategy

> Future revenue opportunities beyond consumer subscriptions.

---

## B2B Corporate Programs

### The Opportunity

Companies send millions of cards annually - employee birthdays, client thank-yous, condolences, work anniversaries, retirements, holidays. Most are painfully generic ("Best wishes from the team!") or outsourced to services that feel impersonal.

### Use Cases

| Use Case | Pain Point | Prosepal Solution |
|----------|------------|-------------------|
| **HR/People Teams** | Writing 50+ birthday cards/month | Bulk generation with employee context |
| **Sales Teams** | Client thank-you cards feel templated | Relationship-aware personalization |
| **Executive Assistants** | CEO needs 200 holiday cards signed | Generate options, maintain voice consistency |
| **Customer Success** | Milestone cards (renewals, anniversaries) | Occasion-specific, business-appropriate tones |
| **Bereavement Support** | Employee loss situations are delicate | Sympathy messages with professional boundaries |

### B2B Product Features

**Team/Admin Dashboard:**
- Centralized billing (one invoice vs individual subscriptions)
- Usage analytics per department/user
- Custom occasion types ("Client Onboarding", "Project Completion")
- Brand voice guidelines fed to AI
- Approval workflows for sensitive occasions

**Enterprise Tier Pricing (Hypothetical):**

| Tier | Seats | Price | Features |
|------|-------|-------|----------|
| Team | 5-25 | $15/user/month | Shared billing, basic analytics |
| Business | 25-100 | $12/user/month | Custom occasions, admin dashboard |
| Enterprise | 100+ | Custom | SSO, API access, dedicated support |

**Revenue Math:**
- 50-person company at $12/user = $600/month ($7,200/year)
- 10 enterprise accounts = $72K ARR
- Equivalent to ~500 individual Pro subscribers

### Implementation Requirements

| Aspect | Current State | B2B Requirement |
|--------|---------------|-----------------|
| **Auth** | Individual Supabase accounts | Team/org structure, SSO (Okta, Azure AD) |
| **Billing** | RevenueCat (consumer IAP) | Stripe for B2B invoicing, annual contracts |
| **Admin** | None | Dashboard, user management, usage reports |
| **Tones** | 6 consumer tones | "Professional", "Corporate Warm", custom brand voice |
| **Data** | Individual history | Team-shared templates, company-wide favorites |

### Risks

1. **Different sales motion** - B2B requires outbound sales, demos, contracts
2. **Support burden** - Enterprise expects dedicated support, SLAs
3. **Feature creep** - "Add Slack integration", "Salesforce sync"
4. **Distraction risk** - Diverts from consumer growth

### Recommendation

**Wait until Month 12+ and $5K+ MRR from consumer.** Then:
1. Test with inbound interest (companies reaching out)
2. Start with simple "Team Plan" (shared billing only)
3. Validate demand before building enterprise features

---

## Partnerships with Card Brands & Retailers

### The Landscape

| Partner Type | Examples | What They Have | What They Lack |
|--------------|----------|----------------|----------------|
| **Card Publishers** | Hallmark, American Greetings, Papyrus | Distribution, brand trust | AI message generation |
| **Online Platforms** | Moonpig, Thortful, Postable | Digital card creation | Personalized message suggestions |
| **Retailers** | Target, Walmart, CVS | Card aisle traffic | In-store digital assistance |
| **Stationery Stores** | Paper Source, local boutiques | Premium customers | Tech integration |

### Partnership Models

#### Model A: White-Label / Embedded SDK

License Prosepal's AI to card platforms.

**Example Flow (Moonpig):**
1. User designs card on Moonpig
2. Clicks "Need message help?"
3. Prosepal-powered widget appears
4. User selects occasion/relationship/tone
5. 3 messages generated, user picks one
6. Message auto-fills into card

**Revenue Model:**
- Per-API-call pricing ($0.01-0.05 per generation)
- Monthly licensing fee ($5K-50K/month based on volume)
- Revenue share (% of card sales with AI messages)

**Technical Requirements:**
- Expose Prosepal AI as REST API
- Partner SDK (React, Swift, Kotlin)
- Multi-tenant architecture
- Usage metering and billing

#### Model B: Retail In-Store Integration

QR codes in card aisles that open Prosepal.

**Example Flow (Target card aisle):**
1. Customer picks up sympathy card
2. Scans QR code on shelf tag
3. Opens Prosepal (or web version)
4. Generates message while standing in aisle
5. Writes message, buys card

**Revenue Model:**
- Retailer pays for QR placement ($X per store/month)
- Co-marketing (retailer promotes app)
- Affiliate revenue

**Benefits:**
- Captures users at highest-intent moment
- Retailer differentiates card aisle
- Low technical integration

#### Model C: Co-Branded Experience

Partner with Hallmark on co-branded feature.

**Example:**
- "Hallmark Message Helper - Powered by Prosepal"
- Lives within Hallmark's app
- Hallmark gets AI capability
- Prosepal gets distribution + credibility

**Revenue Model:**
- Licensing fee + revenue share
- Potential acquisition path

### Partnership Pitch Angles

| Partner | Their Problem | Prosepal's Value |
|---------|---------------|------------------|
| **Moonpig/Thortful** | Users abandon at message step | Reduce abandonment |
| **Hallmark** | Ecards feel impersonal | AI personalization differentiator |
| **Target/Walmart** | Card aisle is passive | Mobile engagement at POS |
| **Paper Source** | Premium customers expect more | "Concierge" message service |

### Risks

1. **Long sales cycles** - 6-18 months for enterprise partnerships
2. **Integration complexity** - Each partner different stack
3. **Brand dilution** - White-label = invisible brand
4. **Dependency** - One big partner = concentration risk
5. **Competition** - Hallmark could build their own

### Recommended Sequence

| Phase | Timeline | Action |
|-------|----------|--------|
| **Now** | Month 1-6 | 100% consumer focus |
| **Soft Signal** | Month 6-9 | Add "For Business" link (capture inbound) |
| **Retail Test** | Month 9-12 | Pilot QR codes with local stationery store |
| **Platform Outreach** | Month 12+ | Approach Moonpig/Thortful with traction data |
| **Big Brand** | Month 18+ | Hallmark only with leverage (downloads, revenue) |

---

## Prioritization Framework

| Opportunity | Revenue Potential | Effort | Timeline | Priority |
|-------------|-------------------|--------|----------|----------|
| Consumer Growth | High (scalable) | Done | Now | **#1** |
| Simple Team Plan | Medium | Low | Month 9+ | #2 |
| Retail QR Pilot | Low-Medium | Low | Month 9+ | #3 |
| Enterprise B2B | High | Very High | Month 12+ | #4 |
| Platform SDK | Very High | Very High | Month 18+ | #5 |

**Key Insight:** Both B2B and partnerships require consumer traction as leverage. A partner meeting goes differently with "50K active users" vs "just launched."
