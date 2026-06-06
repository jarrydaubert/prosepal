# Service Endpoints Map

Purpose: document the SDK methods Prosepal calls, grouped by integration area.

For open gaps, flaky behavior, or pending improvements, use `docs/BACKLOG.md` only.

## Native iOS Staging

The native SwiftUI rewrite should keep a narrow service surface:

- `URLSession` request to the ProsePal gateway contract:
  - `POST /functions/v1/generate-card`
- Supabase Auth REST exchange for Sign in with Apple:
  - token exchange through the configured Supabase Auth endpoint
- StoreKit 2 for local native purchase/restore R&D:
  - product loading
  - purchase
  - restore/sync
  - transaction entitlement state

The native app must not call Firebase AI, Vertex AI, or provider generation SDKs.

## Flutter Production Reference

The sections below document the live Flutter production/reference SDK surfaces.

## Supabase Auth

- `auth.currentUser`
- `auth.onAuthStateChange`
- `auth.signInWithIdToken()`
- `auth.signInWithPassword()`
- `auth.signUp()`
- `auth.resetPasswordForEmail()`
- `auth.signInWithOtp()`
- `auth.updateUser()`
- `auth.signOut()`
- `auth.currentSession`
- `functions.invoke()`

## Sign In With Apple

- `generateRawNonce()`
- `isAvailable()`
- `getAppleIDCredential()`
- `onCredentialRevoked`

## Google Sign In

- `initialize()`
- `isAvailable()`
- `attemptLightweightAuthentication()`
- `authenticate()`
- `signOut()`
- `disconnect()`

## RevenueCat

- `Purchases.configure()`
- `Purchases.getCustomerInfo()`
- `Purchases.getOfferings()`
- `Purchases.purchase()`
- `Purchases.restorePurchases()`
- `RevenueCatUI.presentPaywall()`
- `RevenueCatUI.presentPaywallIfNeeded()`
- `RevenueCatUI.presentCustomerCenter()`
- `Purchases.addCustomerInfoUpdateListener()`
- `Purchases.logIn()`
- `Purchases.logOut()`

## Firebase AI

- `FirebaseAI.googleAI()`
- `generativeModel()`
- `model.generateContent()`

## Local Auth (Biometrics)

- `canCheckBiometrics`
- `isDeviceSupported()`
- `getAvailableBiometrics()`
- `authenticate()`

## Firebase Core and Telemetry

- `Firebase.initializeApp()`
- `FirebaseCrashlytics.recordFlutterFatalError`
- `FirebaseCrashlytics.recordError()`
- `FirebaseAnalytics.logEvent()`
- `FirebaseAnalytics.setUserId()`
- `FirebaseAnalytics.setUserProperty()`

## Other SDKs

- `Share.shareXFiles()` / `Share.share()`
- `InAppReview.requestReview()`
- `launchUrl()`

## Verification References

- Local/CI/device/FTL workflow and operational runbooks: `docs/DEVOPS.md`
- Test command quick reference: `test/README.md`
