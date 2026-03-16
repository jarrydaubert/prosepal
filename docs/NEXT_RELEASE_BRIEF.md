# Prosepal Next Release Spec (Single Shareable Source)

Owner: Product + Engineering

This document is intentionally self-contained. It is the single source to review what is currently built, what is actually stable, and what we should target for the next release.

---

## 1) Executive Summary

Prosepal is a production Flutter mobile app for generating card messages with AI.

Current reality:
- The app is live on iOS and has a substantial working feature set.
- Core architecture and integrations (Supabase, RevenueCat, Firebase AI, Analytics/Crashlytics, Remote Config) are in place.
- `1.1.2` is the live App Store baseline for the next release cycle.
- Unit/widget testing is strong; integration testing exists but still needs hardening for deterministic reliability.
- vNext UI baseline is a tokenized coral/navy/white theme direction (no ad-hoc per-screen color systems).
- The current product design is the intended baseline for vNext, with only targeted quality and parity hardening.

Recommendation for next release:
- Treat live `1.1.2` as the production baseline and do not reopen already-completed config/setup work unless production evidence exposes a concrete defect.
- Use `1.1.3` to tighten operational control around startup, Google/Firebase AI, production monitoring, and support/feedback delivery.
- Keep the current UX as baseline; do not expand `1.1.3` into a broad redesign cycle.
- Allow exactly one scoped user-facing addition in `1.1.3`: direct in-app feedback delivery.
- Avoid major architecture rewrites until the current startup/auth/payment systems are better instrumented and easier to reason about.

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
1. Keep live `1.1.2` stable unless production evidence finds a blocker.
2. Treat the current provider/config audit as complete enough to stop re-checking the same surfaces manually without a concrete trigger.
3. Use `1.1.3` for operational hardening, not a broad feature or visual expansion, with one intentionally scoped exception: direct in-app feedback delivery.
4. Keep the app technically legible as an AI system, not just an app that happens to call Gemini.
5. Avoid large architectural rewrites until the current startup/auth/payments boundaries have stronger telemetry and clearer test oracles.

This lowers release risk while turning the just-completed config work into durable operating discipline.

---

## 12) Live `1.1.2` Baseline

`1.1.2` is now the live production baseline that `1.1.3` should inherit.

### Baseline established by `1.1.2`
- Firebase AI App Check is enforced on the live AI path.
- Production Remote Config now publishes the expected AI/runtime control keys.
- Supabase auth, SMTP, and provider configuration have been re-verified.
- Resend delivery settings and admin access are in place for the current auth-mail path.
- RevenueCat app configuration, webhook wiring, and collaborator/admin setup have been re-verified.

### Do not carry forward as `1.1.3` work unless a real defect appears
- repeating provider-by-provider console audits with no new trigger
- reopening already-verified Firebase/Supabase/Resend/RevenueCat baseline setup
- broad release-readiness chores already completed for `1.1.2`

---

## 13) Locked `1.1.3` Scope

Only the items below define the intended `1.1.3` release. Each item closes only when its backlog DoD is met exactly in [BACKLOG.md](./BACKLOG.md).

### App/runtime must-ship
- `P1-54` pre-Flutter startup timeout hardening
  - exit criteria: pre-`runApp()` startup work reaches a bounded timeout/failure outcome with deterministic regression coverage and startup telemetry that distinguishes pre-Flutter timeouts
- `P1-55` Apple token exchange recovery for delete compliance
  - exit criteria: Apple token exchange no longer silently degrades later account deletion; retry/remediation path, user-facing failure handling, and evidence all exist
- `P1-43` Firebase AI client-block regression hardening
  - exit criteria: wired iOS + Android evidence proves AI generation works on the live path and triage cleanly distinguishes client-block misconfig from content/safety failures
- `P1-53` Direct in-app feedback delivery
  - exit criteria: the app ships a native in-app feedback widget backed by the authenticated Supabase + Resend path, with success/failure handling, fallback behavior, operator docs, and real delivery evidence
- `P1-56` AI error log sanitization
  - exit criteria: production AI telemetry preserves actionable error buckets while redacting provider-internal details from Crashlytics
- `P1-57` Pending usage sync ownership hardening
  - exit criteria: queued usage data has explicit, documented ownership semantics across anonymous usage, sign-out, delete-account, and user switching, with regression coverage

### Release-ops gates for the same cut
- `P0-01` Google/business-account finalization
  - exit criteria: production Google/Firebase ownership gaps are either removed or explicitly documented as the only remaining intentional exceptions
- `VNEXT-10` AI cost/abuse controls
  - exit criteria: AI operator policy is documented and evidenced for allowlist, kill switches, budget controls, rollback, and runtime-disable drills
- `P0-05` Billing budget alert controls
  - exit criteria: active spend alerts are configured, owned, documented, and test-evidenced
- `P1-20` Post-release production pulse checks
  - exit criteria: a concrete 0-60 minute production check protocol exists with named dashboards, thresholds, and evidence that it can actually be run end to end

### Allowed polish if directly tied to a named bug
- a narrow slice of `P0-08a` readability/contrast fixes
- a narrow slice of `P0-08b` navigation/input fixes

### Explicitly defer unless already nearly complete
- `P1-24` deterministic integration journey assertions
- `P1-41` network-independent smoke deterministic mode
- `P0-08c` launch and platform polish
- `P2-16` public QA showcase packaging
- `P2-18` AI technical-depth showcase

### Explicitly out-of-scope for `1.1.3`
- broad visual redesign or theme replacement
- large auth/startup/payment rewrites
- expanding test count without a named failure mode
- RevenueCat web billing/domain work; current app is native-store only
- server-side AI gateway as the new production default

---

## 14) Go/No-Go Gates For `1.1.3`

`1.1.3` is complete only if all are true:
- Analyzer passes.
- Unit/widget tests pass in CI and locally.
- Critical smoke passes locally and in CI.
- Every locked `1.1.3` item above is either closed with its backlog DoD or explicitly removed from the release cut in this document before ship.
- AI-critical flows still show correct behavior on real devices:
  - App Check active
  - generation succeeds when it should
  - failure classes remain distinguishable when it should not
- Post-release checks are documented tightly enough that an operator can run them without guesswork.
- Production cost/budget alerting is configured for the active AI path and evidenced.
- Public docs remain honest about the actual harnesses and evidence available; no portfolio wording outruns the repo reality.

---

## 15) Working Decisions For `1.1.3`

- Keep the current design as the product baseline.
- Prefer infra/ops hardening over new visible features.
- Use staged dependency movement only when a concrete `1.1.3` item requires it.
- Keep support diagnostics aligned with the canonical identity mapping doc and treat mismatches as release-blocking when touched.
- Treat iOS build-script enforcement as a hard gate; do not reintroduce a direct Xcode-only archive path.
- Preserve the App Store compliance guardrails already established:
  - no sign-in requirement before purchase
  - account deletion remains discoverable and functional in-app
  - metadata must not make unsupported pricing claims

---

## 16) Finalization

- Use this document as the planning source for `1.1.3`, not as a status log for ad-hoc work.
- Record release ownership and final sign-off in the release record, not here.
- Move any newly discovered unresolved work to `docs/BACKLOG.md` rather than adding TODOs to this brief.
