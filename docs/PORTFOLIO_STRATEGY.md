# Portfolio Strategy

> Expansion options beyond Prosepal

---

## Option A: Clone Strategy (Separate Apps)

Build separate apps targeting adjacent AI writing niches using same Flutter stack.

| App | Target Niche | Competitors | Differentiator |
|-----|--------------|-------------|----------------|
| **EmailPal** | Professional emails | Writesonic, Copy.ai | Mobile-first, occasion templates |
| **CaptionPal** | Social media captions | Copy.ai, Jasper | One-tap copy, trending hooks |
| **BioWriter** | Dating/LinkedIn bios | Rytr | Swipe UI, preset categories |
| **ToastMaster** | Speeches & toasts | Generic AI | Teleprompter mode, pacing |

### Pros
- Same Flutter stack = fast development
- Proven demand (competitors exist)
- Undercut pricing ($4.99 vs $20+/mo)
- Mobile-first is a real gap in AI writing tools
- Multiple revenue streams

### Cons
- Support burden multiplied per app
- ASO/marketing effort per app
- Gemini API costs scale with each app
- Clone strategy rarely builds defensible moat
- App Store review overhead per app

### Execution (Droid CLI Workflow)
1. Scrape competitor (public pages) → structured JSON
2. Prompt Droid: "Inspire from [JSON] but build unique mobile app with [our animations/polish]"
3. Same Flutter stack, different prompts/UI skin
4. Undercut pricing ($4.99 vs $20+)

---

## Option B: Platform Strategy (Single App)

Expand Prosepal to cover adjacent use cases within one app.

| New "Occasion" | Use Case |
|----------------|----------|
| Professional Email | Work emails, follow-ups, requests |
| Social Caption | Instagram, TikTok, LinkedIn posts |
| Bio | Dating profiles, LinkedIn summaries |
| Toast / Speech | Wedding toasts, retirement speeches |

### Pros
- One codebase, one brand, one subscription
- Single ASO effort captures multiple keywords
- Users discover adjacent features organically
- Lower maintenance burden
- Stronger brand ("Prosepal for everything")

### Cons
- App scope creep risk
- UI complexity as occasions grow
- Single point of failure (one app rejected = all revenue gone)
- May dilute "greeting card" positioning

### Execution
1. Add new occasion categories with appropriate prompts
2. Update ASO metadata to capture new keywords
3. Consider tabbed navigation: Cards | Social | Professional

---

## Recommendation

**Start with Platform Strategy (Option B):**
- Add 2-3 new occasion types to Prosepal
- Validate demand via usage data
- If specific category explodes → spin off dedicated app

**If cloning:** Start with ONE app (CaptionPal has best viral potential due to social sharing). Validate before building others.

---

## Viral Potential Ranking

| App | Viral Mechanism | Ranking |
|-----|-----------------|---------|
| CaptionPal | Captions shared publicly → attribution | High |
| ToastMaster | Speeches performed → word of mouth | Medium |
| EmailPal | Emails are private | Low |
| BioWriter | Bios are static, updated rarely | Low |

---

## Cost Considerations

| Item | Per App |
|------|---------|
| App Store fee | $99/yr (Apple) |
| Gemini API | ~$0.0004/generation |
| RevenueCat | Free until $2.5k MTR |
| Supabase | Free until 50k MAU |
| Support time | 2-4 hrs/week |

---

## Safe Lines

- Features/logic OK to clone
- Avoid exact UI/copy/branding (trademark risk)
- Don't scrape private/authenticated content
- Build genuine differentiation, not 1:1 copies
