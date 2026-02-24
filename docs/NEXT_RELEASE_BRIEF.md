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
- The major redesign is planned but not sufficiently implemented to be the safest next release target.

Recommendation for next release:
- Prioritize an infrastructure/reliability release first.
- Keep current UX as baseline.
- Treat redesign as a controlled follow-up behind feature flag + rollout gates.

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
- Email auth:
  - password mode
  - magic-link mode
  - password reset flow
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
- Auth screen logs auth-started events and supports Apple/Google/email paths.
- Post-auth navigation behavior varies by context:
  - plain login -> home
  - paywall redirect context -> returns to home + paywall behavior
  - restore context -> restore logic and entitlement reconciliation
- Email auth supports:
  - password login/signup
  - magic link
  - optional auto-purchase behavior for specific paywall flows

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

### Email-specific implementation
- Password sign-in/sign-up supported.
- Magic-link sign-in supported.
- Password reset deep-link flow supported.
- Throttling service used for repeated password attempt protection.

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
- Remote-configured primary and fallback model names are supported.
- Current app defaults:
  - primary: `gemini-2.5-flash`
  - fallback: `gemini-2.5-flash-lite`
- vNext production target:
  - production default should be a pinned stable (non-preview) model ID
  - preview models only behind explicit internal/controlled flag
  - fallback remains a pinned stable model

### Runtime model control
- Firebase Remote Config keys support changing model without app release:
  - `ai_model`
  - `ai_model_fallback`
- vNext guardrails required:
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
- AI cost/abuse controls are validated through `docs/AI_COST_ABUSE_RUNBOOK.md` and `./scripts/audit_ai_cost_controls.sh`.
- Identity mapping is validated through `docs/IDENTITY_MAPPING.md` and diagnostics output.

### Backlog policy
- Any open risk, gap, or unresolved validation item must live in `docs/BACKLOG.md`.
- This document defines target architecture and release gates, not progress/status tracking.

---

## 11) Redesign Status and Product Direction

### Current redesign state
- Redesign plan exists and is detailed.
- Implementation is still partial with major phases not complete.
- It is not yet the safest primary target for immediate release.

### Recommended sequencing
1. Ship infrastructure/reliability release first.
2. Freeze major UX changes for that release.
3. Align core screen styling to current live baseline (or explicitly approve intentional deltas).
4. Finalize deterministic integration + device/FTL confidence.
5. Then start redesign rollout behind feature flags and staged metrics gates.

This lowers release risk and gives a trusted baseline for measuring redesign impact.

---

## 12) Proposed Next Release Scope (vNext)

### Must-ship
- Dependency upgrades in controlled batches with regression checks.
- Integration harness stabilization (remove nondeterministic waits/taps, stable assertions).
- Physical-device validation path (wired iOS + wired Android).
- Firebase Test Lab runbook execution and verified pass.
- CI gating policy updated to reflect trusted signals.
- Any high-risk auth/purchase edge-case gaps required for safe release.
- App Check operational hardening:
  - AI path protection posture confirmed for production (not just monitoring intent)
  - iOS and Android provider behavior re-validated
  - Flutter AI SDK App Check integration path verified
  - limited-use token strategy validated (or explicitly deferred with rationale)
- AI model lifecycle hardening:
  - production default model moved to pinned stable non-preview
  - fallback model confirmed active/supported
  - RC allowlist validation live and tested
- Remote Config guardrails shipped as hard requirements:
  - `config_schema_version` live
  - `ai_enabled`, `paywall_enabled`, `premium_enabled` kill switches live
  - RC defaults/template committed and reviewed
  - explicit "no secrets in RC" rule added to release process
- RevenueCat policy finalization:
  - restore behavior policy documented (dashboard setting + expected outcomes)
  - entitlement refresh points documented for premium-critical UX
- Account deletion UX/compliance hardening:
  - active-subscription guidance copy verified
  - "Manage Subscription" path available near deletion flow
  - deletion timing/expectation copy documented and tested
- Build/release guardrail hardening:
  - required `dart-define` preflight check in CI/release script
  - script-only iOS archive enforcement remains hard gate
  - `--dart-define-from-file` migration path documented (adopt now or explicitly defer)
- AI cost/abuse controls explicitly operationalized:
  - API restrictions + app restrictions verified
  - per-user rate limit thresholds documented
  - budget alerts + cost spike response trigger in runbook
- Device abuse-control compliance hardening:
  - decide and document platform approach (current fingerprinting vs migration to native attestation APIs)
  - verify iOS/Android implementation is policy-compliant before release
- UI parity baseline for vNext:
  - core screens visually aligned to live baseline where redesign is out-of-scope
  - any intentional style deltas documented before release

### Explicitly out-of-scope for vNext
- Full redesign rollout.
- Large visual theme replacement.
- New major UX architecture (chat-first) in production.

---

## 13) Go/No-Go Gates For vNext

Release is eligible only if all are true:
- Analyzer passes.
- Unit/widget tests pass in CI and locally.
- Flake audit passes repeated runs.
- Integration smoke passes on iOS simulator and Android emulator.
- Critical integration suite passes on one wired iOS and one wired Android physical device.
- FTL Android run passes for selected critical suite.
- iOS release build process validated via required build script.
- No critical auth/payment/security regressions.
- App Check production posture and provider validation are confirmed for AI-critical paths.
- Production AI model default is stable non-preview; fallback + allowlist validation confirmed.
- Remote Config safety controls (`config_schema_version`, kill switches, no-secrets policy) are active.
- RevenueCat restore behavior policy is documented and validated in test flows.
- Account deletion flow includes subscription handling guidance and management path.
- Release preflight blocks missing required runtime configuration.
- Device abuse-control approach is documented and approved for platform-policy compliance.
- Core screen styling is verified against live baseline (or documented intentional deltas approved).

---

## 14) Feedback Questions (For Sign-Off)

Please comment directly on these points:

1. Do we align on infra-first for the immediate next release?
2. Are any user-facing features mandatory for this release beyond reliability?
3. Which exact integration tests should become hard release gates?
4. What dependency upgrade risk tolerance do we want (aggressive vs staged)?
5. Do we approve redesign as a post-vNext flagged rollout rather than primary target?
6. For vNext visuals, do we require strict live-style parity on core screens (yes/no)?

### Draft sign-off responses (recommended)
1. Yes, align on infra-first for immediate release.
2. No mandatory new user-facing features for vNext beyond reliability and safety hardening.
3. Hard release gates should include:
   - auth: Apple, Google, email/password, magic-link, password reset
   - generation: free-limit path, Pro path, error/retry path
   - monetization: paywall display, purchase, restore, entitlement reconciliation
   - settings: restore, delete-account orchestration, legal/support links
4. Dependency strategy should be staged:
   - batch A: low-risk toolchain/minor updates
   - batch B: Riverpod/annotation ecosystem
   - batch C: RevenueCat SDK pins and purchase-flow regression pass
   - each batch must pass analyzer/tests/integration smoke before merge
5. Yes, redesign should be post-vNext behind feature flags and staged rollout metrics.
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
