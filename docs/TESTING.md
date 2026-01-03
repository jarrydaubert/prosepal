# Testing Guide

## Commands

```bash
flutter test                                      # Unit/widget (376 tests)
flutter test integration_test/                    # Mocked E2E
patrol test -t integration_test/device_only/      # Real SDK (device)
```

## Test Categories

| Category | Method | Coverage |
|----------|--------|----------|
| **A: Mocked** | `flutter test integration_test/` | UI flows, mocked auth/payments |
| **B: Device** | `patrol test device_only/` | RevenueCat, biometrics, Firebase AI |
| **C: Manual** | Human + logs | OAuth, deep links, reinstall |

## SDK Testing Strategy

| SDK | Unit Test | Device Test |
|-----|:---------:|:-----------:|
| RevenueCat | Mock | Real |
| Supabase Auth | Mock | Mock (OAuth manual) |
| Firebase AI | Mock | Real |
| Biometrics | Mock | Real |

---

## User Flows

### Flow 1: Fresh Install (Anonymous)
```
Launch → Onboarding → Home (anon) → Generate (1 free) → Results → Home (0 tokens)
```
- No auth required for first generation
- Token stored locally (SharedPreferences)

### Flow 2: Upgrade (Second Generate)
```
Home → Generate → "Upgrade to Continue" → Auth → Paywall → Purchase → Pro unlocked
```
- Auth required before paywall
- RevenueCat `logIn(supabaseUserId)` links purchase

### Flow 3: Reinstall (Anonymous)
```
Delete app → Reinstall → Onboarding → Home → Generate (new free token)
```
- Local storage cleared = new anonymous user
- Acceptable for "card aisle" impulse use

### Flow 4: Reinstall (Pro User)
```
Delete app → Reinstall → Home (0 tokens) → Auth (same creds) → Pro restored
```
- RevenueCat aliases purchase to Apple ID
- `identifyUser()` restores entitlement

### Flow 5: Multi-Device
```
Sign in on Device B → identifyUser() → Pro synced
```

---

## Pre-Launch Manual Checklist

| Test | Method |
|------|--------|
| Apple Sign In | Real device |
| Google Sign In | Real device |
| Magic link deep link | Real device + email |
| Purchase → Pro unlocked | Sandbox account |
| Restore purchases | Sandbox account |
| AI generates 3 messages | Real device |
| Biometric lock/unlock | Real device |
| Delete account | Real device |
| Sign out clears session | Real device |

---

## Known Issues

| ID | Issue | Severity | Workaround |
|----|-------|----------|------------|
| L5 | User stuck after 3 failed biometrics | Medium | Needs "Sign in instead" fallback |
| R3 | Supabase session may persist in Keychain after reinstall | Low | Rare edge case |
| X2 | No biometric re-auth on foreground | Low | Privacy screen shows, auth on next action |
| O1 | No offline banner | Low | Graceful fail, no crash |

---

## Edge Cases

### Payments
- **Offline purchase**: StoreKit queues, completes when online
- **Purchase interrupted**: StoreKit 2 auto-restores on relaunch
- **Subscription expires**: RevenueCat listener updates Pro status
- **Family sharing**: Works (Apple handles)
- **Refund**: RevenueCat webhook revokes Pro

### Usage
- **Free user generates offline**: Local decrement, syncs later
- **Pro expires after using >1**: Remaining = 0 (can't regenerate free)
- **New account abuse**: Fresh usage (acceptable - low value)

### Auth
- **Session expires**: Supabase auto-refreshes JWT
- **Password changed (web)**: Session invalidated, re-auth required
- **Face ID revoked in Settings**: Error handled, shows retry

---

## Test Structure

```
test/
├── mocks/                  # MockAuthService, etc.
├── services/               # Service logic
└── widgets/screens/        # Widget tests

integration_test/
├── app_test.dart           # Mocked E2E
└── device_only/            # Real SDK tests
```
