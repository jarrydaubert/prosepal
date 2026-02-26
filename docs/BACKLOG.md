# Backlog

> Outstanding TODO items only. Completed work tracked in git history.

---

## P0 - Release Blockers

| Item | Action |
|------|--------|
| Supabase leaked password protection | Enable toggle in Dashboard > Auth (requires paid plan) |

---

## Recurring Maintenance (Calendar Reminders)

| Item | Frequency | Next Due | Action |
|------|-----------|----------|--------|
| Apple OAuth secret | 6 months | ~July 2026 | Regenerate in Apple Developer Console, update in Supabase Auth > Apple provider. **No notification - app breaks silently!** |

---

## HIGH

| Issue | Location | Fix |
|-------|----------|-----|
| Paywall bypasses service interface | `paywall_sheet.dart` | Route getOfferings(), purchasePackage(), restorePurchases() through ISubscriptionService for testability |
| Subscription service 21% coverage | `subscription_service.dart` | Revenue-critical, needs more tests |
| Auth providers 0% coverage | `*_auth_provider.dart` | 86 lines untested auth flow |
| Reauth service 1% coverage | `reauth_service.dart` | Security-critical, nearly untested |
| Fire-and-forget sync loses data | `usage_service.dart:309-310` | Add retry queue, persist pending syncs |
| OAuth re-auth for sensitive ops | `reauth_service.dart:121-135` | Redirect to OAuth provider for account deletion (not just dialog) |
| No E2E tests in CI | `.github/workflows/` | Tests exist in `integration_test/` but not in CI |
| No app state restoration | Forms | Add RestorationMixin - form data lost on process death |

---

## MEDIUM

| Issue | Location | Fix |
|-------|----------|-----|
| Paywall sync button sizing consistency | `paywall_sheet.dart:964-1008` | Google/Email buttons use 14pt font, Apple official widget uses ~17pt. Increase custom `_AuthButton` compact font from 14 to 16 to match Apple's visual weight |
| Password reset deep link UX | `router.dart:121` | Create dedicated `/auth/reset-password` screen that extracts token from deep link instead of redirecting to generic `/auth` |
| Auto-purchase race after email auth | `email_auth_screen.dart:238-241` | Navigate-then-purchase pattern may fail; show dialog before navigation or use deferred callback |
| Document service configurations | Firebase/Supabase/RevenueCat | Screen-by-screen audit of what's enabled/configured in each dashboard. Create `docs/SERVICE_CONFIG.md` with screenshots or detailed notes for reproducibility. |
| Mockito exploration | `test/mocks/` | Evaluate migrating simple mocks to Mockito for reduced boilerplate. Current manual mocks excel at state tracking and error simulation. Consider Mockito for new simple interface mocks. |
| Paywall component decomposition | `paywall_sheet.dart` | 890 lines - extract PaywallHeader, BenefitsSection, PackageSelector, AuthSection for maintainability |
| Paywall trial messaging | `paywall_sheet.dart` | Show trial duration per package dynamically (e.g., "7-day free trial, then $4.99/mo") using `storeProduct.introductoryPrice`. Clearer than "no payment due now" and App Store compliant. |
| Paywall accessibility | `paywall_sheet.dart` | Add Semantics labels for screen readers throughout |
| Paywall branding extraction | `paywall_sheet.dart` | Hard-coded "Prosepal Pro", benefits - extract to config for blueprint cloning |
| Auth/lock logic in root widget | `app.dart` | Extract to `AppLifecycleManager` service for testability |
| Imperative biometric lock navigation | `app.dart` | Move to router redirect + Riverpod notifier pattern |
| Skip Remote Config fetch | `main.dart` | Use cached/defaults on startup, fetch async (~200-500ms saved) |
| Remove OAuth pre-warm | `main.dart` | Warm on auth screen instead of startup (~100-200ms saved) |
| Swift Package Manager | `ios/` | Enable SPM for faster iOS builds (Flutter 3.38+ feature) |

| Auth navigation race conditions | `app.dart` | Use GoRouter `refreshListenable` + global redirect |
| Missing CAPTCHA | `email_auth_screen.dart` | Add Turnstile/hCaptcha + Supabase config |
| Device fingerprint 7% coverage | `device_fingerprint_service.dart` | Free tier abuse prevention undertested |
| AI service 37% coverage | `ai_service.dart` | Retry logic branches untested |
| String-based error detection | `auth_errors.dart:46-179` | Message matching as fallback |
| No connectivity monitoring | App | No `connectivity_plus` - just error messages |
| No circuit breakers | Network | Repeated failures don't trigger fallback |
| No Remote Config | App | Can't toggle features or kill switches remotely |
| No health monitoring | Operations | No uptime monitoring for Supabase/Gemini |
| Magic link custom scheme fallback | `supabase_auth_provider.dart:332` | Deprecate, use HTTPS universal links only |
| RevenueCat in dart-define | Build system | Visible in logs - use --dart-define-from-file |

