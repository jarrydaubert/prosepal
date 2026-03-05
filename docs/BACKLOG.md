# Backlog

Only open TODO items live here.

Rules:
- No status updates, progress notes, or completed work.
- Every item must include a clear, testable Definition of Done (DoD).
- When an item is complete, remove it from this file.

## Global DoD Contract (Applies To Every Item)

A backlog item is only considered complete when all conditions below are true:

1. `Outcome delivered`: The row's feature/fix/docs scope is implemented exactly as written.
2. `Deterministic validation passed`: Relevant validation commands pass with no manual interpretation required.
3. `Evidence attached`: PR/release evidence includes concrete proof (logs, screenshots, CI run IDs, or artifact links) for the completed outcome.
4. `Backlog hygiene`: The completed item is removed from this file in the same change set that provides outcome + validation + evidence.

If any condition is missing, the item remains open.

## Release Priority Order (vNext)

Process items in this order unless an explicit owner override is recorded in release planning.

1. `P0-08` Design token consistency and contrast hardening
2. `P0-09` iOS/Android launch and auth visual parity
3. `P0-07` Next iOS release readiness checklist
4. `VNEXT-08` Wired physical-device validation gates
5. `VNEXT-09` iOS script-only archive validation
6. `VNEXT-10` AI cost/abuse controls
7. `P1-43` Firebase AI client-block regression hardening
8. `P1-48` Startup phase telemetry and budget visibility
9. `P1-40` Startup/router timeout guard under network faults
10. `P1-52` Biometric lifecycle debounce + single-flight guard
11. `VNEXT-11` Canonical identity mapping
12. `VNEXT-12` UI parity with live baseline
13. `VNEXT-13` Device abuse-control compliance decision
14. `P0-05` Billing budget alert controls
15. `P0-04` Auth loading spinner after OAuth sheet
16. `P0-01` Move Google setup to business account
17. `P0-02` Keep redesign out of vNext scope
18. `P1-47` Server-side AI gateway rollout (post-launch trigger)
19. `P2-13` Startup orchestration refactor (post-launch)

