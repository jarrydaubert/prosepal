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

> Combined deep audit findings. Fix before cloning as template.

### CRITICAL - Must Fix Before Launch

| # | Issue | Location | Status | Fix |
|---|-------|----------|--------|-----|
| 1 | **Supabase URL/key hardcoded** | `main.dart:67-68` | **CONFIRMED** | Use `--dart-define` like RevenueCat. Note: These ARE public keys by design, but consistency matters. |
| 2 | **Rate limit fails open** | `rate_limit_service.dart:104` | **CONFIRMED** | Returns `allowed: true` on server error. Fix: fail closed + local fallback |
| 3 | **No route guards** | `router.dart:24-102` | **CONFIRMED** | Deep links bypass auth. Add `redirect` guard to GoRouter |
| 4 | **Non-blocking init failures** | `main.dart:38-84` | **CONFIRMED** | Firebase/Supabase/RC catch-and-continue. Show error screen if critical services fail |
| 5 | **Deep link scheme hijackable** | `AndroidManifest.xml:35`, `Info.plist:73` | **CONFIRMED** | Custom scheme `com.prosepal.prosepal://` can be intercepted. Migrate to HTTPS App Links |
| 6 | **Apple token exchange race** | `auth_service.dart:227-234` | **CONFIRMED** | `unawaited()` - if exchange fails, can't revoke on delete. Store authCode and retry |
| 7 | **Missing error boundary** | `app.dart` | **PARTIAL** | Has Crashlytics but no user-friendly fallback UI. Add `ErrorWidget.builder` |
| 8 | ~~Usage tracking bypass~~ | `usage_service.dart` | **FALSE** | Server-side `checkAndIncrementServerSide()` is enforced for auth users. Anonymous = 1 free anyway |
| 9 | ~~RevenueCat listener leak~~ | `providers.dart:169,189` | **FALSE** | CustomerInfoNotifier properly adds/removes in constructor/dispose. Riverpod manages lifecycle |
| 10 | ~~Double-identify bug~~ | Multiple files | **FALSE** | `Purchases.logIn()` is idempotent. Same userId = no-op. Doesn't create duplicate customers |

### HIGH - Fix Week 1 Post-Launch

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| 11 | **SignOut scope local-only** | `supabase_auth_provider.dart:270` | Use `SignOutScope.global` to invalidate all sessions |
| 12 | **RC init race condition** | `subscription_service.dart:148` | `_isInitialized` set before sync completes. Pro status false during sync |
| 13 | **Wrong exception catch** | `subscription_service.dart:210` | Catches `PurchasesErrorCode` not `PurchasesException`. User cancels logged as errors |
| 14 | **Provider init race** | `providers.dart:167-174` | Listener can overwrite newer CustomerInfo data |
| 15 | **Offline pro check = false** | `providers.dart:205` | Offline users locked out. Cache last known pro status |
| 16 | **Missing Google nonce** | `auth_service.dart:253-301` | Replay attack vulnerability. Add nonce like Apple flow |
| 17 | **Session refresh silent fail** | `supabase_auth_provider.dart:284-291` | Delete may not complete server-side. Fail explicitly |
| 18 | **Missing CAPTCHA** | `email_auth_screen.dart:87-156` | Bot/email enumeration attacks on magic link/signup |
| 19 | **Biometric PIN fallback** | `biometric_service.dart:114-118` | Weak PIN bypasses Face ID. Disable device credential fallback |
| 20 | **Unencrypted biometric pref** | `biometric_service.dart:96-105` | Can toggle off via backup manipulation. Use secure storage |
| 21 | **Deep link redirect unvalidated** | `router.dart:42-44` | Malicious redirects possible. Whitelist allowed routes |
| 22 | **Auth listener silent failure** | `app.dart:96-162` | Supabase down = silent failure. Add error handling |
| 23 | **Navigation race condition** | `app.dart:136-144` | `currentPath` could be null. Add null check |

### MEDIUM - Fix Weeks 2-3

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| 24 | **Prompt injection** | `ai_service.dart:514-519` | User input not sanitized. Add input filtering |
| 25 | **No input length validation** | `ai_service.dart` | Token waste, malformed prompts. Validate before API call |
| 26 | **Concurrent generation race** | `generate_screen.dart:276-312` | Multiple API calls possible. Add mutex/debounce |
| 27 | **Raw JSON in logs** | `ai_service.dart:389` | Privacy - sensitive data in Crashlytics. Truncate/redact |
| 28 | **Truncation retry infinite loop** | `ai_service.dart:378-385` | Doesn't increase maxTokens. Add attempt limit |
| 29 | **Generic catch blocks (22 files)** | Throughout `/lib` | Loses exception type. Add specific catches |
| 30 | **Missing autoDispose** | `providers.dart:251-279` | Memory leak on navigation. Add `.autoDispose` |
| 31 | **Watch/read misuse** | `settings_screen.dart:425-430` | Unnecessary rebuilds. Use `read` for one-off |
| 32 | **Incorrect invalidation** | `generate_screen.dart:320-321` | Invalidates derived, not source provider |
| 33 | **Weak ProGuard rules** | `proguard-rules.pro` | Easy reverse engineering. Strengthen obfuscation |
| 34 | **Log parameter disclosure** | `log_service.dart:154-156` | User data in Crashlytics. Add PII filter |
| 35 | **Device fingerprint in logs** | `rate_limit_service.dart:72-79` | Identifier exposure. Redact |
| 36 | **String-based error detection** | `auth_errors.dart:46-53` | Fragile to SDK changes. Use error codes |
| 37 | **Error auto-dismiss race** | `generate_screen.dart:36-42` | Provider access after unmount. Check mounted |
| 38 | **No provider pre-init** | `main.dart` | Call `authService.initializeProviders()` for faster first sign-in |

### LOW - Post-Launch Polish

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| 39 | **No StoreKit2 config** | `subscription_service.dart` | Add `usesStoreKit2IfAvailable: true` for modern iOS |
| 40 | **No deferred purchase handling** | `subscription_service.dart` | Handle iOS parental controls |
| 41 | **StateNotifier legacy API** | `providers.dart` | Migrate to Notifier/AsyncNotifier (Riverpod 3.x modern) |
| 42 | **Form state in 6 providers** | `providers.dart:251-279` | Consolidate to single NotifierProvider<FormState> |
| 43 | **No environment config class** | Various | Create AppConfig with all dart-defines |
| 44 | **No offline detection** | AI service | Check connectivity before generation |
| 45 | **Re-auth creates new session** | `reauth_service.dart:151-163` | May disrupt sensitive ops. Preserve session |
| 46 | **Device fingerprint spoofable** | `device_fingerprint_service.dart:61-86` | Rooted devices can impersonate. Accept as limitation |
| 47 | **AI model not singleton** | `ai_service.dart:101-314` | Multiple instances possible. Enforce singleton |

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
