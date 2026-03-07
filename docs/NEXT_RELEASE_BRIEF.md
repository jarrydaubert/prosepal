# Prosepal Next Release Spec (Single Shareable Source)

Owner: Product + Engineering

This document is intentionally self-contained. It is the single source to review what is currently built, what is actually stable, and what we should target for the next release.

---

## 1) Executive Summary

Prosepal is a production Flutter mobile app for generating card messages with AI.

Current reality:
- The app is live on iOS and has a substantial working feature set.
- Core architecture and integrations (Supabase, RevenueCat, Firebase AI, Analytics/Crashlytics, Remote Config) are in place.
- Unit/widget testing is strong; integration testing exists but still needs hardening for deterministic reliability.
- vNext UI baseline is a tokenized coral/navy/white theme direction (no ad-hoc per-screen color systems).
- The current product design is the intended baseline for vNext, with only targeted quality and parity hardening.

Recommendation for next release:
- Treat `1.1.2` submission as the completed release-readiness cycle and stop spending backlog attention on already-finished gates.
- Focus next on visible product polish, higher-signal journey tests, and AI reliability/technical depth.
- Keep the current UX as baseline, but raise its consistency and contrast quality.
- Avoid major UX or architecture rewrites until the current startup/auth/payment systems are better instrumented and easier to reason about.

---

## 2) What Is Built Today (Product Scope)

### Core generation experience
- 40 occasions.
- 14 relationship types.
- 9 tones.
- 3 output lengths.
- 3 generated message options per request.
- Optional recipient name + additional details.
- Regenerate and copy actions.

### Account and identity
- Anonymous usage supported for first use.
- Apple Sign-In.
- Google Sign-In.
- Account deletion flow exists.

### Monetization
- Free tier: 1 lifetime generation.
- Pro tier: 500 generations/month.
- RevenueCat integration includes:
  - offerings retrieval
  - purchase
  - restore
  - customer center
  - entitlement checks
- Paywall shown in modal bottom sheet flow.

### Data/user features
- History of generated messages.
- Settings (spelling preference, biometrics, analytics toggle, legal/support links, etc.).
- Settings support flow includes optional diagnostic report sharing (user-controlled toggle).
- Support flow provides two user-controlled levels:
  - standard diagnostics (privacy-redacted)
  - advanced full technical diagnostics (explicit opt-in warning; passwords/tokens still redacted)
- Biometric lock option.
- Calendar/reminder related screens present.

### Platform scope
- Flutter iOS + Android app.
- Web marketing site is separate scope/codebase.

---

## 3) Current User Flows (As Implemented)

### App startup and routing
1. App boots with splash.
2. Startup waits for critical init status (Supabase; RevenueCat may timeout gracefully).
3. Device usage state sync runs before routing.
4. Route decision:
   - onboarding incomplete -> onboarding
   - biometric lock enabled+available -> lock screen
   - anonymous user with restored Pro detected -> auth restore route
   - otherwise -> home

### New free user flow
1. User lands on home.
2. Chooses occasion -> relationship -> tone/details in wizard flow.
3. Generates messages.
4. Copy/share/regenerate available.
5. After free quota is exhausted, paywall is shown.

### Purchase flow
- Purchase can happen without mandatory sign-in (anonymous purchase supported).
- Paywall includes package selection and purchase/restore paths.
- 24h cooldown after explicit dismiss (except forced contexts like explicit upgrade).

### Auth flow and post-auth behavior
- Auth screen logs auth-started events and supports Apple/Google paths.
- Post-auth navigation behavior varies by context:
  - plain login -> home
  - paywall redirect context -> returns to home + paywall behavior
  - restore context -> restore logic and entitlement reconciliation

### Restore/sync behavior
- RevenueCat user identify is executed after auth for account linking.
- Usage sync from server occurs post-auth.
- Restore can activate Pro on returning users.

---

## 4) Auth Integration Details

### Providers and backend
- Supabase is authoritative auth backend.
- Apple and Google use native provider SDKs, then federate to Supabase via ID token sign-in.

