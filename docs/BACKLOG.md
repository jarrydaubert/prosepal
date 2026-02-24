# Backlog

> Burn-down list of outstanding TODO items only.
> Completed work is removed from this file and tracked in git history.

## P0 - Launch Blockers

| Item | Action |
|------|--------|
| Move Google setup to business account | Migrate Google/Play Console setup to business ownership so Android release is not blocked by personal-account tester constraints. |
| Set up `prosepal-web` on GitHub | Create/push `prosepal-web`, configure branch protections, and connect CI. |
| Keep redesign out of vNext scope | Freeze major redesign work until infra/reliability gates pass; vNext only ships live-style parity adjustments. |

## P0 - vNext Execution Plan

| ID | Item | Definition of Done |
|----|------|--------------------|
| `VNEXT-07` | Integration determinism hardening | Flaky tests are repaired or quarantined from blocking gates; trusted critical-smoke suite is the blocking gate; flake audit passes agreed threshold. Tests are added/updated for changed behavior before closure. |
| `VNEXT-08` | Device + Test Lab validation gates | Critical suite passes on one wired iOS and one wired Android physical device; selected Android Firebase Test Lab matrix passes; release evidence is captured. Tests are added/updated for changed behavior before closure. |
| `VNEXT-09` | Release config preflight automation | CI/release preflight fails when required `dart-define` values are missing; iOS script-only archive enforcement is validated. Tests are added/updated for changed behavior before closure. |
| `VNEXT-10` | AI cost/abuse controls | API/app restrictions verified, per-user limits documented, budget alerts configured, and cost-spike kill-switch runbook finalized. Tests are added/updated for changed behavior before closure. |
| `VNEXT-11` | Canonical identity mapping | Single mapping for Supabase ID, RevenueCat App User ID, Analytics ID, and Crashlytics ID is documented and QA-validated across sign-in/sign-out transitions. Tests are added/updated for changed behavior before closure. |
| `VNEXT-12` | UI parity with live baseline | Baseline screenshots captured for core screens; styling deltas are either matched to live style or explicitly approved before release. Tests are added/updated for changed behavior before closure. |
| `VNEXT-13` | Device abuse-control compliance decision | iOS/Android abuse-control approach is documented and approved (existing strategy with rationale or migration to native attestation APIs), and release checklist is updated accordingly. Tests are added/updated for changed behavior before closure. |

## P0 - Product / Infra Issues

| Item | Action |
|------|--------|
| Supabase leaked-password protection | Enable leaked password protection in Supabase Auth when plan supports it. |
| Auth loading spinner after OAuth sheet | Show loading overlay after Apple/Google sheet closes until auth completion resolves. |

## P1 - Testing Gaps

| ID | Gap | Location | Action |
|----|-----|----------|--------|
| `AUDIT-10` | Missing E2E for auth race + stale entitlement edge cases | `integration_test/` | Add E2E coverage for sign-in routing, restore ordering, and stale local entitlement vs server truth. |
| `AUDIT-11` | Missing tests for diagnostic report redaction levels | `test/services/` | Add tests for standard vs advanced diagnostic payload redaction behavior. |
| `AUDIT-12` | Missing visual regression guard for critical screens | `test/` | Add golden/visual regression tests for auth/home/generate/results/paywall/settings core states. |

## P1 - Engineering Tasks

| Item | Location | Action |
|------|----------|--------|
| Password reset deep link UX | `router.dart`, auth screens | Build dedicated `/auth/reset-password` flow that consumes reset token directly. |
| Auto-purchase race after email auth | `email_auth_screen.dart` | Remove navigate-then-purchase race with deterministic purchase trigger sequencing. |
| Document service configuration runbooks | `docs/` | Add reproducible Firebase/Supabase/RevenueCat configuration runbook (`docs/SERVICE_CONFIG.md`). |
| Paywall decomposition | `paywall_sheet.dart` | Split large widget into maintainable sections/components. |
| Paywall accessibility improvements | `paywall_sheet.dart` | Add full semantics labels and verify screen-reader navigation. |
| Connectivity monitoring | app-wide | Add connection state monitoring and graceful degraded UX. |
| Health monitoring runbook | ops/docs | Add Supabase/Firebase AI health monitoring and escalation runbook. |
| CAPTCHA on email auth | `email_auth_screen.dart` | Add Turnstile/hCaptcha path and Supabase-side validation. |
| Release key scan guard | CI/release docs | Add automated pre-release binary/config key scan step. |

## P2 - Lower Priority

| Item | Location | Action |
|------|----------|--------|
| Auth/lock logic extraction | `app.dart` | Move root auth/lock routing logic to dedicated lifecycle service/notifier. |
| Biometric lock navigation cleanup | routing | Move imperative lock navigation to declarative redirect flow. |
| No timeout on splash Pro check | `router.dart` | Add timeout/fallback to avoid startup hangs on slow networks. |
| Biometric auto-disable notice | `router.dart` | Add user-visible notification when biometrics are auto-disabled. |
| History pagination | `history_service.dart` | Introduce paginated/lazy history loading. |
| Accessibility automation suite | test tooling | Add automated accessibility checks in CI. |
