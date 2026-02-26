# Backlog

> **Note:** This file contains only outstanding TODO items. Completed work is tracked in git history, not here. Keep this file clean - remove items when done.

---

## P0 - Release Blockers

| Item | Action |
|------|--------|
| App Store ID | Add to `review_service.dart` and `settings_screen.dart` after App Store approval. Find in App Store Connect > App Information > Apple ID (numeric). |

---

## Operational & Compliance Gaps (Verified)

> Beyond code issues - operational, compliance, and resilience gaps.

### Critical - Pre-Launch Assessment

| Gap | Category | Status | Notes |
|-----|----------|--------|-------|
| No data export | Compliance | **CONFIRMED** | GDPR/CCPA right to portability. Need export button in settings |
| No analytics consent toggle | Compliance | **CONFIRMED** | Privacy policy mentions opt-out but no actual toggle exists |
| Deep links hijackable | Security | **CONFIRMED** | Already in code audit - custom scheme can be intercepted |
| No force update mechanism | Operations | **CONFIRMED** | Can't force users off broken versions. Need Remote Config |
| No SSL certificate pinning | Security | **NOT FOUND** | No pinning configured. Consider for banking-level security apps |
| Offline Pro users locked out | Resilience | **CONFIRMED** | Already in code audit - no local cache of pro status |
| No database backups documented | Operations | **CONFIRMED** | No backup/recovery docs. Supabase handles auto-backups but undocumented |

### High - Week 1 Post-Launch

| Gap | Category | Status | Notes |
|-----|----------|--------|-------|
| No root/jailbreak detection | Security | **CONFIRMED** | No SafetyNet/freeRASP. Consider for fraud prevention |
| No timeouts on Supabase calls | Resilience | **CONFIRMED** | AI has 30s timeout, but auth/usage calls don't |
| No E2E tests in CI | Testing | **CONFIRMED** | Tests exist in `integration_test/` but not in CI workflow |
| No error boundary UI | UX | **CONFIRMED** | Already in code audit - crashes show red screen |
| No app state restoration | UX | **CONFIRMED** | No RestorationMixin. Form data lost on process death |
| History stored unencrypted | Security | **CONFIRMED** | SharedPreferences - user messages readable on rooted devices |
| Privacy policy accuracy | Compliance | **NEEDS REVIEW** | Should verify policy matches actual data practices |

### Medium - v1.1

| Gap | Category | Status | Notes |
|-----|----------|--------|-------|
| No Remote Config / feature flags | Operations | **CONFIRMED** | Can't toggle features or kill switches remotely |
| No health monitoring / alerting | Operations | **VALID** | No uptime monitoring for Supabase/Gemini |
| No circuit breakers | Resilience | **VALID** | Repeated failures don't trigger fallback |
| No connectivity monitoring | Resilience | **CONFIRMED** | No `connectivity_plus` - just error messages |
| No visual regression tests | Testing | **VALID** | No golden tests |
| No performance tests | Testing | **VALID** | No load/stress tests |
| No accessibility test suite | Testing | **VALID** | No a11y automation |
| No localization infrastructure | i18n | **CONFIRMED** | No .arb files or l10n setup |

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

> Combined deep audit findings. Fix before cloning as template.

### CRITICAL - Must Fix Before Launch

| # | Issue | Location | Status | Fix |
|---|-------|----------|--------|-----|
| 1 | ~~Supabase URL/key hardcoded~~ | `main.dart`, `AppConfig` | **FIXED** | Created centralized `AppConfig` class with dart-define. Updated run scripts. |
| 2 | ~~Rate limit fails open~~ | `rate_limit_service.dart` | **FIXED** | Now uses local fallback (10 req/min) when server unavailable |
| 3 | **No route guards** | `router.dart:24-102` | **CONFIRMED** | Deep links bypass auth. Add `redirect` guard to GoRouter |
| 4 | **Non-blocking init failures** | `main.dart:38-84` | **CONFIRMED** | Firebase/Supabase/RC catch-and-continue. Show error screen if critical services fail |
| 5 | **Deep link scheme hijackable** | `AndroidManifest.xml:35`, `Info.plist:73` | **CONFIRMED** | Custom scheme `com.prosepal.prosepal://` can be intercepted. Migrate to HTTPS App Links |
| 6 | **Apple token exchange race** | `auth_service.dart:227-234` | **CONFIRMED** | `unawaited()` - if exchange fails, can't revoke on delete. Store authCode and retry |
| 7 | **Missing error boundary** | `app.dart` | **PARTIAL** | Has Crashlytics but no user-friendly fallback UI. Add `ErrorWidget.builder` |
| 8 | ~~Usage tracking bypass~~ | `usage_service.dart` | **FALSE** | Server-side `checkAndIncrementServerSide()` is enforced for auth users. Anonymous = 1 free anyway |
| 9 | ~~RevenueCat listener leak~~ | `providers.dart:169,189` | **FALSE** | CustomerInfoNotifier properly adds/removes in constructor/dispose. Riverpod manages lifecycle |
| 10 | ~~Double-identify bug~~ | Multiple files | **FALSE** | `Purchases.logIn()` is idempotent. Same userId = no-op. Doesn't create duplicate customers |

