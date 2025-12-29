# Service Endpoints Map

> Exact SDK methods used by Prosepal with test coverage status.

**Legend:** ✅ Tested | ❌ Not tested | ⚠️ Manual only

---

## 1. Supabase (Auth Only)

**Package:** `supabase_flutter: ^2.12.0`  
**Used for:** Authentication only (NO database)  
**Files:** `auth_service.dart`, `main.dart`, `app.dart`

### Endpoints & Coverage

| Method | Location | Unit | Integration |
|--------|----------|:----:|:-----------:|
| `Supabase.initialize()` | main.dart:39 | ⚠️ | ✅ |
| `auth.currentUser` | auth_service.dart:18 | ✅ | ✅ |
| `auth.onAuthStateChange` | auth_service.dart:24 | ✅ | ✅ |
| `auth.signInWithIdToken()` | auth_service.dart:82 | ✅ | ✅ |
| `auth.signInWithOAuth()` | auth_service.dart:91 | ✅ | ✅ |
| `auth.signInWithPassword()` | auth_service.dart:102 | ✅ | ✅ |
| `auth.signUp()` | auth_service.dart:113 | ✅ | ✅ |
| `auth.resetPasswordForEmail()` | auth_service.dart:119 | ✅ | ✅ |
| `auth.signInWithOtp()` | auth_service.dart:125 | ✅ | ✅ |
| `auth.updateUser()` (email) | auth_service.dart:134 | ✅ | ✅ |
| `auth.updateUser()` (password) | auth_service.dart:139 | ✅ | ✅ |
| `auth.signOut()` | auth_service.dart:144 | ✅ | ✅ |
| `functions.invoke()` | auth_service.dart:158 | ✅ | ✅ |

**Unit: 12/13** | **Integration: 13/13**

### Test Files
- `test/services/auth_service_with_mock_test.dart` (55 tests)
- `test/services/auth_service_crypto_test.dart` (12 tests)
- `test/services/auth_service_compliance_test.dart` (13 tests)
- `integration_test/auth_test.dart` (20 tests)

### Mock: `MockAuthService`
- `createFakeUser()` / `createFakeSession()` - Rich fixtures
- `autoEmitAuthState` - Auto-emits auth events
- `methodErrors` map - Per-method error simulation

### Provider: `authServiceProvider`
- Added to `lib/core/providers/providers.dart`
- Overridable for integration tests
- Used by: `auth_screen.dart`, `settings_screen.dart`, `feedback_screen.dart`, `router.dart`

---

## 2. RevenueCat (Subscriptions)

**Package:** `purchases_flutter: ^9.10.2`, `purchases_ui_flutter: ^9.10.2`  
**Used for:** In-app subscriptions  
**File:** `subscription_service.dart`

### Endpoints & Coverage

| Method | Location | Unit | Integration |
|--------|----------|:----:|:-----------:|
| `Purchases.configure()` | subscription_service.dart:97 | ✅ | ❌ |
| `Purchases.getCustomerInfo()` | subscription_service.dart:113 | ✅ | ❌ |
| `Purchases.getOfferings()` | subscription_service.dart:136 | ✅ | ❌ |
| `Purchases.purchase()` | subscription_service.dart:146 | ✅ | ❌ |
| `Purchases.restorePurchases()` | subscription_service.dart:170 | ✅ | ❌ |
| `RevenueCatUI.presentPaywall()` | subscription_service.dart:187 | ✅ | ❌ |
| `RevenueCatUI.presentPaywallIfNeeded()` | subscription_service.dart:204 | ✅ | ❌ |
| `RevenueCatUI.presentCustomerCenter()` | subscription_service.dart:220 | ✅ | ❌ |
| `Purchases.addCustomerInfoUpdateListener()` | subscription_service.dart:228 | ✅ | ❌ |
| `Purchases.logIn()` | subscription_service.dart:238 | ✅ | ❌ |
| `Purchases.logOut()` | subscription_service.dart:247 | ✅ | ❌ |

**Unit: 11/11** | **Integration: 0/11**

### Test File
- `test/services/subscription_service_with_mock_test.dart` (74 tests)

### Mock: `MockSubscriptionService`
- Sandbox testing: iOS (Settings → Developer) / Android (Play Console)

---

## 3. Firebase (Crashlytics Only)

**Package:** `firebase_core`, `firebase_crashlytics`  
**Used for:** Crash reporting only  
**File:** `main.dart`

### Endpoints & Coverage

| Method | Location | Unit | Integration |
|--------|----------|:----:|:-----------:|
| `Firebase.initializeApp()` | main.dart:20 | ⚠️ | ⚠️ |
| `FirebaseCrashlytics.instance.recordFlutterFatalError` | main.dart:27 | ⚠️ | ⚠️ |
| `FirebaseCrashlytics.instance.recordError()` | main.dart:29 | ⚠️ | ⚠️ |

