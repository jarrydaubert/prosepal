# Native Device Debug Runbook

This runbook is for early tethered-iPhone proof of the native auth, purchase,
restore, and gateway legs. It is not release evidence by itself; convert useful
findings into tests, screenshots, or release notes after each pass.

## Local Xcode Environment

Use the local-only `ProsePal Local Staging` scheme for staging/device work.
Keep it under `xcuserdata`; do not copy its secret values into the shared
scheme.

The tracked native Xcode project uses the production ProsePal app identity:

```text
com.prosepal.prosepal
```

That is intentional. Production should reuse the existing ProsePal App Store
Connect app, Sign in with Apple identity, and subscription products. Staging is
UAT through Run environment values and the staging Supabase project; it is not a
second public ProsePal app. It should include:

```text
PROSEPAL_GATEWAY_URL=https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card
PROSEPAL_DEV_GATEWAY_SECRET=<staging-only-secret>
PROSEPAL_SUPABASE_URL=https://llolwgqphwnhbiqewmcq.supabase.co
PROSEPAL_SUPABASE_ANON_KEY=<supabase-anon-key>
PROSEPAL_PREMIUM_PRODUCT_IDS=com.prosepal.pro.yearly,com.prosepal.pro.monthly,com.prosepal.pro.weekly
PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID=com.prosepal.pro.yearly
```

For local paywall product and purchase testing before App Store sandbox products
are proven against the production bundle ID, select this StoreKit configuration
in the local staging scheme:

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

## UAT App Identity And App Store Sandbox

There are three related identities. Keep them separate:

| Identity | Installs beside production? | Bundle ID | Purchase source | Use when |
|----------|-----------------------------|-----------|-----------------|----------|
| Production app | N/A | `com.prosepal.prosepal` | existing App Store Connect products | production/TestFlight replacement for the archived Flutter app |
| Local side-by-side staging | Yes | `com.prosepal.prosepal.staging` | `App/ProsePalStaging.storekit` while tethered | Xcode UAT against staging Supabase on the same device as production |
| App Store/TestFlight UAT | Yes, if a separate app record is created | `com.prosepal.prosepal.staging` | App Store Connect sandbox products for the staging app record | end-to-end sandbox receipt/notification/reconciliation proof |

The tracked project includes a separate `ProsePal Staging` app target and shared
scheme. The shared scheme contains no secrets. To run staging fully, restore or
recreate the ignored local `ProsePal Local Staging` scheme so it targets the
`ProsePal Staging` app and carries the staging Run environment values.

The staging bundle still needs human Apple/Supabase setup before it is a fully
working device/TestFlight environment: Apple Developer App ID, Sign in with
Apple capability, signing profile, Supabase Auth Apple-provider allowance, and
an App Store Connect/TestFlight decision for sandbox receipt testing. Do not
create a second public listing casually; if an App Store Connect record is
needed for TestFlight UAT, keep the intent internal and document it before
creating products.

For App Store sandbox purchase testing:

- Use a human-owned App Store Connect sandbox Apple Account. Never commit or
  paste its credentials into docs, schemes, scripts, logs, or issue comments.
- Local StoreKit configuration is enough to validate native StoreKit UI and
  product handling, but it is not proof that App Store Connect products,
  receipts, App Store Server Notifications, or reconciliation work.
- TestFlight / App Store sandbox evidence must cover product load, purchase
  cancel, pending if reproducible, success, restore, expiry/refund or equivalent
  server notification, and reconciliation to `user_entitlements`.
- Sign in with Apple evidence must be captured for the bundle ID under test.
  A staging bundle ID will need its own Apple Developer App ID capability and
  Supabase Auth Apple-provider allowance; production uses `com.prosepal.prosepal`.

Useful Apple references:

- Sandbox accounts:
  <https://developer.apple.com/help/app-store-connect/test-in-app-purchases/create-a-sandbox-apple-account/>
- TestFlight purchases:
  <https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight/>
- App records:
  <https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/>
- Sign in with Apple configuration:
  <https://developer.apple.com/help/account/capabilities/configure-sign-in-with-apple-for-the-web/>

Back up the local staging scheme outside Git after editing it:

```bash
mkdir -p ~/.config/prosepal/xcode-schemes
cp "prosepal-ios/ProsePal.xcodeproj/xcuserdata/$USER.xcuserdatad/xcschemes/ProsePal Local Staging.xcscheme" ~/.config/prosepal/xcode-schemes/
chmod 600 ~/.config/prosepal/xcode-schemes/"ProsePal Local Staging.xcscheme"
```

If the local scheme disappears after worktree cleanup, restore it without
printing any secret values:

```bash
./scripts/restore-local-staging-scheme.sh
```

## Staging Support Status

| Surface | Staging status |
|---------|----------------|
| Standard generation, signed out | Supported through the staging gateway dev-secret guard. |
| Standard generation, signed in | Supported when Supabase Auth is configured and a valid access token is present; usage is enforced by the gateway RPC. |
| Sign in with Apple | Native entitlement and Supabase Auth REST client are present. Production requires setup for `com.prosepal.prosepal`; side-by-side staging requires separate setup for `com.prosepal.prosepal.staging`. |
| Paywall product loading | Supported through StoreKit 2 using configured product IDs. Use `App/ProsePalStaging.storekit` for local testing until App Store sandbox products are proven against the production bundle. |
| Purchase / restore UI | Supported through StoreKit 2 for local StoreKit testing and App Store sandbox once products exist. |
| Premium generation | Not yet supported by the staging gateway; Premium requests currently fail closed server-side. This needs a gateway/entitlement PR before full Premium generation testing. |

