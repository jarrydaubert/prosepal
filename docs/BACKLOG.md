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
| P1 | Fix 674 lint suggestions | Medium | Medium |
| P3 | Subscription mock enhancements | Medium | Low |
| P4 | Performance optimizations | Medium | Medium |
| P4 | Dark mode support | High | Medium |

---

## 1. Subscription Mock Enhancements

**Current:** Basic mock with `setIsPro()` and simple booleans

**Target:** Rich mock with fake RevenueCat types for detailed assertions

### Fake Offerings

```dart
class FakeOffering {
  final String identifier;
  final List<FakePackage> availablePackages;
}

class FakePackage {
  final String identifier;
  final String productId;
  final double price;
  final String priceString;
  final PackageType packageType;
}
```

### Files to Modify

| File | Changes |
|------|---------|
| `test/mocks/mock_subscription_service.dart` | Add fake types |
| `test/services/subscription_service_with_mock_test.dart` | Use fake types |

---

## 2. Code Quality Cleanup

**Status:** 674 info-level lint suggestions

| Category | Count (approx) | Example |
|----------|----------------|---------|
| `prefer_const_constructors` | ~200 | Add `const` to widget constructors |
| `avoid_catches_without_on_clauses` | ~30 | Specify exception types in catch |
| `unnecessary_await_in_return` | ~15 | Remove redundant await |
| `cascade_invocations` | ~10 | Use `..` cascade operator |
| Other style rules | ~400 | Various minor improvements |

**Approach:** Fix incrementally by file/feature area.

---

## 3. Performance Optimizations

### Lazy Loading

| Screen | Optimization |
|--------|--------------|
| Home | Lazy load occasion cards below fold |
| Settings | Lazy load sections |
| Results | Virtualize message list if > 10 |

### Image Optimization

| Asset | Current | Target |
|-------|---------|--------|
| App icon | Standard | Adaptive icon (Android) |

---

## 4. SettingsScreen Polish

### Missing Features

| Feature | Priority |
|---------|----------|
| Help & FAQ navigation | P2 |
| Loading states for async | P3 |

### Accessibility

| Improvement | Current | Target |
|-------------|---------|--------|
| Semantics | Rating tile only | All interactive elements |
| VoiceOver | Partial | Full support |

---

## 5. Dark Mode Support

**Priority:** P4

**Scope:**
- Add dark theme to `app_theme.dart`
- System/manual toggle in settings
- Test all screens in dark mode

---

## 6. App Store Optimization (ASO) Metadata

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

## Notes

- 674 lint issues are info-level (suggestions), not errors
- Dark mode is nice-to-have, not blocking release
