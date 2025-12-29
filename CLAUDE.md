# CLAUDE.md - Prosepal

## Project Overview

Prosepal is an AI-powered message helper app that generates personalized messages for greeting cards and special occasions. Built with Flutter for iOS and Android.

**Tagline:** "The right words, right now"

**Bundle ID:** com.prosepal.prosepal

## Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Frontend | Flutter | 3.38+ |
| Language | Dart | 3.6+ |
| State Management | Riverpod | 3.0.3 |
| Navigation | go_router | 17.0.1 |
| AI | firebase_ai | 3.6.1 (gemini-3-flash-preview) |
| Payments | RevenueCat | 9.10.2 |
| Analytics | Firebase Analytics | 12.1.0 |
| Crashes | Firebase Crashlytics | 5.0.6 |
| Auth | Supabase | 2.12.0 |
| Google Sign In | google_sign_in | 7.2.0 |
| Apple Sign In | sign_in_with_apple | 7.0.1 |
| Biometrics | local_auth | 2.3.0 |
| Local Storage | SharedPreferences | 2.5.3 |

## Commands

```bash
# Run app (Firebase AI handles Gemini auth)
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

## Project Structure

```
lib/
├── main.dart                    # App entry, Firebase + Supabase init
├── app/
│   ├── app.dart                 # MaterialApp + auth listener
│   └── router.dart              # go_router (splash → onboarding → auth → home)
│
├── features/
│   ├── auth/
│   │   ├── auth_screen.dart     # Apple, Google, Email buttons
│   │   ├── email_auth_screen.dart # Magic Link (passwordless)
│   │   └── lock_screen.dart     # Biometric lock
│   ├── onboarding/
│   │   └── onboarding_screen.dart # 3-slide intro
│   ├── home/
│   │   └── home_screen.dart     # Main screen
│   ├── generate/
│   │   └── generate_screen.dart # Occasion → Relationship → Tone flow
│   ├── results/
│   │   └── results_screen.dart  # 3 message options
│   ├── paywall/
│   │   └── paywall_screen.dart  # Subscription options
│   └── settings/
│       └── settings_screen.dart # Account, security, restore purchases
│
├── core/
│   ├── errors/
│   │   └── auth_errors.dart     # User-friendly error messages
│   ├── services/
│   │   ├── ai_service.dart      # Gemini 2.5 Flash
│   │   ├── auth_service.dart    # Supabase (Apple, Google, Email)
│   │   ├── biometric_service.dart # Face ID / Touch ID
│   │   ├── subscription_service.dart # RevenueCat
│   │   └── usage_service.dart   # Free tier limits
│   ├── models/
│   │   ├── occasion.dart        # 10 occasions
│   │   ├── relationship.dart    # 5 relationships
│   │   ├── tone.dart            # 4 tones
│   │   └── generated_message.dart
│   └── providers/
│       └── providers.dart       # Riverpod providers
│
└── shared/
    ├── atoms/                   # Basic UI elements
    ├── molecules/               # Composite components
    ├── organisms/               # Complex components
    ├── templates/               # Page layouts
    └── theme/
        ├── app_colors.dart
        ├── app_spacing.dart
        └── app_theme.dart
```

## Authentication

**Providers:**
- Apple Sign In (native SDK)
- Google Sign In (native SDK)
- Email Magic Link (custom UI with Supabase OTP)

**Supabase Project:**
- URL: `https://mwoxtqxzunsjmbdqezif.supabase.co`

**Flow:**
1. User enters email → Magic link sent
2. User taps link in email → Auto-signed in
3. RevenueCat linked to Supabase user ID (for purchase restoration)

## Monetization

| Tier | Limit | Price | Trial |
|------|-------|-------|-------|
| **Free** | 3 total (lifetime) | $0 | - |
| **Pro Weekly** | 500/mo | $2.99/wk | 3-day |
| **Pro Monthly** | 500/mo | $4.99/mo | 7-day |
| **Pro Yearly** | 500/mo | $29.99/yr | 7-day |

**RevenueCat Product IDs:**
```
com.prosepal.pro.weekly
com.prosepal.pro.monthly
com.prosepal.pro.yearly
```

## Key Features

| Feature | Status |
|---------|--------|
| 10 Occasions (Birthday, Thank You, etc.) | ✅ |
| 5 Relationships | ✅ |
| 4 Tones (Heartfelt, Casual, Funny, Formal) | ✅ |
| Gemini 2.5 Flash AI | ✅ |
| 3-slide onboarding | ✅ |
| Apple/Google/Magic Link auth | ✅ |
| Face ID / Touch ID lock | ✅ |
| RevenueCat subscriptions | ✅ |
| Restore purchases | ✅ |
| Delete account (Apple requirement) | ✅ |
| Firebase Analytics + Crashlytics | ✅ |
| User-friendly error handling | ✅ |

## Settings Screen (Apple HIG Compliant)

**Sections (top to bottom):**
1. Account (user info)
2. Subscription (status, manage, restore)
3. Security (biometrics toggle)
4. Stats (messages generated)
5. Support (Help, Contact, Rate)
6. Legal (Terms, Privacy)
7. Account Actions (Sign Out, Delete Account)

**Key patterns:**
- Destructive actions at bottom
- Two-step confirmation for delete
- Restore purchases prominently displayed
- Manage subscription links to Apple

## Error Handling

`lib/core/errors/auth_errors.dart` provides user-friendly messages:

```dart
AuthErrorHandler.getMessage(error) // Returns friendly string
AuthErrorHandler.isCancellation(error) // Detects user cancel
```

## Testing

**32 tests passing:**
- UsageService: 7 tests
- BiometricService: 4 tests
- AuthErrorHandler: 8 tests
- Models: 12 tests
- Widget: 1 test

```bash
flutter test
```

## API Keys (Development)

**Gemini AI:** Handled by Firebase AI Logic SDK (no dart-define needed)
- API key managed server-side via Firebase Console
- Enable Gemini Developer API in Firebase Console > AI Logic

**RevenueCat:** Test key in code (replace for production)

## Git Workflow

```bash
# Check status
git status

# Commit
git add .
git commit -m "feat: description"

# Push
git push origin main
```

## Next Steps (Pre-Launch)

- [ ] App Store screenshots (6 screens)
- [ ] App Store description + keywords
- [ ] Privacy policy page (prosepal.app/privacy)
- [ ] Terms of service page (prosepal.app/terms)
- [ ] TestFlight build
- [ ] App Store submission
