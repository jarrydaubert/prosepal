# Service Endpoints Map

> Complete map of all third-party SDK methods used by Prosepal with test coverage status.

**Legend:** ✅ Tested | ❌ Not tested | ⚠️ Manual/Device only

**Last verified:** December 2025

---

## 1. Supabase Auth

**Package:** `supabase_flutter: ^2.12.0`  
**Used for:** Authentication only (NO database)  
**Files:** `auth_service.dart`, `main.dart`, `app.dart`  
**Docs:** https://supabase.com/docs/guides/auth/testing

### SDK Methods Used

| SDK Method | Service Method | Location | Unit | Integration |
|------------|---------------|----------|:----:|:-----------:|
| `Supabase.instance.client` | (getter) | auth_service.dart:17 | ⚠️ | ✅ |
| `auth.currentUser` | `currentUser` | auth_service.dart:20 | ✅ | ✅ |
| `auth.onAuthStateChange` | `authStateChanges` | auth_service.dart:26 | ✅ | ✅ |
| `auth.signInWithIdToken()` | `signInWithApple()` | auth_service.dart:84 | ✅ | ✅ |
| `auth.signInWithOAuth()` | `signInWithGoogle()` | auth_service.dart:93 | ✅ | ✅ |
| `auth.signInWithPassword()` | `signInWithEmail()` | auth_service.dart:104 | ✅ | ✅ |
| `auth.signUp()` | `signUpWithEmail()` | auth_service.dart:115 | ✅ | ✅ |
| `auth.resetPasswordForEmail()` | `resetPassword()` | auth_service.dart:121 | ✅ | ✅ |
| `auth.signInWithOtp()` | `signInWithMagicLink()` | auth_service.dart:127 | ✅ | ✅ |
| `auth.updateUser()` (email) | `updateEmail()` | auth_service.dart:136 | ✅ | ✅ |
| `auth.updateUser()` (password) | `updatePassword()` | auth_service.dart:141 | ✅ | ✅ |
| `auth.signOut()` | `signOut()` | auth_service.dart:146 | ✅ | ✅ |
| `auth.currentSession` | `deleteAccount()` | auth_service.dart:163 | ✅ | ✅ |
| `functions.invoke()` | `deleteAccount()` | auth_service.dart:160 | ✅ | ✅ |

**Unit: 13/14** | **Integration: 13/14**

### Test Files
- `test/services/auth_service_with_mock_test.dart` (55 tests)
- `test/services/auth_service_crypto_test.dart` (12 tests)
- `test/services/auth_service_compliance_test.dart` (13 tests)
- `integration_test/auth_test.dart` (20 tests)

### Mock Strategy
**`mock_supabase_http_client` does NOT support auth** - only database CRUD operations.

**Our approach:** Custom `MockAuthService` implementing `IAuthService` interface.
- `createFakeUser()` / `createFakeSession()` - Rich fixtures
- `autoEmitAuthState` - Auto-emits auth events
- `methodErrors` map - Per-method error simulation
- Provider: `authServiceProvider` (overridable for tests)

---

## 2. Sign In With Apple (Native)

**Package:** `sign_in_with_apple: ^6.1.4`  
**Used for:** Native Apple Sign In credential  
**File:** `auth_service.dart`  
**Docs:** https://pub.dev/packages/sign_in_with_apple

### SDK Methods Used

| SDK Method | Service Method | Location | Unit | Integration |
|------------|---------------|----------|:----:|:-----------:|
| `SignInWithApple.getAppleIDCredential()` | `signInWithApple()` | auth_service.dart:71 | ⚠️ | ⚠️ |

**Unit: 0/1 (device only)** | **Integration: 0/1 (device only)**

### Notes
- Cannot be unit tested - requires real device with Apple ID
- iOS only - no Android equivalent
- Credential is passed to Supabase `signInWithIdToken()`

---

## 3. Google Sign In

**Package:** `google_sign_in: ^7.2.0` (in pubspec.yaml but **NOT USED**)  
**Actual implementation:** Supabase OAuth (`auth.signInWithOAuth()`)  
**File:** `auth_service.dart`  
**Docs:** https://supabase.com/docs/guides/auth/social-login/auth-google

### Current Implementation (OAuth - Browser Flow)

Google Sign In currently uses **Supabase OAuth flow** which opens a browser/webview to Google's login page, then redirects back to the app.

**Current flow:**
1. User taps "Sign in with Google"
2. `auth.signInWithOAuth(OAuthProvider.google)` called
3. Browser opens → Google login page displayed
4. User authenticates with Google
5. Redirect to `com.prosepal.prosepal://login-callback`
6. Supabase creates session

**SDK method:** `auth.signInWithOAuth()` - Listed in Supabase Auth section above

**Testing:** Covered via Supabase `signInWithGoogle()` mock in `MockAuthService`

### Best Practice: Native Google Sign In

