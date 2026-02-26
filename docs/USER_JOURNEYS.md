# User Journeys

> Core navigation flows. Keep concise and up to date.

---

## App Launch Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      APP LAUNCH                              │
├─────────────────────────────────────────────────────────────┤
│ 1. !hasCompletedOnboarding    → /onboarding                 │
│ 2. biometricsEnabled          → /lock → /home               │
│ 3. anonymousWithPro           → /auth?restore=true          │
│ 4. else                       → /home                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Flows

### 1. Fresh Install
```
Launch → Onboarding (3 screens) → Home (anonymous, 1 free)
```

### 2. Anonymous → Upgrade
```
Tap Upgrade → Auth (required) → Sign In → Paywall → Purchase → Biometrics Dialog → Home
                                                              ↓
                                                    Enable → /biometric-setup → Home
                                                    Skip   → Home (pop paywall)
```

### 3. Logged In → Upgrade
```
Tap Upgrade → Paywall → Purchase → Biometrics Dialog → Home
```

### 4. Relaunch Scenarios

| State | Biometrics | Route |
|-------|------------|-------|
| Anonymous | Off | `/home` |
| Anonymous | On | `/lock` → `/home` |
| Logged in | Off | `/home` |
| Logged in | On | `/lock` → `/home` |
| Anonymous + Pro (restore) | - | `/auth?restore=true` |

### 5. Sign Out
```
Settings → Sign Out → Confirm → Clears all data → /home (anonymous)
```

Cleared: History, Usage, Biometrics, RevenueCat link, Auth session

### 6. Biometrics
```
Settings → Security (only visible if signed in) → Toggle On → Authenticate → Enabled
```

**Rule:** Biometrics toggle ONLY shown to signed-in users (prevents lockout)

---

## Screen Entry Points

| Screen | Entry From |
|--------|------------|
| `/onboarding` | Fresh install |
| `/home` | After onboarding, after auth, after purchase |
| `/auth` | Upgrade (anonymous), Settings sign-in, Restore |
| `/paywall` | Upgrade (logged in), After auth redirect |
| `/lock` | App launch (biometrics enabled) |
| `/biometric-setup` | After auth (no redirect), After purchase (enable) |
| `/generate` | Occasion tapped |
| `/results` | Generation complete |
| `/settings` | Settings icon |

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Anonymous tries upgrade | Redirect to auth first |
| Anonymous enables biometrics | **Blocked** - toggle hidden |
| Biometrics fail repeatedly | "Try Again" or device passcode fallback |
| Pro user reinstalls | RevenueCat restores via App Store receipt |
| Sign out clears biometrics | Yes - security setting tied to user |

---

## Test Coverage Needed

| Flow | Status |
|------|--------|
| Fresh install → Free generation | Unit tests ✅ |
| Anonymous upgrade → Auth → Paywall | **Needs integration test** |
| Purchase → Biometrics → Home | **Needs integration test** |
| App relaunch (all states) | **Needs integration test** |
| Sign out clears data | Unit tests ✅ |
| Biometrics lock/unlock | Manual only |

---

## Log Events (Key)

```
[INFO] Onboarding started/completed
[INFO] App launched | initialProStatus=bool
[INFO] Wizard started | occasion=x
[INFO] AI generation started/success/failed
[INFO] Sign in started | provider=x
[INFO] User signed in | userId=x
[INFO] Purchase completed | hasPro=true
[INFO] Pro status updated | hasPro=bool
[INFO] Biometric auth started/success
[INFO] Sign out initiated
[INFO] User signed out
```
