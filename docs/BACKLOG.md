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

## Release Priority Order (next post-submission cycle)

Process items in this order unless an explicit owner override is recorded in release planning.

1. `P0-08a` Core readability and contrast hardening
2. `P0-08b` Navigation and input polish
3. `P1-24` Deterministic integration journey assertions
4. `P1-41` Network-independent smoke deterministic mode
5. `VNEXT-10` AI cost/abuse controls
6. `P0-08c` Launch and platform polish
7. `P2-17` RevenueCat transfer metadata hydration
8. `P2-16` Public QA showcase packaging
9. `P2-18` AI technical-depth showcase
10. `P1-48` Startup phase telemetry and budget visibility
11. `P1-53` Telemetry adapter unification
12. `P1-52` Biometric lifecycle debounce + single-flight guard
13. `VNEXT-11` Canonical identity mapping
14. `VNEXT-13` Device abuse-control compliance decision
15. `VNEXT-12` UI parity with live baseline
16. `P0-05` Billing budget alert controls
17. `P0-04` Auth loading spinner after OAuth sheet
18. `P0-01` Move Google setup to business account
19. `P1-47` Server-side AI gateway rollout (post-launch trigger)
20. `P2-13` Startup orchestration extraction, if justified by telemetry
21. `P2-22` Remove legacy router fallback

