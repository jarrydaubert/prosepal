# Testing

## User Flows

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

## Edge Cases

### Payments
- **Offline purchase**: StoreKit queues, completes when online
- **Purchase interrupted**: StoreKit 2 auto-restores on relaunch
- **Subscription expires**: RevenueCat listener updates Pro status
- **Refund**: RevenueCat webhook revokes Pro

### Usage
- **Free user generates offline**: Local decrement, syncs later
- **Pro expires after using >1**: Remaining = 0

### Auth
- **Session expires**: Supabase auto-refreshes JWT
- **Face ID revoked**: Error handled, shows retry

---

## Known Issues

| ID | Issue | Severity |
|----|-------|----------|
| L5 | User stuck after 3 failed biometrics | Medium |
| R3 | Supabase session may persist in Keychain after reinstall | Low |
| O1 | No offline banner | Low |

---

## Pre-Launch Manual Tests

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
