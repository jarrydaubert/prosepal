# Improvement Backlog

> Tracked enhancements, refactors, and future work.

---

## 0. Recently Completed (Dec 2025)

### 0.1 UI Modernization (2025 Trends) ✅

| Screen | Improvements |
|--------|--------------|
| **AuthScreen** | Glassmorphism logo, gradient background, scale animations, official Google branding assets |
| **OnboardingScreen** | Linear progress bar, glassmorphism emoji containers, haptic feedback, animated CTA button |
| **SettingsScreen** | Modern card-based account header, Pro badge with glow, subtle gray background |
| **HomeScreen** | Subtle gradient background, refined typography |

### 0.2 UX Improvements ✅

| Feature | Files Modified |
|---------|----------------|
| Keyboard dismiss on tap outside | `email_auth_screen.dart`, `feedback_screen.dart`, `details_input.dart` |
| Password sign-in for Apple Review | `email_auth_screen.dart` |

### 0.3 Test Coverage ✅

| Addition | Details |
|----------|---------|
| `settings_screen_test.dart` | 26 comprehensive widget tests |
| Model test consolidation | Deleted duplicate test files |
| CI coverage reporting | Added to GitHub Actions |
| E2E subscription tests | 29 tests for subscription flows |
| E2E user journey tests | Complete user flow testing |
| Integration tests | 12 tests on iOS simulator |

### 0.4 Supabase v2 Upgrade Check ✅

**Current version:** `supabase_flutter: ^2.12.0` - Already on v2!

| Breaking Change | Status | Notes |
|-----------------|--------|-------|
| `Provider` → `OAuthProvider` | ✅ Already using | Using `OAuthProvider.apple`, `OAuthProvider.google` |
| `signInWithApple()` deprecated | ✅ Handled | Using `sign_in_with_apple` package directly |
| PKCE default auth flow | ✅ N/A | Using native OAuth, not deep-link flows |
| `is_` → `isFilter`, `in_` → `inFilter` | ✅ N/A | No PostgREST queries in app (auth-only usage) |
| `.on()` → `.onPostgresChanges()` | ✅ N/A | No Realtime subscriptions used |
| Session refresh not awaited | ✅ Handled | App checks session validity appropriately |
| `webview_flutter` removed | ✅ N/A | Using native sign-in SDKs |

**Conclusion:** No migration needed. App is already v2 compliant.

### 0.5 Brand System Unification ✅

**Simplified 3-color palette for consistency:**

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Coral | `#E57373` | CTAs, links, selection states, brand identity |
| **Text** | Charcoal | `#2D3436` | All text for maximum readability |
| **Background** | Warm White | `#FAFAFA` | Clean, warm canvas |

**WCAG AA Contrast Compliance:**
- textPrimary on background: 12.6:1 ✓
- textSecondary on background: 4.6:1 ✓

**Changes Made:**
- Removed 10+ individual occasion colors → unified primary with opacity
- Single brand gradient throughout onboarding (no more color chaos)
- Occasion cards now use `occasionBackground(index)` and `occasionBorder(index)`
- Legacy colors marked `@Deprecated` for gradual migration

### 0.6 Onboarding Reduction (4 → 3 pages) ✅

| Before | After |
|--------|-------|
| Page 1: Welcome | Page 1: "Stuck on What to Write?" (pain point) |
| Page 2: Features | Page 2: "AI-Crafted Messages" (solution) |
| Page 3: Personalization | Page 3: "Try 3 Free Messages" (value) |
| Page 4: Get Started | *(merged into Page 3)* |

### 0.7 Launch Checklist ✅

Added `docs/LAUNCH_CHECKLIST.md` based on RevenueCat best practices covering:
- RevenueCat configuration verification
- Sandbox testing procedures
- User identity testing
- App Store submission requirements

---

## 1. Onboarding Improvements

**Status:** ✅ COMPLETED

**What was done:**
- Reduced from 4 pages to 3 (more concise, value-focused)
- Unified brand gradient throughout (single coral theme)
- Glassmorphism emoji containers with BackdropFilter
- Haptic feedback on interactions
- Animated CTA button with scale effect

### 1.1 Page Reduction (4 → 3) ✅

| Before | After |
|--------|-------|
| Page 1: Welcome | Page 1: "Stuck on What to Write?" (pain point) |
| Page 2: Features | Page 2: "AI-Crafted Messages" (solution) |
| Page 3: Personalization | Page 3: "Try 3 Free Messages" (value) |
| Page 4: Get Started | *(merged into Page 3)* |

### 1.2 Visual Upgrades ✅

| Enhancement | Status | Notes |
|-------------|--------|-------|
| ~~Lottie animations~~ | ❌ Skipped | Decided to keep emojis for simplicity |
| Glassmorphism | ✅ Done | BackdropFilter on emoji containers |
| Animated gradients | ✅ Done | Single brand gradient, AnimatedContainer |
| ~~Parallax on swipe~~ | ❌ Skipped | Not needed with simplified design |
| Morphing indicators | ✅ Done | Animated dot width on page change |

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