## P0 - Launch Blockers

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P0-08a` | Core readability and contrast hardening | Core screens and subflows in scope (`auth`, `lock`, `settings`, feedback, `history`, `calendar`, and any surfaced support/legal subflow touched by recent polish work) use shared semantic tokens only and have no readable dark-on-dark or light-on-light text regressions. DoD requires: updated widget/golden coverage where structure is stable, physical iOS + Android screenshots for each fixed surface, and an explicit WCAG AA manual verification note for primary text on the scoped screens. |
| `P0-08b` | Navigation and input polish | Back navigation controls use the canonical chevron treatment across scoped screens, text-entry surfaces have consistent icon alignment and capitalization hints, and returning from generate/results/auth flows to home does not leave the search keyboard open. Dialog/input surfaces (delete, reauth, feedback, calendar entry, generate details) remain keyboard-safe and visually stable. DoD requires: regression coverage for each fixed bug path, explicit verification of the results-screen chevron and Gemini attribution spacing, and physical iOS + Android evidence for the named keyboard/navigation flows. |
| `P0-08c` | Launch and platform polish | Launch surfaces look intentional on both platforms: iOS remains visually clean, Android launch treatment is explicitly designed for platform behavior rather than accidental fallback chrome, and any remaining platform differences are documented as deliberate. DoD requires: physical iOS + Android launch screenshots/video evidence, an explicit decision record for Android launch treatment, and no accidental icon/splash fallback behavior on the supported release devices. |
| `P0-05` | Billing budget alert controls | Budget thresholds and notification channels are configured and verified through a dry-run alert path. |
| `P0-04` | Auth loading spinner after OAuth sheet | After Apple/Google auth sheet closes, UI shows deterministic loading state until auth completion resolves or fails with user-visible error. |
| `P0-01` | Move Google setup to business account | Google/Play Console ownership is migrated to business account, required permissions are validated, and Android release flow works without personal-account blockers. |
| `VNEXT-10` | AI cost/abuse controls | API and app restrictions are verified, budget alerts are configured, App Check production posture is confirmed, release Remote Config kill-switch/model allowlist state is reviewed, kill-switch drill passes, and `docs/DEVOPS.md` reflects final policy. |
| `VNEXT-11` | Canonical identity mapping | Supabase ID, RevenueCat App User ID, Analytics ID, and Crashlytics ID mapping is validated across sign-in/sign-out transitions and documented in `docs/IDENTITY_MAPPING.md`. |
| `VNEXT-12` | UI parity with live baseline | Baseline screenshots exist for core screens and any styling delta is either matched to live or explicitly approved before release. |
| `VNEXT-13` | Device abuse-control compliance decision | iOS/Android abuse-control approach is approved, documented, and reflected in release checklist and runtime configuration. |

## P1 - Engineering Tasks

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P1-48` | Startup phase telemetry and budget visibility | Existing startup flow emits structured phase telemetry (`init`, `identity`, `entitlements`, `routing`) with per-phase duration, timeout/fallback reason, and final terminal route outcome. Logs are queryable in Crashlytics/analytics, phase budgets are documented in `docs/DEVOPS.md`, and fault-injection runs prove telemetry captures degraded startup paths deterministically. |
| `P1-53` | Telemetry adapter unification | Feature/domain code emits analytics, logs, and crash-report context through an interface-backed telemetry service or adapter layer rather than direct static calls. Existing redaction rules, event schemas, and operator-visible behavior remain intact unless explicitly documented. DoD requires: at least one startup event, one auth/paywall event, and one AI/runtime diagnostic event are covered by tests using fakes or spies; no secrets or sensitive user content are newly exposed; any operator-facing telemetry changes are documented in `docs/DEVOPS.md`; and `flutter analyze`, `flutter test`, and `./scripts/test_critical_smoke.sh` pass. |
| `P1-47` | Server-side AI gateway rollout (post-launch trigger) | A documented trigger policy exists for enabling a server-side AI gateway (abuse threshold, model-policy requirement, or provider-failover need). A non-production spike path exists behind a disabled feature flag, with parity tests proving no user-visible regression when enabled in staging. Production default remains client-direct until trigger criteria are met and approved. |
| `P1-24` | Deterministic integration journey assertions | Journey tests in `integration_test/journeys/` stop using optional `if (exists(...))` branches for core checkpoints (auth entry, upgrade path, generation result, settings navigation) and fail explicitly when expected UI state is missing. Each retained journey test must justify its existence by targeting a concrete bug/failure mode, and low-signal click-through coverage should be removed rather than padded. DoD includes a keep/rewrite/delete review across the checked-in journey suite, representative journey execution on a real mobile target without silent skips, and clear failure reasons tied to both the missing checkpoint and the named bug the test is meant to catch. |
| `P1-42` | Auth-screen layout flake elimination | The `AuthScreen shows error banner when Google sign-in fails` test no longer produces order-dependent `RenderFlex overflow` failures during randomized multi-file runs. Root cause is fixed (test harness isolation and/or responsive layout constraints), deterministic regression coverage is added, and `./scripts/test_flake_audit.sh` shows zero flakes for this case. |
| `P1-40` | Startup/router timeout guard under network faults | Splash/startup routing reaches an explicit terminal route (`/onboarding`, `/home`, `/auth`, `/lock`, or init error surface) within a bounded timeout even when Supabase/RevenueCat DNS fails. Returning-user entitlement routing is deterministic under delayed RevenueCat init (no false `/onboarding` fallback followed by corrective auth/restore reroute). Integration tests cover both network-fault and delayed-entitlement scenarios with deterministic pass/fail assertions. |
| `P1-52` | Biometric lifecycle debounce + single-flight guard | Biometric lock flow guarantees a single active prompt per foreground transition, ignores duplicate resume/inactive callbacks inside a bounded debounce window, and logs one stable lifecycle transition per lock attempt. Device tests on iOS confirm no rapid repeated `Biometric auth started` bursts during Face ID enable/disable and resume flows. |
| `P1-41` | Network-independent smoke deterministic mode | `integration_test/smoke_test.dart` has a documented deterministic mode (or injected fakes) that removes dependency on live Supabase/RevenueCat reachability for core S1-S5 assertions. CI/device smoke remains stable when outbound network is unavailable or flaky, and the home/onboarding checkpoint does not depend on live backend timing to reach `What's the occasion?` or `Birthday`. |
| `P1-38` | E2E suite failure isolation | `integration_test/e2e_test.dart` execution is split or orchestrated so one early failure does not collapse the full suite into mass `did not complete` noise. Each shard outputs independent pass/fail and artifacts. |
| `P1-34` | Offline-safe integration font loading | Integration runs do not depend on live `fonts.gstatic.com` fetches. `google_fonts` runtime fetching is disabled in test mode (or fonts are bundled/preloaded), and `integration_test/smoke_test.dart` + `integration_test/e2e_test.dart` pass without DNS/network access. |
| `P1-37` | iOS CocoaPods lockfile consistency gate | `ios/Podfile.lock` stays aligned with plugin constraints on clean clone. Running `flutter test -d <ios-device> integration_test/*` does not require ad-hoc pod updates, and CI/dev docs include a reproducible pod consistency check. |
| `P1-27` | QA code documentation standards (Dartdoc/JSDoc) | Public QA-facing helpers and APIs have accurate documentation comments: Dartdoc on shared test helpers/mocks/services and JSDoc on JavaScript/TypeScript automation code in repo scope. Comments describe purpose, inputs/outputs, and failure modes; stale examples are removed; documentation quality is verified in CI (lint/check step) and reflected in `docs/DEVOPS.md`. |
| `P1-44` | Full documentation walkthrough with repo owner | A full walkthrough of repo docs is completed with the repo owner: `README.md`, `docs/DEVOPS.md`, `docs/NEXT_RELEASE_BRIEF.md`, `docs/LAUNCH_CHECKLIST.md`, `docs/IDENTITY_MAPPING.md`, and `docs/BACKLOG.md`. All command snippets are verified runnable, stale references are removed, cross-links are valid, and any follow-up gaps are captured as explicit backlog items. |
| `P1-01` | Social-auth fallback UX | Social sign-in failures show deterministic user guidance, retry actions, and support path coverage in widget/integration tests. |
| `P1-04` | Paywall decomposition | Paywall widget is split into maintainable sections/components with unchanged behavior and passing tests. |
| `P1-05` | Paywall accessibility improvements | Paywall has complete semantics labels and screen-reader navigation validation passes on iOS and Android. |
| `P1-06` | Connectivity monitoring | App-level connection state monitoring is implemented with graceful degraded UX and tested offline/restore scenarios. |
| `P1-07` | Health monitoring runbook | Health monitoring and escalation process is documented in `docs/DEVOPS.md` with clear alert/response steps. |
| `P1-08` | Auth abuse controls for social flows | App Check and provider-side abuse controls are validated for Apple/Google auth flows with documented thresholds and escalation steps. |
| `P1-45` | Sensitive screen capture hardening (paywall/settings) | Android applies and releases `FLAG_SECURE` only while sensitive paywall/subscription views are visible, iOS hides sensitive content in app-switcher snapshots during resign-active transitions, and device validation evidence confirms screenshots/app-switcher previews no longer expose sensitive paywall/subscription content. |
| `P1-46` | iOS auth callback hardening to Universal Links | iOS auth callback flow is validated end-to-end with `https://prosepal.app/auth/...` Universal Links and a live `apple-app-site-association`; custom-scheme callback usage is removed from security-critical auth paths (or explicitly documented as temporary risk with owner sign-off and expiry date). |
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
| `P1-20` | Post-release production pulse checks | `docs/DEVOPS.md` defines a 0-60 minute post-release check protocol (Crashlytics, Supabase, AI cost/error signals, store console sanity) with explicit rollback trigger thresholds. |
| `P1-21` | Release evidence bundle automation | Release workflow publishes an evidence bundle artifact (checks summary, coverage/service-gate outputs, wired/FTL evidence links, Supabase/AI audit outputs, and run-ID traceability). |

