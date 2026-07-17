# How to Use Staging

This runbook explains how to use the internal ProsePal staging app and Supabase
project without leaking secrets or touching production.

## Environment identities

| Environment | Bundle ID | Use |
|---|---|---|
| Production/TestFlight | `com.prosepal.prosepal` | Existing public ProsePal App Store identity |
| Side-by-side staging | `com.prosepal.prosepal.staging` | Internal UAT against staging services |

Known Supabase project references:

- staging: `llolwgqphwnhbiqewmcq`
- production: `mwoxtqxzunsjmbdqezif`

Never infer the mutation target from `supabase status`; it describes the local
stack. Remote changes require an explicit staging project reference or an
explicit `STAGING_DB_URL`.

## Local staging scheme

The shared `ProsePal Staging` scheme contains no secrets. Real staging runs use
the ignored `ProsePal Local Staging` scheme under `xcuserdata`.

Treat the ignored local scheme as a credential-bearing artifact. Never paste,
upload, or attach the complete scheme, an environment dump, or verbose command
output to an issue, chat, or evidence bundle. Share only redacted configuration
names and validated facts such as `dev_secret_configured=true`. Rotate the
staging development secret immediately if its value appears outside the approved
local files or Supabase staging secrets.

Expected Run environment keys:

```text
PROSEPAL_GATEWAY_URL=https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card
PROSEPAL_DEV_GATEWAY_SECRET=<staging-only-secret>
PROSEPAL_SUPABASE_URL=https://llolwgqphwnhbiqewmcq.supabase.co
PROSEPAL_SUPABASE_ANON_KEY=<publishable-key>
PROSEPAL_PREMIUM_PRODUCT_IDS=com.prosepal.pro.yearly,com.prosepal.pro.monthly,com.prosepal.pro.weekly
PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID=com.prosepal.pro.yearly
```

Restore and verify the scheme without printing values:

```bash
./scripts/restore-local-staging-scheme.sh
./scripts/verify-native-staging-plumbing.sh
```

### Local StoreKit configuration

The staging bundle `com.prosepal.prosepal.staging` has no products in App Store
Connect — the `com.prosepal.pro.*` products belong to the production app record.
On-device and simulator staging runs therefore return products only when the
local `ProsePalStaging.storekit` configuration is active for the Run action.

A scheme selects that configuration through
`StoreKitConfigurationFileReference identifier`. Xcode owns this value: selecting
`ProsePalStaging.storekit` from a clean scheme writes
`../../App/ProsePalStaging.storekit`, and that is the canonical reference. Do not
hand-substitute a different spelling such as a bare `App/ProsePalStaging.storekit`
— it is not what Xcode produces. If two identically named entries ever appear in
the dropdown, remove the StoreKit reference from the scheme entirely, reopen
Xcode, and re-select the file so Xcode rewrites a single clean reference.

The scheme path is **not** a cause of zero products. A clean-room experiment
(Xcode 26.6, iOS 26.4 and 26.5 simulators) showed that a brand-new minimal
configuration with a single unrelated product also returns zero, with
`SKTestSession` failing at `[SKTestSession] Error saving configuration file:
Error Domain=SKInternalErrorDomain Code=3`. That is an Xcode/StoreKit
test-runtime failure — the simulator's `storekitd` cannot persist the test
configuration — independent of the `.storekit` contents, the scheme path, the
runtime version, and a freshly erased simulator. When products come back empty,
suspect the StoreKit test runtime, not this configuration. The correct proving
grounds are Apple sandbox or TestFlight (see below).

Local StoreKit testing is independent of App Store Connect. Verifying the real
production products requires the production bundle against Apple sandbox or
TestFlight; it cannot be proven from a local `.storekit` file.

Back up the ignored local scheme outside Git after editing:

```bash
mkdir -p ~/.config/prosepal/xcode-schemes
cp "prosepal-ios/ProsePal.xcodeproj/xcuserdata/$USER.xcuserdatad/xcschemes/ProsePal Local Staging.xcscheme" \
  ~/.config/prosepal/xcode-schemes/
chmod 600 ~/.config/prosepal/xcode-schemes/ProsePal\ Local\ Staging.xcscheme
```

## Device signing

The staging bundle needs an explicit Apple Developer App ID and provisioning
profile with Sign in with Apple enabled. A wildcard team profile cannot carry
the `com.apple.developer.applesignin` entitlement. Fix the App ID/profile rather
than removing the entitlement from the app.

## Local StoreKit

For deterministic tethered development, select:

```text
App/ProsePalStaging.storekit
```

