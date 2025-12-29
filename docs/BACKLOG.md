# Improvement Backlog

> Tracked enhancements, refactors, and future work.

---

## 1. Onboarding Improvements

**Current:** 4-page PageView with emoji icons, gradient backgrounds, flutter_animate

**Target:** Modern 2025 onboarding - shorter, value-first, immersive

### 1.1 Page Reduction (4 → 3)

| Current | Proposed |
|---------|----------|
| Page 1: Welcome | Page 1: Pain point - "Struggling with the right words?" |
| Page 2: Feature overview | Page 2: Solution - "AI-crafted messages in seconds" |
| Page 3: Personalization | Page 3: Instant value - Quick input + "Try It Now" |
| Page 4: Get started | (merged into Page 3) |

### 1.2 Visual Upgrades

| Enhancement | Description | Package/Approach |
|-------------|-------------|------------------|
| Lottie animations | Replace emoji with animated illustrations | `lottie` |
| Glassmorphism | Frosted blur effects on cards | `BackdropFilter` |
| Animated gradients | Slow-shifting background colors | `AnimatedContainer` or shaders |
| Parallax on swipe | Depth effect between layers | Custom `PageView` transform |
| Morphing indicators | Animated dot shapes | Custom `AnimatedContainer` |

### 1.3 Instant Value Demo

**Concept:** Show AI magic before sign-up

```
Page 3:
┌─────────────────────────────────┐
│  Ready to write something       │
│  heartfelt?                     │
│                                 │
│  [Occasion dropdown: Birthday]  │
│                                 │
│  ┌─────────────────────────┐   │
│  │  "Generate Sample" 🎉   │   │
│  └─────────────────────────┘   │
│                                 │
│  ↓ Sample message appears ↓     │
│                                 │
│  "Happy birthday! Wishing you   │
│   a year filled with joy..."    │
│                                 │
│  ┌─────────────────────────┐   │
│  │  "Get Started" →        │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

### 1.4 Micro-interactions

| Interaction | Trigger | Effect |
|-------------|---------|--------|
| Haptic feedback | Swipe/next | Light impact |
| Particle burst | Final CTA tap | Confetti/sparkles |
| Scale animation | Button press | 0.95 → 1.0 spring |

### 1.5 Files to Modify

| File | Changes |
|------|---------|
| `lib/features/onboarding/onboarding_screen.dart` | Page reduction, layout |
| `lib/features/onboarding/pages/` | New page content |
| `pubspec.yaml` | Add `lottie` if not present |
| `assets/animations/` | Lottie JSON files |

---

## 2. Subscription Mock Enhancements

**Current:** Basic mock with `setIsPro()` and simple booleans

**Target:** Rich mock with fake RevenueCat types for detailed assertions

### 2.1 Fake Offerings

```dart
class FakeOffering {
  final String identifier;
  final List<FakePackage> availablePackages;
  
  FakeOffering({
    this.identifier = 'default',
    this.availablePackages = const [],
  });
}

class FakePackage {
  final String identifier;
  final String productId;
  final double price;
  final String priceString;
  final PackageType packageType;
  
  // Constructor with sensible defaults for weekly/monthly/yearly
}
```

### 2.2 Fake CustomerInfo

```dart
class FakeCustomerInfo {
  final Map<String, FakeEntitlementInfo> entitlements;
  final List<String> activeSubscriptions;
  final String? originalAppUserId;
  
  bool get isPro => entitlements['pro']?.isActive ?? false;
}

class FakeEntitlementInfo {
  final bool isActive;
  final DateTime? expirationDate;
  final String? productIdentifier;
}
```

### 2.3 RevenueCat Error Simulation

```dart
enum MockPurchaseError {
  cancelled,
  networkError,
  storeProblem,
  purchaseNotAllowed,
  purchaseInvalid,
  productNotAvailable,
}

