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
| `VNEXT-08` | Wired physical-device validation gates | Critical suite passes on one wired iOS and one wired Android physical device; release evidence is captured. Tests are added/updated for changed behavior before closure. |
| `VNEXT-09` | iOS script-only archive validation | Release-candidate archive is executed through the scripted iOS build path and evidence is captured that direct Xcode-only/plain `flutter build ios` release paths are not used. Tests are added/updated for changed behavior before closure. |
| `VNEXT-10` | AI cost/abuse controls | API/app restrictions verified, per-user limits documented, budget alerts configured, and cost-spike kill-switch runbook finalized. Tests are added/updated for changed behavior before closure. |
| `VNEXT-11` | Canonical identity mapping | Single mapping for Supabase ID, RevenueCat App User ID, Analytics ID, and Crashlytics ID is documented and QA-validated across sign-in/sign-out transitions. Tests are added/updated for changed behavior before closure. |
| `VNEXT-12` | UI parity with live baseline | Baseline screenshots captured for core screens; styling deltas are either matched to live style or explicitly approved before release. Tests are added/updated for changed behavior before closure. |
| `VNEXT-13` | Device abuse-control compliance decision | iOS/Android abuse-control approach is documented and approved (existing strategy with rationale or migration to native attestation APIs), and release checklist is updated accordingly. Tests are added/updated for changed behavior before closure. |

## P0 - Product / Infra Issues

| Item | Action |
|------|--------|
| Supabase leaked-password protection | Enable leaked password protection in Supabase Auth when plan supports it. |
| Auth loading spinner after OAuth sheet | Show loading overlay after Apple/Google sheet closes until auth completion resolves. |
| Firebase API key app restrictions | Add platform application restrictions for Firebase auto-created Android/iOS/browser keys and verify with `./scripts/audit_ai_cost_controls.sh`. |
| Billing budget alert controls | Enable budget alert verification path (permissions/API) and configure release budget thresholds + notifications for AI cost monitoring. |

## P1 - Testing Gaps

| ID | Gap | Location | Definition of Done |
|----|-----|----------|--------------------|
| `AUDIT-18` | Critical widget coverage depth is still thin on auth/onboarding/lock | `test/widgets/screens/` | Each listed screen has deterministic widget tests for primary state, interaction state, and at least one boundary/empty state. New tests run in `./scripts/test_critical_smoke.sh` without flakes. |
| `AUDIT-19` | Critical widget error states are under-tested | `test/widgets/screens/`, `test/mocks/` | Widget tests explicitly assert user-visible error behavior for auth failure, generation failure/rate-limit, and subscription restore/paywall failure using existing mock error injection. |

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
