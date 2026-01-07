# Prosepal - Product Specification

> AI-powered message helper for greeting cards and special occasions

## App Details

| Field | Value |
|-------|-------|
| **App Name** | Prosepal |
| **Tagline** | "The right words, right now" |
| **Bundle ID (iOS)** | com.prosepal.prosepal |
| **Package (Android)** | com.prosepal.prosepal |
| **Minimum iOS** | 15.0 |
| **Minimum Android** | API 23 (Android 6.0) |

---

## The Opportunity

**Problem:** People struggle to write heartfelt messages for occasions
- Birthday cards: "Happy Birthday! Hope you have a great day!" (boring)
- Wedding cards: Stare at blank card for 20 minutes
- Sympathy cards: Terrified of saying the wrong thing

**Solution:** AI that writes genuinely thoughtful, personalized messages in seconds.

---

## USP (Unique Selling Proposition)

**We are NOT:** A card design tool, an ecard sender, a generic AI writing tool

**We ARE:** The app you open when staring at a blank card

| Feature | Competitors | Us |
|---------|-------------|-----|
| Focus | Card design | Message quality |
| Input | "Describe your card" | Occasion + relationship + details |
| Output | One result | 3 options to choose from |
| Speed | Slow (design-heavy) | Instant (text-focused) |

---

## User Personas

| Persona | Description | Values |
|---------|-------------|--------|
| **Last-Minute Linda** | Needs message in 5 minutes, standing in card aisle | Speed, quality, done |
| **Anxious Alex** | Terrified of saying wrong thing (especially sympathy) | Guidance, reassurance |
| **Bulk Betty** | Writing many holiday/thank you cards | Efficiency, variety |

---

## Competitors

### iOS
| App | Focus | Pricing | Weakness |
|-----|-------|---------|----------|
| American Greetings | Ecards + AI | $6.99/mo | 1.2 Trustpilot, billing complaints |
| CardsAI | Card IMAGE design | Credit-based | Visual focus, not message |
| JibJab | Funny videos | $6.99/mo | Entertainment, not heartfelt |

### Web (Free)
| Site | Notes |
|------|-------|
| greetingcardwriter.com | Simple, no app, web only |
| Greetings Island | Part of larger card platform |

**Key Insight:** Most focus on CARD DESIGN, not MESSAGE QUALITY. We own "occasion-first" positioning.

---

## Pricing

| Tier | Price | Trial | Limit |
|------|-------|-------|-------|
| Free | $0 | - | 1 lifetime |
| Weekly | $2.99/wk | 3-day | 500/mo |
| Monthly | $4.99/mo | 7-day | 500/mo |
| Yearly | $29.99/yr | 7-day | 500/mo |

**RevenueCat Product IDs:**
- `com.prosepal.pro.weekly`
- `com.prosepal.pro.monthly`
- `com.prosepal.pro.yearly`

**Why this pricing:**
- Under $5/mo = "coffee money" psychology
- Weekly captures "card aisle panic" impulse buyers
- 29% cheaper than American Greetings

---

## Growth Strategy

Inspired by @maks6361's indie dev approach (30+ apps, $25k MRR).

| Principle | Implementation |
|-----------|---------------|
| Simple MVP | Occasion → Generate → Copy |
| ASO-first | Keyword-optimized title/subtitle |
| Fire and forget | Launch, monitor, iterate winners only |
| Portfolio | Prosepal = first app, more to follow |

### Go-to-Market

| Channel | Action |
|---------|--------|
| Product Hunt | Launch post Week 1 |
| Twitter/X | Build in public |
| TikTok | "POV: You need to write a card" (if traction) |
| Apple Search Ads | If >50 trials/week |

### Risk Monitoring

| Risk | Action Trigger |
|------|----------------|
| Gemini cost spike | If >$50/mo, add caching |
| Low conversion | If <2% trial→paid, tighten free tier |
| Negative reviews | Respond within 24h |

---

## Success Metrics

**North Star:** Monthly Recurring Revenue (MRR)

**90-Day Targets:**
- 1,000 downloads
- 50 paying subscribers (5% conversion)
- $250/month MRR
- 4.5+ App Store rating

**Leading Indicators:**
- DAU, messages generated/day
- Free → Pro conversion rate
- Retention (Day 1, Day 7, Day 30)
