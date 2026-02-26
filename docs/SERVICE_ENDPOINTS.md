# Service Endpoints Map

> Complete map of all third-party SDK methods used by Prosepal with test coverage status.

**Legend:** ✅ Tested | ❌ Not tested | ⚠️ Manual/Device only

**Last verified:** December 2025

---

## Authentication Architecture

### Best Practice: Native SDK + Supabase Token Validation

Supabase recommends using **native SDKs** for social sign-in providers, then passing the ID token to Supabase for session management. This provides:

- **Better UX** - Native popups instead of browser redirects
- **Consistency** - Same pattern for Apple, Google, Facebook
- **Security** - Tokens validated server-side by Supabase
- **Account linking** - Same email from different providers = same user

### Authentication Flow Patterns

| Method | Native SDK | Supabase Role | Best Practice |
|--------|-----------|---------------|:-------------:|
| **Apple** | `sign_in_with_apple` → ID token | `signInWithIdToken()` validates & creates session | ✅ |
| **Google** | `google_sign_in` → ID token | `signInWithIdToken()` validates & creates session | ✅ |
| **Magic Link** | N/A | `signInWithOtp()` handles full flow | ✅ |
| **Email/Password** | N/A | `signInWithPassword()` / `signUp()` | ✅ |

### What Supabase Provides

1. **Session Management** - JWT tokens, refresh tokens, expiry handling
2. **User Database** - `auth.users` table with unified user records
3. **Token Validation** - Verifies ID tokens from Apple/Google are legitimate
4. **Account Linking** - Same email from different providers = same user record
5. **Magic Link Flow** - Complete email OTP flow (send, verify, create session)

### Implementation Pattern (Recommended)

```dart
// Apple Sign In - Native SDK + Supabase
Future<AuthResponse> signInWithApple() async {
  // 1. Get credential from native SDK
  final credential = await SignInWithApple.getAppleIDCredential(...);
  
  // 2. Pass ID token to Supabase for validation & session
  return await supabase.auth.signInWithIdToken(
    provider: OAuthProvider.apple,
    idToken: credential.identityToken!,
    nonce: rawNonce,
  );
}

// Google Sign In - Native SDK + Supabase
Future<AuthResponse> signInWithGoogle() async {
  // 1. Get credential from native SDK
  final googleUser = await GoogleSignIn().signIn();
  final googleAuth = await googleUser!.authentication;
  
  // 2. Pass ID token to Supabase for validation & session
  return await supabase.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: googleAuth.idToken!,
  );
}

// Magic Link - Supabase handles everything
Future<void> signInWithMagicLink(String email) async {
  await supabase.auth.signInWithOtp(
    email: email,
    emailRedirectTo: 'com.prosepal.prosepal://login-callback',
  );
}
```

### Anti-Pattern: OAuth Browser Flow

```dart
// ❌ NOT RECOMMENDED - Opens external browser, poor UX
await supabase.auth.signInWithOAuth(OAuthProvider.google);
```

This approach:
- Opens Safari/Chrome (context switch)
- Requires redirect URL handling
- Less native feel
- No One Tap support

### Official Sign-In Buttons (Required)

Apple and Google require using their official branded buttons:

| Provider | Package | Button Widget | Notes |
|----------|---------|---------------|-------|
| **Apple** | `sign_in_with_apple` | `SignInWithAppleButton` | Required by Apple HIG |
| **Google** | Custom | Custom button with official colors/logo | Google branding guidelines |
| **Email** | N/A | Custom button | No branding requirements |

```dart
// Apple - Official button from sign_in_with_apple package
SignInWithAppleButton(
  text: 'Continue with Apple',
  onPressed: _signInWithApple,
  style: SignInWithAppleButtonStyle.black,
  borderRadius: BorderRadius.all(Radius.circular(12)),
)

// Google - Custom button with official branding
ElevatedButton.icon(
  onPressed: _signInWithGoogle,
  icon: Image.network('https://www.google.com/favicon.ico', height: 18),
  label: Text('Continue with Google'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF757575),
  ),
)
```

