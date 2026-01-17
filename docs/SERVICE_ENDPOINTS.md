# Service Endpoints Map

> SDK methods used by Prosepal with test coverage status.

**Legend:** ✅ Done | ⚠️ Device-only | ❌ Not done

---

## SDKs Overview

> Package versions: see `pubspec.yaml` (source of truth)

| SDK | Purpose |
|-----|---------|
| **Supabase Auth** | User authentication, session management, edge functions |
| **Sign In With Apple** | Native Apple OAuth on iOS/macOS |
| **Google Sign In** | Native Google OAuth on iOS/Android |
| **RevenueCat** | In-app subscriptions, paywall UI, entitlements |
| **Firebase AI** | Gemini AI message generation |
| **Local Auth** | Biometric authentication (Face ID/Touch ID) |
| **Firebase Core** | App initialization, crash reporting |
| **Firebase Analytics** | Usage analytics, event tracking |
| **Share Plus** | Native share sheet for messages |
| **In App Review** | App Store review prompts |
| **URL Launcher** | Open external links (support, legal) |

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

**Total unit/widget tests:** 626