### HIGH - Fix Week 1 Post-Launch

| # | Issue | Location | Status | Fix |
|---|-------|----------|--------|-----|
| 11 | **SignOut scope local-only** | `supabase_auth_provider.dart:270` | **CONFIRMED** | Use `SignOutScope.global` to invalidate all sessions |
| 12 | **RC init race condition** | `subscription_service.dart:148` | **PARTIAL** | `_isInitialized` before sync, but sync is for transfer not fetch |
| 13 | **Wrong exception catch** | `subscription_service.dart:210` | **CONFIRMED** | `PurchasesErrorCode` is enum not exception. Use `PlatformException` |
| 14 | **Provider init race** | `providers.dart:167-174` | **CONFIRMED** | Async fetch could overwrite fresher listener data |
| 15 | **Offline pro check = false** | `providers.dart:205` | **CONFIRMED** | No local cache of pro status. Add SharedPreferences fallback |
| 16 | **Missing Google nonce** | `auth_service.dart:253-301` | **CONFIRMED** | Apple has nonce, Google doesn't. Add for replay protection |
| 17 | **Session refresh silent fail** | `supabase_auth_provider.dart:284-291` | **PARTIAL** | Logs warning but continues. Acceptable if JWT still valid |
| 18 | **Missing CAPTCHA** | `email_auth_screen.dart` | **CONFIRMED** | Interface supports captchaToken but not implemented |
| 19 | **Biometric PIN fallback** | `biometric_service.dart:110` | **DESIGN** | `biometricOnly: false` allows PIN. Intentional for accessibility |
| 20 | **Unencrypted biometric pref** | `biometric_service.dart:96-105` | **CONFIRMED** | SharedPreferences can be modified. Use flutter_secure_storage |
| 21 | **Deep link redirect unvalidated** | `router.dart:42-44` | **PARTIAL** | Internal routes only (prepends `/`), but no whitelist |
| 22 | **Auth listener silent failure** | `app.dart:96-162` | **PARTIAL** | Individual ops have try/catch, stream onError missing |
| 23 | **Navigation race condition** | `app.dart:136-144` | **NEEDS CHECK** | Should verify currentPath null safety |

### MEDIUM - Fix Weeks 2-3

| # | Issue | Location | Status | Fix |
|---|-------|----------|--------|-----|
| 24 | **Prompt injection** | `ai_service.dart:514-519` | **CONFIRMED** | User input directly in prompt. Low impact for greeting cards |
| 25 | **No input length validation** | `ai_service.dart` | **CONFIRMED** | No character limit on recipientName/personalDetails |
| 26 | **Concurrent generation race** | `generate_screen.dart:276` | **PARTIAL** | UI disables button, but rapid taps before state update possible |
| 27 | **Raw JSON in logs** | `ai_service.dart:389` | **CONFIRMED** | `Log.info('AI raw response: $jsonText')` logs full response |
| 28 | **Truncation retry doesn't adapt** | `ai_service.dart:378-385` | **PARTIAL** | Not infinite (bounded by maxRetries), but doesn't increase tokens |
| 29 | **Generic catch blocks (22 files)** | Throughout `/lib` | **CONFIRMED** | Many `catch (e)` lose exception type info |
| 30 | **Missing autoDispose** | `providers.dart:251-279` | **CONFIRMED** | Form providers persist after screen disposal |
| 31 | **Watch/read misuse** | `settings_screen.dart:425-430` | **PARTIAL** | Watches both authStateProvider AND authServiceProvider - redundant |
| 32 | ~~Incorrect invalidation~~ | `generate_screen.dart:320-321` | **FALSE** | Invalidation is correct for service-backed providers |
| 33 | ~~Weak ProGuard rules~~ | `proguard-rules.pro` | **FALSE** | Rules are comprehensive, dictionary file exists |
| 34 | **Log parameter disclosure** | `log_service.dart` | **CONFIRMED** | No PII filtering - raw data passed to Crashlytics |
| 35 | ~~Device fingerprint in logs~~ | `rate_limit_service.dart:86` | **FALSE** | Fingerprint passed to RPC but NOT logged |
| 36 | **String-based error detection** | `auth_errors.dart:46-179` | **CONFIRMED** | Uses statusCode first (good), but message matching as fallback |
| 37 | ~~Error auto-dismiss race~~ | `generate_screen.dart:36-42` | **FALSE** | Timer checks `mounted` before ref access |
| 38 | ~~No provider pre-init~~ | `main.dart:107` | **FALSE** | `authService.initializeProviders()` IS called (unawaited) |

