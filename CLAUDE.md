# CLAUDE.md - Prosepal

## Project Overview

Prosepal is an AI-powered message helper app that generates personalized messages for greeting cards and special occasions. Built with Flutter for iOS, Android, and Web.

**Tagline:** "The right words, right now"

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter 3.38+ |
| Auth + DB | Supabase (V1.1+, not MVP) |
| AI | Gemini 2.5 Flash (via Edge Function) |
| Payments | RevenueCat |
| Analytics | Firebase Analytics |
| Crashes | Firebase Crashlytics |

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
```

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart              # MaterialApp config
│   └── router.dart           # Navigation
├── features/
│   ├── home/                 # Occasion selection grid
│   ├── generate/             # Generation flow screens
│   ├── results/              # 3 message options display
│   ├── paywall/              # Subscription screen
│   └── settings/             # App settings
├── core/
│   ├── services/
│   │   ├── ai_service.dart   # Gemini API calls
│   │   ├── subscription_service.dart
│   │   └── analytics_service.dart
│   ├── models/
│   │   ├── occasion.dart
│   │   ├── relationship.dart
│   │   ├── tone.dart
│   │   └── message.dart
│   └── theme/
│       ├── colors.dart
│       ├── typography.dart
│       └── spacing.dart
└── shared/
    ├── widgets/
    └── extensions/
```

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
  - Recipient name
  - Memory/context
    ↓
Generate (API call)
    ↓
Results (3 options)
  - Copy to clipboard
  - Regenerate
```

## Monetization

| Tier | Limit | Price |
|------|-------|-------|
| Free | 3/day | $0 |
| Pro Monthly | Unlimited | $4.99/mo |
| Pro Yearly | Unlimited | $29.99/yr |

## Key Files

| File | Purpose |
|------|---------|
| `docs/PRODUCT_SPEC.md` | Full product specification |
| `lib/core/services/ai_service.dart` | Gemini API integration |
| `lib/features/home/home_screen.dart` | Main occasion grid |
| `lib/features/generate/` | Multi-step generation flow |

## Coding Conventions

- Use Riverpod for state management
- Follow Flutter style guide
- Use `const` constructors where possible
- Keep widgets small and focused
- Extract business logic to services
- Use named routes for navigation

## Environment Variables

Create `.env` file (DO NOT COMMIT):
```
GEMINI_API_KEY=xxx
REVENUECAT_IOS_KEY=xxx
REVENUECAT_ANDROID_KEY=xxx
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/features/home/home_screen_test.dart
```