// Usage in tests:
subscriptionService.errorToThrow = MockPurchaseError.cancelled;
```

### 2.4 Files to Modify

| File | Changes |
|------|---------|
| `test/mocks/mock_subscription_service.dart` | Add fake types |
| `test/services/subscription_service_with_mock_test.dart` | Use fake types in assertions |

---

## 3. Test Cleanup

### 3.1 Model Test Consolidation

**Current:** 5 files with duplication

| Action | Files |
|--------|-------|
| Keep | `models_test.dart` (comprehensive) |
| Delete | `occasion_test.dart`, `relationship_test.dart`, `tone_test.dart`, `message_length_test.dart` |

### 3.2 Unused Test Removal

| File | Reason | Action |
|------|--------|--------|
| `supabase_endpoints_test.dart` | Tests DB ops, app uses auth only | Delete |

### 3.3 Missing Widget Tests

| Screen | Priority |
|--------|----------|
| `results_screen_test.dart` | P2 |
| `settings_screen_test.dart` | P2 |
| `paywall_screen_test.dart` | P2 |
| `auth_screen_test.dart` | P2 |

---

## 4. CI/CD Improvements

**Current:** `.github/workflows/ci.yml`
- Linux: Analyze, test, format (~2 min)
- macOS: iOS build (main only, ~80 min billed)
- Linux: Android build (main only, ~5 min)

**Budget:** 2,000 mins/month free tier. See `.github/BUDGET.md`

### 4.1 Coverage Threshold

```yaml
# Add to analyze job in .github/workflows/ci.yml
- name: Run tests with coverage threshold
  run: flutter test --coverage --min-coverage=70
```

### 4.2 Integration Test Step (Optional)

```yaml
# Add new job - expensive (macOS = 10x), only run on main
integration-tests:
  name: Integration Tests
  runs-on: macos-latest
  timeout-minutes: 20
  needs: analyze
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.38.5'
        cache: true
    - run: flutter pub get
    - name: Boot iOS Simulator
      run: |
        xcrun simctl boot "iPhone 15 Pro" || true
        xcrun simctl list devices booted
    - name: Run integration tests
      run: flutter test integration_test/
