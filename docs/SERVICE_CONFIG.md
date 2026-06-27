# Service Configuration

This document covers active native iOS service configuration.

For the archived Flutter production app, use tag
`flutter-prod-freeze-2026-06-25`, branch `legacy/flutter-production-reference`,
and the historical docs under `docs/legacy-flutter/`.

## Native Staging

Production native identity reuses the existing ProsePal App Store Connect app:

```text
com.prosepal.prosepal
```

Staging is UAT through staging Supabase, local StoreKit/sandbox configuration,
and the ignored local Xcode scheme. Do not create a second public ProsePal app
unless there is a deliberate release decision to do so.

Environment identities:

| Environment | Bundle ID | Display name | Install behavior | Notes |
|-------------|-----------|--------------|------------------|-------|
| Production | `com.prosepal.prosepal` | `ProsePal` | normal production/TestFlight app | existing App Store Connect app and product IDs |
| Local staging scheme | `com.prosepal.prosepal` | `ProsePal` | replaces production on the device | staging Supabase and local StoreKit via ignored scheme |
| Side-by-side UAT app | proposed `com.prosepal.prosepal.staging` | proposed `ProsePal Staging` | can install beside production | not implemented yet; needs separate Apple Developer/App Store Connect/Auth setup |

The side-by-side UAT app is useful, but it is not just a scheme rename. It
needs a separate bundle identity, signing capability setup, keychain/storage
separation, display name, and App Store sandbox/TestFlight decision.

Known staging ref:

```text
llolwgqphwnhbiqewmcq
```

Native staging uses:

- Supabase Edge Function gateway: `generate-card`
- Supabase Auth for Sign in with Apple session exchange
- StoreKit 2 local/sandbox product loading
- App Store Server Notifications V2 and reconciliation functions for future
  server-side entitlement proof

## Xcode Run Environment

Use a local-only scheme for device testing. Do not commit local scheme secrets.

Common keys:

- `PROSEPAL_GATEWAY_URL`
- `PROSEPAL_DEV_GATEWAY_SECRET` (staging only)
- `PROSEPAL_SUPABASE_URL`
- `PROSEPAL_SUPABASE_ANON_KEY`
- `PROSEPAL_PREMIUM_PRODUCT_IDS`
- `PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID`

See `prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md` for setup steps.

## Supabase Secrets

Secrets are configured manually in the Supabase dashboard or CLI by the human
operator. Do not print or commit values.

Expected staging secret names include:

- `PROSEPAL_DEV_GATEWAY_SECRET`
- provider/gateway keys required by `generate-card`
- App Store Server API / ASSN V2 verification material for entitlement work
- feedback/email provider secrets when feedback sending is enabled

## StoreKit

Native product IDs reused from the existing ProsePal App Store Connect app:

- `com.prosepal.pro.yearly`
- `com.prosepal.pro.monthly`
- `com.prosepal.pro.weekly`

StoreKit config:

- `prosepal-ios/App/ProsePalStaging.storekit`

The local StoreKit file is for simulator/dev proof only. Production entitlement
truth belongs to the Supabase App Store notification/reconciliation path once
staging is proven.

App Store sandbox/TestFlight proof requires human-owned sandbox tester accounts
and App Store Connect products for the bundle/app record under test. Do not
commit sandbox tester credentials, StoreKit receipts, App Store Server API
material, or signed payloads. Useful Apple references:

- <https://developer.apple.com/help/app-store-connect/test-in-app-purchases/create-a-sandbox-apple-account/>
- <https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight/>

## Not Native Defaults

Do not add these to the active native client by default:

- RevenueCat
- Firebase AI / Vertex AI / Gemini-direct client path
- provider-specific generation SDKs
- Sentry or analytics SDKs without a separate privacy/product decision
