# Testing

> Test strategy and edge cases for Prosepal

---

## Test Structure

| Location | Purpose |
|----------|---------|
| `test/**` | Unit/widget tests (mocked) |
| `integration_test/journeys/` | User journey tests (j1-j10) |
| `integration_test/coverage/` | Exhaustive option coverage |

---

## Automated User Flows

### Flow 1: Fresh Install
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

### Flow 4: Multi-Device Sync
```
Sign in on Device B → identifyUser() → Pro synced from RevenueCat
```

---

## Edge Cases (Covered by Tests)

### Payments
| Scenario | Expected Behavior |
|----------|-------------------|
| Offline purchase | StoreKit queues, completes when online |
| Purchase interrupted | StoreKit 2 auto-restores on relaunch |
| Subscription expires | RevenueCat listener updates Pro status |
| Refund processed | RevenueCat webhook revokes Pro |

### Usage
| Scenario | Expected Behavior |
|----------|-------------------|
| Free user generates offline | Local decrement, syncs when online |
| Pro expires after using >1 | Remaining = 0 (not negative) |

### Auth
| Scenario | Expected Behavior |
|----------|-------------------|
| Session expires | Supabase auto-refreshes JWT |
| Face ID permission revoked | Error handled, shows retry option |

---

## Manual Tests (Real Device Only)

These cannot be automated and require manual verification:

| Test | Reason |
|------|--------|
| Apple Sign In | OAuth flow requires real Apple ID |
| Google Sign In | OAuth flow requires real Google account |
| Magic link deep link | Requires email + URL scheme |
| Purchase → Pro unlocked | Requires Sandbox StoreKit |
| Restore purchases | Requires Sandbox StoreKit |
| AI generates 3 messages | Requires real Gemini API |
| Biometric lock/unlock | Requires hardware |
| Delete account | Destructive, verify Apple token revocation |

---

## Known Limitations

| Issue | Severity | Notes |
|-------|----------|-------|
| 3 failed biometrics shows generic error | Medium | iOS limitation, can't distinguish |
| Supabase session persists in Keychain after reinstall | Low | Expected iOS behavior |
| No offline banner | Low | App works offline, no indicator |

---

## Running Tests

```bash
# All unit/widget tests
flutter test

# Specific test file
flutter test test/services/auth_service_test.dart

# Integration tests (requires device)
flutter test integration_test/

# With coverage
flutter test --coverage
```