### LOW - Post-Launch Polish

| # | Issue | Location | Status | Fix |
|---|-------|----------|--------|-----|
| 39 | **No StoreKit2 config** | `subscription_service.dart` | **VALID** | Add `usesStoreKit2IfAvailable: true` for modern iOS |
| 40 | **No deferred purchase handling** | `subscription_service.dart` | **VALID** | Handle iOS parental controls |
| 41 | **StateNotifier legacy API** | `providers.dart` | **VALID** | Migrate to Notifier/AsyncNotifier (Riverpod 3.x modern) |
| 42 | **Form state in 6 providers** | `providers.dart:251-279` | **VALID** | Consolidate to single NotifierProvider<FormState> |
| 43 | **No environment config class** | Various | **VALID** | Create AppConfig with all dart-defines |
| 44 | **No offline detection** | AI service | **VALID** | Check connectivity before generation |
| 45 | **Re-auth creates new session** | `reauth_service.dart:151-163` | **NEEDS CHECK** | May disrupt sensitive ops. Preserve session |
| 46 | **Device fingerprint spoofable** | `device_fingerprint_service.dart` | **ACCEPTED** | Rooted devices can impersonate. Acceptable limitation |
| 47 | **AI model not singleton** | `ai_service.dart` | **VALID** | Multiple instances possible via Provider. Enforce singleton |

### What's Already Good (Preserve These!)

| Pattern | Location | Why |
|---------|----------|-----|
| Server-side usage enforcement | `usage_service.dart` | RPC with RLS prevents client tampering |
| AI error classification + retry | `ai_service.dart` | Typed exceptions, exponential backoff with jitter |
| Service/Interface pattern | `core/interfaces/` | Clean DI, testable via overrides |
| Device fingerprinting | `device_fingerprint_service.dart` | Prevents free tier reinstall abuse |
| Privacy screen on background | `app.dart` | Prevents app switcher screenshots |
| Biometric lock with timeout | `app.dart`, `reauth_service.dart` | Security without annoying users |
| Apple token exchange | `supabase_auth_provider.dart` | Required for account deletion compliance |
| Test Store blocked in release | `subscription_service.dart` | Prevents production crash |
| syncPurchases on init | `subscription_service.dart` | Restores subscriptions after reinstall |
| App Check enabled | `main.dart` | Firebase attestation |
| HTTPS-only enforced | Network config | Both platforms |
| Centralized logging | `log_service.dart` | Crashlytics integration |

### Testing Gaps to Address

- Listener memory leak scenarios
- Prompt injection attempts
- Route guard bypass via deep links
- Network failure recovery paths
- Concurrent generation attempts
- Auth state transitions during sensitive ops
- Offline behavior with cached data

---

## External Dependency Resilience (Verified Risks)

> Dependencies with confirmed deprecation timelines or breaking change potential.

### Gemini Model - Action by May 2026

| Item | Status | Action |
|------|--------|--------|
| `gemini-2.5-flash` shutdown | **June 2026** (confirmed) | Add model fallback list in `ai_config.dart` |
| No fallback on model 404 | Missing | Catch `ModelNotFoundError`, try `gemini-2.5-flash-lite` then `gemini-3-flash` |
| Model version not tracked | Missing | Add model name to analytics/logs for debugging |

### Supabase Key Rotation - Monitor Throughout 2026

| Item | Status | Action |
|------|--------|--------|
| Key format | ✅ Already using `sb_publishable_` | No action needed |
| Rotation alerts | Missing | Subscribe to https://supabase.com/changelog |
| Graceful auth failure | Missing | Show "maintenance" screen if auth fails, not crash |
| Edge function JWT verification | Potential risk | If JWT secret rotates, edge functions reject requests |

### App Resilience (Recommended)

| Item | Priority | Action |
|------|----------|--------|
| Force update capability | P2 | Add Firebase Remote Config with `min_app_version` check on startup |
| Maintenance mode UI | P2 | Remote-triggerable "under maintenance" screen |
| Offline banner | P3 | Show connectivity status when offline |
| Health check endpoint | P3 | Edge function to verify all services operational |

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