## 10. SettingsScreen Improvements

**Status:** Current implementation is solid and production-ready. These are polish items.

### 10.1 DI Refactoring (Required for Testing)

**Problem:** Screen uses `BiometricService.instance` singleton and `ref.read(subscriptionServiceProvider)` directly, making widget tests fail.

**Solution:**
```dart
// Before
final supported = await BiometricService.instance.isSupported;

// After - inject via provider
final biometricService = ref.watch(biometricServiceProvider);
final supported = await biometricService.isSupported;
```

| File | Changes |
|------|---------|
| `lib/core/providers/providers.dart` | Add `biometricServiceProvider` |
| `lib/features/settings/settings_screen.dart` | Use providers instead of singletons |
| `test/widgets/screens/settings_screen_test.dart` | Create with mocked providers |

### 10.2 Visual Polish

| Enhancement | Description | Priority |
|-------------|-------------|----------|
| Micro-animations | Fade/scale on tile taps | P3 |
| Glassmorphism headers | Blurred section backgrounds | P4 |
| Dynamic theming | Light/dark/system toggle | P3 |

### 10.3 Accessibility

| Improvement | Current | Target |
|-------------|---------|--------|
| Semantics | Rating tile only | All interactive elements |
| VoiceOver | Partial | Full support with state announcements |
| Contrast | Standard | Verify WCAG AA compliance |

### 10.4 Missing Features

| Feature | Status | Priority |
|---------|--------|----------|
| Help & FAQ navigation | `// TODO` | P2 |
| App Store ID for reviews | Empty string | P2 |
| Loading states for async | Basic spinner | P3 |

### 10.5 Files to Modify

| File | Changes |
|------|---------|
| `lib/features/settings/settings_screen.dart` | DI, accessibility, polish |
| `lib/core/providers/providers.dart` | Add biometric provider |
| `lib/core/services/biometric_service.dart` | Remove singleton, add interface |

---

## Priority Matrix

| Priority | Item | Effort | Impact | Status |
|----------|------|--------|--------|--------|
| ~~P0~~ | ~~Firebase AI migration~~ | ~~High~~ | ~~High~~ | ✅ **DONE** |
| ~~P0~~ | ~~Supabase v2 upgrade check~~ | ~~Low~~ | ~~High~~ | ✅ **DONE** (already compliant) |
| ~~P1~~ | ~~UI Modernization (Auth, Onboarding, Settings, Home)~~ | ~~High~~ | ~~High~~ | ✅ **DONE** |
| ~~P1~~ | ~~Create settings_screen_test.dart~~ | ~~Medium~~ | ~~Medium~~ | ✅ **DONE** (26 tests) |
| ~~P2~~ | ~~Model test consolidation~~ | ~~Low~~ | ~~Low~~ | ✅ **DONE** |
| **P0** | **RevenueCat offerings empty** | Low | **BLOCKER** | ❌ Dashboard config needed |
| **P0** | **Test on real device** | Low | **BLOCKER** | ❌ Apple Sign In, paywall |
| **P0** | **App Store ID for reviews** | Low | **BLOCKER** | ❌ Add after app is live |
| P1 | Run integration tests on device | Medium | High | ❌ Pending |
| ~~P2~~ | ~~Onboarding page reduction (4→3)~~ | ~~Medium~~ | ~~Medium~~ | ✅ **DONE** |
| ~~P2~~ | ~~Brand system unification~~ | ~~Medium~~ | ~~High~~ | ✅ **DONE** |
| ~~P2~~ | ~~E2E subscription tests~~ | ~~Medium~~ | ~~High~~ | ✅ **DONE** (29 tests) |
| P1 | Fix 674 lint suggestions | Medium | Medium | ❌ Pending |
| P3 | Subscription mock enhancements | Medium | Low | ❌ Pending |
| ~~P3~~ | ~~Lottie animations~~ | ~~Medium~~ | ~~Medium~~ | ❌ Skipped (keeping emojis) |
| P4 | Performance optimizations | Medium | Medium | ❌ Pending |
| P4 | Dark mode support | High | Medium | ❌ Pending |

---

## 🔴 Release Blockers

| Item | Action Required |
|------|-----------------|
| **RevenueCat offerings empty** | Go to https://app.revenuecat.com → Products → Offerings → Add packages to 'default' |
| **Test on real device** | Connect device, run `flutter run`, test Apple Sign In + paywall |
| **App Store ID for reviews** | Add to `_rateApp()` in settings_screen.dart after app goes live |

---

## Notes

- ✅ **Firebase AI migration COMPLETED** - now using firebase_ai 3.6.1
- ✅ **Supabase v2 COMPLIANT** - already using 2.12.0 with correct patterns
- ✅ **UI Modernization COMPLETED** - 2025 trends applied to all major screens
- ✅ **Brand System UNIFIED** - 3-color palette, WCAG AA contrast compliant
- ✅ **Onboarding REDUCED** - 4 pages → 3 pages, value-focused
- ✅ **Test coverage improved** - 554 unit/widget + 41 integration/E2E tests
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
