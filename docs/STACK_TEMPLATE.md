# Flutter App Blueprint

> How to build another app exactly like Prosepal. Copy this stack, swap the content.

---

## The Stack

| Layer | Technology | Why |
|-------|------------|-----|
| **Framework** | Flutter | iOS + Android from one codebase |
| **State** | Riverpod 3.x | Compile-safe, testable, code generation |
| **Navigation** | go_router | Official Flutter team, type-safe routes |
| **AI** | Firebase AI (Gemini) | No API key in client, secure, cheap |
| **Auth** | Supabase | Free tier, Apple/Google/Email built-in |
| **Payments** | RevenueCat | Handles both stores, no server needed |
| **Analytics** | Firebase Analytics + Crashlytics | Free, reliable |
| **Storage** | SharedPreferences + Supabase | Local cache + server sync |

---

## Project Structure

```
lib/
├── main.dart                 # Initialize Firebase, Supabase, RevenueCat
├── firebase_options.dart     # Auto-generated
│
├── app/
│   ├── app.dart              # MaterialApp, theme, ProviderScope wrapper
│   └── router.dart           # go_router with splash → auth → home flow
│
├── core/
│   ├── config/               # AI config, feature flags
│   ├── errors/               # User-friendly error messages
│   ├── interfaces/           # Service contracts (for DI/testing)
│   ├── models/               # Data models (freezed for immutability)
│   ├── providers/            # Riverpod providers (central registration)
│   └── services/             # Business logic implementations
│
├── features/                 # One folder per feature
│   ├── auth/                 # Sign in, sign up, lock screen
│   ├── home/                 # Main screen
│   ├── [your-feature]/       # Your app's core feature
│   ├── paywall/              # Subscription screen
│   ├── onboarding/           # First-run tutorial
│   └── settings/             # Account, preferences, legal
│
└── shared/                   # Reusable UI (Atomic Design)
    ├── atoms/                # Buttons, cards, icons
    ├── molecules/            # Compound widgets
    ├── organisms/            # Complex components
    └── theme/                # Colors, typography, spacing
```

---

## Setup Checklist

### 1. Create Flutter Project

```bash
flutter create --org com.yourcompany appname
cd appname
```

### 2. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  # State
  flutter_riverpod: ^3.1.0
  riverpod_annotation: ^4.0.0
  
  # Navigation
  go_router: ^17.0.1
  
  # AI
  firebase_ai: ^3.6.1
  
  # Auth
  supabase_flutter: ^2.12.0
  google_sign_in: ^7.2.0
  sign_in_with_apple: ^7.0.1
  
  # Payments
  purchases_flutter: ^9.10.2
  purchases_ui_flutter: ^9.10.2
  
  # Firebase
  firebase_core: ^4.3.0
  firebase_analytics: ^12.1.0
  firebase_crashlytics: ^5.0.6
  
  # Utils
  shared_preferences: ^2.5.3
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0

dev_dependencies:
  riverpod_generator: ^4.0.0+1
  build_runner: ^2.10.4
  freezed: ^3.2.3
  json_serializable: ^6.11.2
  mocktail: ^1.0.4
```

### 3. Configure Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (creates firebase_options.dart)
flutterfire configure
```

In Firebase Console:
1. Enable Firebase AI (Gemini)
2. Enable Analytics
3. Enable Crashlytics

### 4. Configure Supabase

1. Create project at supabase.com
2. Enable auth providers: Apple, Google, Email
3. Add to `main.dart`:

```dart
await Supabase.initialize(
  url: 'https://YOUR_PROJECT.supabase.co',
  anonKey: 'YOUR_ANON_KEY',
);
```

### 5. Configure RevenueCat

1. Create app at app.revenuecat.com
2. Add products in App Store Connect / Play Console
3. Import products to RevenueCat
4. Create entitlement (e.g., "pro")
5. Add API keys to `subscription_service.dart`

### 6. Platform Config

**iOS (ios/Runner/Info.plist):**
```xml
<!-- Face ID -->
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to unlock [AppName]</string>

<!-- Google Sign In URL scheme -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>$(GOOGLE_REVERSED_CLIENT_ID)</string>
    </array>
  </dict>
</array>
```

**Android (android/app/build.gradle.kts):**
```kotlin
android {
    compileSdk = 36
    defaultConfig {
        minSdk = 23
        targetSdk = 35
    }
}
```

