# Test Audit

> **376 unit tests** | **52 scenarios** (see SCENARIO_AUDIT.md)

Every test must answer: **"What bug would this catch?"**

---

## Commands

```bash
# Unit/widget tests
flutter test

# Integration tests (mocked services)
flutter test integration_test/

# Device-only tests (real RevenueCat)
patrol test -t integration_test/device_only/revenuecat_test.dart
```

---

## Test Categories

| Category | Method | What |
|----------|--------|------|
| **A: Mocked** | `flutter test integration_test/` | UI flows with mocked auth/payments |
| **B: Device SDK** | `patrol test device_only/` | Real RevenueCat, biometrics |
| **C: Manual** | Human + logs | OAuth, deep links, reinstall |

---

## SDK Strategy

| SDK | Unit | Integration |
|-----|:----:|:-----------:|
| RevenueCat | Mock | Real device |
| Supabase Auth | Mock | Mock (OAuth manual) |
| Firebase AI | Mock | Real device |
| Biometrics | Mock | Real device |

---

## Test Structure

```
test/
├── mocks/                  # MockAuthService, MockSubscriptionService, etc.
├── services/               # Service logic tests
└── widgets/screens/        # Widget tests

integration_test/
├── app_test.dart           # Mocked E2E (Patrol syntax)
├── flutter_test.dart       # Mocked E2E (integration_test package)
└── device_only/
    └── revenuecat_test.dart
```

---

## Pre-Launch Checklist

Manual verification on real device:

- [ ] Apple/Google Sign In
- [ ] Magic link deep link
- [ ] Test purchase → Pro unlocked
- [ ] Restore purchases
- [ ] AI generates 3 messages
- [ ] Biometric lock/unlock
- [ ] Delete account (edge function)
- [ ] Sign out clears session

---

## Known Issues

- **Patrol + AppAuth**: Conflict with Google Sign-In framework. Use `flutter test integration_test/` for mocked flows.
- **Category C**: OAuth, biometrics, reinstall scenarios require manual verification with logs.