## P2 - Lower Priority

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P2-01` | Auth/lock logic extraction | Root auth/lock routing logic is moved to dedicated lifecycle service/notifier with unchanged behavior and passing tests. |
| `P2-02` | Biometric lock navigation cleanup | Imperative biometric lock navigation is replaced with declarative redirect flow and integration tests cover lock/unlock transitions. |
| `P2-05` | History pagination | History loading is paginated/lazy with deterministic UX for empty/loading/error states. |
| `P2-06` | Accessibility automation suite | Automated accessibility checks are part of CI with documented pass/fail criteria. |
| `P2-08` | Database backup restore verification | Supabase backup restore procedure is documented in `docs/DEVOPS.md` with steps to verify a restore, and at least one test restore has been completed and evidenced. |
| `P2-12` | Device fingerprint real-service test coverage | Add direct tests for `DeviceFingerprintService` RPC/result mapping and graceful-degradation paths (server unavailable, fingerprint unavailable, Postgrest errors) using Supabase stubs/fakes rather than only mock-self-tests. |
| `P2-13` | Startup orchestration extraction, if justified by telemetry | Production startup telemetry from `P1-48` or a documented maintenance/reliability review identifies at least one concrete problem in the current startup flow: repeated timeout fallbacks, hard-to-isolate failures, or high review/debug cost caused by mixed widget/orchestration logic. Only the affected startup decision/orchestration paths are extracted from `lib/app/router.dart` into pure functions or a coordinator service, while route outcomes, timeout budgets, and telemetry semantics stay unchanged unless explicitly documented. DoD requires: deterministic unit coverage for init error, onboarding, biometric-lock, entitlement-restore, success, timeout, and exception permutations; no regression in startup terminal-route behavior; and `flutter analyze`, `flutter test`, and `./scripts/test_critical_smoke.sh` pass. |
| `P2-14` | Re-evaluate custom-lint compatibility | On a scheduled toolchain review, verify whether the published `custom_lint`/`riverpod_lint` ecosystem is compatible with the current Flutter/Dart/Riverpod analyzer line, document the decision in `docs/DEVOPS.md`, and either reintroduce the lint stack with passing `flutter analyze`/`flutter test`/`./scripts/test_critical_smoke.sh` or explicitly keep it deferred with recorded evidence. |
| `P2-16` | Public QA showcase packaging | `README.md` includes a concise risk-to-test-layer matrix, links to concrete evidence sources for local, wired-device, Patrol native-risk, and Firebase Test Lab runs, and describes Patrol/FTL usage honestly as selective native-risk coverage rather than the mainline harness. The public story must explicitly favor a small number of high-signal, bug-oriented tests over inflated test counts or threshold-chasing. `docs/DEVOPS.md` and linked runbooks expose runnable commands for collecting that evidence, the public wording is reviewed against the actual repo workflows/harnesses, and a repo-owner walkthrough confirms the showcase story is accurate and portfolio-ready. |
| `P2-17` | RevenueCat transfer metadata hydration | `user_entitlements` rows created from RevenueCat `TRANSFER` flows preserve or recover canonical `product_id` and `expires_at` values instead of leaving them null. Delete-account/recreate/restore/sign-in validation proves the backend row contains `is_pro=true` plus non-null metadata, and the recovery path is documented in `docs/DEVOPS.md` if webhook/event ordering can still temporarily omit those fields. |
| `P2-18` | AI technical-depth showcase | The repo and app make the AI system design legible and impressive without hand-waving: public docs explain the pinned-model strategy, Remote Config controls, App Check posture, structured JSON contract, fallback path, and typed error handling; diagnostics/support surfaces expose the active AI runtime (backend, primary/fallback model, allowlist state, App Check token mode, config schema version) without leaking secrets; and at least one reproducible evidence path demonstrates a non-happy-path AI behavior (for example fallback-model recovery, client-block triage, or blocked-content classification) with a clear oracle and captured artifact. |
| `P2-21` | Diagnostic auth-provider summary consistency | The support/diagnostic report shows `last_sign_in_provider`, `Most Recent Identity Provider`, and `current_session_source` values that match the actual authenticated session semantics after Apple/Google sign-in, linked-account reuse, and token refresh. DoD requires a clear provider precedence policy, deterministic unit coverage for linked-provider edge cases, and at least one real-device report sample where summary fields match the corresponding recent auth logs. |
| `P2-22` | Remove legacy router fallback | The legacy `appRouter` path in `lib/app/router.dart` is removed once the guarded router migration is confirmed stable. All app entrypoints use the canonical guarded router path only, no docs or tests reference the legacy router, and navigation/regression coverage continues to pass. DoD requires: `flutter analyze`, `flutter test`, and `./scripts/test_critical_smoke.sh` pass. |
