# Identity Mapping

## Purpose

Define the canonical user-identity mapping across auth, subscriptions, and telemetry.

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
