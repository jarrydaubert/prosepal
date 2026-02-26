# Improvement Backlog

> What's left to do. Completed items are removed.

---

## 🔴 Release Blockers

| Item | Action Required |
|------|-----------------|
| **RevenueCat offerings empty** | Go to https://app.revenuecat.com → Products → Offerings → Add packages to 'default' |
| **Test on real device** | Connect device, run `flutter run`, test Apple Sign In + paywall |
| **App Store ID for reviews** | Add to `_rateApp()` in settings_screen.dart after app goes live |

---

## Priority Matrix

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| **P0** | **RevenueCat offerings config** | Low | BLOCKER |
| **P0** | **Real device testing** | Low | BLOCKER |
| **P0** | **App Store ID for reviews** | Low | BLOCKER |
| P4 | Dark mode support | High | Medium |

---

## 1. Dark Mode Support

**Priority:** P4

**Scope:**
- Add dark theme to `app_theme.dart`
- System/manual toggle in settings
- Test all screens in dark mode

---

## 2. App Store Optimization (ASO) Metadata

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

## 3. Code Quality Improvements

### BiometricService Dependency Injection
- Singleton pattern limits full test isolation
- Add injectable constructor for `LocalAuthentication` and `SharedPreferences`
- Would enable pure unit testing without global overrides