> ⚠️ **Recommendation:** Supabase docs support BOTH approaches, but **native `google_sign_in`** provides better UX.

| Approach | UX | Setup Complexity | Package |
|----------|----|-----------------:|---------|
| **OAuth (current)** | Opens browser | Simple | None (built into Supabase) |
| **Native (recommended)** | Google popup in-app | More setup | `google_sign_in` |

**Native implementation (from Supabase docs):**
```dart
import 'package:google_sign_in/google_sign_in.dart';

Future<void> signInWithGoogle() async {
  final googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final googleUser = await googleSignIn.signIn();
  final googleAuth = await googleUser!.authentication;
  final idToken = googleAuth.idToken;

  if (idToken == null) throw Exception('No ID Token found.');

  await supabase.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
  );
}
```

**Benefits of native approach:**
- Better UX (Google popup within app, not browser redirect)
- Consistent with Apple Sign In (both use native SDKs)
- One Tap / automatic sign-in support
- No context switch to browser

**Note:** The `google_sign_in: ^7.2.0` package is already in pubspec.yaml but unused. Migration would use this existing dependency.

---

## 4. RevenueCat (Subscriptions)

**Package:** `purchases_flutter: ^9.10.2`, `purchases_ui_flutter: ^9.10.2`  
**Used for:** In-app subscriptions  
**File:** `subscription_service.dart`  
**Docs:** https://www.revenuecat.com/docs/test-and-launch/testing

### SDK Methods Used

| SDK Method | Service Method | Location | Unit | Integration |
|------------|---------------|----------|:----:|:-----------:|
| `Purchases.setLogLevel()` | `initialize()` | subscription_service.dart:93 | ✅ | ✅ |
| `Purchases.configure()` | `initialize()` | subscription_service.dart:97 | ✅ | ✅ |
| `Purchases.getCustomerInfo()` | `isPro()`, `getCustomerInfo()` | subscription_service.dart:113,125 | ✅ | ✅ |
| `Purchases.getOfferings()` | `getOfferings()` | subscription_service.dart:136 | ✅ | ✅ |
| `Purchases.purchase()` | `purchasePackage()` | subscription_service.dart:146 | ✅ | ✅ |
| `Purchases.restorePurchases()` | `restorePurchases()` | subscription_service.dart:170 | ✅ | ✅ |
| `RevenueCatUI.presentPaywall()` | `showPaywall()` | subscription_service.dart:187 | ✅ | ✅ |
| `RevenueCatUI.presentPaywallIfNeeded()` | `showPaywallIfNeeded()` | subscription_service.dart:204 | ✅ | ⚠️ |
| `RevenueCatUI.presentCustomerCenter()` | `showCustomerCenter()` | subscription_service.dart:220 | ✅ | ⚠️ |
| `Purchases.addCustomerInfoUpdateListener()` | `addCustomerInfoListener()` | subscription_service.dart:228 | ✅ | ✅ |
| `Purchases.logIn()` | `identifyUser()` | subscription_service.dart:238 | ✅ | ✅ |
| `Purchases.logOut()` | `logOut()` | subscription_service.dart:247 | ✅ | ⚠️ |

**Unit: 12/12** | **Integration: 9/12**

### Test Files
- `test/services/subscription_service_with_mock_test.dart` (74 tests)
- `integration_test/revenuecat_test.dart` (12 tests)

### Mock Strategy
Custom `MockSubscriptionService` implementing `ISubscriptionService` interface.

### Testing Environments
1. **Test Store** (current): Instant purchases, no sandbox accounts needed
2. **Apple Sandbox**: Real store simulation, requires sandbox tester account
3. **TestFlight**: Production-like, renewals every 24 hours

---

## 5. Google AI (Gemini)

**Package:** `google_generative_ai: ^0.4.7` ⚠️ **DEPRECATED**  
**Used for:** Message generation  
**File:** `ai_service.dart`  
**Docs:** https://ai.google.dev/gemini-api/docs

### SDK Methods Used

| SDK Method | Service Method | Location | Unit | Integration |
|------------|---------------|----------|:----:|:-----------:|
| `GenerativeModel()` | `model` getter | ai_service.dart:41 | ✅ | ❌ |
| `model.generateContent()` | `generateMessages()` | ai_service.dart:80 | ✅ | ❌ |

**Unit: 2/2** | **Integration: 0/2**

### Test Files
- `test/services/ai_service_test.dart` (35 tests)
- `test/services/ai_service_http_test.dart` (30 tests)
- `test/services/ai_service_generation_test.dart` (33 tests)

### Mock Strategy
`MockClient` from `http` package to intercept HTTP requests.

### Important Note
> **Package is deprecated.** Google recommends migrating to Firebase Vertex AI SDK.
> See: https://firebase.google.com/docs/vertex-ai

---

## 6. Local Auth (Biometrics)

