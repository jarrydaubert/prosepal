# Backlog

> Actionable items only. High-level.

---

## Release Blockers (P0)

| Item | Action |
|------|--------|
| App Store ID | Add to `_rateApp()` and `review_service.dart` after approval |
| IAP Products | Submit in App Store Connect |

---

## Technical Debt

| Item | Location | Notes |
|------|----------|-------|
| UsageService race condition | `usage_service.dart` | Atomic increment via Supabase RPC |
| Hardcoded usage limits | `usage_service.dart` | Move to remote config |
| Supabase singleton | `usage_service.dart` | Inject client for testability |
| Integration/E2E tests | `integration_test/` | Navigation flows: onboarding→auth→paywall→biometric |

---

## Known Issues

| Issue | Severity |
|-------|----------|
| Supabase session persists in Keychain | Low |
| No offline banner | Low |
| HomeScreen usage indicator tests failing (3) | Low |

---

## Compliance (v1.1)

| Item | Notes |
|------|-------|
| Data export feature | GDPR right to portability - export user data as JSON |
| Analytics opt-out | Settings toggle to disable Firebase Analytics |
| Apple Privacy Labels | Fill in App Store Connect (similar to Play Data Safety) |
| Apple token revocation | Call Apple revocation endpoint on account delete |

---

## v1.1 Features

### Core
- Regeneration option ("Generate More")
- Message history / favorites
- Feedback (thumbs up/down per message)
- Pull-to-refresh on home
- Occasion search/filter

### Security
- Lifecycle re-auth (biometrics on resume)
- Passcode fallback
- Apple token revocation on delete
- Encrypted history storage

### Enhancements
- More tones (Sarcastic, Nostalgic, Poetic)
- "Make it rhyme" toggle
- Multi-language (Spanish, French)
- Tablet/landscape layout

### Integrations
- Birthday reminders + push notifications
- Shareable card preview (image export)
- Photo integration (Gemini multimodal)

---

## Future Ideas (v2.0+)

- International expansion (Japan)
- Group messages
- Scheduling
- Address book sync

---

## ASO Metadata

**iOS App Name:** `Prosepal - Card Message Writer`
**iOS Subtitle:** `AI Birthday & Thank You Notes`
**Keywords:** `greeting card writer,thank you note,wedding message,sympathy card,get well,anniversary,graduation`
**Category:** Utilities / Lifestyle
**Age Rating:** 4+

**Screenshot Captions:**
1. "The right words, right now"
2. "Birthday, wedding, sympathy & more"
3. "Tailored to your relationship"
4. "3 unique messages in seconds"
5. "Funny, warm, or formal"
6. "Standing in the card aisle? We've got you"