---

## LOW

| Issue | Location | Fix |
|-------|----------|-----|
| Settings restore missing usage sync | `settings_screen.dart:143-153` | Add `usageService.syncFromServer()` call after restore for UI consistency |
| Audit autoDispose usage | `providers.dart` | Review all StateProviders - autoDispose only for single-screen state, not cross-screen navigation state. Fixed: selectedOccasionProvider, generationResultProvider |
| No timeout on splash Pro check | `router.dart:244` | Add timeout with fallback to prevent hang on slow network |
| No notification on bio auto-disable | `router.dart:200` | Show toast when biometrics unavailable and auto-disabled |
| AI config not env-configurable | `ai_config.dart` | Consider Remote Config for model/params (see Gemini section) |
| Missing Google nonce | `auth_service.dart` | Native SDK has built-in protections |
| Generic catch blocks | Throughout `/lib` | ~65 remaining, core services done |
| No SSL certificate pinning | Network | Consider for banking-level security |
| No visual regression tests | Testing | Add golden tests |
| Type-safe env with envied | `app_config.dart` | Replace manual dart-define with `envied` package for type-safe .env |
| URL format validation | `app_config.dart` | Add regex validation for SUPABASE_URL in validate() |
| Auth error localization | `auth_errors.dart` | Integrate `intl` package for multi-language error messages |
| Auth error enums | `auth_errors.dart` | Replace string matching with typed error enums for safety |
| Apple web runtime check | `apple_auth_provider.dart` | Add `kIsWeb` check to require webAuthenticationOptions |
| Token revocation docs | Auth providers | Document server-side revocation webhook integration |
| OAuth scope parameters | `IAuthService` | Add optional scopes/redirectUri to signInWithApple/Google |
| User metadata methods | `IAuthService` | Add updateMetadata/getMetadata for custom user claims |
| MFA/2FA support | `IAuthService` | Add enableMFA/verifyMFA when Supabase supports it |
| Biometric reason localization | `IBiometricService` | Integrate with intl for localized reason messages |
| Google auth state stream | `IGoogleAuthProvider` | Add Stream<GoogleAuthState> for reactive UI updates |
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
| Paywall | `paywall_sheet.dart` |
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
| ~~Model name hardcoded~~ | DONE - RemoteConfigService fetches `ai_model` from Remote Config |
| Wire up model 404 fallback | `ai_service.dart:339` - Call `switchToFallback()` when model returns 404 |
| Model version monitoring | Default: gemini-3-flash-preview, fallback: gemini-2.5-flash. Update Remote Config when 3-flash goes stable |

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

### Lint Cleanup (357 info-level warnings)

Target: Zero analyzer warnings for squeaky clean codebase.

| Rule | Count | Fix | Priority |
|------|-------|-----|----------|
| `prefer_expression_function_bodies` | 117 | Convert `{ return x; }` to `=> x` | Low |
| `avoid_catches_without_on_clauses` | 58 | Add specific exception types to catch blocks | Medium |
| `prefer_const_constructors` | 48 | Add `const` keyword where possible | Low |
| `cascade_invocations` | 34 | Use `..` cascade notation | Low |
| `avoid_redundant_argument_values` | 15 | Remove args matching defaults | Low |
| `use_if_null_to_convert_nulls_to_bools` | 11 | Use `?? false` pattern | Low |
| `unnecessary_lambdas` | 8 | Use tearoffs instead of `() => fn()` | Low |
| `prefer_const_literals_to_create_immutables` | 6 | Add `const` to list/map literals | Low |
| `avoid_dynamic_calls` | 6 | Add type annotations | Medium |
| `unawaited_futures` | 5 | Wrap with `unawaited()` or await | Medium |
| `directives_ordering` | 5 | Sort imports alphabetically | Low |
| `deprecated_member_use` | 4 | Update to non-deprecated APIs | Medium |
| `unnecessary_import` | 2 | Remove redundant imports | Low |
| Misc (10 other rules) | ~20 | Various minor fixes | Low |

**Approach:** Fix in batches by rule type during low-priority sprints.

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
| Server-side Pro verification (RevenueCat webhook) | `supabase/functions/revenuecat-webhook/`, `user_entitlements` table |
| AI error classification + retry | `ai_service.dart` |
| Service/Interface pattern | `core/interfaces/` |
| Device fingerprinting | `device_fingerprint_service.dart` |
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
| Security documentation | `docs/SECURITY.md` |

---

## Future Expansion

| Initiative | Reference |
|------------|-----------|
| B2B Corporate Programs | `docs/EXPANSION_STRATEGY.md` |
| Retail/Brand Partnerships | `docs/EXPANSION_STRATEGY.md` |
| Platform Cloning | `docs/CLONING_PLAYBOOK.md` |
