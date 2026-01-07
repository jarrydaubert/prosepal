# User Journeys

## App Launch
1. `!onboarded` → `/onboarding`
2. `biometrics` → `/lock` → `/home`
3. `anon+Pro` → `/auth?restore=true`
4. `else` → `/home`

## Flows
- **Fresh:** Launch → Onboarding → Home (anon, 1 free)
- **Anon Upgrade:** Upgrade → Auth → Sign In → Paywall → Purchase → Bio? → Home
- **Logged Upgrade:** Upgrade → Paywall → Purchase → Bio? → Home
- **Sign Out:** Settings → Confirm → Clear all → Home (anon)

## Relaunch
| State | Bio | Route |
|-------|-----|-------|
| Anon | Off | `/home` |
| Anon | On | `/lock` → `/home` |
| Logged | Off | `/home` |
| Logged | On | `/lock` → `/home` |
| Anon+Pro | - | `/auth?restore=true` |

## Rules
- Bio toggle: **signed-in users only** (prevents lockout)
- Sign out clears: history, usage, bio, RevenueCat, session
- Upgrade always requires auth if anonymous

## Screens
| Route | Entry |
|-------|-------|
| `/onboarding` | Fresh install |
| `/home` | Default |
| `/auth` | Anon upgrade, settings, restore |
| `/paywall` | Logged upgrade, post-auth redirect |
| `/lock` | Bio enabled + launch |
| `/biometric-setup` | Post-auth, post-purchase |
| `/generate` | Occasion tap |
| `/results` | Generation done |
| `/settings` | Settings icon |

## Integration Tests Needed
- [ ] Anon → Auth → Paywall → Purchase → Home
- [ ] Relaunch all states
- [ ] Sign out clears data
