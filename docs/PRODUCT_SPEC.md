# Prosepal - Product Specification

> AI-powered message helper for greeting cards and special occasions

## App Details

| Field | Value |
|-------|-------|
| **App Name** | Prosepal |
| **Tagline** | "The right words, right now" |
| **Bundle ID (iOS)** | com.prosepal.prosepal |
| **Package (Android)** | com.prosepal.prosepal |
| **Platforms** | iOS (App Store), Android (Google Play) |
| **Minimum iOS** | 15.0 |
| **Minimum Android** | API 23 (Android 6.0) |
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

## Growth Strategy: Max's Portfolio Approach

Inspired by @maks6361's indie dev strategy (30+ apps, $25k MRR in 10 months).

### Key Principles Applied to Prosepal

| Max's Strategy | Our Implementation |
|----------------|-------------------|
| Simple MVP, one feature | Occasion → Generate → Copy |
| Flutter cross-platform | iOS + Android from day 1 |
| RevenueCat subscriptions | Weekly/Monthly/Yearly trials |
| ASO-first discovery | Keyword-optimized title/subtitle |
| Fire and forget | Launch, monitor, iterate only winners |
| Portfolio approach | Prosepal = first app, more to follow |

### ASO Keywords to Target

**Primary Keywords (High Intent):**
- "what to write in card" (problem-aware)
- "greeting card message" (solution-aware)
- "birthday message generator"
- "thank you note writer"
- "sympathy card message"

**Long-Tail Keywords (Less Competition):**
- "what to write in graduation card"
- "wedding card message ideas"
- "get well soon message generator"
- "condolence message helper"

**App Store Title Strategy:**
```
Title: Prosepal - Card Message Writer
Subtitle: AI Birthday, Thank You & Gift Messages
```

**Google Play Title:**
```
Prosepal: Card Message Writer - AI Birthday & Thank You Notes
```

### Subscription Strategy (Max's Model)

| Tier | Price | Trial | Why |
|------|-------|-------|-----|
| Weekly | $2.99/week | 3-day | Impulse users, high LTV if converts |
| Monthly | $4.99/mo | 7-day | Standard |
| Yearly | $29.99/yr | 7-day | Best value, lock in |

**Why Weekly?** Max found weekly subs convert well for utility apps - users who need it NOW will pay.

### Launch Checklist (Max's Fire-and-Forget)

- [ ] Launch iOS + Android same week
- [ ] Don't babysit - check metrics after 5 days (iOS) / 2 weeks (Android)
- [ ] If < 10 trials in first week → Move on or pivot keywords
- [ ] If > 50 trials → Double down, add Apple Search Ads
- [ ] Cross-promote future apps subtly

### Soft Launch & Promotion Plan

| Channel | Action | Timing |
|---------|--------|--------|
| **Product Hunt** | Launch post | Week 1 |
| **Twitter/X** | Build in public thread | Ongoing |
| **TikTok** | "POV: You need to write a card" slideshows | If traction |
| **Apple Search Ads** | On winners only | If >50 trials/week |

> **Note:** Avoid Reddit self-promotion - high ban risk.

### Countering Free Web Tools

Free web tools (greetingcardwriter.com, etc.) exist but lack mobile advantages:

| Our Advantage | Why It Matters |
|---------------|----------------|
| **Mobile-first** | Write while standing in card aisle |
| **Offline capable** | No WiFi needed at store |
| **Quick copy/share** | One tap to clipboard |
| **Saved history** (V1.1) | Reuse for same person next year |
| **3 variations** | Choice, not just one output |

**ASO Screenshot Strategy:**
1. "Standing in the card aisle? We've got you."
2. "3 personalized options in seconds"
3. "Birthday, Wedding, Sympathy & more"
4. "Copy. Paste. Done."

### Conversion Optimization

**Risk:** Generous free tier (3/day) may reduce conversions.

**Mitigation - A/B Test These:**

| Variant | Free Tier | Hypothesis |
|---------|-----------|------------|
| A (Default) | 3/day | Hooks users, converts power users |
| B (Tight) | 1/day | Forces conversion faster |
| C (Occasion-limited) | 3/day, but only 2 occasions free | Upsells variety seekers |

**Pro Value-Adds to Test:**
- More tones (Poetic, Inspirational, Religious)
- Longer messages option
- "Remember this person" feature
- No "Powered by Prosepal" watermark on share

### Risk Monitoring

| Risk | Monitor | Action Trigger |
|------|---------|----------------|
| Gemini API cost spike | Monthly bill | If >$50/mo, add caching |
| Gemini rate limits | Error logs | Implement queue/retry |
| Low conversion | RevenueCat | If <2% trial→paid, tighten free |
| ASO keyword shifts | Sensor Tower (monthly) | Update metadata quarterly |
| Negative reviews | App Store Connect | Respond within 24h |