Xcode stores that selection as the identifier `../../App/ProsePalStaging.storekit`
(see [Local StoreKit configuration](#local-storekit-configuration) for why this
Xcode-owned value is canonical and why the path is not the cause of a zero-product
result). If a scheme is restored or edited while Xcode is open, quit Xcode
completely before reopening the project so it does not run with a cached scheme.
Opening the paywall on a working StoreKit test runtime must log a product request
that returns all three configured identifiers; a zero-product result is not
accepted as local StoreKit proof — but confirm the runtime is healthy (no
`SKInternalErrorDomain Code=3`) before blaming the configuration.

The product identifiers live under
`subscriptionGroups[].subscriptions[]`, not the top-level `products` array.
Local StoreKit proves client UI and transaction handling only; it does not prove
App Store Connect products, server notifications, refund, or reconciliation.

## Safe Edge Function deployment

Deploy only after explicit human approval and use the staging reference:

```bash
supabase functions deploy generate-card --project-ref llolwgqphwnhbiqewmcq
```

Anonymous staging generation requires both:

- `GATEWAY_DEV_ALLOW_ANONYMOUS=true`; and
- a configured `PROSEPAL_DEV_GATEWAY_SECRET` sent by the local staging app.

The function fails closed when the flag is enabled without the secret.

### Checking for deployment drift

Deployed Edge Functions can lag the repository. A batch deploy pins a version,
then later refactors land in `supabase/functions/` without redeploying, so the
running function is older than the source. Symptoms are runtime behaviour that
the current source cannot explain (for example an HTTP status the source no
longer returns). Confirm before trusting source alone:

```bash
supabase functions download <slug> --project-ref llolwgqphwnhbiqewmcq --workdir /tmp/deployed-<slug>
diff supabase/functions/<slug>/index.ts /tmp/deployed-<slug>/supabase/functions/<slug>/index.ts
```

An empty diff means the deployed function matches the repository. A non-empty
diff means the deployed function is stale; redeploy from source only after
explicit human approval (see the deploy step above).

## Safe database migration

`STAGING_DB_URL` is a secret because it embeds database credentials. Keep it in
the human operator’s shell and never print it.

```bash
STAGING_DB_URL='postgresql://...' ./scripts/supabase-staging.sh db-push
```

The guarded helper requires a dry run and explicit confirmation. Never use
`supabase db push --linked` from a production-linked checkout.

## Gateway smoke

```bash
./scripts/prosepal-staging-smoke.sh
```

A healthy response is HTTP 200 with a standard lane, no fallback, and three
generated messages. The script obtains the local development secret without
printing it.

Request-ledger proof must demonstrate:

- last-free-allowance races produce one provider call and one charge;
- duplicate keys produce one provider call and safe replay;
- provider failure is reclaimable without consuming usage;
- abandoned leases become reclaimable;
- expired replay payloads require a fresh client key; and
- scheduled cleanup succeeds and removes expired data.

Run these probes only against staging identities created for the test.

## Apple and account continuity

Use human-owned sandbox accounts and never store their credentials in the
repository. Test Apple sign-in both with a matching existing-account email and
with Hide My Email, because private relay may create a separate Supabase
identity. A continuity/linking decision is required before treating those
accounts as interchangeable.

Following the [Supabase native Apple configuration
guide](https://supabase.com/docs/guides/auth/social-login/auth-apple#configuration-swift-native),
the staging project's Authentication → Providers → Apple → Client IDs must
allow both native token audiences:

```text
com.prosepal.prosepal
com.prosepal.prosepal.staging
```

Keep the production Supabase project limited to approved production identities.
An `Unacceptable audience in id_token` auth log means the App ID that signed the
token is missing from the target project's Apple Client IDs; fix the provider
allow-list rather than changing the app nonce flow or weakening token checks.

### Apple account-deletion revocation credentials

After a successful Supabase Apple sign-in, the app forwards the Apple
authorization code to the `exchange-apple-token` function to store a refresh
token for later account-deletion revocation. That function needs four Apple
server secrets to mint the client secret:

```text
APPLE_TEAM_ID
APPLE_CLIENT_ID
APPLE_KEY_ID
APPLE_PRIVATE_KEY
```

When any is missing, `readAppleServerConfig` returns nothing and the function
answers with a 5xx, which the client surfaces as
`auth_apple_revocation_material_failed outcome=server_unavailable`. Sign-in then
reports a server-unavailable error even though the Supabase token exchange
itself succeeded. These must be configured as function secrets (never in the app
bundle or a scheme); the private key is the `.p8` contents with real newlines or
`\n` escapes.

Staging status (2026-07-16): all four secrets are configured, real-device Sign
in with Apple succeeded, revocation material stored successfully, and
`exchange-apple-token` worked without redeployment. Treat this section as setup
guidance for new environments, not a current staging blocker.

## DNS and inactive projects

If the staging hostname returns `NXDOMAIN` or the app reports
`NSURLErrorDomain Code=-1003`, check:

```bash
supabase projects list --output json
```

Resume an inactive staging project in the dashboard and wait for DNS before
changing app code.

## Pass criteria

- The app targets the staging URL and bundle identity.
- No production project is mutated.
- No secret is printed, committed, or placed in a shared scheme.
- Gateway, auth, StoreKit mode, and target identity are named in private release
  evidence.
- Any failure becomes backlog work with a deterministic definition of done.
