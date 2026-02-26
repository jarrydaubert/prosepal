# Backlog

> Prioritized TODO items only.

---

## Release Blockers (P0)

| Item | Action |
|------|--------|
| App Store ID | Add to `_rateApp()` and `review_service.dart` after approval |
| IAP Products | Submit in App Store Connect |

## Deployment (COMPLETED 2025-01-07)

All migrations, edge functions, and secrets deployed:
- ✅ Migrations 004-007 applied (device usage, rate limiting, Apple credentials)
- ✅ Edge functions deployed (delete-user, exchange-apple-token)
- ✅ Apple secrets configured (Key ID: 5UFN3MDA2Q)

---

## P1 - Security (COMPLETED)

All P1 security items implemented:
- Re-auth for sensitive operations (deleteAccount)
- Env vars required for RevenueCat keys (fail in release if missing)
- Client-side auth rate limiting with exponential backoff
- Screenshot/screen recording prevention (release builds only)

---

## P2 - Technical Debt (REVIEWED)

| Item | Status |
|------|--------|
| Consolidate ErrorLogService | ✅ Merged into LogService |
| Form state consolidation | SKIPPED - No validation logic needed, current pattern works well |
| AutoDispose for transient state | SKIPPED - Explicit reset pattern is more predictable |
| Supabase singleton injection | SKIPPED - Try/catch pattern already handles testability |
| Hardcoded usage limits | SKIPPED - Server RPC already overrides limits, client values are just fallbacks |

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