**Android Network Security (android/app/src/main/res/xml/network_security_config.xml):**
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
</network-security-config>
```

---

## Core Patterns

### main.dart Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Firebase (for crash reporting during init)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 2. Supabase
  await Supabase.initialize(url: '...', anonKey: '...');
  
  // 3. RevenueCat
  final subscriptionService = SubscriptionService();
  await subscriptionService.initialize();
  
  // 4. SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // 5. Run app with provider overrides
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        subscriptionServiceProvider.overrideWithValue(subscriptionService),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Service Interface Pattern

```dart
// interfaces/subscription_interface.dart
abstract class ISubscriptionService {
  Future<void> initialize();
  Future<bool> isPro();
  Future<void> showPaywall();
}

// services/subscription_service.dart
class SubscriptionService implements ISubscriptionService {
  // Real implementation
}

// In tests, override with mock
```

### Riverpod Providers

```dart
// providers/providers.dart

// Service providers (singletons)
final subscriptionServiceProvider = Provider<ISubscriptionService>((ref) {
  return SubscriptionService();
});

// State providers
final isProProvider = StateProvider<bool>((ref) => false);

// Computed providers
final remainingGenerationsProvider = Provider<int>((ref) {
  final isPro = ref.watch(isProProvider);
  return isPro ? 500 : 3;
});
```

### Router with Auth Guard

```dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),
    GoRoute(path: '/auth', builder: (_, __) => AuthScreen()),
    GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
    // ... more routes
  ],
);

// In SplashScreen, determine initial route:
if (!hasCompletedOnboarding) context.go('/onboarding');
else if (!isLoggedIn) context.go('/auth');
else context.go('/home');
```

### AI Service with Structured Output

```dart
class AiService {
  Future<List<String>> generate(String prompt) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-flash-preview',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'items': Schema.array(items: Schema.string()),
          },
        ),
      ),
    );
    
    final response = await model.generateContent([Content.text(prompt)]);
    final json = jsonDecode(response.text!);
    return List<String>.from(json['items']);
  }
}
```

---

## Monetization Pattern

### Free Tier with Server-Side Tracking

```dart
// Prevents reinstall abuse
class UsageService {
  // Local cache for fast reads
  int getLocalCount() => _prefs.getInt('usage_count') ?? 0;
  
  // Sync with server on sign-in
  Future<void> syncWithServer(String userId) async {
    final serverCount = await _fetchFromSupabase(userId);
    final localCount = getLocalCount();
    final maxCount = max(serverCount, localCount);
    await _saveToSupabase(userId, maxCount);
    await _prefs.setInt('usage_count', maxCount);
  }
}
```

### RevenueCat Integration

```dart
class SubscriptionService {
  Future<bool> isPro() async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.all['pro']?.isActive ?? false;
  }
  
  Future<void> showPaywall() async {
    await RevenueCatUI.presentPaywallIfNeeded('pro');
  }
}
```

---

## Testing Strategy

### Mock Services via Provider Overrides

```dart
void main() {
  testWidgets('shows paywall when not pro', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionServiceProvider.overrideWithValue(MockSubscriptionService()),
        ],
        child: MyApp(),
      ),
    );
  });
}
```

### What to Mock vs Real Device

| Mock in Tests | Real Device Only |
|---------------|------------------|
| Subscription status | Actual purchases |
| Auth state | Native OAuth UI |
| AI responses | Biometrics |
| Usage counts | Deep links |

---

## Security Checklist

- [ ] HTTPS only (network_security_config.xml for Android)
- [ ] No API keys in client code (use Firebase AI)
- [ ] ProGuard/R8 for Android release
- [ ] Supabase RLS for user data
- [ ] RevenueCat handles all payment data

---

## Costs (Monthly)

| Service | Free Tier | Notes |
|---------|-----------|-------|
| Supabase | 500MB, 50K auth | More than enough for MVP |
| RevenueCat | $2.5K MTR | 1% after limit |
| Firebase AI | Free tier generous | Pay per token after |
| Firebase Analytics | Free | Unlimited |
| GitHub Actions | 2000 mins | Use Linux runners |

**Total MVP cost: $0** (just domain ~$12/yr)

---

## Clone for New App

1. Copy this project structure
2. Replace app name, bundle ID
3. Create new Firebase project
4. Create new Supabase project
5. Create new RevenueCat app
6. Swap out `features/[your-feature]/`
7. Update models for your domain
8. Update AI prompts
9. Launch!

The auth, payments, analytics, and infrastructure are 100% reusable.
