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

## Priority Matrix

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| P1 | Run integration tests on device | Low | High |
| P2 | Create missing widget tests | Medium | Medium |
| P2 | Onboarding improvements | High | High |
| P3 | Model test consolidation | Low | Low |
| P3 | Subscription mock enhancements | Medium | Low |
| P3 | CI coverage threshold | Low | Medium |
| P4 | Performance optimizations | Medium | Medium |

---

## Notes

- Onboarding changes are UX polish, not blocking release
- Subscription mock enhancements improve test quality but current tests are sufficient
- Model test duplication doesn't break anything, just adds noise
