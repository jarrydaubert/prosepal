# Backlog

> Outstanding TODO items only. Completed work tracked in git history.

---

## P0 - Release Blockers

| Item | Action |
|------|--------|
| App Store ID | Add to `review_service.dart` and `settings_screen.dart` after approval |
| Supabase leaked password protection | Enable toggle in Dashboard > Auth (requires paid plan) |

---

## CRITICAL

| Issue | Location | Fix |
|-------|----------|-----|
| No data export | Settings | GDPR/CCPA right to portability - add export button |
| No analytics consent toggle | Settings | Privacy policy mentions opt-out but no toggle exists |
| No force update mechanism | App startup | Can't force users off broken versions - add Remote Config |

---

## HIGH

| Issue | Location | Fix |
|-------|----------|-----|
| Log parameter disclosure | `log_service.dart` | No PII filtering - raw data to Crashlytics (GDPR risk) |
| Raw AI response in logs | `ai_service.dart:389` | User content logged - add truncation/hashing |
| No root/jailbreak detection | App startup | Add SafetyNet/freeRASP for fraud prevention |
| No E2E tests in CI | `.github/workflows/` | Tests exist in `integration_test/` but not in CI |
| No app state restoration | Forms | Add RestorationMixin - form data lost on process death |
| Privacy policy accuracy | Legal | Verify policy matches actual data practices |

---

## MEDIUM

| Issue | Location | Fix |
|-------|----------|-----|
| Prompt injection | `ai_service.dart:514-519` | User input directly in prompt - add sanitization |
| No input length validation | `ai_service.dart` | No character limit on recipientName/personalDetails |
| Missing CAPTCHA | `email_auth_screen.dart` | Add Turnstile/hCaptcha + Supabase config |
| String-based error detection | `auth_errors.dart:46-179` | Message matching as fallback |
| No connectivity monitoring | App | No `connectivity_plus` - just error messages |
| No circuit breakers | Network | Repeated failures don't trigger fallback |
| Concurrent generation race | `generate_screen.dart:276` | Rapid taps before state update possible |
| Generic catch blocks | Throughout `/lib` | Many `catch (e)` lose exception type info |
| Missing autoDispose | `providers.dart:251-279` | Form providers persist after screen disposal |
| No Remote Config | App | Can't toggle features or kill switches remotely |
| No health monitoring | Operations | No uptime monitoring for Supabase/Gemini |

---

## LOW

| Issue | Location | Fix |
|-------|----------|-----|
| Missing Google nonce | `auth_service.dart` | Native SDK has built-in protections |
| No StoreKit2 config | `subscription_service.dart` | Add `usesStoreKit2IfAvailable: true` |
| No deferred purchase handling | `subscription_service.dart` | Handle iOS parental controls |
| StateNotifier legacy API | `providers.dart` | Migrate to Notifier/AsyncNotifier |
| Form state in 6 providers | `providers.dart:251-279` | Consolidate to single NotifierProvider |
| No offline detection | AI service | Check connectivity before generation |
| AI model not singleton | `ai_service.dart` | Enforce singleton pattern |
| No SSL certificate pinning | Network | Consider for banking-level security |
| No visual regression tests | Testing | Add golden tests |
| No performance tests | Testing | Add load/stress tests |
| No accessibility test suite | Testing | Add a11y automation |

---

## Compliance (v1.1)

| Item | Notes |
|------|-------|
| Apple Privacy Labels | Fill in App Store Connect |
| Cross-platform subscription docs | Add FAQ note: subscriptions are per-store |

---

## Localization

| Item | Location |
|------|----------|
| Results screen | `results_screen.dart` - Extract to .arb |
| Auth screens | `auth_screen.dart`, `email_auth_screen.dart` |
| Paywall | `custom_paywall_screen.dart` |
| Settings | `settings_screen.dart` |
| Accessibility | Add Semantics widgets throughout |

---

## v1.1 Features

- Regeneration option ("Generate More")
- History multi-select and batch delete
- Feedback (thumbs up/down per message)
- Occasion search/filter
- More tones (Sarcastic, Nostalgic, Poetic)
- Multi-language (Spanish, French)
- Birthday reminders + push notifications

---

## External Dependencies

### Gemini Model - Action by May 2026

| Item | Action |
|------|--------|
| `gemini-2.5-flash` shutdown June 2026 | Add model fallback list in `ai_config.dart` |
| No fallback on model 404 | Catch error, try `gemini-2.5-flash-lite` then `gemini-3-flash` |

### Supabase - Monitor 2026

| Item | Action |
|------|--------|
| Key rotation alerts | Subscribe to supabase.com/changelog |
| Graceful auth failure | Show "maintenance" screen, not crash |

---

## MRR-Gated Experiments

| Item | Trigger | Notes |
|------|---------|-------|
| Increase free tier to 3 lifetime | MRR > $5k | Better retention, higher API costs |
| 1 free/month for churned users | MRR > $10k | Win-back campaign |

---

## Tech Debt

| Item | Notes |
|------|-------|
| Simplify auth navigation | Remove `redirectTo` params - just `pop()` on dismiss |

---

## Known Issues

| Issue | Severity |
|-------|----------|
| Supabase session persists in Keychain | Low |
| Android: OnBackInvokedCallback not enabled | Low |

---

## What's Already Good (Preserve)

| Pattern | Location |
|---------|----------|
| Server-side usage enforcement (RPC + RLS) | `usage_service.dart` |
| AI error classification + retry | `ai_service.dart` |
| Service/Interface pattern | `core/interfaces/` |
| Device fingerprinting | `device_fingerprint_service.dart` |
| Privacy screen on background | `app.dart` |
| Biometric lock with timeout | `app.dart`, `reauth_service.dart` |
| Apple token exchange | `supabase_auth_provider.dart` |
| Test Store blocked in release | `subscription_service.dart` |
| syncPurchases on init | `subscription_service.dart` |
| App Check enabled | `main.dart` |
| HTTPS-only enforced | Network config |
| Centralized logging | `log_service.dart` |
| 30s timeout on network calls | Auth/Supabase services |
| Encrypted secure storage | Biometric pref, history |
| HTTPS Universal/App Links | Deep link security |
| Global sign-out | All sessions invalidated |
| Rate limiting (fail-closed) | Client + server |

---

## Future Expansion

| Initiative | Reference |
|------------|-----------|
| B2B Corporate Programs | `docs/EXPANSION_STRATEGY.md` |
| Retail/Brand Partnerships | `docs/EXPANSION_STRATEGY.md` |
| Platform Cloning | `docs/CLONING_PLAYBOOK.md` |
