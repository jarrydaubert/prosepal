# Prosepal

Prosepal is an AI-powered greeting message app for creating high-quality card and occasion messages quickly.

## What It Does

- Generates multiple message options from occasion, relationship, tone, and optional personal details.
- Supports anonymous-first usage with optional account sign-in for persistence and restore flows.
- Integrates subscription entitlements through RevenueCat.
- Uses Firebase AI (Gemini) with runtime safety controls and operational kill-switches.

## Reliability And Safety

- Infrastructure-first release policy before major redesign work.
- Hardened GitHub repository and Actions posture for public-repo safety.
- Deterministic CI gate with analyzer, smoke tests, and TypeScript validation for Supabase functions.
- Canonical DevOps runbook for release, rollback, and incident handling.

## Quick Start

```bash
flutter pub get
flutter run
flutter analyze
flutter test
./scripts/test_flake_audit.sh
./scripts/cleanup.sh --dry-run
```

## Developer Commands

```bash
./scripts/run_ios.sh
./scripts/run_android.sh
./scripts/run_wired_evidence.sh --suite smoke
./scripts/audit_ai_cost_controls.sh
```

## Core Docs

- `AGENTS.md` - Canonical agent policy
- `CLAUDE.md` - Claude compatibility profile
- `SECURITY.md` - Vulnerability reporting process
- `docs/NEXT_RELEASE_BRIEF.md` - vNext scope and release gates
- `docs/BACKLOG.md` - Only open work tracker
- `docs/DEVOPS.md` - Canonical DevOps runbook (CI/CD, testing gates, release, ops)
- `docs/REMOTE_CONFIG.md` - Remote Config keys and safety rules
- `docs/REVENUECAT_POLICY.md` - Subscription identity and restore policy
- `docs/IDENTITY_MAPPING.md` - Canonical auth/subscription/telemetry identity map
- `docs/DOCS_POLICY.md` - Evergreen documentation rules