```

**Warning:** This adds ~10 min macOS = 100 billed minutes per push to main.

---

## 5. Performance

### 5.1 Lazy Loading

| Screen | Optimization |
|--------|--------------|
| Home | Lazy load occasion cards below fold |
| Settings | Lazy load sections |
| Results | Virtualize message list if > 10 |

### 5.2 Image Optimization

| Asset | Current | Target |
|-------|---------|--------|
| Onboarding images | PNG | WebP or Lottie |
| App icon | Standard | Adaptive icon (Android) |

---

---

## 6. Firebase AI Migration (COMPLETED)

**Status:** ✅ COMPLETED - Dec 2025

**Before:** `google_generative_ai: ^0.4.7` (DEPRECATED)

**After:** `firebase_ai: ^3.6.1` (Firebase AI Logic SDK)

### 6.1 Benefits Achieved

| Improvement | Details |
|-------------|---------|
| No exposed API key | Firebase handles auth server-side |
| Spark plan compatible | Works on free tier |
| Firebase ecosystem | App Check, analytics ready |
| Modern API | Uses Gemini 2.5 Flash model |

### 6.2 Changes Made

- ✅ Replaced `google_generative_ai` with `firebase_ai` in pubspec.yaml
- ✅ Updated `ai_service.dart` to use `FirebaseAI.googleAI()` pattern
- ✅ Removed `GEMINI_API_KEY` dart-define requirement
- ✅ Updated `SafetySetting` to new 3-param constructor
- ✅ Updated all tests to remove old API references
- ✅ All 726 tests passing

### 6.3 Setup Required (Firebase Console)

1. Go to Firebase Console > AI Logic
2. Click "Get Started"
3. Select "Gemini Developer API" (free tier)
4. API key is managed server-side automatically

---

## 7. Code Quality Cleanup

**Status:** 674 info-level lint suggestions

### 7.1 Categories

| Category | Count (approx) | Example |
|----------|----------------|---------|
| `prefer_const_constructors` | ~200 | Add `const` to widget constructors |
| `avoid_catches_without_on_clauses` | ~30 | Specify exception types in catch |
| `unnecessary_await_in_return` | ~15 | Remove redundant await |
| `cascade_invocations` | ~10 | Use `..` cascade operator |
| `omit_local_variable_types` | ~10 | Use `var` or `final` instead |
| Other style rules | ~400 | Various minor improvements |

### 7.2 Approach

Fix incrementally by file/feature area rather than all at once.

---

## 8. Test Improvements

### 8.1 Pre-existing Test Failure

One test in `generate_screen_test.dart` fails due to widget off-screen in test environment. Not a real bug - test viewport issue.

### 8.2 AI Integration Tests

Post-Firebase migration, add integration tests using Firebase emulator for:
- Message generation flow
- Error handling (rate limits, content blocked)
- Streaming responses

### 8.3 Crashlytics Mock

Add basic Firebase Crashlytics initialization mock for improved test coverage.

---

## Priority Matrix

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| ~~P0~~ | ~~Firebase AI migration~~ | ~~High~~ | ✅ **DONE** |
| P1 | Run integration tests on device | Low | High |
| P1 | Fix 674 lint suggestions | Medium | Medium |
| P2 | Create missing widget tests | Medium | Medium |
| P2 | Onboarding improvements | High | High |
| P3 | Model test consolidation | Low | Low |
| P3 | Subscription mock enhancements | Medium | Low |
| P3 | CI coverage threshold | Low | Medium |
| P4 | Performance optimizations | Medium | Medium |

---

## Notes

- ✅ **Firebase AI migration COMPLETED** - now using firebase_ai 3.6.1
- Onboarding changes are UX polish, not blocking release
- Subscription mock enhancements improve test quality but current tests are sufficient
- Model test duplication doesn't break anything, just adds noise
- 674 lint issues are info-level (suggestions), not errors

---

## 9. App Store Optimization (ASO) Metadata

> Use when submitting to App Store Connect and Google Play Console.

### 9.1 App Store (iOS)

**App Name (30 chars max):**
```
Prosepal - Card Message Writer
```

**Subtitle (30 chars max):**
```
AI Birthday & Thank You Notes
```

**Keywords (100 chars, comma-separated):**
```
greeting card writer,thank you note,wedding message,sympathy card,get well,anniversary,graduation
```

**Promotional Text (170 chars, update anytime):**
```
Perfect for the holidays! Generate heartfelt messages for Christmas cards, New Year wishes, and more. 3 free messages to try.
```

**Description (4000 chars max):**
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

STANDING IN THE CARD AISLE?
No problem. Get beautiful, personalized messages in under 30 seconds. No more writer's block.

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

**What's New (for updates):**
```
• Improved message quality with latest AI
• Faster generation times
• Bug fixes and performance improvements
```

### 9.2 Google Play (Android)

**Title (50 chars max):**
```
Prosepal - AI Card Message Writer
```

**Short Description (80 chars):**
```
Write perfect greeting card messages. Birthday, thank you, wedding & more.
```

**Full Description:** Same as iOS description above.

### 9.3 Keywords to Target

**High Intent:**
- "what to write in a birthday card"
- "thank you note generator"
- "sympathy card message ideas"
- "wedding card message"
- "get well soon message"

**Solution Aware:**
- "greeting card writer"
- "AI message generator"
- "card message helper"

### 9.4 Screenshot Captions (6 recommended)

1. **Hero** - "The right words, right now"
2. **Occasions** - "Birthday, wedding, sympathy & more"
3. **Personalization** - "Tailored to your relationship"
4. **Results** - "3 unique messages in seconds"
5. **Tones** - "Funny, warm, or formal"
6. **Quick** - "Standing in the card aisle? We've got you"

### 9.5 App Preview Video (15-30 sec)

1. Show blank card problem (2s)
2. Open app, select occasion (3s)
3. Choose relationship & tone (3s)
4. Tap generate (2s)
5. Show 3 results appearing (4s)
6. Copy message (2s)
7. End card: "Prosepal - The right words, right now" (2s)

### 9.6 Category & Age Rating

- **Primary Category:** Utilities
- **Secondary Category:** Lifestyle
- **Age Rating:** 4+ (no objectionable content)

### 9.7 Localization Priority

1. English (US) - Primary
2. English (UK) - Minor spelling differences
3. Spanish - Future
4. French - Future
5. German - Future