### Apple-specific implementation
- Nonce-based flow is implemented:
  - raw nonce generated
  - SHA-256 hash sent to Apple
  - raw nonce sent to Supabase for token validation
- Apple authorization code exchange edge-function path exists to support account-deletion compliance flow.

### Google-specific implementation
- Native Google SDK integration present.
- Lightweight auth attempt first, then interactive auth.
- Supabase sign-in with ID token (and access token when present).

### Auth policy
- New sign-in is social-only (Apple/Google).
- Supabase remains authoritative auth backend.
- Email auth routes are removed from app navigation.

### Account deletion
- Calls Supabase edge function for user deletion path.
- Handles sign-out/cleanup behavior.

---

## 5) Payments/Entitlements Integration Details

### RevenueCat architecture
- `SubscriptionService` wraps RevenueCat SDK.
- Platform-specific API key selection via build config.
- Test Store safeguards exist (blocked for release mode).

### Entitlement model
- Entitlement ID: `pro`.
- Pro access checks are based on active entitlements from RevenueCat customer info.

### Purchase path
- Offerings loaded from RevenueCat.
- Package purchase performed via native store flow.
- Paywall result and purchase outcome are logged.

### Restore and account linking
- `restorePurchases` implemented.
- `identifyUser` executed post-auth to align purchases with signed-in user.
- Customer info invalidation/refetch paths exist.
- RevenueCat anonymous identity now uses a persisted app-specific anonymous ID (instead of random SDK logout IDs) to reduce synthetic "new users" inflation in dashboard metrics.

### Restore behavior policy
- Anonymous purchase remains allowed.
- Canonical identity:
  - authenticated: Supabase user ID
  - signed-out: persisted app-specific anonymous ID
- On auth, RevenueCat identity is switched via `logIn(userId)` to reconcile entitlements.
- RevenueCat project restore behavior target: `Transfer to new App User ID`.
- Expected outcomes are documented for:
  - anonymous purchase -> login
  - user switch on same device
  - reinstall + restore
- Premium-critical surfaces refresh customer info before showing entitlement-dependent actions.
- Sources of truth:
  - `docs/REVENUECAT_POLICY.md`
  - `docs/IDENTITY_MAPPING.md`

### Paywall controls
- Paywall shown as bottom sheet, not route page.
- Dismiss analytics captured.
- Dismiss cooldown persisted in preferences.

---

## 6) AI (Gemini) Setup Details

### Provider and model
- AI generation uses Firebase AI SDK (Gemini).
- Runtime backend default is Vertex (`AI_BACKEND=vertex`), with optional override to Google Developer API path (`AI_BACKEND=google`) for controlled debugging.
- Remote-configured primary and fallback model names are supported.
- Current app defaults:
  - primary: `gemini-2.5-flash`
  - fallback: `gemini-2.5-flash-lite`
- vNext production target:
  - production default remains pinned by explicit stable model ID (no alias)
  - preview models only for controlled/internal experiments
  - fallback remains a pinned stable model

### Runtime model control
- Firebase Remote Config keys support changing model without app release:
  - `ai_model`
  - `ai_model_fallback`
- vNext guardrails required:
  - pinned model IDs only (never `latest` aliases)
  - allowlist validation for model IDs
  - `config_schema_version` key
  - kill switches for `ai_enabled`, `paywall_enabled`, and `premium_enabled`
  - no secrets in Remote Config
  - Remote Config defaults/template versioned in repo (`docs/REMOTE_CONFIG_TEMPLATE.json`)

### Generation behavior
- Structured JSON schema expected from model response.
- System instruction is centralized and tuned for 3 card-message outputs.
- Safety settings configured for harassment/hate/sexual/dangerous content thresholds.
- Timeout + retry logic exists with typed error classification.
- Fallback model switching is implemented for primary model failures.

### Error handling
- Distinct error classes and user-facing messages for:
  - network/timeouts
  - rate limiting
  - content blocked
  - model unavailable
  - empty/parse/truncation cases

---

## 7) Data, Limits, and Backend Enforcement

### Usage policy (implemented)
- Free limit: 1 lifetime generation.
- Pro limit: 500/month.