**Unit: 0/3 (manual)** | **Integration: 0/3 (manual)**

### Notes
- Requires manual verification in Firebase console
- Use `firebase_core_platform_interface` for initialization mocking if needed

---

## 4. Google AI (Gemini)

**Package:** `google_generative_ai: ^0.4.7`  
**Used for:** Message generation  
**File:** `ai_service.dart`

### Endpoints & Coverage

| Method | Location | Unit | Integration |
|--------|----------|:----:|:-----------:|
| `GenerativeModel()` | ai_service.dart:41 | ✅ | ❌ |
| `model.generateContent()` | ai_service.dart | ✅ | ❌ |

**Unit: 2/2** | **Integration: 0/2**

### Test Files
- `test/services/ai_service_test.dart` (35 tests)
- `test/services/ai_service_http_test.dart` (30 tests)
- `test/services/ai_service_generation_test.dart` (33 tests)

### Mock: `MockClient` (http package)
- Tests all occasions, relationships, tones
- Error handling: rate limit, network, safety block

---

## 5. Local Auth (Biometrics)

**Package:** `local_auth: ^3.0.0`  
**Used for:** App lock screen  
**File:** `biometric_service.dart`

### Endpoints & Coverage

| Method | Location | Unit | Integration |
|--------|----------|:----:|:-----------:|
| `LocalAuthentication().canCheckBiometrics` | biometric_service.dart:36 | ✅ | ⚠️ |
| `LocalAuthentication().isDeviceSupported()` | biometric_service.dart:36 | ✅ | ⚠️ |
| `LocalAuthentication().getAvailableBiometrics()` | biometric_service.dart:45 | ✅ | ⚠️ |
| `LocalAuthentication().authenticate()` | biometric_service.dart:86 | ✅ | ⚠️ |

**Unit: 4/4** | **Integration: 0/4 (device only)**

### Test File
- `test/services/biometric_service_mock_test.dart` (35 tests)

### Mock: `MockBiometricService`

---

## 6. Sign In With Apple

**Package:** `sign_in_with_apple`  
**Used for:** Native Apple Sign In  
**File:** `auth_service.dart`

### Endpoints & Coverage

| Method | Location | Unit | Integration |
|--------|----------|:----:|:-----------:|
| `SignInWithApple.getAppleIDCredential()` | auth_service.dart:63 | ⚠️ | ⚠️ |

**Unit: 0/1 (device only)** | **Integration: 0/1 (device only)**

### Notes
- Cannot be unit tested - requires real device with Apple ID
- iOS only - no Android equivalent

---

## Summary

| Service | Endpoints | Unit | Integration |
|---------|:---------:|:----:|:-----------:|
| **Supabase Auth** | 13 | 12/13 ✅ | 13/13 ✅ |
| **RevenueCat** | 11 | 11/11 ✅ | 0/11 ❌ |
| **Google AI** | 2 | 2/2 ✅ | 0/2 ❌ |
| **Biometrics** | 4 | 4/4 ✅ | 0/4 ⚠️ |
| **Firebase** | 3 | 0/3 ⚠️ | 0/3 ⚠️ |
| **Apple Sign In** | 1 | 0/1 ⚠️ | 0/1 ⚠️ |
| **TOTAL** | **34** | **29/34** | **13/34** |

### Test Counts
| Type | Count |
|------|------:|
| Unit tests (services) | 287 |
| Integration tests (auth) | 20 |

---

## Integration Test Gaps

Priority items to add in `integration_test/`:

### Supabase Auth (13/13 done) ✅
- [x] Sign in with email flow
- [x] Sign up flow  
- [x] Sign out flow
- [x] Auth state persistence
- [x] Sign in with Apple
- [x] Sign in with Google
- [x] Error handling
- [x] Auth state changes (signedIn/signedOut)
- [x] Password reset flow
- [x] Magic link flow
- [x] Update email
- [x] Update password
- [x] Delete account

### RevenueCat
- [ ] Paywall display
- [ ] Purchase flow (sandbox)
- [ ] Restore purchases
- [ ] Pro status affects UI

### Google AI
- [ ] Full generation flow
- [ ] Error states in UI

---

## Official Docs

| Service | Testing Documentation |
|---------|----------------------|
| Supabase | [Auth Testing](https://supabase.com/docs/guides/auth/testing) |
| RevenueCat | [Testing Guide](https://www.revenuecat.com/docs/test-and-launch/testing) |
| Firebase | [Crashlytics Testing](https://firebase.google.com/docs/crashlytics/test-implementation) |
| Google AI | [Gemini API](https://ai.google.dev/gemini-api/docs) |
| local_auth | [pub.dev](https://pub.dev/packages/local_auth) |
| sign_in_with_apple | [pub.dev](https://pub.dev/packages/sign_in_with_apple) |

*Last verified: December 2025*