### Dependency Notes

| Package | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `supabase_flutter` | ^2.12.0 | Auth session management | Core dependency |
| `sign_in_with_apple` | ^7.0.1 | Native Apple credential + button | iOS only |
| `google_sign_in` | ^7.2.0 | Native Google credential | 7.x with new API |

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

### Implementation ✅ Best Practice

```dart
Future<AuthResponse> signInWithApple() async {
  final rawNonce = _generateNonce();
  final hashedNonce = _sha256ofString(rawNonce);

  // 1. Native SDK gets Apple credential
  final credential = await SignInWithApple.getAppleIDCredential(
    scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    nonce: hashedNonce,
  );

  // 2. Pass ID token to Supabase for validation & session
  return await _client.auth.signInWithIdToken(
    provider: OAuthProvider.apple,
    idToken: credential.identityToken!,
    nonce: rawNonce,
  );
}
```

### Notes
- Cannot be unit tested - requires real device with Apple ID
- iOS only - no Android equivalent
- Nonce prevents replay attacks (hashed for Apple, raw for Supabase)

---

## 3. Google Sign In (Native)

**Package:** `google_sign_in: ^6.2.2`  
**Used for:** Native Google Sign In credential  
**File:** `auth_service.dart`  
**Docs:** https://supabase.com/docs/guides/auth/social-login/auth-google

### SDK Methods Used

| SDK Method | Service Method | Location | Unit | Integration |
|------------|---------------|----------|:----:|:-----------:|
| `GoogleSignIn().signIn()` | `signInWithGoogle()` | auth_service.dart | ⚠️ | ⚠️ |
| `GoogleSignInAccount.authentication` | `signInWithGoogle()` | auth_service.dart | ⚠️ | ⚠️ |

**Unit: 0/2 (device only)** | **Integration: 0/2 (device only)**

### Implementation ✅ Best Practice

```dart
Future<AuthResponse> signInWithGoogle() async {
  // 1. Native SDK gets Google credential
  final googleSignIn = GoogleSignIn(
    // iOS client ID from Google Cloud Console
    clientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
    serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );
  
  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    throw AuthException('Google Sign In cancelled');
  }
  
  final googleAuth = await googleUser.authentication;
  final idToken = googleAuth.idToken;
  
  if (idToken == null) {
    throw AuthException('No ID Token from Google');
  }

  // 2. Pass ID token to Supabase for validation & session
  return await _client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
  );
}
```

### Setup Requirements

**Google Cloud Console:**
1. Create OAuth 2.0 Client IDs for iOS and Web
2. Add iOS bundle ID: `com.prosepal.prosepal`
3. Add Web client ID to Supabase Dashboard → Auth → Providers → Google

**iOS (Info.plist):**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### Notes
- Cannot be unit tested - requires real device with Google account
- Works on iOS and Android
- Consistent UX with Apple Sign In (native popup, no browser)
- Supports One Tap / automatic sign-in

---

## 4. Magic Link (Email OTP)

**Package:** `supabase_flutter: ^2.12.0`  
**Used for:** Passwordless email authentication  
**File:** `auth_service.dart`  
**Docs:** https://supabase.com/docs/guides/auth/auth-email-passwordless

### SDK Methods Used

| SDK Method | Service Method | Location | Unit | Integration |
|------------|---------------|----------|:----:|:-----------:|
| `auth.signInWithOtp()` | `signInWithMagicLink()` | auth_service.dart | ✅ | ✅ |

### Implementation ✅ Best Practice

```dart
Future<void> signInWithMagicLink(String email) async {
  await _client.auth.signInWithOtp(
    email: email,
    emailRedirectTo: kIsWeb ? null : 'com.prosepal.prosepal://login-callback',
  );
}
```

### Notes
- Supabase handles the entire flow (send email, verify token, create session)
- No native SDK needed - Supabase is the provider
- Deep link handling required for mobile apps
- Email template customizable in Supabase Dashboard

### UI

Custom UI - TextField + Button calling `signInWithMagicLink()`.

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