### Portfolio Expansion Ideas

If Prosepal works, clone the pattern for other text-generation niches:

| App Idea | Same Tech | Keyword Niche |
|----------|-----------|---------------|
| **EmailPal** | ✅ | Professional email writer |
| **CaptionPal** | ✅ | Social media caption generator |
| **BioWriter** | ✅ | Dating/LinkedIn bio generator |
| **ToastMaster** | ✅ | Wedding/event speech writer |
| **ReviewHelper** | ✅ | Product review writer |

Each app: Same Flutter codebase, same Gemini API, different prompts/UI skin.

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

### Competitor Pricing Comparison

| App | Platform | Free Tier | Subscription | Annual | Notes |
|-----|----------|-----------|--------------|--------|-------|
| **American Greetings** | iOS/Android | 7-day trial | $6.99/mo | $35.99/yr | 1.2 Trustpilot, billing complaints |
| **JibJab** | iOS/Android | Limited | $6.99/mo | $35.99/yr | Entertainment focus, not messages |
| **AI Greeting Card Generator** | iOS | None | $19.99/mo | - | Overpriced, image-focused |
| **Cardory** | iOS | Limited | ~$4.99/mo | ~$29.99/yr | Card design, weak messages |
| **greetingcardwriter.com** | Web | Unlimited | FREE | FREE | No app, basic UX |
| **Greetings Island** | Web | Unlimited | FREE | FREE | Part of card platform |
| **Vondy Card Writer** | Web | Limited | $19/mo | - | Generic AI tool |
| **TextAI** | iOS | Limited | $6.99/mo | $49.99/yr | General writing, not occasion-specific |

### Our Pricing Strategy

| Tier | Limit | Price | Trial | vs Competition |
|------|-------|-------|-------|----------------|
| **Free** | 3 total (lifetime) | $0 | - | Try before you buy |
| **Pro Weekly** | 500/mo | $2.99/wk | 3-day | Impulse buyers, high LTV |
| **Pro Monthly** | 500/mo | $4.99/mo | 7-day | 29% cheaper than American Greetings |
| **Pro Yearly** | 500/mo | $29.99/yr | 7-day | 17% cheaper than American Greetings |

**Why 3 total (not 3/day)?**
- Limits YOUR cost exposure: max $0.00012 per free user ever
- 10K free users = $1.20 total cost (not $36/month recurring)
- 3 generations = 9 message options = enough to prove value
- Creates real conversion pressure after trial

**Why this pricing:**
- Under $5/mo = "coffee money" psychology
- **Weekly option** = Max's strategy, converts impulse users who need it NOW
- Yearly saves 50% = encourages commitment
- Free tier generous enough to hook users
- Cheaper than American Greetings (the biggest player)

**RevenueCat Product IDs:**
```
com.prosepal.pro.weekly    // $2.99/week, 3-day trial
com.prosepal.pro.monthly   // $4.99/month, 7-day trial
com.prosepal.pro.yearly    // $29.99/year, 7-day trial
```

### Pricing Validation

**Competitive Positioning:**
- American Greetings: $1.99-$6.99/mo → We're in the sweet spot
- Most AI writing tools: $5-$20/mo → We're at the low end
- Free web tools exist but lack mobile convenience

**Industry Benchmarks (Utility Apps):**
- Successful subs: $3-$10/mo range
- Weekly plans: $3-$6 typical
- Trial-to-paid conversion: 2-5% (higher with trials)
- Higher-priced apps = better Day 35 retention

**Why Our Pricing Works:**

| Tier | Psychology | Target User |
|------|------------|-------------|
| Weekly $2.99 | "Need it NOW" impulse | Card aisle panic buyer |
| Monthly $4.99 | "Coffee money" threshold | Regular card sender |
| Yearly $29.99 | 50% savings commitment | Gift-giving enthusiast |

**Weekly Sub Economics:**
- Higher initial uptake, steeper churn
- But: Captures high-LTV impulse users
- Pairs with yearly discount to encourage commitment

**A/B Test if Resistance:**
- Try $3.99/week (still under $4 psychology)
- Extend trials (5-day weekly, 14-day monthly)
- But start with current pricing - it's validated

### Usage Monitoring & Fair Use

**Free Tier (3 Lifetime):**
- Total count stored in SharedPreferences
- Never resets - once used, gone forever
- Max cost per free user: $0.00012

**Pro Tier (500/month):**
- Monthly count resets on 1st of month
- Prevents bot abuse / scraping
- 500/month far exceeds real usage (5-10 cards typical)

