# Testing

> Flows and edge cases here drive `integration_test/scenario_tests.dart`

---

## User Flows (Automated)

### Flow 1: Fresh Install (Anonymous)
```
Launch → Onboarding → Home → Generate (1 free) → Results → Home (0 remaining)
```

### Flow 2: Upgrade Path
```
Home → Generate → "Upgrade to Continue" → Auth → Paywall → Purchase → Pro unlocked
```

### Flow 3: Reinstall (Pro User)
```
Reinstall → Home (0) → Auth (same creds) → Pro restored via RevenueCat
```

### Flow 4: Multi-Device
```
Sign in on Device B → identifyUser() → Pro synced
```

---

## Edge Cases (Automated)

### Payments
- Offline purchase → StoreKit queues, completes when online
- Purchase interrupted → StoreKit 2 auto-restores on relaunch
- Subscription expires → RevenueCat listener updates Pro status
- Refund → RevenueCat webhook revokes Pro

### Usage
- Free user generates offline → Local decrement, syncs later
- Pro expires after using >1 → Remaining = 0

### Auth
- Session expires → Supabase auto-refreshes JWT
- Face ID revoked → Error handled, shows retry

---

## Known Issues

| ID | Issue | Severity | Automated |
|----|-------|----------|-----------|
| L5 | User stuck after 3 failed biometrics | Medium | No |
| R3 | Supabase session persists in Keychain after reinstall | Low | No |
| O1 | No offline banner | Low | No |

---

## Manual Tests (Real Device Only)

| Test | Why Manual |
|------|------------|
| Apple Sign In | OAuth |
| Google Sign In | OAuth |
| Magic link deep link | Email + URL scheme |
| Purchase → Pro unlocked | Sandbox StoreKit |
| Restore purchases | Sandbox StoreKit |
| AI generates 3 messages | Real Gemini API |
| Biometric lock/unlock | Hardware |
| Delete account | Destructive |

---

## Test Files

| File | Purpose |
|------|---------|
| `test/**` | Unit/widget tests (mocked) |
| `integration_test/scenario_tests.dart` | All flows + edge cases (Patrol) |
| `integration_test/golden_path_test.dart` | Firebase Test Lab smoke tests |
| `integration_test/simple_test.dart` | Basic sanity tests |
