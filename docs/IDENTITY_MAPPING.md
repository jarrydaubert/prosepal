# Identity Mapping

## Purpose

Define the canonical user-identity mapping across auth, subscriptions, and telemetry.

Scope note:

- Existing Flutter production identity uses Supabase, RevenueCat, Firebase
  Analytics, and Firebase Crashlytics.
- Native iOS should preserve the ownership rules, not automatically inherit
  every telemetry or subscription SDK.
- Native Premium generation must be authorized by gateway/server entitlement
  state, not by local UI or stale local purchase cache alone.

## Canonical IDs

| Surface | Canonical ID |
|---------|--------------|
| Supabase Auth | `supabase.auth.currentUser.id` when signed in |
| RevenueCat | Supabase user ID when signed in; persisted `anon_<uuid>` when signed out |
| Firebase Analytics | Same as Supabase user ID when signed in; cleared on sign out |
| Firebase Crashlytics | Same as Supabase user ID when signed in; cleared on sign out |
| In-app diagnostics (`Log.currentUserId`) | Mirrors last telemetry ID set by app code; cleared on sign out |

## Rules

- Never use email or other guessable identifiers as RevenueCat App User ID.
- Always identify RevenueCat with Supabase user ID after successful auth.
- On sign out/delete-account, switch RevenueCat to persisted anonymous ID and clear telemetry user ID.
- If auth user changes, clear stale entitlement cache before refresh.

## Runtime Ownership

- Auth state transitions are handled in `lib/app/app.dart`.
- RevenueCat identity transitions are handled in `lib/core/services/subscription_service.dart`.
- Telemetry user-ID set/clear is handled in `lib/core/services/log_service.dart`.
- User-sendable support snapshot is generated in `lib/core/services/diagnostic_service.dart`.
- Pending usage queue ownership is enforced in `lib/core/services/usage_service.dart`.

## Pending Usage Ownership

- Authenticated pending usage syncs are owned by the exact Supabase user ID that
  created them.
- Signed-out state quarantines user-owned pending syncs by leaving them bound to
  their original user ID; they are not reassigned to the next account that
  signs in.
- Anonymous pending syncs are device-local only. They must never be rebound to
  whichever authenticated user signs in next.
- Anonymous-to-authenticated usage convergence happens through
  `syncFromServer()` local/server count reconciliation, not by reassigning
  anonymous queue entries.
- Sign out discards anonymous pending syncs and keeps authenticated pending
  syncs quarantined for the same user to resume later.
- Delete-account purges pending syncs owned by the deleted user and also drops
  anonymous queue entries because there is no longer a safe owner to attach
  them to.
- Stale pending syncs expire after 7 days and are discarded rather than applied
  to any later session.

## QA Validation Flow

1. Start signed out, open diagnostics, confirm:
   - Supabase ID is `(none)`.
   - RevenueCat ID is anonymous (`anon_...`) or `(none)` before SDK init.
   - Telemetry ID is `(none)`.
2. Sign in, open diagnostics, confirm:
   - Supabase ID, RevenueCat ID, and Telemetry ID align to the same user.
   - Identity status reports `Aligned`.
3. Sign out, open diagnostics, confirm:
   - Supabase ID and Telemetry ID return to `(none)`.
   - RevenueCat ID is anonymous.
4. Sign in with a different account on the same device, confirm:
   - RevenueCat ID and Telemetry ID switch to the new Supabase ID.
   - No stale entitlement state remains from prior account.

## Failure Handling

- If IDs diverge, capture a diagnostic report from Settings and attach it to a backlog item.
- Treat identity divergence as release-blocking for auth/purchase changes.
- Escalate RevenueCat transfer anomalies using `docs/REVENUECAT_POLICY.md`.
