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
| Edge function not verified | `supabase_auth_provider.dart:375` | Add health check for delete-user/exchange-apple-token on init |
| Account deletion orphan data | Edge function | Verify cleanup of usage, fingerprints, history tables |
| No data export | Settings | GDPR/CCPA right to portability - add export button |
| No analytics consent toggle | Settings | Privacy policy mentions opt-out but no toggle exists |
| No force update mechanism | App startup | Can't force users off broken versions - add Remote Config |

---

## HIGH

| Issue | Location | Fix |
|-------|----------|-----|
| Paywall bypasses service interface | `custom_paywall_screen.dart` | Calls SDK directly - can't mock/test purchase flow |
| Subscription service 21% coverage | `subscription_service.dart` | Revenue-critical, needs more tests |
| Auth providers 0% coverage | `*_auth_provider.dart` | 86 lines untested auth flow |
| Reauth service 1% coverage | `reauth_service.dart` | Security-critical, nearly untested |
| Fire-and-forget sync loses data | `usage_service.dart:309-310` | Add retry queue, persist pending syncs |

| OAuth re-auth weak | `reauth_service.dart:133-140` | Require password/re-OAuth for sensitive ops |
| No root/jailbreak detection | App startup | Add SafetyNet/freeRASP for fraud prevention |
| No E2E tests in CI | `.github/workflows/` | Tests exist in `integration_test/` but not in CI |
| No app state restoration | Forms | Add RestorationMixin - form data lost on process death |
| Privacy policy accuracy | Legal | Verify policy matches actual data practices |

---

## MEDIUM

| Issue | Location | Fix |
|-------|----------|-----|

| Missing CAPTCHA | `email_auth_screen.dart` | Add Turnstile/hCaptcha + Supabase config |
| Device fingerprint 7% coverage | `device_fingerprint_service.dart` | Free tier abuse prevention undertested |
| AI service 37% coverage | `ai_service.dart` | Retry logic branches untested |
| String-based error detection | `auth_errors.dart:46-179` | Message matching as fallback |
| No connectivity monitoring | App | No `connectivity_plus` - just error messages |
| No circuit breakers | Network | Repeated failures don't trigger fallback |

| Generic catch blocks | Throughout `/lib` | Many `catch (e)` lose exception type info |

| No Remote Config | App | Can't toggle features or kill switches remotely |
| No health monitoring | Operations | No uptime monitoring for Supabase/Gemini |
| Magic link custom scheme fallback | `supabase_auth_provider.dart:332` | Deprecate, use HTTPS universal links only |
| RevenueCat in dart-define | Build system | Visible in logs - use --dart-define-from-file |

---

## LOW

| Issue | Location | Fix |
|-------|----------|-----|
| Missing Google nonce | `auth_service.dart` | Native SDK has built-in protections |



| No SSL certificate pinning | Network | Consider for banking-level security |
| No visual regression tests | Testing | Add golden tests |
| No performance tests | Testing | Add load/stress tests |
| No history pagination | `history_service.dart` | 200-item cap fine, add lazy loading v1.1 |
| No accessibility test suite | Testing | Add a11y automation |

---

## Theoretical / Cloning Concerns

> Items that are "best practice" but don't affect production. Revisit when cloning.

| Issue | Location | Reality |
|-------|----------|---------|
| Supabase singleton direct access | `usage_service.dart:60-66` | Tests pass, works fine |
| AI system instruction hardcoded | `ai_service.dart:22-52` | Only matters if cloning |
| Domain models hidden coupling | `core/models/*.dart` | Just how Dart works |
| App-specific code undocumented | `features/`, `core/models/` | Cloning concern only |
| Device fingerprint spoofable | `device_fingerprint_service.dart` | Documented limitation |
| AI model not singleton | `ai_service.dart` | Works fine via Provider |
| Navigation string path comparison | `app.dart` | Works, minor smell |
| Legacy appRouter variable | `router.dart` | Cleanup task |
| StateNotifier legacy API | `providers.dart` | Preference, not broken |
| Form state in 6 providers | `providers.dart:251-279` | Preference, works fine |

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
