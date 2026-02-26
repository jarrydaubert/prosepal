# Backlog

> **Note:** This file contains only outstanding TODO items. Completed work is tracked in git history, not here. Keep this file clean - remove items when done.

---

## P0 - Release Blockers

| Item | Action |
|------|--------|
| App Store ID | Add to `review_service.dart` and `settings_screen.dart` after App Store approval. Find in App Store Connect > App Information > Apple ID (numeric). |

---

## P3 - Compliance (v1.1)

| Item | Notes |
|------|-------|
| Data export feature | GDPR right to portability |
| Analytics opt-out | Settings toggle |
| Apple Privacy Labels | Fill in App Store Connect |
| Cross-platform subscription docs | Add FAQ/Terms note: subscriptions are per-store (iOS/Android separate) |

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

### Core Features

- Regeneration option ("Generate More")
- History multi-select (select all/individual, batch delete)
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
| Android: OnBackInvokedCallback not enabled | Low |

---

## P6 - SEO Content Strategy (Post-Launch)

> Wait until app is live and has reviews. Focus on App Store ASO first.

### Tier 1 - Low Difficulty, High Volume
| Keyword | Volume | Difficulty | Action |
|---------|--------|------------|--------|
| sympathy messages | 135K | 27% | Create `/messages/sympathy` landing page |
| condolence messages | 60K | 23% | Bundle with sympathy page |

### Tier 2 - Medium Difficulty
| Keyword | Volume | Difficulty | Action |
|---------|--------|------------|--------|
| happy birthday wishes | 368K | 57% | Create `/messages/birthday` page |
| congratulations messages | 135K | 48% | Create `/messages/congratulations` page |
| thank you notes | 110K | 45% | Create `/messages/thank-you` page |

### Content Ideas
- "50 Sympathy Card Messages That Actually Help"
- "What to Write in a Wedding Card (With Examples)"
- "Birthday Wishes for Every Relationship"

---

## P8 - Future Expansion

| Initiative | Reference |
|------------|-----------|
| B2B Corporate Programs | `docs/EXPANSION_STRATEGY.md` |
| Retail/Brand Partnerships | `docs/EXPANSION_STRATEGY.md` |
| Platform Cloning | `docs/CLONING_PLAYBOOK.md` |
