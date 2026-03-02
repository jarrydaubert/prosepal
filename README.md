# Prosepal

Prosepal is an AI-powered greeting message app for iOS. It generates personalised card and occasion messages from occasion type, relationship, tone, and optional personal context.

## What It Does

- Generates multiple message options using Gemini via Firebase AI, with retry and safety handling.
- Supports anonymous-first usage with optional Google sign-in for persistence and restore flows.
- Manages subscription entitlements through RevenueCat with deterministic identity/restore behavior.
- Uses Remote Config runtime controls for production safety toggles.

## Test Architecture

The app uses a layered test strategy:

- Unit tests: service-layer behavior with minimum service coverage gate (`./scripts/check_service_coverage.sh`)
- Widget tests: critical screen coverage in smoke gate (`./scripts/test_critical_smoke.sh`)
- Integration tests: Patrol journeys + wired-device evidence + Firebase Test Lab flow

Flaky tests are tagged and excluded from blocking CI until fixed. Flake auditing runs via `./scripts/test_flake_audit.sh`.

## Reliability And Safety

- Infrastructure-first release policy.
- Hardened GitHub repository and Actions posture for public-repo safety.
- Deterministic CI gate with commit-attribution guard, analyzer, smoke tests, and service coverage threshold.
- Canonical DevOps runbook for release, rollback, and incident handling.

## Quick Start

```bash
flutter pub get
./scripts/setup-hooks.sh
flutter analyze
flutter test
./scripts/test_critical_smoke.sh
```

## Developer Commands

```bash
# Run on device
./scripts/run_ios.sh
./scripts/run_android.sh

# Integration evidence
./scripts/run_wired_evidence.sh --suite smoke
./scripts/run_wired_evidence.sh --suite full

# QA/release checks
./scripts/test_flake_audit.sh
./scripts/audit_ai_cost_controls.sh
```

## Core Docs

- `AGENTS.md` - Canonical agent policy and working rules
- `CLAUDE.md` - Claude compatibility profile
- `SECURITY.md` - Vulnerability reporting process
- `docs/NEXT_RELEASE_BRIEF.md` - vNext scope and release gates
- `docs/BACKLOG.md` - Open work tracker
- `docs/DEVOPS.md` - Canonical DevOps runbook (CI/CD, testing gates, release, ops)
- `docs/REMOTE_CONFIG.md` - Remote Config keys and safety rules
- `docs/REVENUECAT_POLICY.md` - Subscription identity and restore policy
- `docs/IDENTITY_MAPPING.md` - Canonical auth/subscription/telemetry identity map
- `docs/DOCS_POLICY.md` - Evergreen documentation rules