### Enforcement model
- Local cache for responsiveness.
- Server-side checks for authoritative enforcement on authenticated users.
- Device fingerprint path exists to reduce free-tier abuse across reinstalls/account switching.

### Supabase usage paths
- RPC usage check/increment flow is used for server-side enforcement.
- Device free-tier RPC check path is used for anonymous/device gating.

### Known caveat
- Device fingerprint strategy is deterrence, not absolute anti-fraud.
- Device identity approach must remain platform-policy compliant; vNext requires an explicit decision and documentation for iOS/Android abuse controls.

---

## 8) Configuration and Build Setup

### Build-time env model
- Key configuration is via `--dart-define` (centralized in app config).
- Required categories:
  - Supabase URL/key
  - RevenueCat platform keys
  - Google auth client IDs

### iOS release guardrail
- iOS release builds must use project build script so dart-defines are correctly baked.
- Direct plain `flutter build ios` / Xcode-only archive paths can omit required runtime config.

### Historical release learnings (must preserve)
- A previous iOS release was shipped without required dart-defines, causing a grey-screen startup failure and App Store rollback.
- App Store review previously rejected the app for requiring sign-in before purchase and for metadata disclosure gaps.
- Current paywall and release process were explicitly adjusted to address those issues:
  - purchase without mandatory sign-in
  - optional auth for cross-device sync
  - strict scripted iOS release build path
  - explicit subscription/terms metadata hygiene
- These are non-negotiable constraints for vNext and all future release candidates.

### Firebase app wiring
- FlutterFire config present for Android/iOS.
- Firebase options generated and app IDs configured.

---

## 9) Test Setup

### Test pyramid
- Unit tests: service/model/logic coverage.
- Widget tests: screen behavior and rendering.
- Integration tests: smoke + journey + coverage suites under `integration_test/`.
- Patrol should be adopted selectively for true native/system UI interactions, not as a blanket replacement for the existing integration harness.

### Local commands used
- `flutter analyze`
- `flutter test`
- `flutter test integration_test/<file>.dart -d <device-id>`
- `./scripts/test_flake_audit.sh`

### CI currently wired
- CI workflow runs:
  - pub get
  - analyzer
  - unit/widget tests with coverage artifact
- Separate flaky-audit workflow runs periodic randomized/serial test stress script.

### Firebase Test Lab setup
- Android instrumentation scaffold is present in project.
- Dedicated FTL-oriented integration entrypoints exist.
- Release validation requires executing the FTL critical suite and attaching evidence in release artifacts.

---

## 10) Quality and Risk Model

### Gate policy
- Analyzer, unit/widget tests, and critical smoke are blocking gates.
- Flaky tests are quarantined and tracked in backlog before release gating.
- Release preflight is enforced via `scripts/release_preflight.sh` and `scripts/test_release_preflight.sh`.
- AI cost/abuse controls are validated through `docs/DEVOPS.md` and `./scripts/audit_ai_cost_controls.sh`.
- Identity mapping is validated through `docs/IDENTITY_MAPPING.md` and diagnostics output.

### Backlog policy
- Any open risk, gap, or unresolved validation item must live in `docs/BACKLOG.md`.
- This document defines target architecture and release gates, not progress/status tracking.

---

## 11) Product Direction

### Recommended sequencing
1. Keep the submitted `1.1.2` release stable unless Apple review finds a blocker.
2. Use the next cycle to improve visible product polish and test credibility at the same time.
3. Prefer fewer, sharper journey tests over broader click-through coverage.
4. Keep the app technically legible as an AI system, not just an app that happens to call Gemini.
5. Avoid large architectural rewrites until the current startup/auth/payments boundaries have stronger telemetry and clearer test oracles.

This lowers release risk and preserves the current design baseline while hardening release confidence.

---

## 12) Proposed Next Release Scope (post-`1.1.2` submission)

### Must-ship for the next cycle
- Visible UI polish and consistency (`P0-08`) so the app looks intentionally designed rather than merely functional.
- Journey test quality hardening (`P1-24`) so green integration results are actually trustworthy.
- AI reliability hardening (`P1-43`, `VNEXT-10`) so the Gemini/Firebase AI path remains defensible on real devices and in public portfolio review.
- Smoke determinism under weaker network conditions (`P1-41`) so the blocking story stays credible.
- RevenueCat transfer metadata hydration (`P2-17`) so backend entitlement rows are complete, not merely permissive.

