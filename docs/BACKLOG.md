# Backlog

Only open TODO items live here.

Rules:
- No status updates, progress notes, or completed work.
- Every item must include a clear, testable Definition of Done (DoD).
- If an item changes runtime behavior, its DoD must define regression
  protection: automated coverage at the right layer or an explicit replacement
  evidence path with a named bug target and oracle.
- When an item is complete, remove it from this file.

## Backlog Mantra

- Open TODO items only.
- Clear, testable DoD only.
- Behavior changes must say how they stay fixed:
  - automated coverage at the right layer, or
  - explicit replacement evidence path with a named bug target and oracle.

## Global DoD Contract (Applies To Every Item)

A backlog item is only considered complete when all conditions below are true:

1. `Outcome delivered`: The row's feature/fix/docs scope is implemented exactly as written.
2. `Regression protection defined`: If the item changes behavior, completion adds or updates automated coverage at the right layer, or explicitly justifies why automation is the wrong layer. That justification must name the target bug, the pass/fail oracle, and the replacement evidence path.
3. `Deterministic validation passed`: Relevant validation commands pass with no manual interpretation required.
4. `Evidence attached`: PR/release evidence includes concrete proof (logs, screenshots, CI run IDs, or artifact links) for the completed outcome.
5. `Backlog hygiene`: The completed item is removed from this file in the same change set that provides outcome + validation + evidence.

If any condition is missing, the item remains open.

## Release Priority Order (`v1.1.3` active cycle)

Process items in this order unless an explicit owner override is recorded in release planning.

1. `P0-01` Move Google setup to business account
2. `VNEXT-10` AI cost/abuse controls
3. `P1-43` Firebase AI client-block regression hardening
4. `P1-54` Pre-Flutter startup timeout hardening
5. `P1-55` Apple token exchange recovery for delete compliance
6. `P0-05` Billing budget alert controls
7. `P1-20` Post-release production pulse checks
8. `P1-53` Direct in-app feedback delivery
9. `P1-56` AI error log sanitization
10. `P1-57` Pending usage sync ownership hardening
11. `P0-08a` Core readability and contrast hardening
12. `P0-08b` Navigation and input polish
13. `P1-24` Deterministic integration journey assertions
14. `P1-41` Network-independent smoke deterministic mode
15. `P0-08c` Launch and platform polish
16. `P2-17` RevenueCat transfer metadata hydration
17. `P2-16` Public QA showcase packaging
18. `P2-18` AI technical-depth showcase
19. `P1-48` Startup phase telemetry and budget visibility
20. `P1-52` Biometric lifecycle debounce + single-flight guard
21. `VNEXT-11` Canonical identity mapping
22. `VNEXT-13` Device abuse-control compliance decision
23. `VNEXT-12` UI parity with live baseline
24. `P0-04` Auth loading spinner after OAuth sheet
25. `P1-47` Server-side AI gateway rollout (post-launch trigger)
26. `P2-13` Startup orchestration refactor (post-launch)

