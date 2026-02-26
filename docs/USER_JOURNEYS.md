# User Journeys

> Auth/payment flow reference. Current state and target state.

---

## Core Principle

**Free tier = anonymous OK | Paid tier = auth required first**

---

## Launch Decision Tree

```
Launch
  ├─ !onboarded → /onboarding
  ├─ biometrics enabled → /lock → /home
  └─ else → /home
```

---

## Flow: Onboarding Complete

```
Onboarding [Get Started]
  │
  ├─ hasPro && !loggedIn → /auth (link orphaned Pro)
  ├─ hasPro && loggedIn → /home
  └─ !hasPro → /paywall (dismissable)
                  │
                  ├─ [X Dismiss] → /home (1 free generation)
                  ├─ [Subscribe] → AUTH REQUIRED (see below)
                  └─ [Restore] → AUTH REQUIRED (see below)
```

---

## Flow: Subscribe (TARGET)

```
                    ┌─────────────────────────────┐
                    │  CURRENT         TARGET     │
                    ├─────────────────────────────┤
                    │  Pay → Auth?    Auth → Pay  │
                    │  X dismissable  No X        │
                    │  Pro orphanable Pro linked  │
                    └─────────────────────────────┘

TARGET FLOW:
[Subscribe] → /auth (NO X) → Sign in → /paywall → Purchase → /home
                                                      │
                                              RevenueCat.identify(userId)
                                              Pro linked to account ✓
```

---

## Flow: Restore (TARGET)

```
                    ┌─────────────────────────────────────┐
                    │  CURRENT              TARGET        │
                    ├─────────────────────────────────────┤
                    │  Paywall: No auth     Auth required │
                    │  Settings: Auth req   Auth required │
                    │  Inconsistent         Consistent    │
                    └─────────────────────────────────────┘

TARGET FLOW (all restore buttons):
[Restore] → if !loggedIn → /auth (NO X) → Sign in → Restore → result
```

---

## Flow: Generate (Free Tier Exhausted)

```
Generate Screen (remaining=0)
  │
  └─ [Upgrade] → /auth (NO X) → Sign in → /paywall → Purchase → /home

CURRENT BUG: Auth has X, user can dismiss and is stuck in loop
TARGET: No X on auth when in payment flow
```

---

## Flow: Anonymous Free Tier

```
                    ┌──────────────────────────────────────────┐
                    │  CURRENT                 TARGET          │
                    ├──────────────────────────────────────────┤
                    │  Local check only        Server check    │
                    │  Reinstall = abuse       Fingerprint DB  │
                    └──────────────────────────────────────────┘

TARGET FLOW:
Generate (anonymous, !isPro)
  │
  └─ checkDeviceFreeTierServerSide() BEFORE generation
      │
      ├─ allowed → generate → markDeviceUsedFreeTier (server)
      └─ blocked → "Upgrade to Pro"
```

---

## Decision Record

**Decision:** Auth First, Then Pay  
**Date:** 2026-01-11  
**Confirmed by:** Code audit + RevenueCat docs research  

**Rationale:**
- RevenueCat Flutter SDK lacks `onPurchaseInitiated` callback (iOS/Android native only)
- Industry standard (Spotify, Netflix, Disney+) requires auth before premium access
- Eliminates orphaned subscriptions - Pro always linked to account
- Simplifies implementation - no `isPostPurchase` tracking needed

**Sources:**
- RevenueCat docs: https://www.revenuecat.com/docs/tools/paywalls
- RevenueCat community: "Check if user is logged in; if anonymous, prompt to create account before paywall"

---

## Implementation Summary

```dart
// PAYWALL: Subscribe button
if (!authService.isLoggedIn) {
  context.push('/auth?redirect=paywall');
  return;
}
// proceed with purchase...

// PAYWALL: Restore button  
if (!authService.isLoggedIn) {
  context.push('/auth?redirect=paywall');
  return;
}
// proceed with restore...

// GENERATE SCREEN: Upgrade button (remaining=0)
context.push('/auth?redirect=paywall');

// AUTH SCREEN: X button logic
final canDismiss = widget.redirectTo != 'paywall' && 
                   (widget.redirectTo != null || context.canPop());
```

---

## Auth Screen Parameters

```dart
AuthScreen({
  String? redirectTo,      // 'paywall' = no X button
  bool isProRestore,       // Show "link your Pro" messaging
  bool autoRestore,        // Auto-restore after auth
})
```

---

## State Persistence

| State | Storage | Survives Reinstall |
|-------|---------|-------------------|
| `isLoggedIn` | Supabase session | No |
| `hasPro` | RevenueCat | Yes (if linked to account) |
| `deviceUsedFreeTier` | Server fingerprint | Yes |
| `onboardingComplete` | SharedPrefs | No |
| `user_usage` | Supabase table | Yes (tied to user_id) |

---

## Routes

| Route | Entry Point | Auth Required |
|-------|-------------|---------------|
| `/onboarding` | Fresh install | No |
| `/home` | Default | No |
| `/auth` | Payment flows, settings | N/A (is auth) |
| `/paywall` | After auth for payment | Yes |
| `/generate` | Occasion tap | No |
| `/results` | Generation complete | No |
| `/settings` | Settings icon | No |
| `/history` | History tab | No |
| `/lock` | Biometrics enabled | No |
