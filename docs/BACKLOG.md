# Backlog

Only open TODO items live here.

Rules:
- No status updates, progress notes, or completed work.
- Every item must include a clear, testable Definition of Done (DoD).
- When an item is complete, remove it from this file.

## P0 - Launch Blockers

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P0-01` | Move Google setup to business account | Google/Play Console ownership is migrated to business account, required permissions are validated, and Android release flow works without personal-account blockers. |
| `P0-02` | Keep redesign out of vNext scope | vNext release scope excludes major redesign code paths; only reliability and approved live-style parity changes are included in release candidate. |
| `VNEXT-08` | Wired physical-device validation gates | Critical suite passes on one wired iOS and one wired Android physical device; release evidence bundle is captured and attached. |
| `VNEXT-09` | iOS script-only archive validation | Release-candidate archive succeeds via scripted iOS build path and evidence confirms non-scripted archive paths are not used. |
| `VNEXT-10` | AI cost/abuse controls | API and app restrictions are verified, budget alerts are configured, kill-switch drill passes, and `docs/DEVOPS.md` reflects final policy. |
| `VNEXT-11` | Canonical identity mapping | Supabase ID, RevenueCat App User ID, Analytics ID, and Crashlytics ID mapping is validated across sign-in/sign-out transitions and documented in `docs/IDENTITY_MAPPING.md`. |
| `VNEXT-12` | UI parity with live baseline | Baseline screenshots exist for core screens and any styling delta is either matched to live or explicitly approved before release. |
| `VNEXT-13` | Device abuse-control compliance decision | iOS/Android abuse-control approach is approved, documented, and reflected in release checklist and runtime configuration. |
| `P0-03` | Supabase leaked-password protection | Leaked-password protection is enabled (or explicitly documented as unavailable on current plan) and auth behavior is validated in test flows. |
| `P0-04` | Auth loading spinner after OAuth sheet | After Apple/Google auth sheet closes, UI shows deterministic loading state until auth completion resolves or fails with user-visible error. |
| `P0-05` | Billing budget alert controls | Budget thresholds and notification channels are configured and verified through a dry-run alert path. |

## P1 - Engineering Tasks

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P1-01` | Password reset deep-link UX | Dedicated `/auth/reset-password` flow consumes reset token directly and is covered by widget/integration tests. |
| `P1-02` | Auto-purchase race after email auth | Email auth purchase path is deterministic, race condition is removed, and integration coverage proves correct sequence. |
| `P1-03` | Service configuration runbook | `docs/SERVICE_CONFIG.md` exists and includes reproducible Firebase/Supabase/RevenueCat configuration steps with pass criteria. |
| `P1-04` | Paywall decomposition | Paywall widget is split into maintainable sections/components with unchanged behavior and passing tests. |
| `P1-05` | Paywall accessibility improvements | Paywall has complete semantics labels and screen-reader navigation validation passes on iOS and Android. |
| `P1-06` | Connectivity monitoring | App-level connection state monitoring is implemented with graceful degraded UX and tested offline/restore scenarios. |
| `P1-07` | Health monitoring runbook | Health monitoring and escalation process is documented in `docs/DEVOPS.md` with clear alert/response steps. |
| `P1-08` | CAPTCHA on email auth | CAPTCHA path is integrated for email auth, server-side validation is enforced, and failure UX is deterministic. |
| `P1-09` | Release key scan guard | Automated pre-release key scan step exists in CI/release workflow and blocks on secret-pattern hits. |

## P2 - Lower Priority

| ID | Item | Definition of Done |
|----|------|--------------------|
| `P2-01` | Auth/lock logic extraction | Root auth/lock routing logic is moved to dedicated lifecycle service/notifier with unchanged behavior and passing tests. |
| `P2-02` | Biometric lock navigation cleanup | Imperative biometric lock navigation is replaced with declarative redirect flow and integration tests cover lock/unlock transitions. |
| `P2-03` | Splash Pro-check timeout | Startup Pro check has timeout/fallback path and app no longer hangs on slow or failed network conditions. |
| `P2-04` | Biometric auto-disable notice | User-visible notice is shown when biometrics are auto-disabled and behavior is covered by tests. |
| `P2-05` | History pagination | History loading is paginated/lazy with deterministic UX for empty/loading/error states. |
| `P2-06` | Accessibility automation suite | Automated accessibility checks are part of CI with documented pass/fail criteria. |
