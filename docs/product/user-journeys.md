# User Journeys

These journeys define how the native app should behave from the user’s point of
view. They are product contracts, not screen-by-screen implementation notes.

## First use and writing

```text
Launch
  -> Welcome, only when needed
  -> Start writing
  -> Person
  -> Relationship and moment
  -> What is true
  -> Write Draft
  -> Edit or adjust
  -> Copy, share/send, or save
```

- Welcome does not force sign-in, notifications, or purchase.
- After welcome, the native tab bar keeps Write, Drafts, and Settings available;
  switching destinations preserves each destination's SwiftUI state for the
  current app session.
- Typing does not silently start generation.
- The user’s note remains present after offline or retryable failure.
- The app never exposes provider or model names.

## Private and careful drafting

```text
Write Draft
  -> route by moment, register, availability, and connectivity
     -> Private Draft on device
     -> Take More Care through the gateway
  -> user-safe draft or honest error
```

Private drafting is preferred for ordinary moments where the device model is
available. Take More Care handles sensitive or higher-stakes writing. It is not
a Premium gate. Eligible technical failures may fall back to the other lane;
content blocks do not bypass the refusal.

## Draft revision

```text
Draft ready
  -> direct edit or adjustment
  -> snapshot current wording
  -> show revised wording
  -> Undo or Keep
```

The user can recover earlier wording during the session and after relaunch.
Changing the underlying moment invalidates stale generated output.

## Save, share, and delete

- Copy and native sharing act on the current visible draft.
- Saving is deliberate; generation alone does not create visible history.
- Saved drafts can be opened, edited, and shared. Deletion asks for confirmation;
  failed edits or deletions retain the last persisted draft and show an honest error.
- Truth Beads and Voice Cards require destructive confirmation.
- Relationship-memory deletion rolls back after a failed save and reports that
  the item remains stored.

## Purchase and restore

```text
Paywall or limit boundary
  -> load StoreKit products
  -> purchase, cancel, or remain pending
  -> refresh entitlement
  -> unlock only after verified convergence
```

- Purchase does not require a ProsePal account first.
- Cancellation and pending purchase do not unlock Premium.
- Restore is available from Paywall and Settings.
- Store ownership comes from Apple; server policy remains authoritative for
  server-side paid limits or extras.

## Sign in with Apple

```text
Account entry
  -> Apple authorization with nonce
  -> Supabase token exchange
  -> Keychain session
  -> entitlement and account refresh
```

- Duplicate sign-in requests are ignored while one is in flight.
- Access tokens refresh before use; concurrent refresh callers share one task.
- Offline refresh preserves the signed-in identity for recovery.
- Terminal refresh rejection clears the session.
- Sign-out cannot be undone by a late refresh result.

## Account deletion

```text
Authenticated user confirms deletion
  -> server validates caller
  -> revoke Apple authorization when configured
  -> delete server/auth data
  -> erase local account state and relationship vault
  -> report any partial local cleanup honestly
```

The server owns privileged deletion. The native app never contains a service
role key.

## Account switching

After User A signs out, User B must not inherit User A’s session, Premium state,
account-scoped diagnostics, or server usage. Local relationship memory is
device-local and follows the explicit local-data controls rather than being
silently rebound to another account.

## Optional system entry points

App Intent, Shortcuts, widget/control, and Share Extension handoffs may start a
Moment with sanitized context. A surface that cannot pass production-target and
handoff QA is omitted from v1 rather than allowed to destabilize the core app.

## Related documentation

- [Capabilities](./capabilities.md)
- [Authentication and accounts](../engineering/auth-and-accounts.md)
- [Subscriptions](../engineering/subscriptions.md)
- [Release contract](./v1-launch-contract.md)
