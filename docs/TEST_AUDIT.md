# Test Audit

> **365 tests** | `flutter test` | Last audited: Dec 2025

---

## Philosophy

Every test must answer: **"What bug would this catch?"**

**Keep:** Business logic, user flows, error handling, edge cases
**Delete:** Static values, mock helpers, duplicates, tests that never fail

---

## External SDK Strategy

**Automated tests:** Mock via dependency injection
**Pre-launch:** Real device with sandbox accounts

| SDK | Mock Class | Interface |
|-----|------------|-----------|
| RevenueCat | `MockSubscriptionService` | `ISubscriptionService` |
| Supabase Auth | `MockAuthService` | `IAuthService` |
| Firebase AI | Direct parsing tests | N/A (test at boundaries) |

### What Mocking Covers
- UI state changes (Pro/Free, logged in/out)
- Navigation flows
- Error message display
- Loading states

### What Requires Real Device
- Native OAuth UI (Apple/Google sheets)
- Store purchases & receipts
- Deep links / magic links
- Actual AI generation quality

---

## Deleted (Low Value)

| File | Reason |
|------|--------|
| `auth_service_crypto_test.dart` | Tested local functions, not real code. Duplicated by `auth_service_test.dart` |
| `ai_service_http_test.dart` | Duplicated `ai_service_generation_test.dart`. MockClient never injected into AiService |
| `ai_service_test.dart` | 100% redundant with `ai_service_generation_test.dart` |
| `subscription_service_test.dart` (30 tests) | Static API keys, hardcoded prices, constant values |
| `models_test.dart` (40 tests) | Static enum values (emojis, labels, counts) |
| `auth_service_compliance_test.dart` (8 tests) | Static URL strings, regex tests on literals |

---

## Integration Tests

| File | Tests | Status |
|------|-------|--------|
| `app_test.dart` | 12 | ✅ Simulator |
| `e2e_subscription_test.dart` | 29 | ✅ Simulator |
| `e2e_user_journey_test.dart` | 18 | ✅ Simulator |
| `device_only/revenuecat_test.dart` | 13 | ⚠️ Real device |

**Deleted:** `auth_test.dart`, `firebase_test.dart` (broken - required real SDK init)

---

## Known Gaps

| Screen | Status | Notes |
|--------|--------|-------|
| `paywall_screen.dart` | ⚠️ | Fallback paywall has debug info - not prod ready. Needs cleanup + widget test |
| `auth_screen.dart` | OK | Covered by integration tests |
| `onboarding_screen.dart` | OK | First-run only, low risk |
| `lock_screen.dart` | OK | Biometric service tested, UI simple |
| `email_auth_screen.dart` | OK | Auth service tested |
| `legal_screen.dart` | OK | Static content |
| `feedback_screen.dart` | OK | Simple form |

---

## Pre-Launch Checklist (Real Device)

- [ ] Apple/Google Sign In works
- [ ] Magic link opens app
- [ ] Offerings load (not empty)
- [ ] Test purchase unlocks Pro
- [ ] Restore purchases works
- [ ] AI generates 3 messages
- [ ] All 10 occasions work

---

## Future Test Improvements

### Mock Enhancements
| Mock | Potential Addition |
|------|-------------------|
| `MockSubscriptionService` | Simulate entitlement expiration via timed CustomerInfo updates |
| `MockSupabaseAuthProvider` | Simulate deep-link OAuth completion (code exchange → session) |
| `MockBiometricService` | Add `BiometricType.iris` if needed for future devices |

### Missing Widget Tests (Priority Order)
1. **`paywall_screen_test.dart`** - Revenue-critical, only covered by integration tests
2. **`auth_screen_test.dart`** - Sign-in options, error messages, OAuth provider selection
3. **`onboarding_screen_test.dart`** - Multi-step flow, completion persistence, skip behavior
4. **`lock_screen_test.dart`** - Biometric prompt, blur overlay on backgrounding

### Missing Unit Test Scenarios
- **Invalid JSON handling**: Test `fromJson` throws on malformed data or unknown enum values
- **OAuth deep-link simulation**: Test magic link / OAuth callback handling
- **Session persistence**: Test initial session load on app restart
- **Pro monthly limit**: Test 500+ generations to verify `canGeneratePro` returns false

### Integration Test Improvements
- **Deterministic state control**: Mock external services via provider overrides
- **Robust waiting**: Replace hardcoded delays with `pumpAndSettle` + custom `waitFor` helpers
- **Deeper assertions**: Verify ResultsScreen display, message cards, context headers
- **Error path coverage**: Test network failures, rate limits, content blocks
- **Flaky test fix**: `e2e_user_journey_test.dart` "Free User Complete Journey" occasionally fails

### Additional Test Types
- **Golden Tests**: Visual regression for cards, results, paywall screens
- **Performance Tests**: AI generation latency, large message list rendering
- **Coverage Reporting**: Enable `flutter test --coverage` for metrics

### Accessibility Testing
- **Semantic finders**: Use `bySemanticsLabel` for more resilient element location
- **Touch targets**: Verify all interactive elements meet 44pt minimum
- **Screen reader support**: Check meaningful labels on buttons and cards

---

## Commands

```bash
flutter test                           # Unit/widget (365 tests)
flutter test integration_test/ -d "iPhone 17 Pro"  # Integration (59 tests)
```
