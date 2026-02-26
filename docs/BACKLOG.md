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

### UX Improvements (from flow analysis)

| Item | Rationale |
|------|-----------|
| Skip biometric prompt after sign-in | Only offer after purchase - feels contradictory right after authenticating |
| A/B test paywall after onboarding | Capture Day 0 conversion window: "Start trial OR Try 1 free" |
| Configurable lock timeout | Settings: Immediate / 1 min / 5 min / Never (if users ask) |
| Restore Pro "continue as guest" option | Don't gate access for reinstalls - let them use Pro while prompting sign-in |

### Core Features

- Regeneration option ("Generate More")
- Message history / favorites
- Feedback (thumbs up/down per message)
- Occasion search/filter
- More tones (Sarcastic, Nostalgic, Poetic)
- Multi-language (Spanish, French)
- Birthday reminders + push notifications

---

## P7 - MRR-Gated Experiments

> Only explore these once revenue justifies the increased server costs.

| Item | Trigger | Notes |
|------|---------|-------|
| Increase free tier to 3 lifetime | MRR > $5k | More engagement opportunities, better retention for users not ready to pay. Trade-off: slower conversion, higher Gemini API costs |
| 1 free/month for churned users | MRR > $10k | Win-back campaign - let lapsed users try again |

---

## Tech Debt

| Item | Notes |
|------|-------|
| Simplify auth screen navigation | Remove `redirectTo` params - just `pop()` on dismiss and let calling screens react to auth state changes |

---

## Known Issues

| Issue | Severity |
|-------|----------|
| Supabase session persists in Keychain | Low |
| No offline banner | Low |

---

## P6 - Future Expansion

| Initiative | Reference |
|------------|-----------|
| B2B Corporate Programs | `docs/EXPANSION_STRATEGY.md` |
| Retail/Brand Partnerships | `docs/EXPANSION_STRATEGY.md` |
| Platform Cloning | `docs/CLONING_PLAYBOOK.md` |
