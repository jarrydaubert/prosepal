# Cloning Playbook

> Leverage Prosepal's stack to rapidly clone adjacent SaaS products.

---

## Philosophy

- **Inspire, don't copy** - Features/logic legal, UI/branding not
- **Differentiate or die** - Add 10-20% unique value
- **Speed is the moat** - 2-4 weeks MVP with AI tooling

---

## Reusable Stack

| Layer | Tech |
|-------|------|
| Framework | Flutter 3.38+ |
| State | Riverpod 3.x |
| Navigation | go_router |
| AI | Firebase AI (Gemini) |
| Auth | Supabase |
| Payments | RevenueCat |
| Animations | flutter_animate, Rive, confetti |

---

## Target Selection Criteria

Pick targets with:
- High MRR ($10K+/month proves demand)
- Vocal complaints (G2, Reddit, X)
- Overpriced for individuals ($15+/month)
- Weak mobile presence
- No moat beyond brand

---

## Process (5 Phases)

### Phase 1: Intel (Day 1-2)

1. Sign up for target (free trial)
2. Screen record every flow, edge case, error state
3. Export data where possible (reveals schemas)
4. Review docs, APIs, changelogs
5. Feed to Claude: "Reverse engineer schema and flows"

**Tools:** Playwright for automated exploration, Mobbin for UI patterns

### Phase 2: Scope (Day 2-3)

6. Categorize features with Claude:
   - **Core MVP** (3-5 features delivering 80% value)
   - **Important** (post-launch)
   - **Bloat** (skip)

7. Mine complaints from G2/Reddit/X → your differentiators

### Phase 3: Build (Week 1-2)

8. Architecture prompt to Claude:
   - Schema design
   - API structure
   - Auth flow
   - Payment integration

9. Screenshot-to-code workflow:
   - Screenshot pages → Claude → Flutter components
   - Pixel-close but visually distinct (no brand infringement)

10. Daily iteration:
    - Review AI-generated code
    - Manual complex work
    - Test core flows
    - Queue next tasks

### Phase 4: Differentiate (Week 2-3)

11. Add unique value:
    - Better animations (flutter_animate)
    - Niche focus (specific industry)
    - Faster UX (mobile-first)
    - Lower pricing (undercut)
    - New integrations

12. Legal review:
    - No copied UI/branding
    - No trademark infringement
    - Clean-room implementation

### Phase 5: Launch (Week 3-4)

13. Ship to small audience:
    - X/Twitter
    - IndieHackers
    - Relevant Discord/Reddit

14. Cold outreach:
    - Find dissatisfied users of target
    - Offer solution to their complaints

15. Iterate on feedback with Claude

---

## Clone Candidates

| App | Target Inspiration | Differentiator | Viral Potential |
|-----|-------------------|----------------|-----------------|
| **CaptionPal** | Copy.ai, Jasper | Mobile-first, trending hooks, one-tap copy | High (captions shared publicly) |
| **EmailPal** | Writesonic | Occasion templates, mobile UX | Low (emails private) |
| **BioWriter** | Rytr | Swipe UI, preset categories | Low (bios static) |
| **ToastMaster** | Generic AI | Teleprompter mode, pacing, rehearsal | Medium (speeches performed) |

---

## Legal Guardrails

| Do | Don't |
|----|-------|
| Clone features and logic | Copy UI pixel-for-pixel |
| Inspire from patterns | Use their branding/logos/trademarks |
| Build from public observation | Scrape private/authenticated data |
| Differentiate visually | Clone exact pricing tiers or copy |
| Focus on unmet needs | Ignore cease-and-desist if received |

---

## Success Metrics

| Milestone | Target |
|-----------|--------|
| MVP shipped | 2-4 weeks |
| First paying user | Week 4-6 |
| $1K MRR | Month 2-3 |
| $10K MRR | Month 6-12 |

---

## Tools

| Category | Tools |
|----------|-------|
| AI Coding | Claude Opus, Cursor, Aider |
| Scraping/Intel | Droid CLI, Playwright |
| UI Patterns | Mobbin, v0.dev, Uizard |
| Analytics | PostHog (self-hosted) |
| Monitoring | Sentry, LogRocket |

---

## Decision: Clone vs Expand Prosepal

| Signal | Action |
|--------|--------|
| Adjacent use case (emails, captions) | Expand Prosepal first |
| Demand validated in Prosepal data | Spin off dedicated app |
| Unrelated market entirely | New clone from scratch |

**Recommendation:** Start with platform expansion (add occasions to Prosepal), spin off only when data validates demand.