### Strongly recommended for the same cycle
- Public QA showcase packaging (`P2-16`) once the above quality work is in place.
- AI technical-depth showcase (`P2-18`) so the repo demonstrates LLM engineering judgment, not just API usage.
- Startup telemetry tightening (`P1-48`) if the next cycle still touches startup/auth/payment boundaries.

### Explicitly out-of-scope for the next cycle
- Another rushed release-readiness push unless Apple review forces a hotfix.
- Test-count inflation or broad new E2E suites without strong bug targets.
- Large visual theme replacement disconnected from the current design baseline.
- Server-side AI gateway as production default (`P1-47`) unless clear trigger criteria are met.
- Startup orchestration/state-machine rewrite (`P2-13`) before the current system is better instrumented.

---

## 13) Go/No-Go Gates For The Next Engineering Cycle

The next cycle is complete only if all are true:
- Analyzer passes.
- Unit/widget tests pass in CI and locally.
- Critical smoke passes locally and in CI.
- The journey suite keeps only tests with a named bug target and explicit oracle; low-signal tests are removed or rewritten.
- Wired iOS smoke, Patrol pilot, and Firebase Test Lab critical Android suite still pass after any changes to startup/auth/payments/UI.
- Core screens touched by the cycle are visually sane on physical iOS and Android devices with attached before/after evidence where applicable.
- AI-critical flows still show correct behavior on real devices:
  - App Check active
  - generation succeeds when it should
  - failure classes remain distinguishable when it should not
- RevenueCat/Supabase entitlement state remains aligned after purchase, restore, sign-in, sign-out, and delete/recreate edge paths.
- Public docs remain honest about the actual harnesses and evidence available; no portfolio wording outruns the repo reality.

---

## 14) Feedback Questions (For Sign-Off)

Please comment directly on these points:

1. Do we align on infra-first for the immediate next release?
2. Are any user-facing features mandatory for this release beyond reliability?
3. Which exact integration tests should become hard release gates?
4. What dependency upgrade risk tolerance do we want (aggressive vs staged)?
5. Do we confirm the current design remains the product baseline for vNext?
6. For vNext visuals, do we require strict live-style parity on core screens (yes/no)?

### Draft sign-off responses (recommended)
1. Yes, align on infra-first for immediate release.
2. No mandatory new user-facing features for vNext beyond reliability and safety hardening.
3. Hard release gates should include:
   - auth: Apple and Google sign-in success/cancellation/error paths
   - generation: free-limit path, Pro path, error/retry path
   - monetization: paywall display, purchase, restore, entitlement reconciliation
   - settings: restore, delete-account orchestration, legal/support links
4. Dependency strategy should be staged:
   - batch A: low-risk toolchain/minor updates
   - batch B: Riverpod/annotation ecosystem
   - batch C: purchase/auth/device-regression pass after dependency movement
   - each batch must pass analyzer/tests/integration smoke before merge
5. Yes, keep the current design as the product baseline for vNext.
6. Yes, enforce live-style parity for vNext core screens unless a delta is explicitly approved.

### Additional recommendations from audit
- Treat iOS build-script enforcement as a hard gate (no direct Xcode-only archive path).
- Preserve App Store compliance guardrails that fixed prior rejection:
  - no sign-in requirement before purchase
  - account deletion remains discoverable and functional in-app
  - paid features and terms disclosures remain explicit
- Integration flake policy:
  - fix deterministic failures where possible
  - quarantine unstable tests from hard gate until repaired
  - keep a trusted critical-smoke suite as the blocking release gate
- Keep support diagnostics aligned with the canonical identity mapping doc and treat mismatches as release-blocking.

---

## 15) Finalization

- Freeze this document for the release candidate once sign-off is complete.
- Record sign-off ownership and release version in the release record, not in this spec.
- Move any unresolved item to `docs/BACKLOG.md` before release tagging.
