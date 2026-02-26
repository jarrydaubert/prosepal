# User Journeys

> Quick reference for app navigation logic

---

## App Launch Decision Tree

```
Launch
  ├─ !onboarded → /onboarding
  ├─ biometrics enabled → /lock → /home
  ├─ anon + Pro → /auth?restore=true
  └─ else → /home
```

---

## Core Flows

| Flow | Steps |
|------|-------|
| **Fresh Install** | Launch → Onboarding → Home (anon, 1 free) |
| **Anon Upgrade** | Upgrade → Auth → Sign In → Paywall → Purchase → Bio? → Home |
| **Logged Upgrade** | Upgrade → Paywall → Purchase → Bio? → Home |
| **Sign Out** | Settings → Confirm → Clear all → Home (anon) |

---

## Relaunch States

| User State | Biometrics | Route |
|------------|------------|-------|
| Anonymous | Off | `/home` |
| Anonymous | On | `/lock` → `/home` |
| Logged In | Off | `/home` |
| Logged In | On | `/lock` → `/home` |
| Anon + Pro | Any | `/auth?restore=true` |

---

## Business Rules

- **Biometric toggle:** Signed-in users only (prevents lockout)
- **Sign out clears:** History, usage, biometrics, RevenueCat, session
- **Upgrade flow:** Always requires auth if anonymous
- **Pro restore:** Detects orphaned Pro and prompts auth

---

## Screen Routes

| Route | Entry Point |
|-------|-------------|
| `/onboarding` | Fresh install |
| `/home` | Default (post-onboard) |
| `/auth` | Anon upgrade, settings sign-in, restore |
| `/paywall` | Logged upgrade, post-auth redirect |
| `/lock` | Biometrics enabled + app launch |
| `/biometric-setup` | Post-auth, post-purchase (optional) |
| `/generate` | Occasion tap from home |
| `/results` | Generation complete |
| `/settings` | Settings icon tap |
| `/history` | History tab |
