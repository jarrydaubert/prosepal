# Service Endpoints Map

> SDK methods used by Prosepal with test coverage status.

**Legend:** ✅ Done | ⚠️ Device-only | ❌ Not done

---

## SDKs Overview

| SDK | Package | Purpose |
|-----|---------|---------|
| **Supabase Auth** | `supabase_flutter: ^2.12.0` | User authentication, session management, edge functions |
| **Sign In With Apple** | `sign_in_with_apple: ^7.0.1` | Native Apple OAuth on iOS/macOS |
| **Google Sign In** | `google_sign_in: ^7.2.0` | Native Google OAuth on iOS/Android |
| **RevenueCat** | `purchases_flutter: ^9.10.2` | In-app subscriptions, paywall UI, entitlements |
| **Firebase AI** | `firebase_ai: ^3.6.1` | Gemini AI message generation |
| **Local Auth** | `local_auth: ^3.0.0` | Biometric authentication (Face ID/Touch ID) |
| **Firebase Core** | `firebase_core`, `firebase_crashlytics` | App initialization, crash reporting |
| **Firebase Analytics** | `firebase_analytics: ^12.1.0` | Usage analytics, event tracking |
| **Share Plus** | `share_plus: ^12.0.1` | Native share sheet for messages |
| **In App Review** | `in_app_review: ^2.0.11` | App Store review prompts |
| **URL Launcher** | `url_launcher: ^6.3.1` | Open external links (support, legal) |
| **Vercel** | Hosting | Landing page, privacy policy, terms, support |
| **GitHub** | Repository | Source control, CI/CD |

---

## 1. Supabase Auth

| SDK Method | Unit | Integration |
|------------|:----:|:-----------:|
| `auth.currentUser` | ✅ | ✅ |
| `auth.onAuthStateChange` | ✅ | ✅ |
| `auth.signInWithIdToken()` | ✅ | ✅ |
| `auth.signInWithPassword()` | ✅ | ✅ |
| `auth.signUp()` | ✅ | ✅ |
| `auth.resetPasswordForEmail()` | ✅ | ✅ |
| `auth.signInWithOtp()` | ✅ | ✅ |
| `auth.updateUser()` | ✅ | ✅ |
| `auth.signOut()` | ✅ | ✅ |
| `auth.currentSession` | ✅ | ✅ |
| `functions.invoke()` | ✅ | ✅ |

---

## 2. Sign In With Apple

| SDK Method | Unit | Integration |
|------------|:----:|:-----------:|
| `generateRawNonce()` | ✅ | ⚠️ |
| `isAvailable()` | ✅ | ⚠️ |
| `getAppleIDCredential()` | ✅ | ⚠️ |
| `onCredentialRevoked` | ✅ | ⚠️ |

---

## 3. Google Sign In

| SDK Method | Unit | Integration |
|------------|:----:|:-----------:|
| `initialize()` | ✅ | ⚠️ |
| `isAvailable()` | ✅ | ⚠️ |
| `attemptLightweightAuthentication()` | ✅ | ⚠️ |
| `authenticate()` | ✅ | ⚠️ |
| `signOut()` | ✅ | ⚠️ |
| `disconnect()` | ✅ | ⚠️ |

---

## 4. RevenueCat

| SDK Method | Unit | Integration |
|------------|:----:|:-----------:|
| `Purchases.configure()` | ✅ | ✅ |
| `Purchases.getCustomerInfo()` | ✅ | ✅ |
| `Purchases.getOfferings()` | ✅ | ✅ |
| `Purchases.purchase()` | ✅ | ✅ |
| `Purchases.restorePurchases()` | ✅ | ✅ |
| `RevenueCatUI.presentPaywall()` | ✅ | ✅ |
| `RevenueCatUI.presentPaywallIfNeeded()` | ✅ | ⚠️ |
| `RevenueCatUI.presentCustomerCenter()` | ✅ | ⚠️ |
| `Purchases.addCustomerInfoUpdateListener()` | ✅ | ✅ |
| `Purchases.logIn()` | ✅ | ✅ |
| `Purchases.logOut()` | ✅ | ⚠️ |

---

## 5. Firebase AI

| SDK Method | Unit | Integration |
|------------|:----:|:-----------:|
| `FirebaseAI.googleAI()` | ✅ | ⚠️ |
| `generativeModel()` | ✅ | ⚠️ |
| `model.generateContent()` | ✅ | ⚠️ |

---

## 6. Local Auth (Biometrics)

| SDK Method | Unit | Integration |
|------------|:----:|:-----------:|
| `canCheckBiometrics` | ✅ | ⚠️ |
| `isDeviceSupported()` | ✅ | ⚠️ |
| `getAvailableBiometrics()` | ✅ | ⚠️ |
| `authenticate()` | ✅ | ⚠️ |

---

## 7. Firebase Core

| SDK Method | Unit | Integration |
|------------|:----:|:-----------:|
| `Firebase.initializeApp()` | ⚠️ | ⚠️ |
| `FirebaseCrashlytics.recordFlutterFatalError` | ⚠️ | ⚠️ |
| `FirebaseCrashlytics.recordError()` | ⚠️ | ⚠️ |

---

## Summary

| Service | Unit | Integration |
|---------|:----:|:-----------:|
| Supabase Auth | ✅ 11/11 | ✅ 11/11 |
| Sign In With Apple | ✅ 4/4 | ⚠️ Device |
| Google Sign In | ✅ 6/6 | ⚠️ Device |
| RevenueCat | ✅ 11/11 | ✅ 8/11 |
| Firebase AI | ✅ 3/3 | ⚠️ Device |
| Biometrics | ✅ 4/4 | ⚠️ Device |
| Firebase Core | ⚠️ Manual | ⚠️ Manual |

**Total unit tests:** 503
