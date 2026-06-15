# Native Device Debug Runbook

This runbook is for early tethered-iPhone proof of the native auth, purchase,
restore, and gateway legs. It is not release evidence by itself; convert useful
findings into tests, screenshots, or release notes after each pass.

## Local Xcode Environment

Use the local-only `ProsePal Local Staging` scheme for staging/device work.
Keep it under `xcuserdata`; do not copy its secret values into the shared
scheme. It should include:

```text
PROSEPAL_GATEWAY_URL=https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card
PROSEPAL_DEV_GATEWAY_SECRET=<staging-only-secret>
PROSEPAL_SUPABASE_URL=https://llolwgqphwnhbiqewmcq.supabase.co
PROSEPAL_SUPABASE_ANON_KEY=<supabase-anon-key>
PROSEPAL_PREMIUM_PRODUCT_IDS=com.prosepal.pro.yearly,com.prosepal.pro.monthly,com.prosepal.pro.weekly
PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID=com.prosepal.pro.yearly
```

For local paywall product and purchase testing before App Store Connect products
are attached to the native bundle ID, select this StoreKit configuration in the
local staging scheme:

```text
App/ProsePalStaging.storekit
```

If `Product.products(for:)` returns zero products even though
`PROSEPAL_PREMIUM_PRODUCT_IDS` is configured, check the local scheme XML before
debugging StoreKit code. The local-only scheme should contain a StoreKit
reference that resolves from the `.xcscheme` file to the tracked config:

```text
StoreKitConfigurationFileReference identifier="../../../../App/ProsePalStaging.storekit"
```

The path above is for:

```text
ProsePal.xcodeproj/xcuserdata/<user>.xcuserdatad/xcschemes/ProsePal Local Staging.xcscheme
```

Do not commit that local scheme, because it also carries staging environment
values. If Xcode's dropdown shows two `ProsePalStaging.storekit` entries, choose
the one that persists to the local scheme and resolves to
`prosepal-ios/App/ProsePalStaging.storekit`.

The StoreKit file has an empty top-level `products` array because these are
auto-renewable subscriptions. The product IDs live under
`subscriptionGroups[].subscriptions[]`; the expected local count is three:
yearly, monthly, and weekly.

Do not commit Xcode scheme secrets, Supabase `.temp` link state, provider keys,
StoreKit receipts, auth tokens, or screenshots under tracked paths.

## Staging Support Status

| Surface | Staging status |
|---------|----------------|
| Standard generation, signed out | Supported through the staging gateway dev-secret guard. |
| Standard generation, signed in | Supported when Supabase Auth is configured and a valid access token is present; usage is enforced by the gateway RPC. |
| Sign in with Apple | Native entitlement and Supabase Auth REST client are present. Requires Apple Developer bundle setup and Supabase Auth Apple provider setup for `com.prosepal.prosepal.native`. |
| Paywall product loading | Supported through StoreKit 2 using configured product IDs. Use `App/ProsePalStaging.storekit` for local testing if App Store Connect products are not ready for the native bundle. |
| Purchase / restore UI | Supported through StoreKit 2 for local StoreKit testing and App Store sandbox once products exist. |
| Premium generation | Not yet supported by the staging gateway; Premium requests currently fail closed server-side. This needs a gateway/entitlement PR before full Premium generation testing. |

## OSLog Filters

Filter Xcode Console or Console.app by subsystem:

```text
com.prosepal.native
```

Useful event families:

```text
app_started
onboarding_completed
tab_selected
paywall_shown
subscription_event
auth_apple_started
auth_apple_succeeded
auth_apple_failed
gateway_request_started
gateway_request_succeeded
gateway_request_failed
generation_succeeded
generation_failed
```

Logs must remain privacy-safe: no raw recipient names, user card details, prompt
text, generated text, auth tokens, provider keys, StoreKit receipts, or provider
payloads.

## Breakpoints For First Proof

Set symbolic/file breakpoints on these functions while proving the flow:

| Leg | Breakpoint | Confirms |
|-----|------------|----------|
| App startup | `ProsePalRootView.body.task` | persisted auth load starts after launch |
| Auth session load | `ProsePalAppModel.loadAuthSession` | keychain session is loaded or cleared |
| Apple request start | `ProsePalAppModel.beginAppleSignInRequest` | nonce generated once; duplicate taps ignored |
| Apple completion | `AppleSignInControl.handle` | Apple sheet returned success/cancel/failure |
| Supabase exchange | `ProsePalAppModel.completeAppleSignIn` | ID token is exchanged without logging token value |
| Auth REST call | `SupabaseAuthClient.signInWithIDToken` | Supabase receives provider/id-token exchange request |
| Session persist | `AuthSessionController.replaceSession` | access token stored in keychain |
| Product load | `ProsePalAppModel.loadSubscriptionProducts` | paywall asks for configured products |
| StoreKit products | `StoreKitSubscriptionClient.loadProducts` | App Store products resolve from configured IDs |
| Purchase start | `ProsePalAppModel.purchasePremium` | selected product ID is used |
| StoreKit purchase | `StoreKitSubscriptionClient.purchase` | purchase result is success/pending/cancelled |
| Restore start | `ProsePalAppModel.restorePurchases` | paywall/settings restore path starts |
| StoreKit restore | `StoreKitSubscriptionClient.restorePurchases` | App Store sync completes or fails safely |
| Purchase result | `ProsePalAppModel.applySubscriptionPurchaseResult` | local Premium UI changes only for active entitlement |
| Gateway request | `GatewayMessageWritingClient.generateCard` | auth/dev-secret headers are configured without printing values |
| Gateway response | `ProsePalAppModel.generate` | usage/result/error states render from `CardResponse`/`GenerationError` |
| Sign out | `ProsePalAppModel.signOut` | keychain, biometric, signed-in, and stale Premium UI state clear |

## Manual Pass Checklist

Run these with the device tethered:

1. Fresh install launches welcome and completes to Create.
2. Standard generation works signed out through staging gateway.
3. Premium tap opens paywall and does not force sign-in before purchase.
4. Product rows load; if not configured, unavailable state is visible.
5. Cancel purchase; Premium remains locked and paywall remains usable.
6. Pending purchase, if sandbox can produce it; Premium remains locked.
7. Successful sandbox purchase; local Premium UI updates, then gateway Premium
   still depends on server entitlement behavior.
8. Restore from paywall; success/no-active-subscription/error states are honest.
9. Restore from Settings uses the same restore path.
10. Sign in with Apple from Settings; session persists across relaunch.
11. Sign in with Apple from Paywall; paywall stays purchase-first and sync is
    framed as continuity.
12. Generate while signed in; gateway request includes auth token path and logs
    authenticated behavior without token/content exposure.
13. Sign out clears signed-in state, biometric lock, and stale Premium UI.

## Automated Coverage

Before/after manual device work, run:

```bash
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Relevant native tests:

- `AuthPurchaseFlowTests`
- `SettingsParityStateTests`
- `UsagePolicyTests`
- `MessageWritingClientTests`
- `AuthSessionTests`