**Usage Tracking Implementation:**

| Data | Storage | Reset |
|------|---------|-------|
| Total count (free) | Local (SharedPreferences) | Never |
| Monthly count (Pro) | Local (SharedPreferences) | 1st of month |
| Subscription status | RevenueCat (server) | Real-time |

**Flow:**
```
User taps "Generate"
    ↓
Check subscription status (RevenueCat)
    ↓
If Free:
    - Check total count < 3
    - If exceeded → Show paywall
    ↓
If Pro:
    - Check monthly count < 500
    - If exceeded → Show "Fair use limit reached" message
    ↓
Generate message
    ↓
Increment counters
```

**Cost Protection Math:**
```
Free user max cost:
- 3 generations × $0.00004 = $0.00012 per user EVER
- 10,000 free users = $1.20 total

Pro user at max usage:
- 500 generations/month × $0.00004 = $0.02/month API cost
- Revenue: $4.99/month
- Margin: $4.97 (99.6% gross margin)
```

### Key Insights from Competition

1. **Most focus on CARD DESIGN, not MESSAGE QUALITY**
   - Apps generate pretty images but messages are afterthought
   - Our USP: Message-first, not design-first

2. **Pricing is all over the place**
   - Free web tools exist but lack mobile experience
   - $19.99/mo apps are clearly overpriced
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

## Tech Stack (Cutting-Edge 2025)

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Frontend** | Flutter | 3.38+ | Cross-platform (iOS, Android, Web) |
| **Language** | Dart | 3.6+ | Null safety, records, patterns |
| **State Management** | Riverpod | 3.0+ | Compile-time safety, no BuildContext dependency |
| **Navigation** | go_router | 17.0+ | Declarative routing, deep links |
| **AI** | google_generative_ai | 0.4.7+ | Direct Gemini 2.0 Flash API |
| **Payments** | RevenueCat | 6.0+ | Cross-platform subscriptions |
| **Analytics** | Firebase Analytics | 10.7+ | Events, funnels, retention |
| **Crashes** | Firebase Crashlytics | 3.4+ | Error tracking, diagnostics |
| **Local Storage** | shared_preferences | 2.2+ | Usage tracking, settings |
| **HTTP** | dio | 5.4+ | API calls with interceptors |
| **Animations** | flutter_animate | 4.3+ | Declarative animations |

### Platform Distribution

| Platform | Store | Status |
|----------|-------|--------|
| iOS | Apple App Store | Primary launch |
| Android | Google Play Store | Primary launch |
| Web | N/A | Not planned |

### Key Flutter Packages (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management (Riverpod 3.0 - cutting edge)
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

  # Navigation
  go_router: ^17.0.0

  # AI - Direct Gemini API (no backend needed!)
  google_generative_ai: ^0.4.7

  # Payments
  purchases_flutter: ^6.0.0

  # Firebase
  firebase_core: ^2.24.0
  firebase_analytics: ^10.7.0
  firebase_crashlytics: ^3.4.0

  # UI
  google_fonts: ^6.1.0
  flutter_animate: ^4.3.0
  gap: ^3.0.0                    # Spacing widget

  # Utils
  shared_preferences: ^2.2.0
  flutter_dotenv: ^5.1.0
  dio: ^5.4.0
  envied: ^0.5.0                 # Compile-time env vars (secure)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  riverpod_generator: ^3.0.0     # Code generation for Riverpod
  build_runner: ^2.4.0
  envied_generator: ^0.5.0
```

### API Cost Estimate
- ~500 tokens per message generation (3 options)
- **Gemini 2.0 Flash: $0.08 per 1M tokens**
- Cost per generation: ~$0.00004
- **10,000 generations = $0.40**
- Extremely sustainable at scale

### Why This Stack?

| Choice | Rationale |
|--------|-----------|
| **Flutter 3.38+** | Latest stable, dot shorthands, performance improvements |
| **Riverpod 3.0** | Cutting-edge state management, compile-time safety, code generation |
| **go_router** | Official Flutter team router, deep linking, type-safe |
| **Direct Gemini API** | No backend needed for MVP, $0.08/1M tokens, official Google package |
| **RevenueCat** | Handles iOS + Android + Web, no server needed |
| **Firebase** | Free analytics/crashlytics, reuse PawNova account |
| **envied** | Compile-time env vars (more secure than flutter_dotenv) |

### Why NOT Supabase for MVP?

- MVP doesn't need auth or cloud database
- Direct Gemini API works fine for text generation
- Local storage (SharedPreferences) sufficient for usage tracking
- **Add Supabase in V1.1** when we add user accounts + history

---

## V1.1: Authentication & Account Linking (Post-MVP)

### Sign-In Methods (Same as PawNova)

| Method | Provider | Package |
|--------|----------|---------|
| **Apple Sign In** | Supabase Auth | supabase_flutter |
| **Google Sign In** | Supabase Auth | supabase_flutter + google_sign_in |
| **Email/Password** | Supabase Auth | supabase_flutter |

### Account Linking Flow

```
User starts as anonymous (MVP)
    ↓
