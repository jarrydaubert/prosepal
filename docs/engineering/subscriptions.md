# Subscriptions and Entitlement

The native app uses StoreKit 2 directly. ProsePal account sign-in is not a
prerequisite for product loading, purchase, or restore.

## Client responsibilities

`StoreKitSubscriptionClient`:

- loads only configured product identifiers;
- selects a recommended product when configured;
- purchases through StoreKit;
- distinguishes purchase success, cancellation, pending, and no entitlement;
- synchronizes StoreKit during restore;
- derives current entitlement from verified configured and explicitly retired
  products, so unrelated StoreKit transactions cannot abort the scan;
- combines current transactions with subscription renewal status; and
- exposes a launch-time `Transaction.updates` stream.

## Entitlement state

The client returns one of three states:

- `active`: verified subscribed or grace-period access, with product, expiry,
  renewal state, and transaction ownership;
- `confirmedInactive`: StoreKit verified billing retry, expiry, revocation, or
  the absence of an active ProsePal entitlement; or
- `unknown`: StoreKit could not establish safe truth because configuration,
  products, verification, ownership, or the store was unavailable.

Unknown never creates Premium. `MomentAccountModel` may retain previously verified
active entitlement during a transient unknown result for the same ProsePal
account. Confirmed inactivity and account identity changes clear that state.
This avoids both unsafe grants and false downgrades caused by a temporary store
failure.

## Transaction-update policy

```text
StoreKit Transaction.updates
  -> reject unverified update
  -> reject an explicitly different appAccountToken
  -> refresh serialized entitlement state
  -> correlate product and grant/removal effect
  -> finish only after safe convergence succeeds
  -> leave unfinished after convergence failure so StoreKit can redeliver
```

Unverified, mismatched, and uncorrelated transactions cannot unlock Premium and
are not finished. The listener begins when the root account model is created and
is cancelled when that model is released. Purchase transactions use the same
deferred-finish rule; StoreKit delivery is acknowledged only after the matching
active product has reached the account model.

## Entitlement ownership

StoreKit is authoritative for current on-device purchase state. Supabase App
Store notification and reconciliation functions provide the server-side source
for paid gateway limits and future cloud extras. The UI cannot grant server
capability merely by setting a local Premium flag.

When a valid signed-in Supabase UUID exists, purchase uses it as
`appAccountToken`. A transaction linked to a different UUID fails closed.
Unlinked transactions remain compatible with local Premium so a user can buy
before signing in; linking that purchase to server-side capability is a
separate reconciliation concern and must be proved in sandbox/TestFlight.

## Product identifiers

- `com.prosepal.pro.yearly`
- `com.prosepal.pro.monthly`
- `com.prosepal.pro.weekly`

The local `prosepal-ios/App/ProsePalStaging.storekit` file supports deterministic
development. It includes a test-only retired identifier that is recognized only
when a client explicitly opts into it; it never appears in the three-product
paywall. The app-hosted `ProsePalStoreKitTests` target exercises the real client
through `SKTestSession`. A skipped StoreKit Test is an open gate, not a pass, and
local testing is not proof that App Store Connect products, server
notifications, renewal, refund, or reconciliation work.

## Server boundaries

- `app-store-notifications` verifies App Store Server Notifications V2 and
  records entitlement events.
- `app-store-reconcile-entitlement` obtains and reconciles authoritative App
  Store state.
- `appAccountToken` is the ownership link when a valid signed-in Supabase UUID
  is available.

## User experience rules

- Do not force sign-in before purchase.
- Do not unlock after cancellation, pending state, or an unverified transaction.
- Do not clear same-account verified access merely because StoreKit is
  temporarily unavailable; show the verification problem honestly.
- Clear local Premium before reconciling a different ProsePal account.
- Keep Restore available from Paywall and Settings.
- Describe Premium as offering higher writing limits. Do not claim unlimited
  drafting, publish an exact allowance, or imply that careful writing is
  Premium-only unless the approved server policy and App Store metadata support
  that promise.
- Surface product-loading and restore failures honestly.

## Release proof

Package tests prove deterministic policy and model behavior. The app-hosted
StoreKit target must execute every direct scenario without skips on a working
Apple runtime. Sandbox/TestFlight evidence must then prove product loading,
purchase, restore, transaction updates, renewal or approval, Family Sharing
changes if enabled, revocation/refund, server notification, and reconciliation.
See [Release](../operations/release.md).
