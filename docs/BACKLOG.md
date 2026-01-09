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

## Architecture Audit (Gold Standard Fixes)

> Deep audit findings for making this codebase the template for future apps.

### P0 - Critical (Fix Before Cloning)

| Issue | Location | Fix |
|-------|----------|-----|
| Supabase URL/key hardcoded | `main.dart:67-68` | Use dart-define like RevenueCat (consistency) |

### P1 - Important (Should Fix)

| Issue | Location | Fix |
|-------|----------|-----|
| SignOut scope is local-only | `supabase_auth_provider.dart:270` | Use `SignOutScope.global` to invalidate all sessions |
| Generic catch blocks (22 files) | Throughout `/lib` | Add specific exception types (AuthException, PurchasesErrorCode, etc.) |
| CustomerInfo listener lifecycle | `providers.dart:164-199` | Track listener refs to prevent potential leaks |
| No provider pre-initialization | `main.dart` | Call `authService.initializeProviders()` for faster first sign-in |

### P2 - Nice to Have (Post-Launch)

| Issue | Location | Fix |
|-------|----------|-----|
| No StoreKit2 configuration | `subscription_service.dart` | Add `usesStoreKit2IfAvailable: true` for modern iOS |
| No deferred purchase handling | `subscription_service.dart` | Handle iOS parental controls (PurchasesErrorCode.productNotAvailableForPurchaseError) |
| StateNotifier/StateProvider legacy API | `providers.dart` | Migrate to Notifier/AsyncNotifier (Riverpod 3.x modern) |
| Auth listener magic link race | `app.dart:97-142` | Debounce or use single navigation source |
| No environment config abstraction | Various | Create AppConfig class with all dart-defines |
| No offline detection | AI service | Check connectivity before generation |

### P3 - Low Priority

| Issue | Location | Notes |
|-------|----------|-------|
| Form state spread across 6 providers | `providers.dart:251-279` | Could consolidate to single NotifierProvider<FormState> |
| No autoDispose on form providers | `providers.dart` | Add .autoDispose for memory optimization |
| unawaited token exchange | `auth_service.dart:206-214` | Fire-and-forget could fail silently (acceptable trade-off) |

### What's Already Good (Keep These Patterns)

| Pattern | Location | Why It's Good |
|---------|----------|---------------|
| AI error classification + retry | `ai_service.dart` | Comprehensive typed exceptions, exponential backoff with jitter |
| Server-side usage enforcement | `usage_service.dart` | Atomic RPC prevents client tampering |
| Device fingerprinting | `device_fingerprint_service.dart` | Prevents free tier abuse via reinstall |
| Service/Interface pattern | `core/interfaces/` | Clean DI, easy to mock in tests |
| Privacy screen on background | `app.dart` | Prevents screenshots in app switcher |
| Biometric lock with timeout | `app.dart`, `reauth_service.dart` | Security without annoying users |
| Apple token exchange | `supabase_auth_provider.dart` | Required for account deletion compliance |
| Test Store blocked in release | `subscription_service.dart` | Prevents accidental production crash |
| syncPurchases on init | `subscription_service.dart` | Restores subscriptions after reinstall |

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
