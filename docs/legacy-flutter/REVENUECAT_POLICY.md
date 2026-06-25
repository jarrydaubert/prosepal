# RevenueCat Policy

> LEGACY (Flutter baseline). This document preserves the existing Flutter
> RevenueCat continuity policy. The native iOS direction is StoreKit 2 first,
> with server/gateway entitlement as source of truth; see
> `prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md` and `docs/BACKLOG.md`.

## Purpose

Define identity and restore behavior for subscriptions.

Scope note:

- This is the existing Flutter production RevenueCat continuity policy.
- Native iOS may retain RevenueCat for entitlement continuity, but that decision
  must be made deliberately before production replacement.
- The current native R&D path may use StoreKit 2 locally without treating local
  purchase state as authorization for Premium gateway access.
- Gateway/server entitlement policy remains authoritative for Premium
  generation.

## Restore Behavior Setting

- Project setting target: `Transfer to new App User ID`.

## Canonical Identity Rules

- Authenticated user: Supabase user ID is the RevenueCat App User ID.
- Signed-out user: persisted app-specific anonymous ID (`anon_<uuid>`).
- Do not use email or other guessable identifiers as App User ID.

## Expected Outcomes

- Anonymous purchase -> login:
  - `logIn(userId)` links/transfers entitlement to authenticated user.
- User switch on same device:
  - Sign-out switches to persisted anonymous ID.
  - Next sign-in calls `logIn(nextUserId)` and refreshes entitlements.
- Reinstall + restore:
  - `restorePurchases()` and `syncPurchases()` reconcile store ownership.
  - If entitlement exists for store account, active entitlement is restored.

## Entitlement Refresh Points

- Before presenting paywall, refresh `CustomerInfo` and skip paywall if `pro` is active.
- After `restorePurchases()`, refresh entitlement providers/state.
- After identity changes (`logIn`/logout switch), run entitlement sync/refresh.

## Support Handling

- If entitlement appears moved unexpectedly, collect:
  - current App User ID
  - previous App User ID (if known)
  - platform store account context
  - restore action timestamps
- Escalate with RevenueCat support when transfer outcomes diverge from policy.
