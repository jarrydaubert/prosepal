# User Journeys

These journeys define how the iOS app should behave from the user’s point of
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
- After welcome, the tab bar keeps Write, Drafts, and Settings available;
  switching destinations preserves each destination's SwiftUI state for the
  current app session.
- Typing does not silently start generation.
- The user’s note remains present after offline or retryable failure.
- The app never exposes provider or model names.

## Private and careful drafting

```text
Write Draft
  -> route by occasion policy, availability, and connectivity
     -> Private Draft on device
     -> careful writing through the gateway
  -> user-safe draft or honest error
```

Private drafting is preferred for ordinary moments where the device model is
available. Sensitive or higher-stakes occasions route to careful writing
automatically. It is not a Premium gate or a post-draft action. Eligible
technical failures may fall back to the other lane; content blocks do not
bypass the refusal.

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

- Copy and system sharing act on the current visible draft. Share opens the
  system chooser; ProsePal neither promises a named destination nor treats
  opening or cancelling that chooser as a successful send.
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
- Premium is presented as higher writing limits, not unlimited use. Exact
  remaining-use and reset copy appears only when approved structured policy
  metadata reaches the user-facing state.

## Sign in with Apple

```text
Account entry
  -> Apple authorization with nonce
  -> Supabase token exchange
  -> authenticated one-time-code exchange for deletion revocation material
  -> Keychain session
  -> Apple credential-state checks and revocation observation
  -> entitlement and account refresh
```

- Duplicate sign-in requests are ignored while one is in flight.
- Access tokens refresh before use; concurrent refresh callers share one task.
- Offline refresh preserves the signed-in identity for recovery.
- Terminal refresh rejection clears the session.
- Sign-out cannot be undone by a late refresh result.
- Revoked, missing, or transferred Apple credentials return the app to signed
  out without deleting local drafts or relationship memory.

## Account deletion

```text
Authenticated user confirms deletion
  -> server validates caller
  -> require and revoke stored Apple refresh material for Apple accounts
  -> validate app-data cleanup and delete auth data
  -> erase local account state and relationship vault
  -> report any partial local cleanup honestly
```

The server owns privileged deletion. The iOS app never contains a service
role key. A failure before final auth deletion starts guarantees that the auth
account remains and can be retried, although idempotent earlier cleanup may have
completed. If the final delete starts but cannot be confirmed, the app reports
that deletion is still being finalized, erases its local account state, and
explains that the user should retry only if sign-in remains possible. It does
not claim that the remote account survived a timed-out request.

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
