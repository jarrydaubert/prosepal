# Improvement Backlog

> What's left to do. Completed items are removed.

---

## 🔴 Release Blockers

| Item | Action Required |
|------|-----------------|
| **App Store ID for reviews** | Add to `_rateApp()` in settings_screen.dart after app goes live |

---

## Priority Matrix

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| **P0** | **App Store ID for reviews** | Low | Post-approval |
| P1 | Bold styling refactor (paywall remaining) | Low | High |
| P2 | GenUI SDK exploration | Medium | High |
| P4 | Dark mode support | High | Medium |

---

## 1. Bold Styling Refactor

**Status:** Nearly Complete (Jan 2026)

### Completed Screens
- onboarding_screen.dart
- auth_screen.dart
- email_auth_screen.dart
- home_screen.dart + occasion_grid.dart + usage_indicator.dart
- generate_screen.dart + relationship_picker.dart + tone_selector.dart + details_input.dart
- results_screen.dart
- settings_screen.dart

### Remaining
- paywall_screen.dart

### Pattern Established
- **Borders**: 2-3px primary color, no shadows/glassmorphism
- **Animations**: ValueKey for proper re-triggering
- **Text**: Direct TextStyle (not Theme.of(context))
- **Feedback**: HapticFeedback.lightImpact() on press
- **Structure**: Components at bottom with `// === COMPONENTS ===` header
- **Padding**: 20px horizontal consistently

---

## 2. GenUI SDK for Flutter

**Priority:** P2 - Research

**What**: Runtime dynamic UI generation using AI
**Use Case**: Let users customize message card designs at runtime with AI-generated layouts

### Research Notes
- Look into Flutter GenUI SDK for implementation
- Use AI Studio for rapid UI prototyping with Prosepal-themed prompts
- Extract reusable widgets from generated code

### Software 3.0 Concepts (Karpathy, Y Combinator 2025)
- LLMs as "operating system" for software creation
- Shift from traditional coding to prompt engineering
- Human-in-the-loop oversight for generated code

---

## 3. Dark Mode Support

**Priority:** P4

**Scope:**
- Add dark theme to `app_theme.dart`
- System/manual toggle in settings
- Test all screens in dark mode

---

## 4. Future App Ideas (Post-Prosepal)

### AI Content Generator (Jasper.ai Clone)
- **Target**: $10M+ MRR company
- **Feature**: Mobile app for messages, captions, marketing copy
- **Builds on**: Prosepal's greeting card AI expertise
- **Stack**: Flutter + Claude Opus + Supabase + Riverpod

### FAQ/Knowledge Base Generator (Intercom/Notion Clone)
- **Feature**: Auto-generate FAQs from chat logs/reviews
- **Use Case**: Business response libraries

### AI Audio Message Creator (Descript Clone)
- **Feature**: Text-to-audio voiceovers, audiograms
- **Extends**: Prosepal to multimedia greeting cards

---

## 5. App Store Optimization (ASO) Metadata

> Use when submitting to App Store Connect.

### App Store (iOS)

**App Name (30 chars max):**
```
Prosepal - Card Message Writer
```

**Subtitle (30 chars max):**
```
AI Birthday & Thank You Notes
```

**Keywords (100 chars):**
```
greeting card writer,thank you note,wedding message,sympathy card,get well,anniversary,graduation
```

**Description:**
```
Stuck staring at a blank card? Prosepal helps you write the perfect message in seconds.

WHETHER IT'S A BIRTHDAY, WEDDING, OR SYMPATHY CARD
Tell us the occasion, your relationship, and the tone you want. Our AI generates 3 unique, heartfelt messages tailored just for you.

PERFECT FOR:
• Birthday cards - from funny to heartfelt
• Thank you notes - genuine appreciation made easy  
• Wedding & anniversary messages
• Sympathy & get well cards
• Graduation, retirement, new baby
• Any occasion where words matter

HOW IT WORKS:
1. Choose the occasion
2. Select your relationship (friend, parent, colleague)
3. Pick a tone (warm, funny, formal)
4. Get 3 AI-generated messages instantly
5. Copy your favorite and you're done!

TRY FREE:
• 3 free message generations
• No account required to start
• Upgrade anytime for unlimited access

PRIVACY FIRST:
• Messages generated on-demand, not stored
• Your data is never sold or shared
• Delete your account anytime

Download now and never struggle with "what to write" again.
```

### Screenshot Captions (6 recommended)

1. "The right words, right now"
2. "Birthday, wedding, sympathy & more"
3. "Tailored to your relationship"
4. "3 unique messages in seconds"
5. "Funny, warm, or formal"
6. "Standing in the card aisle? We've got you"

### Category & Age Rating

- **Primary Category:** Utilities
- **Secondary Category:** Lifestyle
- **Age Rating:** 4+

---

## 6. Code Quality Improvements

### BiometricService Dependency Injection
- Singleton pattern limits full test isolation
- Add injectable constructor for `LocalAuthentication` and `SharedPreferences`
- Would enable pure unit testing without global overrides
