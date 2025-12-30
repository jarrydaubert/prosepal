# Prosepal Tests

> See **[docs/TEST_AUDIT.md](../docs/TEST_AUDIT.md)** for full test strategy and coverage.

## Quick Reference

```bash
# All unit/widget tests (479 tests)
flutter test

# Single file
flutter test test/services/auth_service_test.dart

# Integration tests (requires simulator)
flutter test integration_test/ -d "iPhone 17 Pro"
```

## Structure

```
test/
├── services/          # Service unit tests (auth, subscription, AI, etc.)
├── widgets/screens/   # Screen widget tests
├── models/            # Model serialization tests
├── errors/            # Error handling tests
├── app/               # App lifecycle tests
└── mocks/             # Mock implementations for DI

integration_test/
├── app_test.dart              # App launch, navigation
├── e2e_subscription_test.dart # Free/Pro user flows
├── e2e_user_journey_test.dart # Complete user journeys
└── device_only/               # Tests requiring real device
```

## Mocks

Import all mocks with:
```dart
import '../mocks/mocks.dart';
```

| Mock | Interface | Purpose |
|------|-----------|---------|
| `MockAuthService` | `IAuthService` | Supabase auth |
| `MockSubscriptionService` | `ISubscriptionService` | RevenueCat |
| `MockBiometricService` | `IBiometricService` | Local auth |
| `MockAppleAuthProvider` | `IAppleAuthProvider` | Apple Sign In |
| `MockGoogleAuthProvider` | `IGoogleAuthProvider` | Google Sign In |
| `MockSupabaseAuthProvider` | `ISupabaseAuthProvider` | Supabase client |

## Pre-Launch (Real Device)

- [ ] Apple/Google Sign In works
- [ ] Offerings load (not empty)
- [ ] Test purchase unlocks Pro
- [ ] AI generates 3 messages
