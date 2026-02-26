# Backlog

> **Note:** This file contains only outstanding TODO items. Completed work is tracked in git history, not here. Keep this file clean - remove items when done.

---

## P0 - Release Blockers

| Item | Action |
|------|--------|
| App Store ID | Add to `review_service.dart` after App Store approval |
| IAP Products | Submit in App Store Connect |

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
