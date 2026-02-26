# Prosepal - Product Specification

> AI-powered message helper for greeting cards and special occasions

## App Details

| Field | Value |
|-------|-------|
| **App Name** | Prosepal |
| **Tagline** | "The right words, right now" |
| **Bundle ID (iOS)** | com.prosepal.prosepal |
| **Package (Android)** | com.prosepal.prosepal |
| **Platforms** | iOS (App Store), Android (Google Play), Web |
| **Minimum iOS** | 15.0 |
| **Minimum Android** | API 21 (Android 5.0) |
| **Framework** | Flutter 3.38+ |

---

## The Opportunity

**Problem:** People struggle to write heartfelt messages for occasions
- Birthday cards: "Happy Birthday! Hope you have a great day!" (boring)
- Wedding cards: Stare at blank card for 20 minutes
- Sympathy cards: Terrified of saying the wrong thing
- Thank you notes: Generic and forgettable
- Graduation cards: Same clichés every time

**Solution:** AI that writes genuinely thoughtful, personalized messages

---

## Competitive Analysis (DETAILED)

### Direct Competitors - iOS

| App | Focus | Pricing | Rating | Weakness |
|-----|-------|---------|--------|----------|
| **American Greetings** | Ecards + AI text | $6.99/mo after trial | 4.9 iOS, 1.2 Trustpilot | Billing complaints, clunky, ecard-focused not message-focused |
| **CardsAI** | AI card IMAGE design | Credit-based | New | Focuses on visual design, not message writing |
| **GreetingAI** | AI card templates | Unknown | New | Template-focused, not message quality |
| **AI Greeting Card Generator** | GPT + DALL-E cards | $19.99/mo (!!!) | 4+ | Overpriced, image-focused |
| **JibJab** | Funny videos/ecards | $6.99/mo or $35.99/yr | 4+ | Entertainment, not heartfelt messages |
| **Cardory** | Card templates | Freemium | 4+ | Design tool, weak on message generation |

### Direct Competitors - Android

| App | Focus | Rating | Downloads |
|-----|-------|--------|-----------|
| **AI Greeting Card Generator** | Card + message | Unknown | Low |
| **AI Message Writer** | General messages | 4+ | 10K+ |
| **Greeting Cards Maker: AI Magic** | Card design | 4+ | 100K+ |
| **AI Text Message Generator** | All occasions | 4+ | 10K+ |

### Web Competitors

| Site | Pricing | Notes |
|------|---------|-------|
| **greetingcardwriter.com** | FREE | Simple, no app, just web |
| **Greetings Island Wish Generator** | FREE | Part of larger card platform |
| **Vondy Card Writer** | Freemium | Generic AI tool, not specialized |
| **Copy.ai** | Freemium | General writing, not occasion-focused |

### Key Insights from Competition

1. **Most focus on CARD DESIGN, not MESSAGE QUALITY**
   - Apps generate pretty images but messages are afterthought
   - Our USP: Message-first, not design-first

2. **Pricing is all over the place**
   - American Greetings: $6.99/mo (but poor reviews)
   - AI Greeting Card Generator: $19.99/mo (way overpriced)
   - Many free web tools exist
   - Sweet spot: $4.99-6.99/mo with generous free tier

3. **American Greetings has terrible trust**
   - 1.2 stars on Trustpilot
   - Billing complaints, deceptive trials
   - Opportunity: Be transparent, no tricks

4. **Free web tools exist but lack mobile experience**
   - greetingcardwriter.com is free but web-only
   - Mobile-first with offline access is differentiator

5. **No one owns "occasion-first" positioning**
   - Most apps are "AI card maker"
   - We position as "What to write" helper

---

## Our USP (Unique Selling Proposition)

### Primary USP: "The right words, right now"

**We are NOT:**
- A card design tool
- An ecard sender
- A generic AI writing tool

**We ARE:**
- The app you open when staring at a blank card
- Occasion + relationship = perfect message
- Personal details make it genuinely yours