## P0 - Launch Blockers

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P0-08a` | Core readability and contrast hardening | Core screens and subflows in scope (`auth`, `lock`, `settings`, feedback, `history`, `calendar`, and any surfaced support/legal subflow touched by recent polish work) use shared semantic tokens only and have no readable dark-on-dark or light-on-light text regressions. DoD requires: updated widget/golden coverage where structure is stable, physical iOS + Android screenshots for each fixed surface, and an explicit WCAG AA manual verification note for primary text on the scoped screens. |
| `P0-08b` | Navigation and input polish | Back navigation controls use the canonical chevron treatment across scoped screens, text-entry surfaces have consistent icon alignment and capitalization hints, and returning from generate/results/auth flows to home does not leave the search keyboard open. Dialog/input surfaces (delete, reauth, feedback, calendar entry, generate details) remain keyboard-safe and visually stable. DoD requires: regression coverage for each fixed bug path, explicit verification of the results-screen chevron and Gemini attribution spacing, and physical iOS + Android evidence for the named keyboard/navigation flows. |
| `P0-08c` | Launch and platform polish | Launch surfaces look intentional on both platforms: iOS remains visually clean, Android launch treatment is explicitly designed for platform behavior rather than accidental fallback chrome, and any remaining platform differences are documented as deliberate. DoD requires: physical iOS + Android launch screenshots/video evidence, an explicit decision record for Android launch treatment, and no accidental icon/splash fallback behavior on the supported release devices. |
| `P0-05` | Billing budget alert controls | Production cost surfaces used by Prosepal have documented alert thresholds, owners, and notification channels. At minimum this includes the active Google/Firebase AI runtime path and any project-level budget used for Gemini/Firebase AI spending. DoD requires: the alert thresholds are recorded in `docs/DEVOPS.md`, notification destinations are verified from the business-managed admin path, and at least one dry-run or test alert path is evidenced so alert delivery is not assumed. |
| `P0-04` | Auth loading spinner after OAuth sheet | After Apple/Google auth sheet closes, UI shows deterministic loading state until auth completion resolves or fails with user-visible error, and users cannot accidentally dismiss or double-submit the auth surface while completion is still in flight. DoD requires: widget coverage for success, failure, and cancellation paths; explicit verification that provider-specific loading copy/state appears after the native auth sheet returns control; and real-device evidence on the active social providers showing the post-sheet state is visible long enough to confirm the app is finalizing auth rather than appearing frozen. |
| `P0-01` | Move Google setup to business account | The live Google/Firebase project remains the existing production project (`prosepal-1a24b`) and stays fully operable from the business Workspace identity without requiring undiscovered personal-account-only access. DoD requires: the already-granted Workspace Firebase/Google Auth access remains validated, any remaining Google admin dependency on the personal account is explicitly documented or removed, the Play Console path is resolved as an intentional policy decision (verified organization-conversion path with evidence, or explicit acceptance of the personal-account testing path), and `docs/SERVICE_OWNERSHIP_MIGRATION.md` reflects only the unresolved Google ownership gaps. |
| `VNEXT-10` | AI cost/abuse controls | Firebase AI production posture is treated as an operational system, not just SDK wiring. DoD requires: App Check enforcement remains verified on the live AI path, Remote Config kill switches and pinned model defaults are reviewed against the active release config, the permitted production model IDs are documented as an allowlist, the operator policy explicitly states which model changes can ship via Remote Config versus which changes require a new app release, Google/Firebase budget alerts are configured and evidenced, at least one kill-switch drill or equivalent runtime-disable proof is captured, and `docs/DEVOPS.md` documents the final operator policy for AI runtime, rollback, and abuse/cost response. |
| `VNEXT-11` | Canonical identity mapping | Supabase ID, RevenueCat App User ID, Analytics ID, and Crashlytics ID mapping is validated across sign-in/sign-out transitions and documented in `docs/IDENTITY_MAPPING.md`. |
| `VNEXT-12` | UI parity with live baseline | Baseline screenshots exist for core screens and any styling delta is either matched to live or explicitly approved before release. |
| `VNEXT-13` | Device abuse-control compliance decision | iOS/Android abuse-control approach is approved, documented, and reflected in release checklist and runtime configuration. |

## P1 - Engineering Tasks

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P1-48` | Startup phase telemetry and budget visibility | Existing startup flow emits structured phase telemetry (`init`, `identity`, `entitlements`, `routing`) with per-phase duration, timeout/fallback reason, and final terminal route outcome. Logs are queryable in Crashlytics/analytics, phase budgets are documented in `docs/DEVOPS.md`, and fault-injection runs prove telemetry captures degraded startup paths deterministically. |
| `P1-43` | Firebase AI client-block regression hardening | Real-device AI generation succeeds on both wired iOS and wired Android using the current Firebase AI + App Check setup, and the evidence bundle captures the active model, backend, and App Check posture for each run. Failure classification must distinguish client/app-block configuration errors from true content-safety blocks, and `docs/DEVOPS.md` must include a deterministic triage checklist for `client application <empty> are blocked` style failures with a named oracle for "fixed" versus "still misconfigured". |
| `P1-54` | Pre-Flutter startup timeout hardening | Any initialization that occurs before `runApp()` reaches a bounded outcome instead of waiting indefinitely on remote services. DoD requires: Firebase init and any other pre-Flutter network-dependent startup work use explicit timeout/failure handling, the app deterministically reaches either the Flutter splash or init error surface within a documented launch budget under injected hung/degraded init conditions, startup telemetry distinguishes pre-Flutter timeout from post-splash startup timeout, and regression coverage exists for the timeout + graceful-degradation path without relying on ambient real-network failure. |
| `P1-55` | Apple token exchange recovery for delete compliance | Apple sign-in no longer silently leaves account deletion non-compliant when authorization-code exchange fails. DoD requires: the exchange path uses bounded retry during sign-in, a persistent remediation state or equivalent recovery path exists when all retries fail, delete-account flow either completes revocation successfully or blocks with explicit actionable guidance instead of failing silently, regression coverage exists for transient and persistent exchange-failure paths, and real-device/manual evidence proves the app does not end in a silent "delete will fail later" state. |
| `P1-56` | AI error log sanitization | Production AI error telemetry keeps actionable classification while redacting internal backend details from Crashlytics. DoD requires: release-mode logging strips or normalizes URLs, model identifiers, project/resource identifiers, and similar provider-internal strings before `Log.warning`/`Log.error` emit AI failure details, regression coverage exists for FirebaseAIException and general-exception logging paths, support diagnostics still preserve the named user-facing error bucket/oracle needed for triage, and `docs/DEVOPS.md` documents what AI runtime detail is allowed in production telemetry versus debug-only logs. |
| `P1-57` | Pending usage sync ownership hardening | Pending usage syncs have explicit ownership semantics across anonymous generation, sign-out, delete-account, and account switching. DoD requires: queued usage can never be attributed to a different authenticated user without an intentional documented rule, sign-out/delete flows either clear or quarantine prior-user pending syncs with a logged rationale, regression coverage exists for same-user resume, different-user sign-in, anonymous-to-authenticated transition, and stale-queue expiry, and `docs/IDENTITY_MAPPING.md` documents the final ownership policy for pending usage data. |
| `P1-47` | Server-side AI gateway rollout (post-launch trigger) | A documented trigger policy exists for enabling a server-side AI gateway (abuse threshold, model-policy requirement, or provider-failover need). A non-production spike path exists behind a disabled feature flag, with parity tests proving no user-visible regression when enabled in staging. Production default remains client-direct until trigger criteria are met and approved. |
| `P1-24` | Deterministic integration journey assertions | Journey tests in `integration_test/journeys/` stop using optional `if (exists(...))` branches for core checkpoints (auth entry, upgrade path, generation result, settings navigation) and fail explicitly when expected UI state is missing. Each retained journey test must justify its existence by targeting a concrete bug/failure mode, and low-signal click-through coverage should be removed rather than padded. DoD includes a keep/rewrite/delete review across the checked-in journey suite, representative journey execution on a real mobile target without silent skips, and clear failure reasons tied to both the missing checkpoint and the named bug the test is meant to catch. |
| `P1-42` | Auth-screen layout flake elimination | The `AuthScreen shows error banner when Google sign-in fails` test no longer produces order-dependent `RenderFlex overflow` failures during randomized multi-file runs. Root cause is fixed (test harness isolation and/or responsive layout constraints), deterministic regression coverage is added, and `./scripts/test_flake_audit.sh` shows zero flakes for this case. |
| `P1-40` | Startup/router timeout guard under network faults | Splash/startup routing reaches an explicit terminal route (`/onboarding`, `/home`, `/auth`, `/lock`, or init error surface) within a bounded timeout even when Supabase/RevenueCat DNS fails. Returning-user entitlement routing is deterministic under delayed RevenueCat init (no false `/onboarding` fallback followed by corrective auth/restore reroute). Integration tests cover both network-fault and delayed-entitlement scenarios with deterministic pass/fail assertions. |
| `P1-52` | Biometric lifecycle debounce + single-flight guard | Biometric lock flow guarantees a single active prompt per foreground transition, ignores duplicate resume/inactive callbacks inside a bounded debounce window, and logs one stable lifecycle transition per lock attempt. Device tests on iOS confirm no rapid repeated `Biometric auth started` bursts during Face ID enable/disable and resume flows. |
| `P1-53` | Direct in-app feedback delivery | Settings feedback no longer depends on `mailto:` or an external mail app for the primary path. An authenticated backend path (for example a Supabase Edge Function) accepts feedback plus optional diagnostics, relays it through Resend to `jarryd@prosepal.app`, and returns clear success/failure states to the app. Manual copy/share fallback remains available when backend delivery fails. DoD requires: the client never exposes a Resend secret, `docs/DEVOPS.md` documents the delivery path plus operator checks, regression coverage exists for successful submit plus backend-failure fallback, and release evidence proves a production-configured feedback submission reaches the Workspace inbox without opening the device mail client. |
| `P1-41` | Network-independent smoke deterministic mode | `integration_test/smoke_test.dart` has a documented deterministic mode (or injected fakes) that removes dependency on live Supabase/RevenueCat reachability for core S1-S5 assertions. CI/device smoke remains stable when outbound network is unavailable or flaky, and the home/onboarding checkpoint does not depend on live backend timing to reach `What's the occasion?` or `Birthday`. |
| `P1-36` | Journey launch readiness hardening | `integration_test/journeys/_helpers.dart` `launchApp()` waits for a concrete ready surface (onboarding/auth/home) with bounded timeout and clear failure reasons. `j1_fresh_install_test.dart` no longer produces `did not complete` behavior during wired-device execution. |
| `P1-38` | E2E suite failure isolation | `integration_test/e2e_test.dart` execution is split or orchestrated so one early failure does not collapse the full suite into mass `did not complete` noise. Each shard outputs independent pass/fail and artifacts. |
| `P1-34` | Offline-safe integration font loading | Integration runs do not depend on live `fonts.gstatic.com` fetches. `google_fonts` runtime fetching is disabled in test mode (or fonts are bundled/preloaded), and `integration_test/smoke_test.dart` + `integration_test/e2e_test.dart` pass without DNS/network access. |
| `P1-37` | iOS CocoaPods lockfile consistency gate | `ios/Podfile.lock` stays aligned with plugin constraints on clean clone. Running `flutter test -d <ios-device> integration_test/*` does not require ad-hoc pod updates, and CI/dev docs include a reproducible pod consistency check. |
| `P1-27` | QA code documentation standards (Dartdoc/JSDoc) | Public QA-facing helpers and APIs have accurate documentation comments: Dartdoc on shared test helpers/mocks/services and JSDoc on JavaScript/TypeScript automation code in repo scope. Comments describe purpose, inputs/outputs, and failure modes; stale examples are removed; documentation quality is verified in CI (lint/check step) and reflected in `docs/DEVOPS.md`. |
| `P1-44` | Full documentation walkthrough with repo owner | A full walkthrough of repo docs is completed with the repo owner: `README.md`, `docs/DEVOPS.md`, `docs/NEXT_RELEASE_BRIEF.md`, `docs/LAUNCH_CHECKLIST.md`, `docs/IDENTITY_MAPPING.md`, and `docs/BACKLOG.md`. All command snippets are verified runnable, stale references are removed, cross-links are valid, and any follow-up gaps are captured as explicit backlog items. |
| `P1-29` | Test-doc reference accuracy cleanup | Test docs only reference existing test files and runnable commands. Remove stale path references from docs and align command examples with current workflow gates. |
| `P1-01` | Social-auth fallback UX | Social sign-in failures show deterministic user guidance, retry actions, and support path coverage in widget/integration tests. |
| `P1-04` | Paywall decomposition | Paywall widget is split into maintainable sections/components with unchanged behavior and passing tests. |
| `P1-05` | Paywall accessibility improvements | Paywall has complete semantics labels and screen-reader navigation validation passes on iOS and Android. |
| `P1-06` | Connectivity monitoring | App-level connection state monitoring is implemented with graceful degraded UX and tested offline/restore scenarios. |
| `P1-07` | Health monitoring runbook | Health monitoring and escalation process is documented in `docs/DEVOPS.md` with clear alert/response steps. |
| `P1-08` | Auth abuse controls for social flows | App Check and provider-side abuse controls are validated for Apple/Google auth flows with documented thresholds and escalation steps. |
| `P1-45` | Sensitive screen capture hardening (paywall/settings) | Android applies and releases `FLAG_SECURE` only while sensitive paywall/subscription views are visible, iOS hides sensitive content in app-switcher snapshots during resign-active transitions, and device validation evidence confirms screenshots/app-switcher previews no longer expose sensitive paywall/subscription content. |
| `P1-46` | iOS auth callback hardening to Universal Links | iOS auth callback flow is validated end-to-end with `https://prosepal.app/auth/...` Universal Links and a live `apple-app-site-association`; custom-scheme callback usage is removed from security-critical auth paths (or explicitly documented as temporary risk with owner sign-off and expiry date). |
| `P1-03` | Service configuration runbook | `docs/SERVICE_CONFIG.md` exists and includes reproducible Firebase/Supabase/RevenueCat configuration steps with pass criteria. |
| `P1-14` | Workflow step summaries | CI/release/governance workflows publish structured `GITHUB_STEP_SUMMARY` output for gates, artifacts, and key timing/cost signals. |
| `P1-15` | CI dependency caching optimization | CI caches for dependency/tooling paths are tuned and documented, with before/after runtime evidence showing no reliability regression. |
| `P1-16` | Deterministic artifact controls | CI/release jobs enforce lockfile integrity (`dart pub get --enforce-lockfile` or equivalent), build metadata is captured, and reproducibility checks are documented and runnable. |
| `P1-10` | Monthly governance audit automation | Scheduled/manual GitHub workflow validates ruleset drift and CI usage budget against defined thresholds, emits run-ID linked evidence artifacts, and includes month-over-month trend review fields. |
| `P1-12` | DevOps troubleshooting runbook section | `docs/DEVOPS.md` contains concise, command-level playbooks for GitHub/API outages, stale evidence recovery, token expiry/rotation, and release rollback. |
| `P1-13` | Scoped Dependabot auto-merge pilot | Auto-merge is enabled only for explicitly allowed low-risk dependency updates, requires existing mandatory checks, and includes documented disable/rollback criteria. |
| `P1-11` | Automated semantic release flow | Release automation from `main` merges creates SemVer tags and GitHub Release notes from commit history/PR metadata with dry-run and rollback procedure documented in `docs/DEVOPS.md`. |
| `P1-17` | Deployment safety guardrails verification | Deployment workflow validates target project/environment bindings before production path execution and documents tested rollback path. |
| `P1-18` | Build-once promote release flow | Release pipeline promotes a previously built, checks-passed artifact (instead of rebuilding at release time), with artifact provenance linked to the exact CI run and commit SHA. |
| `P1-19` | Protected production environments | GitHub environments (`staging`/`production`) gate production-key usage with required reviewers and environment-scoped secrets/variables documented in `docs/DEVOPS.md`. |
| `P1-20` | Post-release production pulse checks | `docs/DEVOPS.md` defines a 0-60 minute post-release check protocol with named owners, exact console/tooling surfaces, and explicit rollback trigger thresholds. At minimum the protocol must cover Crashlytics, Firebase AI/App Check health, Supabase auth + function health, RevenueCat webhook/entitlement sanity, and store-console release sanity. DoD requires: the protocol is runnable from the documented commands and dashboards, the pass/fail thresholds are concrete enough to avoid subjective interpretation, and at least one release or dry-run evidence bundle proves the checklist can actually be executed end to end. |
| `P1-21` | Release evidence bundle automation | Release workflow publishes an evidence bundle artifact (checks summary, coverage/service-gate outputs, wired/FTL evidence links, Supabase/AI audit outputs, and run-ID traceability). |

