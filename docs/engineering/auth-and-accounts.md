# Authentication and Accounts

ProsePal provides anonymous first use and optional Sign in with Apple for
continuity, authenticated gateway usage, and account controls.

## Sign-in flow

```text
Apple authorization
  -> cryptographically random nonce and SHA-256 request nonce
  -> Apple ID token + one-time authorization code + opaque Apple user ID
  -> Supabase Auth token exchange
  -> authenticated exchange-apple-token Edge Function
  -> validated Apple grant; refresh token stored server-side for deletion only
  -> AuthSession stored in Keychain
  -> account and entitlement refresh
```

The native app sends the Apple identity token and raw nonce to the Supabase Auth
REST boundary. After Supabase authenticates the caller, it forwards the one-time
authorization code and opaque Apple user ID to `exchange-apple-token` with the
new Supabase access token. The server binds Apple’s token response to the
authenticated Apple identity and configured client ID before storing only the
refresh token required for later revocation. Authorization codes, Apple access
tokens, client-secret JWTs, private keys, and identity tokens are not logged or
persisted by this flow.

The app requests no Apple contact scopes because it does not consume the
credential’s full name or email fields. The cryptographic nonce and Supabase ID-
token validation remain the login boundary.

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
  refresh cannot resurrect an old session; and
- preserves the opaque Apple credential user ID across refresh so
  AuthenticationServices can re-check the account relationship.

## Apple credential lifecycle

`SystemAppleCredentialStateProvider` observes
`ASAuthorizationAppleIDProvider.credentialRevokedNotification` and performs a
bounded `getCredentialState` check for the opaque Apple user ID kept with the
Keychain session. Authorized credentials remain signed in. Revoked, not-found,
or transferred credentials clear the ProsePal session and account-scoped
entitlement state. A revocation notification also fails closed if the follow-up
state check is unavailable. These transitions do not erase relationship memory,
saved drafts, or other device-local writing.

A transient credential-state error during ordinary launch does not invent a
revocation or discard a refreshable Supabase session.

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
bundle. For an Apple account, deletion requires the stored Apple refresh token,
revokes it through Apple’s endpoint, validates every cleanup result, and only
then deletes the Supabase auth user. Apple, database, timeout, or auth-deletion
failure keeps the account and credential row available for an idempotent retry.
The credential row is removed by its `auth.users` cascade after successful auth
deletion.

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
- `prosepal-ios/Sources/ProsePalAPI/AppleAccountLifecycleClient.swift`
- `prosepal-ios/Sources/ProsePalAPI/AppleCredentialState.swift`
- `prosepal-ios/Sources/ProsePalAPI/KeychainAuthSessionStore.swift`
- `prosepal-ios/Sources/ProsePalAPI/AccountMaintenanceClient.swift`
- `supabase/functions/delete-user/`
- `supabase/functions/exchange-apple-token/`
