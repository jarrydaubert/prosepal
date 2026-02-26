# CLAUDE.md - Prosepal

AI-powered message helper for greeting cards. "The right words, right now."

## Quick Reference

| Item | Value |
|------|-------|
| Bundle ID | `com.prosepal.prosepal` |
| Min iOS | 15.0 |
| Min Android | API 23 (Android 6.0) |
| Flutter | 3.38+ |
| Dart | 3.10+ |

## Commands

```bash
flutter run                    # Run app
flutter test                   # All tests
flutter analyze                # Lint
dart format .                  # Format
dart run build_runner build --delete-conflicting-outputs  # Regenerate freezed
./scripts/setup-hooks.sh       # Install pre-commit hook (format + analyze)
```

## Pre-commit Hook (RECOMMENDED)

Run `./scripts/setup-hooks.sh` to install. Auto-runs before each commit:
- `dart format --set-exit-if-changed lib/ test/`
- `flutter analyze --no-fatal-infos`

## Key Services

| Service | Dashboard |
|---------|-----------|
| Supabase | https://supabase.com/dashboard (auth, usage tracking) |
| RevenueCat | https://app.revenuecat.com (subscriptions) |
| Firebase | https://console.firebase.google.com (AI, analytics, crashes) |

## Architecture

- **State**: Riverpod 3.x with code generation
- **Navigation**: go_router with auth guards
- **AI**: Firebase AI (Gemini) with structured JSON output
- **Auth**: Supabase (Apple, Google, Email)
- **Payments**: RevenueCat (weekly/monthly/yearly)

## Project Structure

```
lib/
├── app/           # App shell, router
├── core/          # Services, models, providers, interfaces
├── features/      # Screens by feature (auth, home, generate, etc.)
└── shared/        # Reusable UI (components, theme)
```

## Documentation

| Doc | Purpose |
|-----|---------|
| `docs/ARCHITECTURE.md` | File map |
| `docs/BACKLOG.md` | Remaining work |
| `docs/LAUNCH_CHECKLIST.md` | Pre-launch tasks |
| `docs/TESTING.md` | Test coverage details |
| `docs/SERVICE_ENDPOINTS.md` | SDK method coverage |

## Monetization

| Tier | Limit |
|------|-------|
| Free | 1 total (lifetime) |
| Pro | 500/month |

## Firebase Remote Config (CONFIGURED)

AI model and force update controlled via Firebase Console > Remote Config (Client):

| Parameter | Current Value | Purpose |
|-----------|---------------|---------|
| `ai_model` | `gemini-2.5-flash` | Primary Gemini model |
| `ai_model_fallback` | `gemini-2.5-flash-lite` | Fallback if primary fails |
| `min_app_version_ios` | `1.0.0` | Force update threshold |
| `min_app_version_android` | `1.0.0` | Force update threshold |

To switch AI models (e.g., when Gemini 3 SDK support arrives):
1. Firebase Console > Prosepal > Run > Remote Config
2. Edit `ai_model` → `gemini-3-flash-preview`
3. Publish changes

See: `lib/core/services/remote_config_service.dart`

## Security

- HTTPS only (Android network_security_config, iOS ATS)
- ProGuard/R8 obfuscation on Android
- Supabase RLS for usage data
- RevenueCat handles all payment data
