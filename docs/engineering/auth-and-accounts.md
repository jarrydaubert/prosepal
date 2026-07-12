# Authentication and Accounts

ProsePal provides anonymous first use and optional Sign in with Apple for
continuity, authenticated gateway usage, and account controls.

## Sign-in flow

```text
Apple authorization
  -> cryptographically random nonce and SHA-256 request nonce
  -> Apple ID token
  -> Supabase Auth token exchange
  -> AuthSession stored in Keychain
  -> account and entitlement refresh
```

The native app sends the Apple identity token and raw nonce to the Supabase Auth
REST boundary. It does not log either value.

## Session continuity

`AuthSessionController` is an actor that owns the stored session and access-token
refresh. It:

- returns an access token only when it is usable;
- coalesces concurrent refresh callers into one shared task;
- persists a rotated session before returning it;
- accepts rotated refresh tokens only when present;
- clears the session after terminal 400, 401, or 403 rejection;
- preserves the refreshable identity after offline or server failure; and
- cancels and drains in-flight refresh before replacement or sign-out, so a late
  refresh cannot resurrect an old session.

## Gateway authentication

When signed in, the gateway client obtains the current token immediately before
the request and sends it as a bearer token. `generate-card` validates that token
with Supabase Auth before request-ledger or provider work.

The staging gateway can support signed-out development calls only when anonymous
development mode and its separate secret are both configured. Production must
not use that path.

## Sign-out

Sign-out attempts the Supabase logout boundary, clears the Keychain session, and
resets account-scoped Premium and UI state. Local relationship data follows the
separate local-data controls rather than being silently attributed to another
account.

## Account deletion

The app calls the authenticated `delete-user` Edge Function. Privileged deletion
uses the server’s service role; no privileged credential exists in the native
bundle. Apple revocation material is exchanged and stored through the separate
`exchange-apple-token` boundary when that server configuration is enabled.

After server deletion, the app clears its session, entitlement state, local
relationship vault, saved drafts, and recovery state. Failure and partial local
cleanup remain visible; the user can retry local erasure through Privacy & data.

## Configuration

The app requires these public values for live auth:

- `PROSEPAL_SUPABASE_URL`
- `PROSEPAL_SUPABASE_ANON_KEY`

See [Configuration](../reference/configuration.md) for archive and runtime
delivery.

## Verification sources

- `prosepal-ios/Sources/ProsePalAPI/AuthSession.swift`
- `prosepal-ios/Sources/ProsePalAPI/SupabaseAuthClient.swift`
- `prosepal-ios/Sources/ProsePalAPI/KeychainAuthSessionStore.swift`
- `prosepal-ios/Sources/ProsePalAPI/AccountMaintenanceClient.swift`
- `supabase/functions/delete-user/`
- `supabase/functions/exchange-apple-token/`
