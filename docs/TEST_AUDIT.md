# Test Audit

> **376 unit/widget tests** | **52 Patrol integration tests**

```bash
# Unit/widget tests
flutter test

# Integration tests (Patrol - see note below)
patrol test -t integration_test/app_test.dart
```

### Patrol Status (Jan 2026)
Patrol tests are properly configured but currently blocked by a **known AppAuth framework embedding issue** affecting apps with OAuth plugins (Google Sign-In, Apple Sign-In). Tests will execute once:
- Running on CI with proper framework embedding
- Upstream Patrol fix is released
- Or using `flutter drive` for basic flows

---

## Philosophy

Every test must answer: **"What bug would this catch?"**

**Keep:** Business logic, user flows, error handling, edge cases
**Delete:** Static values, mock helpers, duplicates, tests that never fail

---

## Testing Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Unit/Widget | `flutter_test` | Service logic, UI components |
| Integration | **Patrol** | End-to-end user flows |
| Mocking | `mocktail` | Dependency injection |

### Why Patrol?

Patrol replaced the standard `integration_test` package for:
- **Automatic waiting** - no hardcoded `Duration` delays
- **Native automation** - permissions, notifications, biometrics
- **Robust finders** - `$('Text')`, `$(Icons.settings)`, `$(#key)`
- **Deterministic testing** - mocked services via provider overrides

---

## External SDK Strategy

| SDK | Unit Tests | Integration |
|-----|:----------:|:-----------:|
| RevenueCat | MockSubscriptionService | Real device (`device_only/`) |
| Supabase Auth | MockAuthService | Mocked via provider |
| Firebase AI | Parsing tests | Real device only |
| Biometrics | MockBiometricService | Real device only |

---

## Test Files

### Unit/Widget Tests (`test/`)

```
test/
├── mocks/                        # Test doubles
│   ├── mock_auth_service.dart
│   ├── mock_biometric_service.dart
│   └── mock_subscription_service.dart
├── models/                       # Model tests
├── services/                     # Service tests
├── theme/                        # Theme tests
└── widgets/screens/              # Widget tests
```

### Integration Tests (`integration_test/`)

```
integration_test/
├── app_test.dart                 # Main Patrol tests (mocked)
└── device_only/
    └── revenuecat_test.dart      # Real device RevenueCat tests
```

---

## Integration Test Coverage

### Mocked Tests (`app_test.dart`)

| Flow | Status |
|------|:------:|
| App launch (logged in/out) | ✅ |
| Onboarding flow | ✅ |
| All 10 occasions | ✅ |
| All 5 relationships | ✅ |
| All 4 tones | ✅ |
| Free user → upgrade prompt | ✅ |
| Pro user → generate button | ✅ |
| **Generation → results screen** | ✅ |
| **Network error handling** | ✅ |
| **Rate limit error handling** | ✅ |
| **Content blocked error** | ✅ |
| **Error dismiss and retry** | ✅ |
| Pro user settings | ✅ |
| Upgrade flow to paywall | ✅ |
| Settings navigation | ✅ |

### Device-Only Tests (`device_only/revenuecat_test.dart`)

| Test | Verifies |
|------|----------|
| SDK initialization | `isConfigured == true` |
| Store type reporting | Test Store vs Production |
| Offerings endpoint | Returns current offering |
| Package availability | At least one package exists |
| Product identifiers | Valid IDs and prices |
| Monthly package | Expected package type |
| User identity | App User ID assigned |
| Entitlements structure | Object accessible |
| Restore purchases | Completes without error |
| User ID consistency | Same after restore |
| isPro status | Matches entitlement |
| Paywall loads offerings | Real price displays |
| Restore option visible | UI element present |
| Settings status | Shows Free/Pro correctly |
| Network resilience | Handles repeated calls |
| Product configuration | All required products |
| Entitlement ID | Matches expected "pro" |

---

## Pre-Launch Checklist (Real Device)

- [ ] Apple/Google Sign In works
- [ ] Magic link opens app
- [ ] Offerings load (not empty)
- [ ] Test purchase unlocks Pro
- [ ] Restore purchases works
- [ ] AI generates 3 messages
- [ ] All 10 occasions work
- [ ] Biometric lock works

---

## Commands

```bash
# Unit/widget tests (376 tests)
flutter test

# Integration tests via flutter drive (works with OAuth plugins)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/simple_test.dart

# Patrol tests (blocked by AppAuth issue - see status note above)
patrol test -t integration_test/app_test.dart

# Device-only tests (real RevenueCat)
patrol test -t integration_test/device_only/revenuecat_test.dart
```

---

## Deleted Tests (Low Value)

| File | Reason |
|------|--------|
| `auth_service_crypto_test.dart` | Tested local functions, duplicated |
| `ai_service_http_test.dart` | MockClient never injected |
| `subscription_service_test.dart` | Static API keys, constants |
| `models_test.dart` | Static enum values |
| Old `integration_test/*.dart` | Replaced with Patrol |

---

## Future Improvements

| Category | Items |
|----------|-------|
| **Native Testing** | Biometric prompts, permission dialogs |
| **Visual** | Golden tests for key screens |
| **Performance** | AI generation latency |
| **Accessibility** | Semantic finders, touch targets |