## OSLog Filters

Filter Xcode Console or Console.app by subsystem:

```text
com.prosepal.prosepal
com.prosepal.prosepal.staging
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
| App startup | `MomentAppRootView.body.task` | persisted auth load starts after launch |
| Auth/account initial state | `MomentAccountModel.loadInitialState` | keychain session and local entitlement state are loaded |
| Auth session load | `MomentAccountModel.loadAuthSession` | keychain session is loaded or cleared |
| Apple request start | `MomentAccountModel.beginAppleSignInRequest` | nonce generated once; duplicate taps ignored |
| Apple completion | `MomentAppleSignInControl.handle` | Apple sheet returned success/cancel/failure |
| Supabase exchange | `MomentAccountModel.completeAppleSignIn` | ID token is exchanged without logging token value |
| Auth REST call | `SupabaseAuthClient.signInWithIDToken` | Supabase receives provider/id-token exchange request |
| Session persist | `AuthSessionController.replaceSession` | access token stored in keychain |
| Product load | `MomentAccountModel.loadSubscriptionProducts` | paywall asks for configured products |
| StoreKit products | `StoreKitSubscriptionClient.loadProducts` | App Store products resolve from configured IDs |
| Purchase start | `MomentAccountModel.purchasePremium` | selected product ID is used |
| StoreKit purchase | `StoreKitSubscriptionClient.purchase` | purchase result is success/pending/cancelled |
| Restore start | `MomentAccountModel.restorePurchases` | paywall/settings restore path starts |
| StoreKit restore | `StoreKitSubscriptionClient.restorePurchases` | App Store sync completes or fails safely |
| Purchase result | `MomentAccountModel.applySubscriptionPurchaseResult` | local Premium UI changes only for active entitlement |
| Moment setup changed | `MomentModel.resetDraftForMomentChange` | person-first edits clear stale draft state without starting generation |
| Moment draft started | `MomentModel.draftNow` | `Write draft`, `Try again`, or an explicit adjustment starts generation |
| Private draft | `FoundationModelsPrivateDraftClient.draft` | everyday lane uses local private drafting when available |
| Careful draft | `GatewayCarefulMomentClient.generate` | current careful lane reaches staging gateway without printing values |
| Gateway request | `GatewayMessageWritingClient.generateCard` | auth/dev-secret headers are configured without printing values |
| Draft response | `MomentModel.draftNow` / `MomentModel.takeMoreCareNow` | result/error states render from service responses |
| Sign out | `MomentAccountModel.signOut` | keychain, biometric, signed-in, and stale Premium UI state clear |

## Manual Pass Checklist

Run these with the device tethered:

1. Fresh install launches welcome and completes to Moment.
2. Everyday Moment draft works through the private lane when the device supports
   it, or shows an honest unavailable state when it does not.
3. Take more care opens/uses the careful lane without exposing provider/model
   language.
4. Premium tap opens paywall and does not force sign-in before purchase.
5. Product rows load; if not configured, unavailable state is visible.
6. Cancel purchase; Premium remains locked and paywall remains usable.
7. Pending purchase, if sandbox can produce it; Premium remains locked.
8. Successful sandbox purchase; local Premium UI updates, while future
   Premium/extras gateway behavior still depends on server entitlement.
9. Restore from paywall; success/no-active-subscription/error states are honest.
10. Restore from Settings uses the same restore path.
11. Sign in with Apple from Settings; session persists across relaunch.
12. Sign in with Apple from Paywall; paywall stays purchase-first and sync is
    framed as continuity.
13. Take more care while signed in; gateway request includes auth token path and
    logs authenticated behavior without token/content exposure.
14. Sign out clears signed-in state, biometric lock, and stale Premium UI.

For App Store sandbox evidence, add:

15. Product load from App Store Connect products, not only local StoreKit.
16. Purchase with sandbox Apple Account; app receives an active local
    entitlement.
17. App Store Server Notification event is written in staging without granting
    entitlement for harmless TEST notifications.
18. Reconciliation agrees with the App Store Server API for the signed-in user.
19. Restore after reinstall/account switch resolves honestly and does not carry
    stale Premium UI across identities.

## Automated Coverage

Before/after manual device work, run:

```bash
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Relevant native tests:

- `MomentAccountModelTests`
- `MomentModelTests`
- `MessageWritingServiceTests`
- `RelationshipVaultTests`
- `ProsePalAppIntentsTests`
- `CardContractTests`
- `NativeDiagnosticsTests`
- `NativeRuntimeReadinessTests`
- `MessageWritingClientTests`
- `AuthSessionTests`

## Staging DNS / Inactive Project Check

If device generation fails with:

```text
NSURLErrorDomain Code=-1003
A server with the specified hostname could not be found
```

check DNS and project status before changing app code:

```bash
nslookup llolwgqphwnhbiqewmcq.supabase.co
supabase projects list --output json
```

If the project shows `status: INACTIVE` or the hostname returns `NXDOMAIN`,
resume `prosepal-staging` in the Supabase dashboard and wait for DNS to return.
The expected staging project is `llolwgqphwnhbiqewmcq`; do not touch production
`mwoxtqxzunsjmbdqezif`.
