# Staging

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

Back it up outside Git after editing:

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