**Package:** `local_auth: ^3.0.0`  
**Used for:** App lock screen (Face ID / Touch ID)  
**File:** `biometric_service.dart`  
**Docs:** https://pub.dev/packages/local_auth

### SDK Methods Used

| SDK Method | Service Method | Location | Unit | Integration |
|------------|---------------|----------|:----:|:-----------:|
| `LocalAuthentication().canCheckBiometrics` | `isSupported` | biometric_service.dart:36 | ✅ | ⚠️ |
| `LocalAuthentication().isDeviceSupported()` | `isSupported` | biometric_service.dart:36 | ✅ | ⚠️ |
| `LocalAuthentication().getAvailableBiometrics()` | `availableBiometrics` | biometric_service.dart:45 | ✅ | ⚠️ |
| `LocalAuthentication().authenticate()` | `authenticate()` | biometric_service.dart:89 | ✅ | ⚠️ |

**Unit: 4/4** | **Integration: 0/4 (device only)**

### Test File
- `test/services/biometric_service_mock_test.dart` (35 tests)

### Mock Strategy
Custom `MockBiometricService` implementing `IBiometricService` interface.
- Simulator cannot authenticate - device required

---

## 7. Firebase (Crashlytics Only)

**Package:** `firebase_core`, `firebase_crashlytics`  
**Used for:** Crash reporting only (NO Analytics in code)  
**File:** `main.dart`  
**Docs:** https://firebase.google.com/docs/crashlytics/test-implementation

### SDK Methods Used

| SDK Method | Location | Unit | Integration |
|------------|----------|:----:|:-----------:|
| `Firebase.initializeApp()` | main.dart:20 | ⚠️ | ⚠️ |
| `FirebaseCrashlytics.instance.recordFlutterFatalError` | main.dart:27 | ⚠️ | ⚠️ |
| `FirebaseCrashlytics.instance.recordError()` | main.dart:29 | ⚠️ | ⚠️ |

**Unit: 0/3 (manual)** | **Integration: 0/3 (manual)**

### Test File
- `integration_test/firebase_test.dart` (informational tests)

### Notes
- Requires manual verification in Firebase console
- Use `firebase_core_platform_interface` for initialization mocking if needed
- Force a test crash: `FirebaseCrashlytics.instance.crash()`

---

## Summary

| Service | SDK Methods | Unit | Integration | Notes |
|---------|:-----------:|:----:|:-----------:|-------|
| **Supabase Auth** | 14 | 13/14 ✅ | 13/14 ✅ | Includes Google OAuth |
| **Sign In With Apple** | 1 | 0/1 ⚠️ | 0/1 ⚠️ | Device only |
| **Google Sign In** | 0 | - | - | Uses Supabase OAuth (not native SDK) |
| **RevenueCat** | 12 | 12/12 ✅ | 9/12 ✅ | |
| **Google AI** | 2 | 2/2 ✅ | 0/2 ❌ | Package deprecated |
| **Biometrics** | 4 | 4/4 ✅ | 0/4 ⚠️ | Device only |
| **Firebase** | 3 | 0/3 ⚠️ | 0/3 ⚠️ | Manual verification |
| **TOTAL** | **36** | **31/36** | **22/36** | |

### Test Counts

| Type | Count |
|------|------:|
| Unit tests (services) | 287 |
| Integration tests (auth) | 20 |
| Integration tests (revenuecat) | 12 |
| Integration tests (firebase) | 6 |

---

## Gaps & Recommendations

### High Priority
1. **Google AI integration tests** - Add E2E generation flow test
2. **Firebase unit tests** - Mock initialization for coverage

### Medium Priority
3. **Biometrics integration** - Device-only, accept ⚠️ status
4. **Sign In With Apple** - Device-only, accept ⚠️ status

### Low Priority (UI-specific)
5. `RevenueCatUI.presentPaywallIfNeeded()` - Requires specific entitlement state
6. `RevenueCatUI.presentCustomerCenter()` - UI presentation test
7. `Purchases.logOut()` - Requires logged-in RevenueCat user

### Migration Needed
- **google_generative_ai is DEPRECATED** - Migrate to Firebase Vertex AI SDK

---

## Official Testing Docs

| Service | Documentation |
|---------|--------------|
| Supabase | [Auth Testing](https://supabase.com/docs/guides/auth/testing) |
| RevenueCat | [Testing Guide](https://www.revenuecat.com/docs/test-and-launch/testing) |
| RevenueCat | [Test Store](https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store) |
| Firebase | [Crashlytics Testing](https://firebase.google.com/docs/crashlytics/test-implementation) |
| Google AI | [Gemini API](https://ai.google.dev/gemini-api/docs) |
| local_auth | [pub.dev](https://pub.dev/packages/local_auth) |
| sign_in_with_apple | [pub.dev](https://pub.dev/packages/sign_in_with_apple) |
| mock_supabase_http_client | [pub.dev](https://pub.dev/packages/mock_supabase_http_client) |
