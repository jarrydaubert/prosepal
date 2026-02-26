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
```

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
└── shared/        # Reusable UI (atoms, molecules, organisms, theme)
```

## Documentation

| Doc | Purpose |
|-----|---------|
| `docs/ARCHITECTURE.md` | File map |
| `docs/BACKLOG.md` | Remaining work |
| `docs/LAUNCH_CHECKLIST.md` | Pre-launch tasks |
| `docs/TEST_AUDIT.md` | Test coverage details |
| `docs/SERVICE_ENDPOINTS.md` | SDK method coverage |

## Monetization

| Tier | Limit |
|------|-------|
| Free | 1 total (lifetime) |
| Pro | 500/month |

## Security

- HTTPS only (Android network_security_config, iOS ATS)
- ProGuard/R8 obfuscation on Android
- Supabase RLS for usage data
- RevenueCat handles all payment data
