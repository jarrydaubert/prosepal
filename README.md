# Prosepal

Prosepal is a Flutter iOS/Android app that generates personalised greeting-card messages with Gemini via Firebase AI. It is also a public quality-engineering portfolio project: the repo is structured to show how auth, subscriptions, AI, lifecycle, and release risk can be tested and evidenced in a modern mobile app.

## Quality Engineering Showcase

This repo is intended to demonstrate:

- risk-based mobile QA thinking, not just test volume
- deterministic Flutter gates for fast feedback
- physical-device validation for auth, biometrics, payments, lifecycle, and rendering
- cloud-device evidence for reproducible release confidence
- pragmatic automation choices: standard `integration_test` for core flows, selective Patrol adoption for true native/system interactions
- operational discipline through runbooks, cleanup scripts, evidence capture, and backlog hygiene

## App Risk Surface

The app is intentionally not trivial. It includes:

- AI generation through Firebase AI / Gemini
- anonymous-first and signed-in auth flows
- RevenueCat entitlements, restore, and identity transfer
- biometric lock and lifecycle transitions
- onboarding, routing, history, paywall, and calendar flows
- Remote Config and App Check safety controls

Those domains are where mobile apps usually become flaky, stateful, and hard to verify. The test approach is built around that risk.

## Test Strategy

### 1. Deterministic Flutter Gate

Fast local and CI confidence for logic, UI, and routing:

- `flutter analyze`
- `flutter test`
- `./scripts/test_critical_smoke.sh`

What this covers:

- service logic and model behavior
- widget rendering and UI states
- screen-level regressions on the most critical flows
- deterministic checks that should pass without real devices or live stores

### 2. Wired Device Validation

Physical iOS and Android runs are first-class, not an afterthought.

Use:

```bash
./scripts/reset_devices.sh
./scripts/run_ios.sh
./scripts/run_android.sh
./scripts/run_wired_evidence.sh --suite smoke
./scripts/run_wired_evidence.sh --suite full
```

What this is for:

- OAuth sheet behavior
- RevenueCat paywall / restore / purchase flows
- biometric prompts and resume behavior
- launch/auth visual parity
- real rendering differences between iOS and Android

### 3. Cloud / Native-Risk Coverage

Two different tools serve different purposes:

- Firebase Test Lab:
  - reproducible Android device evidence in the cloud
  - good for smoke and release-oriented confidence
- Patrol:
  - appropriate when a test genuinely needs native/system automation
  - examples: permission dialogs, social-auth sheets, store/native surfaces, settings deep-links

Current repo reality:

- the checked-in integration journeys under `integration_test/` use Flutter's standard `integration_test` harness
- Patrol is installed and configured, but should be adopted selectively where it adds real value

## Why This Test Mix

This repo deliberately does not try to force every test into one framework.

- unit/widget tests are the fastest and most trustworthy for app logic and UI states
- device runs are the right place for mobile-specific behavior
- Firebase Test Lab gives repeatable hardware-backed evidence
- Patrol should be used only where Flutter alone is weak

Quality matters more than test count:

- one high-signal test with a strong oracle is better than ten shallow
  click-through tests
- green is only trustworthy when pass/fail is tied to the bug the test is meant
  to catch
- low-signal or silently-skipping tests should be rewritten or removed, not
  defended because they increase numbers

That split is intentional. It is the test strategy I would use on a real mobile team.

## Evidence

The repo is designed to produce evidence, not just green commands.

Examples:

- wired-device evidence bundles from `./scripts/run_wired_evidence.sh`
- visual regression artifacts from `./scripts/test_visual_regression.sh`
- smoke and release-oriented commands in [docs/DEVOPS.md](docs/DEVOPS.md)
- open quality work with explicit Definition of Done in [docs/BACKLOG.md](docs/BACKLOG.md)

## Quick Start

```bash
flutter pub get
./scripts/setup-hooks.sh
flutter analyze
flutter test
./scripts/test_critical_smoke.sh
```

## Useful Commands

```bash
# Clean local/device reset
./scripts/reset_devices.sh

# Run on physical devices
./scripts/run_ios.sh
./scripts/run_android.sh

# Integration evidence
./scripts/run_wired_evidence.sh --suite smoke
./scripts/run_wired_evidence.sh --suite full

# QA / reliability checks
./scripts/test_flake_audit.sh
./scripts/test_visual_regression.sh
./scripts/audit_ai_cost_controls.sh

# Cloud-device validation
flutter build apk --debug -t integration_test/ftl_test.dart
cd android && JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home ./gradlew app:assembleAndroidTest -Ptarget=../integration_test/ftl_test.dart
```

## Honesty About Scope

This repo aims to show sound QA judgment, not fake completeness.

- not every high-value flow should be a Patrol test
- not every device issue should be mocked away
- flaky tests are a quality problem and should be isolated or fixed, not normalized
- docs should match the real harness in use

Where work remains, it is tracked in [docs/BACKLOG.md](docs/BACKLOG.md) with explicit, testable completion criteria.

## Core Docs

- `AGENTS.md` - Canonical working rules for repo changes
- `CLAUDE.md` - Claude compatibility profile
- [docs/DEVOPS.md](docs/DEVOPS.md) - Testing, CI/CD, release, and operational runbooks
- [docs/NEXT_RELEASE_BRIEF.md](docs/NEXT_RELEASE_BRIEF.md) - Release scope and gates
- [docs/BACKLOG.md](docs/BACKLOG.md) - Open work only, with Definition of Done
- [docs/SECURITY.md](docs/SECURITY.md) - Security posture and reporting rules
- [docs/REVENUECAT_POLICY.md](docs/REVENUECAT_POLICY.md) - Subscription identity and restore policy
- [docs/IDENTITY_MAPPING.md](docs/IDENTITY_MAPPING.md) - Auth / subscription / telemetry identity map
- [docs/DOCS_POLICY.md](docs/DOCS_POLICY.md) - Evergreen documentation rules
