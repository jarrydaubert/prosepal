# Test Audit

> Unit/widget tests: `flutter test` | Integration tests: `patrol test`

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

| Flow | Tests | Mocked |
|------|:-----:|:------:|
| App launch (logged in/out) | ✅ | Yes |
| Onboarding flow | ✅ | Yes |
| All 10 occasions | ✅ | Yes |
| All 5 relationships | ✅ | Yes |
| All 4 tones | ✅ | Yes |
| Free user → upgrade prompt | ✅ | Yes |
| Pro user → generate button | ✅ | Yes |
| Settings navigation | ✅ | Yes |
| RevenueCat SDK | ✅ | No (device_only) |

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
# Unit/widget tests
flutter test

# Integration tests (Patrol)
patrol test -t integration_test/app_test.dart

# Device-only tests (real RevenueCat)
patrol test -t integration_test/device_only/revenuecat_test.dart

# Run with hot reload during development
patrol develop -t integration_test/app_test.dart
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
