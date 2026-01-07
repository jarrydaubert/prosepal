# Backlog

> Prioritized TODO items only.

---

## Release Blockers (P0)

| Item | Action |
|------|--------|
| App Store ID | Add to `_rateApp()` and `review_service.dart` after approval |
| IAP Products | Submit in App Store Connect |

## Deployment Required

```bash
# Run in Supabase SQL Editor (Dashboard > SQL Editor)
supabase/migrations/004_create_device_usage.sql
supabase/migrations/005_create_device_check_rpc.sql
supabase/migrations/006_create_rate_limiting.sql
supabase/migrations/007_create_apple_credentials.sql

# Deploy Edge Functions
supabase functions deploy delete-user
supabase functions deploy exchange-apple-token

# Set Apple secrets (for token revocation)
supabase secrets set APPLE_TEAM_ID=xxx APPLE_CLIENT_ID=xxx APPLE_KEY_ID=xxx APPLE_PRIVATE_KEY=xxx
```

---

## P1 - Security (COMPLETED)

All P1 security items implemented:
- Re-auth for sensitive operations (deleteAccount)
- Env vars required for RevenueCat keys (fail in release if missing)
- Client-side auth rate limiting with exponential backoff
- Screenshot/screen recording prevention (release builds only)

---

## P2 - Technical Debt

| Item | Location |
|------|----------|
| Consolidate ErrorLogService | `error_log_service.dart` - Merge into LogService |
| Form state consolidation | `providers.dart` - Single NotifierProvider |
| AutoDispose for transient state | `providers.dart` |
| Supabase singleton injection | `usage_service.dart` - For testability |
| Hardcoded usage limits | `usage_service.dart` - Move to remote config |

---

## P3 - Compliance (v1.1)

| Item | Notes |
|------|-------|
| Data export feature | GDPR right to portability |
| Analytics opt-out | Settings toggle |
| Apple Privacy Labels | Fill in App Store Connect |

---

## P4 - Localization & Accessibility

| Item | Location |
|------|----------|
| Results screen | `results_screen.dart` - Extract strings to .arb |
| Auth screens | `auth_screen.dart`, `email_auth_screen.dart` |
| Paywall | `custom_paywall_screen.dart` |
| Settings | `settings_screen.dart` |
| Accessibility | Add Semantics widgets throughout |

---

## P5 - v1.1 Features

- Regeneration option ("Generate More")
- Message history / favorites
- Feedback (thumbs up/down per message)
- Occasion search/filter
- More tones (Sarcastic, Nostalgic, Poetic)
- Multi-language (Spanish, French)
- Birthday reminders + push notifications

---

## Known Issues

| Issue | Severity |
|-------|----------|
| Supabase session persists in Keychain | Low |
| No offline banner | Low |
| HomeScreen usage indicator tests failing (3) | Low |