## P2 - Lower Priority

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P2-01` | Auth/lock logic extraction | Root auth/lock routing logic is moved to dedicated lifecycle service/notifier with unchanged behavior and passing tests. |
| `P2-02` | Biometric lock navigation cleanup | Imperative biometric lock navigation is replaced with declarative redirect flow and integration tests cover lock/unlock transitions. |
| `P2-03` | Splash Pro-check timeout | Startup Pro check has timeout/fallback path and app no longer hangs on slow or failed network conditions. |
| `P2-04` | Biometric auto-disable notice | User-visible notice is shown when biometrics are auto-disabled and behavior is covered by tests. |
| `P2-05` | History pagination | History loading is paginated/lazy with deterministic UX for empty/loading/error states. |
| `P2-06` | Accessibility automation suite | Automated accessibility checks are part of CI with documented pass/fail criteria. |
| `P2-07` | Drop synonym prompt tests in ai_service_test | Remove brittle synonym-matching prompt tests (lines 284-316) that assert copy phrases like "funny/humor/light" and "brief/short/1-2"; contract-style `.prompt` assertions already cover the same guarantee. Tests pass after removal with no coverage loss. |
| `P2-08` | Database backup restore verification | Supabase backup restore procedure is documented in `docs/DEVOPS.md` with steps to verify a restore, and at least one test restore has been completed and evidenced. |
| `P2-11` | Mock-layer usage hygiene | Every file in `test/mocks/` is either exercised by at least one test or removed. In particular, `mock_reauth_service.dart` is either used by `reauth_service_test.dart`/widget tests or deleted to avoid dead mock surface area. |
| `P2-12` | Device fingerprint real-service test coverage | Add direct tests for `DeviceFingerprintService` RPC/result mapping and graceful-degradation paths (server unavailable, fingerprint unavailable, Postgrest errors) using Supabase stubs/fakes rather than only mock-self-tests. |
| `P2-13` | Startup orchestration refactor (post-launch) | Startup is moved to an explicit orchestration state machine/service with isolated phase boundaries, cancellation semantics, and deterministic tests for success/failure permutations. Refactor is informed by production startup telemetry from `P1-48` and does not regress route determinism or launch latency budgets. |
| `P2-14` | Re-evaluate custom-lint compatibility | On a scheduled toolchain review, verify whether the published `custom_lint`/`riverpod_lint` ecosystem is compatible with the current Flutter/Dart/Riverpod analyzer line, document the decision in `docs/DEVOPS.md`, and either reintroduce the lint stack with passing `flutter analyze`/`flutter test`/`./scripts/test_critical_smoke.sh` or explicitly keep it deferred with recorded evidence. |
| `P2-16` | Public QA showcase packaging | `README.md` includes a concise risk-to-test-layer matrix, links to concrete evidence sources for local, wired-device, Patrol native-risk, and Firebase Test Lab runs, and describes Patrol/FTL usage honestly as selective native-risk coverage rather than the mainline harness. The public story must explicitly favor a small number of high-signal, bug-oriented tests over inflated test counts or threshold-chasing. `docs/DEVOPS.md` and linked runbooks expose runnable commands for collecting that evidence, the public wording is reviewed against the actual repo workflows/harnesses, and a repo-owner walkthrough confirms the showcase story is accurate and portfolio-ready. |
| `P2-17` | RevenueCat transfer metadata hydration | `user_entitlements` rows created from RevenueCat `TRANSFER` flows preserve or recover canonical `product_id` and `expires_at` values instead of leaving them null. Delete-account/recreate/restore/sign-in validation proves the backend row contains `is_pro=true` plus non-null metadata, and the recovery path is documented in `docs/DEVOPS.md` if webhook/event ordering can still temporarily omit those fields. |
| `P2-18` | AI technical-depth showcase | The repo and app make the AI system design legible and impressive without hand-waving: public docs explain the pinned-model strategy, Remote Config controls, App Check posture, structured JSON contract, fallback path, and typed error handling; diagnostics/support surfaces expose the active AI runtime (backend, primary/fallback model, allowlist state, App Check token mode, config schema version) without leaking secrets; and at least one reproducible evidence path demonstrates a non-happy-path AI behavior (for example fallback-model recovery, client-block triage, or blocked-content classification) with a clear oracle and captured artifact. |
| `P2-21` | Diagnostic auth-provider summary consistency | The support/diagnostic report shows `last_sign_in_provider`, `Most Recent Identity Provider`, and `current_session_source` values that match the actual authenticated session semantics after Apple/Google sign-in, linked-account reuse, and token refresh. DoD requires a clear provider precedence policy, deterministic unit coverage for linked-provider edge cases, and at least one real-device report sample where summary fields match the corresponding recent auth logs. |
| `P2-22` | Mobile app SAST coverage decision | The repo documents and evaluates a security-focused static-analysis strategy for Dart/Flutter app code instead of implicitly treating workflow/edge-function CodeQL coverage as the whole security story. DoD requires: `docs/DEVOPS.md` states exactly what static security analysis does and does not cover for app code, at least one candidate Dart/Flutter SAST path is trialed with recorded evidence, and the final decision is either an adopted runnable CI check or an explicit documented gap with owner, rationale, and review cadence. |
