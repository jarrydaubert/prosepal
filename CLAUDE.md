# CLAUDE.md - Prosepal

## Project Overview

Prosepal is an AI-powered message helper app that generates personalized messages for greeting cards and special occasions. Built with Flutter for iOS, Android, and Web.

**Tagline:** "The right words, right now"

**Platforms:** iOS (App Store), Android (Google Play), Web (future)

## Tech Stack (Cutting-Edge 2025)

| Layer | Technology | Version |
|-------|------------|---------|
| Frontend | Flutter | 3.38+ |
| Language | Dart | 3.6+ |
| State Management | Riverpod | 3.0+ |
| Navigation | go_router | 17.0+ |
| AI | google_generative_ai | 0.4.7+ (Direct Gemini 2.0 Flash) |
| Payments | RevenueCat | 6.0+ |
| Analytics | Firebase Analytics | 10.7+ |
| Crashes | Firebase Crashlytics | 3.4+ |
| Local Storage | SharedPreferences | 2.2+ |

**Note:** No backend for MVP! Direct Gemini API + local storage. Add Supabase in V1.1 for auth/history.

## Commands

```bash
# Run app
flutter run

# Run on iOS simulator
flutter run -d "iPhone 16 Pro"

# Run on Chrome
flutter run -d chrome

# Build iOS
flutter build ios

# Build Android
flutter build appbundle

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .

# Generate Riverpod code
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure (Atomic Design + Feature-First)

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp + ProviderScope
│   └── router.dart                 # go_router configuration
│
├── features/                       # Feature-first organization
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       └── occasion_grid.dart
│   ├── generate/
│   │   ├── generate_screen.dart
│   │   ├── generate_provider.dart  # Riverpod provider
│   │   └── widgets/
│   ├── results/
│   │   ├── results_screen.dart
│   │   └── widgets/
│   ├── paywall/
│   │   └── paywall_screen.dart
│   └── settings/
│       └── settings_screen.dart
│
├── core/
│   ├── services/
│   │   ├── ai_service.dart         # Gemini API wrapper
│   │   ├── subscription_service.dart
│   │   ├── usage_service.dart      # Daily/monthly limits
│   │   └── analytics_service.dart
│   ├── models/
│   │   ├── occasion.dart
│   │   ├── relationship.dart
│   │   ├── tone.dart
│   │   └── generated_message.dart
│   └── providers/
│       ├── usage_provider.dart
│       └── subscription_provider.dart
│
└── shared/
    ├── atoms/                      # Basic UI building blocks
    │   ├── app_button.dart
    │   ├── app_text.dart
    │   ├── app_icon.dart
    │   └── app_card.dart
    ├── molecules/                  # Combinations of atoms
    │   ├── icon_label.dart
    │   ├── selection_chip.dart
    │   └── loading_indicator.dart
    ├── organisms/                  # Complex components
    │   ├── occasion_tile.dart
    │   ├── message_option.dart
    │   └── paywall_card.dart
    ├── templates/                  # Page layouts
    │   ├── base_screen.dart
    │   └── scrollable_screen.dart
    ├── theme/
    │   ├── app_colors.dart
    │   ├── app_typography.dart
    │   ├── app_spacing.dart
    │   └── app_theme.dart
    └── extensions/
        ├── context_extensions.dart
        └── string_extensions.dart
```

## Atomic Design Hierarchy

| Level | Description | Examples |
|-------|-------------|----------|
| **Atoms** | Smallest UI units | `AppButton`, `AppText`, `AppIcon` |
| **Molecules** | Atom combinations | `IconLabel`, `SelectionChip` |
| **Organisms** | Complex components | `OccasionTile`, `MessageOption` |
| **Templates** | Page layouts | `BaseScreen`, `ScrollableScreen` |
| **Pages** | Full screens | `HomeScreen`, `ResultsScreen` |

## Core Concepts

### Occasions (10 types)
1. Birthday
2. Thank You
3. Sympathy
4. Wedding/Engagement
5. Graduation
6. Baby/New Parent
7. Get Well
8. Anniversary
9. Congratulations
10. Apology

### Relationships
- Close friend
- Family member
- Colleague/Boss
- Acquaintance
- Romantic partner

### Tones (MVP: 4)
- Heartfelt
- Casual
- Funny
- Formal

## Monetization & Usage Limits

| Tier | Limit | Price |
|------|-------|-------|
| Free | 3 total (lifetime) | $0 |
| Pro Weekly | 500/mo | $2.99/wk |
| Pro Monthly | 500/mo | $4.99/mo |
| Pro Yearly | 500/mo | $29.99/yr |

**Free tier = 3 generations EVER (not daily). Limits your cost to $0.00012 per free user.**

**Usage tracked locally (SharedPreferences), subscription via RevenueCat.**

## Generation Flow

```
Home (Occasion Grid)
    ↓
Select Occasion
    ↓
Select Relationship
    ↓
Select Tone
    ↓
Add Personal Details (optional)
    ↓
Check usage limits
    ↓
Generate (Gemini API)
    ↓
Results (3 options)
    ↓
Copy to clipboard
```

## Key Files

| File | Purpose |
|------|---------|
| `docs/PRODUCT_SPEC.md` | Full product specification |
| `lib/core/services/ai_service.dart` | Gemini API integration |
| `lib/core/services/usage_service.dart` | Daily/monthly limit tracking |
| `lib/features/home/home_screen.dart` | Main occasion grid |

## Coding Conventions

- **Riverpod 3.0** with code generation (`@riverpod` annotations)
- **go_router** for navigation (type-safe, declarative)
- **Atomic Design** for UI components
- Use `const` constructors where possible
- Keep widgets small and focused (<200 lines)
- Extract business logic to services/providers
- Use `Gap` widget for spacing (not `SizedBox`)

## Environment Variables

Use `envied` for compile-time security. Create `lib/env/env.dart`:

```dart
import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GEMINI_API_KEY', obfuscate: true)
  static String geminiApiKey = _Env.geminiApiKey;
  
  @EnviedField(varName: 'REVENUECAT_IOS_KEY', obfuscate: true)
  static String revenueCatIosKey = _Env.revenueCatIosKey;
  
  @EnviedField(varName: 'REVENUECAT_ANDROID_KEY', obfuscate: true)
  static String revenueCatAndroidKey = _Env.revenueCatAndroidKey;
}
```

Then create `.env` file (DO NOT COMMIT):
```
GEMINI_API_KEY=xxx
REVENUECAT_IOS_KEY=xxx
REVENUECAT_ANDROID_KEY=xxx
```

Run `dart run build_runner build` to generate.

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/features/home/home_screen_test.dart

# Generate mocks (if using mockito)
dart run build_runner build
```
