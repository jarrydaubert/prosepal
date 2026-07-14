# Subscriptions and Entitlement

The native app uses StoreKit 2 directly. ProsePal account sign-in is not a
prerequisite for product loading, purchase, or restore.

## Client responsibilities

`StoreKitSubscriptionClient`:

- loads only configured product identifiers;
- selects a recommended product when configured;
- purchases through StoreKit;
- distinguishes success, cancellation, pending, and no-active-entitlement;
- synchronizes StoreKit during restore;
- derives current entitlement from verified configured transactions, ignoring
  unrelated product IDs before treating verification failure as relevant; and
- exposes a launch-time `Transaction.updates` stream.

## Transaction-update policy

```text
StoreKit Transaction.updates
  -> reject unverified update
  -> refresh serialized entitlement state
  -> finish verified transaction only after convergence succeeds
  -> leave unfinished after convergence failure so StoreKit can redeliver
```

Unverified transactions cannot unlock Premium and are never finished. The
listener begins when the root account model is created and is cancelled when
that model is released.

## Entitlement ownership

StoreKit is authoritative for current on-device purchase state. Supabase App
Store notification and reconciliation functions provide the server-side source
for paid gateway limits and future cloud extras. The UI cannot grant server
capability merely by setting a local Premium flag.

## Product identifiers

- `com.prosepal.pro.yearly`
- `com.prosepal.pro.monthly`
- `com.prosepal.pro.weekly`

The local `prosepal-ios/App/ProsePalStaging.storekit` file supports deterministic
development. It is not proof that App Store Connect products, server
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
- Keep Restore available from Paywall and Settings.
- Explain limits and paid extras without claiming the careful writing route is
  Premium-only.
- Surface product-loading and restore failures honestly.

## Release proof

Local StoreKit tests prove client behaviour only. Sandbox/TestFlight evidence
must prove product loading, purchase, restore, transaction updates, renewal or
approval, Family Sharing changes where applicable, revocation/refund, server
notification, and reconciliation. See [Release](../operations/release.md).