## P0 - Launch Blockers

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P0-07` | Next iOS release readiness checklist | `docs/IOS_RELEASE_CHECKLIST.md` contains an explicit pre-release checklist and every line item is executed with evidence: version/build bump, `flutter analyze`, `flutter test`, `./scripts/test_critical_smoke.sh`, wired iOS smoke/journey run, scripted iOS archive success, Crashlytics dSYM upload verification, Firebase App Check + AI generation verification on physical iOS, RevenueCat entitlement/paywall verification, Supabase auth/provider verification, App Store Connect metadata/release notes/screenshots review, TestFlight sanity pass, git-history secret audit (`git log --all -- .env.local` + CI secret scan output), and rollback path confirmation with owner sign-off. |
| `VNEXT-08` | Wired physical-device validation gates | Critical suite passes on one wired iOS and one wired Android physical device; release evidence bundle is captured and attached. |
| `P0-08` | Design token consistency and contrast hardening | Core screens (`home`, `generate`, `results`, `history`, `settings`, `calendar`, `auth`, onboarding, paywall) use shared semantic tokens only (canonical palette: navy/slate backgrounds, coral actions, white/light surfaces) with no light-on-light or dark-on-dark regressions. Back navigation controls are visually consistent across screens, text-field prefix/suffix icon alignment is consistent, and text-entry surfaces provide deterministic keyboard-dismiss behavior (`done` action and/or explicit dismiss affordance). DoD evidence requires: updated golden baseline for affected core screens, physical iOS + Android screenshots for each affected flow, and an explicit WCAG AA manual verification note for primary text before RC cut. |
| `P0-09` | iOS/Android launch and auth visual parity | Cold-launch capture on physical iOS and Android shows matching launch background tone, no white/grey flash during transition to Flutter splash/auth, and consistent auth-screen logo/button contrast treatment. Evidence screenshots/videos are attached in release artifact bundle. |
| `P0-05` | Billing budget alert controls | Budget thresholds and notification channels are configured and verified through a dry-run alert path. |
| `VNEXT-09` | iOS script-only archive validation | Release-candidate archive succeeds via scripted iOS build path and evidence confirms non-scripted archive paths are not used. |
| `P0-04` | Auth loading spinner after OAuth sheet | After Apple/Google auth sheet closes, UI shows deterministic loading state until auth completion resolves or fails with user-visible error. |
| `P0-01` | Move Google setup to business account | Google/Play Console ownership is migrated to business account, required permissions are validated, and Android release flow works without personal-account blockers. |
| `VNEXT-10` | AI cost/abuse controls | API and app restrictions are verified, budget alerts are configured, kill-switch drill passes, and `docs/DEVOPS.md` reflects final policy. |
| `VNEXT-11` | Canonical identity mapping | Supabase ID, RevenueCat App User ID, Analytics ID, and Crashlytics ID mapping is validated across sign-in/sign-out transitions and documented in `docs/IDENTITY_MAPPING.md`. |
| `VNEXT-12` | UI parity with live baseline | Baseline screenshots exist for core screens and any styling delta is either matched to live or explicitly approved before release. |
| `VNEXT-13` | Device abuse-control compliance decision | iOS/Android abuse-control approach is approved, documented, and reflected in release checklist and runtime configuration. |
| `P0-02` | Keep redesign out of vNext scope | vNext release scope excludes major redesign code paths; only reliability and approved live-style parity changes are included in release candidate. |

## P1 - Engineering Tasks

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P1-48` | Startup phase telemetry and budget visibility | Existing startup flow emits structured phase telemetry (`init`, `identity`, `entitlements`, `routing`) with per-phase duration, timeout/fallback reason, and final terminal route outcome. Logs are queryable in Crashlytics/analytics, phase budgets are documented in `docs/DEVOPS.md`, and fault-injection runs prove telemetry captures degraded startup paths deterministically. |
| `P1-43` | Firebase AI client-block regression hardening | Real-device AI generation succeeds on wired iOS and Android using the current Firebase AI + App Check setup, and failure classification distinguishes client/app-block configuration errors from true content-safety blocks. `docs/DEVOPS.md` includes a deterministic checklist for debugging `client application <empty> are blocked` responses. |
| `P1-47` | Server-side AI gateway rollout (post-launch trigger) | A documented trigger policy exists for enabling a server-side AI gateway (abuse threshold, model-policy requirement, or provider-failover need). A non-production spike path exists behind a disabled feature flag, with parity tests proving no user-visible regression when enabled in staging. Production default remains client-direct until trigger criteria are met and approved. |
| `P1-24` | Deterministic integration journey assertions | Journey tests in `integration_test/journeys/` stop using optional `if (exists(...))` branches for core checkpoints (auth entry, upgrade path, generation result, settings navigation) and fail explicitly when expected UI state is missing. Updated journeys run green in deterministic local/device execution and include clear assertion reasons. |
| `P1-42` | Auth-screen layout flake elimination | The `AuthScreen shows error banner when Google sign-in fails` test no longer produces order-dependent `RenderFlex overflow` failures during randomized multi-file runs. Root cause is fixed (test harness isolation and/or responsive layout constraints), deterministic regression coverage is added, and `./scripts/test_flake_audit.sh` shows zero flakes for this case. |
| `P1-40` | Startup/router timeout guard under network faults | Splash/startup routing reaches an explicit terminal route (`/onboarding`, `/home`, `/auth`, `/lock`, or init error surface) within a bounded timeout even when Supabase/RevenueCat DNS fails. Returning-user entitlement routing is deterministic under delayed RevenueCat init (no false `/onboarding` fallback followed by corrective auth/restore reroute). Integration tests cover both network-fault and delayed-entitlement scenarios with deterministic pass/fail assertions. |
| `P1-52` | Biometric lifecycle debounce + single-flight guard | Biometric lock flow guarantees a single active prompt per foreground transition, ignores duplicate resume/inactive callbacks inside a bounded debounce window, and logs one stable lifecycle transition per lock attempt. Device tests on iOS confirm no rapid repeated `Biometric auth started` bursts during Face ID enable/disable and resume flows. |
| `P1-41` | Network-independent smoke deterministic mode | `integration_test/smoke_test.dart` has a documented deterministic mode (or injected fakes) that removes dependency on live Supabase/RevenueCat reachability for core S1-S5 assertions. CI/device smoke remains stable when outbound network is unavailable or flaky. |
| `P1-39` | Android smoke integration harness stall (`did not complete`) | `flutter test -d <android-device> integration_test/smoke_test.dart` completes deterministically on wired hardware. No test hangs at `S1` with `+0` progress, and failures (if any) surface as explicit assertions/timeouts with actionable stack traces. |
| `P1-35` | Smoke suite determinism and async hygiene | `integration_test/smoke_test.dart` removes guarded async conflicts and fragile route assumptions (`S4`/`S5`), uses deterministic waits/finders, and passes on wired Android + iOS without manual retries. |
| `P1-36` | Journey launch readiness hardening | `integration_test/journeys/_helpers.dart` `launchApp()` waits for a concrete ready surface (onboarding/auth/home) with bounded timeout and clear failure reasons. `j1_fresh_install_test.dart` no longer produces `did not complete` behavior during wired-device execution. |
| `P1-38` | E2E suite failure isolation | `integration_test/e2e_test.dart` execution is split or orchestrated so one early failure does not collapse the full suite into mass `did not complete` noise. Each shard outputs independent pass/fail and artifacts. |
| `P1-34` | Offline-safe integration font loading | Integration runs do not depend on live `fonts.gstatic.com` fetches. `google_fonts` runtime fetching is disabled in test mode (or fonts are bundled/preloaded), and `integration_test/smoke_test.dart` + `integration_test/e2e_test.dart` pass without DNS/network access. |
| `P1-37` | iOS CocoaPods lockfile consistency gate | `ios/Podfile.lock` stays aligned with plugin constraints on clean clone. Running `flutter test -d <ios-device> integration_test/*` does not require ad-hoc pod updates, and CI/dev docs include a reproducible pod consistency check. |
| `P1-27` | QA code documentation standards (Dartdoc/JSDoc) | Public QA-facing helpers and APIs have accurate documentation comments: Dartdoc on shared test helpers/mocks/services and JSDoc on JavaScript/TypeScript automation code in repo scope. Comments describe purpose, inputs/outputs, and failure modes; stale examples are removed; documentation quality is verified in CI (lint/check step) and reflected in `docs/DEVOPS.md`. |
| `P1-44` | Full documentation walkthrough with repo owner | A full walkthrough of repo docs is completed with the repo owner: `README.md`, `docs/DEVOPS.md`, `docs/NEXT_RELEASE_BRIEF.md`, `docs/LAUNCH_CHECKLIST.md`, `docs/IDENTITY_MAPPING.md`, and `docs/BACKLOG.md`. All command snippets are verified runnable, stale references are removed, cross-links are valid, and any follow-up gaps are captured as explicit backlog items. |
| `P1-29` | Test-doc reference accuracy cleanup | Test docs only reference existing test files and runnable commands. Remove stale path references (for example `test/features/settings/haiku_screen_test.dart` in `docs/HAIKU_EASTER_EGG.md`) and align command examples with current workflow gates. |
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
| `P1-20` | Post-release production pulse checks | `docs/DEVOPS.md` defines a 0-60 minute post-release check protocol (Crashlytics, Supabase, AI cost/error signals, store console sanity) with explicit rollback trigger thresholds. |
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