### Key Differentiators

| Feature | Competitors | Us |
|---------|-------------|-----|
| **Primary focus** | Card design | Message quality |
| **Input** | "Describe your card" | Occasion + relationship + details |
| **Output** | One result | 3 options to choose from |
| **Personalization** | Generic | Incorporates names, memories, context |
| **Tone control** | Limited | Heartfelt, funny, formal, casual, poetic |
| **Speed** | Slow (design-heavy) | Instant (text-focused) |
| **Pricing** | Confusing, aggressive | Simple, transparent, generous free tier |
| **Trust** | Billing complaints | No tricks, cancel anytime |

### Positioning Statement

> "For anyone staring at a blank card, **[App Name]** is the AI message helper that gives you three perfect options in seconds—personalized with names, memories, and the right tone for your relationship."

---

## Name Options (Verified Available)

### Availability Check Results

| Name | iOS App Store | Google Play | Notes |
|------|---------------|-------------|-------|
| **Prosepal** | ✅ Available | ✅ Available | Top pick |
| **Penfolio** | ✅ Available | ✅ Available | Professional vibe |
| Wordsmith | ❌ Taken | ❌ Taken | Multiple apps |
| Inkwell | ❌ Taken | ❌ Taken | Journal app |
| CardCraft | ❌ Taken | ❌ Taken | Direct competitor! |
| Wordcraft | ❌ Taken | ❌ Taken | Word games |
| Heartfelt | ❌ Taken | - | Mental health app |
| Toastly | ❌ Taken | - | Wedding app |

### Recommended: **Prosepal**

**Why Prosepal:**
- "Prose" = written words (exactly what we do)
- "Pal" = friendly helper (approachable, not intimidating)
- Easy to spell and pronounce
- Available on both app stores
- Domain likely available: prosepal.app, prosepal.io
- Memorable and unique

**Tagline options:**
- "The right words, right now"
- "Your personal message helper"
- "Never stare at a blank card again"
- "Perfect words for every occasion"

---

## Core Features (MVP)

### Occasions Supported
1. **Birthday** - Friend, family, colleague, child
2. **Thank You** - Gift received, help given, hospitality
3. **Sympathy** - Loss of loved one, pet, job
4. **Wedding/Engagement** - Card, speech, toast
5. **Graduation** - High school, college, professional
6. **Baby/New Parent** - Congratulations, shower
7. **Get Well** - Illness, surgery, recovery
8. **Anniversary** - Romantic, work anniversary
9. **Congratulations** - Promotion, achievement, new home
10. **Apology** - Personal, professional

### Input Flow
```
1. Select occasion (e.g., "Birthday")
2. Select relationship (e.g., "Close friend")
3. Add personal details (optional):
   - Recipient's name
   - Shared memory/inside joke
   - Their interests
   - Your name (for signing)
4. Select tone: Heartfelt / Funny / Formal / Casual
5. Generate → 3 options appear
6. Edit/regenerate or copy
```

### Output Options
- **Copy text** - Paste anywhere
- **Share as card** - Beautiful shareable image
- **Export** - PDF for printing

---

## Monetization

### Free Tier
- 3 messages per day
- All occasions available
- Basic tones (heartfelt, casual)
- Copy text only

### Pro Tier - $4.99/month or $29.99/year
- Unlimited messages
- All tones (including funny, formal, poetic)
- Shareable card designs
- Save favorites
- Message history
- Priority generation

### Why This Pricing?
- Low enough for impulse purchase
- High enough for sustainable business
- Yearly discount encourages commitment
- Under $5/month is "coffee money" psychology

---

## Differentiators (USP)

### 1. **Occasion-First, Not AI-First**
- Users don't want "AI writing"
- They want "help with my wedding card"
- UI centers on occasion selection, not chatbot

### 2. **Relationship Context**
- "Thank you to boss" ≠ "Thank you to best friend"
- Tone adapts to relationship
- Appropriate formality levels