User wants to save history / sync devices
    ↓
Prompt: "Sign in to save your messages"
    ↓
User signs in with Apple/Google/Email
    ↓
If email already linked to different provider:
    - "This email is linked to [Google]. Sign in with Google to continue."
    ↓
If new account:
    - Create account, migrate local data to cloud
    ↓
If existing account:
    - Merge local data with cloud data
```

### Account Linking Rules

| Scenario | Behavior |
|----------|----------|
| New user signs in with Apple | Create account with Apple ID |
| Same user signs in with Google (same email) | Link Google to existing account |
| User tries Email with existing Apple email | Prompt to sign in with Apple first, then link |
| User on new device signs in | Pull history from cloud |

### Supabase Auth Config (V1.1)

```sql
-- Enable providers in Supabase Dashboard:
-- 1. Apple (requires Apple Developer account)
-- 2. Google (requires GCP OAuth credentials)
-- 3. Email (built-in, no external config)

-- User profiles table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  email TEXT,
  display_name TEXT,
  avatar_url TEXT,
  subscription_tier TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message history table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  occasion TEXT NOT NULL,
  relationship TEXT NOT NULL,
  tone TEXT NOT NULL,
  details TEXT,
  generated_messages JSONB NOT NULL,
  selected_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can read own messages"
  ON messages FOR SELECT USING (auth.uid() = user_id);
```

### Why Same as PawNova?

- Proven pattern that works
- Users expect Apple/Google sign-in on mobile
- Email fallback for users without Apple/Google
- Account linking prevents duplicate accounts
- Supabase handles all the complexity

---

## Architecture: Atomic Design + Feature-First

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp + ProviderScope
│   └── router.dart                 # go_router configuration
│
├── features/                       # Feature-first organization
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       └── occasion_grid.dart
│   ├── generate/
│   │   ├── generate_screen.dart
│   │   ├── generate_provider.dart  # Riverpod provider
│   │   └── widgets/
│   │       ├── relationship_picker.dart
│   │       ├── tone_selector.dart
│   │       └── details_input.dart
│   ├── results/
│   │   ├── results_screen.dart
│   │   └── widgets/
│   │       └── message_card.dart
│   ├── paywall/
│   │   └── paywall_screen.dart
│   └── settings/
│       └── settings_screen.dart
│
├── core/
│   ├── services/
│   │   ├── ai_service.dart         # Gemini API wrapper
│   │   ├── subscription_service.dart
│   │   └── analytics_service.dart
│   ├── models/
│   │   ├── occasion.dart
│   │   ├── relationship.dart
│   │   ├── tone.dart
│   │   └── generated_message.dart
│   └── providers/
│       └── usage_provider.dart     # Daily limit tracking
│
└── shared/
    ├── atoms/                      # Atomic Design: smallest units
    │   ├── app_button.dart
    │   ├── app_text.dart
    │   ├── app_icon.dart
    │   └── app_card.dart
    ├── molecules/                  # Atomic Design: combinations
    │   ├── icon_label.dart
    │   ├── selection_chip.dart
    │   └── loading_indicator.dart
    ├── organisms/                  # Atomic Design: complex components
    │   ├── occasion_tile.dart
    │   ├── message_option.dart
    │   └── paywall_card.dart
    ├── templates/                  # Atomic Design: page layouts
    │   ├── base_screen.dart
    │   └── scrollable_screen.dart
    ├── theme/
    │   ├── app_colors.dart
    │   ├── app_typography.dart
    │   ├── app_spacing.dart
    │   └── app_theme.dart
    └── extensions/
        ├── context_extensions.dart
        └── string_extensions.dart
```

### Atomic Design Hierarchy

| Level | Description | Examples |
|-------|-------------|----------|
| **Atoms** | Basic UI building blocks, single purpose | `AppButton`, `AppText`, `AppIcon`, `AppCard` |
| **Molecules** | Simple combinations of atoms | `IconLabel`, `SelectionChip`, `LoadingIndicator` |
| **Organisms** | Complex, reusable components | `OccasionTile`, `MessageOption`, `PaywallCard` |
| **Templates** | Page layouts, no business logic | `BaseScreen`, `ScrollableScreen` |
| **Pages/Screens** | Full screens with business logic | `HomeScreen`, `ResultsScreen` |

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
