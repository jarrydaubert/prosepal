# Prosepal

AI-powered message helper for greeting cards and special occasions.

**"The right words, right now"**

## Features

- 10 occasions (Birthday, Wedding, Sympathy, Thank You, etc.)
- 5 relationship types
- 4 tones (Heartfelt, Casual, Funny, Formal)
- 3 AI-generated message options per request
- Free tier with Pro subscription upgrades

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter |
| State | Riverpod |
| Navigation | go_router |
| AI | Firebase AI (Gemini) |
| Auth | Supabase |
| Payments | RevenueCat |
| Analytics | Firebase Analytics + Crashlytics |

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test
```

## Project Structure

```
lib/
├── app/           # App shell, router
├── core/          # Services, models, providers
├── features/      # Feature screens
└── shared/        # Reusable UI components
```

## Documentation

See `docs/` for detailed documentation:
- `ARCHITECTURE.md` - Project structure
- `LAUNCH_CHECKLIST.md` - Release checklist
- `TEST_AUDIT.md` - Test coverage

## Environment Setup

1. **Firebase**: Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
2. **Supabase**: Configure URL and anon key in `main.dart`
3. **RevenueCat**: Add API keys in `subscription_service.dart`

## License

Proprietary - All rights reserved