### 3. **Personal Details Integration**
- "Mention how we met at Sarah's party"
- "Reference their love of hiking"
- Makes it feel genuinely personal

### 4. **Multiple Options**
- Always generate 3 variations
- User picks the one that feels right
- Can regenerate specific ones

### 5. **Beautiful Shareable Cards**
- Not just text - visual output
- Instagram-story ready
- Print-quality PDF

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Flutter 3.38+ | Cross-platform (iOS, Android, Web) |
| **State Management** | Riverpod | Reactive state, dependency injection |
| **Auth + DB** | Supabase | Auth (V1.1+), Postgres, Edge Functions |
| **AI** | Gemini 2.5 Flash | Text generation via Supabase Edge Function |
| **Payments** | RevenueCat | Subscriptions (iOS + Android + Web) |
| **Analytics** | Firebase Analytics | User events, funnels, retention |
| **Crashes** | Firebase Crashlytics | Error tracking, diagnostics |
| **Local Storage** | SharedPreferences | Usage tracking, settings |

### Platform Distribution

| Platform | Store | Status |
|----------|-------|--------|
| iOS | Apple App Store | Primary launch |
| Android | Google Play Store | Primary launch |
| Web | prosepal.app (future) | Post-launch |

### Key Flutter Packages

```yaml
dependencies:
  flutter_riverpod: ^2.4.0      # State management
  purchases_flutter: ^6.0.0      # RevenueCat
  supabase_flutter: ^2.0.0       # Supabase (V1.1+)
  firebase_core: ^2.24.0         # Firebase
  firebase_analytics: ^10.7.0    # Analytics
  firebase_crashlytics: ^3.4.0   # Crash reporting
  google_fonts: ^6.1.0           # Typography
  flutter_animate: ^4.3.0        # Animations
  shared_preferences: ^2.2.0     # Local storage
  flutter_dotenv: ^5.1.0         # Environment variables
```

### API Cost Estimate
- ~500 tokens per message generation
- Gemini 2.5 Flash: ~$0.0001 per generation
- 3 options = $0.0003 per use
- **Very low marginal cost** - sustainable at scale

### Why This Stack?

| Choice | Rationale |
|--------|-----------|
| **Flutter** | Single codebase for iOS + Android + Web, fast iteration |
| **Supabase** | Generous free tier (50K MAU), Postgres, Edge Functions hide API keys |
| **Gemini Flash** | Cheapest quality AI, fast responses, Google reliability |
| **RevenueCat** | Handles both stores, webhooks, analytics, no backend needed |
| **Firebase** | Free analytics/crashlytics, already have account from PawNova |

---

## User Personas

### 1. "Last-Minute Linda" (Primary)
- Needs a card message in 5 minutes
- Standing in the card aisle or about to write
- Values: Speed, quality, done
- Willing to pay to save time

### 2. "Anxious Alex"
- Terrified of saying wrong thing (especially sympathy)
- Overthinks every word
- Values: Guidance, reassurance, appropriateness
- Willing to pay for confidence

### 3. "Bulk Betty"
- Writing many holiday/thank you cards
- Wants variety, not copy-paste
- Values: Efficiency, personalization at scale
- Willing to pay for unlimited

---

## MVP Scope (2-3 Weeks)

### MVP Feature Matrix

| Feature | MVP | V1.1 | V2 |
|---------|-----|------|-----|
| Occasion selection (10 types) | ✅ | | |
| Relationship picker | ✅ | | |
| Tone selector (4 options) | ✅ | | |
| Recipient name input | ✅ | | |
| Personal detail input (1 field) | ✅ | | |
| Generate 3 message options | ✅ | | |
| Copy to clipboard | ✅ | | |
| 3 free generations/day | ✅ | | |
| Usage tracking (local) | ✅ | | |
| Paywall screen | ✅ | | |
| RevenueCat subscription | ✅ | | |
| Apple/Google auth | | ✅ | |
| Message history | | ✅ | |
| Favorite messages | | ✅ | |
| Shareable card images | | | ✅ |
| More tones (poetic, etc.) | | | ✅ |
| Speech writer mode | | | ✅ |

### Week 1: Core Generation Flow
- [ ] Flutter project setup with folder structure
- [ ] Home screen with occasion grid (10 occasions)
- [ ] Generation flow: Occasion → Relationship → Tone → Details → Generate
- [ ] Gemini API integration (via Supabase Edge Function)
- [ ] Results screen with 3 options
- [ ] Copy to clipboard functionality
- [ ] Basic loading/error states

### Week 2: Monetization + Polish
- [ ] Local usage tracking (UserDefaults/SharedPreferences)
- [ ] Free tier limit (3/day) with reset at midnight
- [ ] RevenueCat SDK integration
- [ ] Paywall screen (triggers after limit reached)
- [ ] Subscription options: $4.99/mo, $29.99/yr
- [ ] Restore purchases
- [ ] App icons and splash screen
- [ ] Basic analytics (Firebase)

### Week 3: Launch Prep
- [ ] App Store screenshots (6 screens)
- [ ] App Store description and keywords
- [ ] Privacy policy page (hosted)
- [ ] Terms of service page (hosted)
- [ ] TestFlight build for beta testers
- [ ] Bug fixes from beta feedback
- [ ] Submit to App Store review

### What's NOT in MVP (Intentionally)
- ❌ User accounts/auth (use anonymous + local storage)
- ❌ Cloud sync (not needed until history feature)
- ❌ Card image generation (focus on text first)
- ❌ Social sharing (copy is enough for V1)
- ❌ Multiple languages (English only for launch)

---

## Prompt Engineering Strategy

### System Prompt Structure
```
You are a thoughtful message writer helping someone express genuine care.

Context:
- Occasion: {occasion}
- Relationship: {relationship}
- Recipient: {name}
- Tone: {tone}
- Personal details: {details}

Write 3 distinct message options, each:
- 2-4 sentences
- Warm and genuine, not generic
- Incorporate personal details naturally
- Match the specified tone
- Avoid clichés like "wishing you all the best"

Format as JSON: {"messages": ["...", "...", "..."]}
```

### Tone Examples
- **Heartfelt:** Emotional, sincere, meaningful
- **Casual:** Friendly, light, conversational
- **Funny:** Witty, playful, brings a smile
- **Formal:** Professional, respectful, appropriate for work
- **Poetic:** Lyrical, beautiful, elevated language

---

## Future Features (Post-MVP)

1. **Speech Writer** - Wedding toasts, eulogies, retirement speeches
2. **Email Templates** - Professional thank you, follow-up, apology
3. **Social Captions** - Birthday posts, tribute posts
4. **Card Designer** - More card templates, custom backgrounds
5. **Occasion Reminders** - Sync contacts, remind before birthdays
6. **Voice Input** - Speak your thoughts, AI polishes

---

## Success Metrics

### North Star: Monthly Recurring Revenue (MRR)

### Leading Indicators
- Daily Active Users (DAU)
- Messages generated per day
- Free → Pro conversion rate
- Retention (Day 1, Day 7, Day 30)

### Targets (First 90 Days)
- 1,000 downloads
- 50 paying subscribers (5% conversion)
- $250/month MRR
- 4.5+ App Store rating

---

## Go-to-Market

### ASO (App Store Optimization)
Keywords: "birthday message", "wedding card message", "what to write", "sympathy card", "thank you note", "greeting card helper"

### Social Proof
- Screenshots showing beautiful output
- "Before/After" - generic vs personalized
- User testimonials

### Viral Hooks
- Shareable cards with subtle branding
- "Made with Prosepal" watermark on free tier
- Share to Instagram stories

### Launch Strategy
1. Soft launch to friends/family for feedback
2. Product Hunt launch
3. Reddit (r/weddingplanning, r/Etiquette, r/LifeProTips)
4. TikTok content: "I used AI to write my best friend's birthday card"
