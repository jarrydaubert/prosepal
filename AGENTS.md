# AGENTS.md - Prosepal

This file defines how coding agents should work in this repo. Keep it short and keep it true.

CLAUDE.md defers to this file. If there is any conflict, this file is the source of truth.

## Purpose

Prosepal is an AI-powered greeting-card message app focused on reliability, privacy, and safe release execution.

## Priorities

- Reliability first: infra/test hardening before new feature scope.
- Security and privacy by default: no secret leakage, no unsafe logging.
- Backlog is the only burn-down source for open work.
- Evergreen docs: runbooks/specs only, no status-style reporting.
- Preserve release safety guardrails learned from prior store issues.

## Source Of Truth

- Release scope and gates: `docs/NEXT_RELEASE_BRIEF.md`
- Outstanding work only: `docs/BACKLOG.md`
- Documentation rules: `docs/DOCS_POLICY.md`
- Testing approach: `docs/TEST_STRATEGY.md`
- Supabase verification: `docs/SUPABASE_TESTS.md`

## Before You Change Code

- Check existing patterns first; avoid unnecessary rewrites.
- Keep auth/payments/AI flows deterministic and testable.
- Validate platform-sensitive behavior (Apple/Google auth, purchases, restore).
- Avoid logging PII/secrets or exposing server credentials client-side.

## After You Change Code

- Run `flutter analyze`.
- Run `flutter test`.
- Run targeted integration tests for changed journeys when relevant.
- If you cannot run tests locally, state that clearly in your summary.

## Docs Rules

- Do not put TODO/in-flight/status notes in evergreen docs.
- Do not include test counts/pass-rate claims in evergreen docs.
- Move all open issues/actions to `docs/BACKLOG.md`.

## Testing Rules

- Keep blocking gates deterministic.
- Quarantine flaky tests from blocking gates until fixed.
- Track flaky fixes in backlog with clear definition of done.

## Repo Files

- `CLAUDE.md` is a Claude-specific compatibility profile that defers to this file.
- `.claude/commands/` contains optional Claude slash-command prompts.
- `.claude/skills/` contains reusable skill modules loaded on demand.
- `README.md` is for human onboarding and day-to-day project setup.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.38+ / Dart 3.10+ |
| State | Riverpod 3.x |
| Navigation | go_router |
| AI | Firebase AI (Gemini) |
| Auth | Supabase |
| Payments | RevenueCat |
| Analytics | Firebase Analytics + Crashlytics |

Key constraints:
- Riverpod providers must be declared at the top level (no runtime creation inside widgets).
- All navigation must go through go_router; do not use `Navigator.push` directly.
- RevenueCat is the single source of truth for entitlement state; never gate features on local state alone.
- Firebase AI calls must be wrapped so they are mockable in tests.

---

## Key Source Files

| File | Purpose |
|------|---------|
| `lib/core/services/ai_service.dart` | AI prompts and generation (Gemini via Firebase AI) |
| `lib/core/services/subscription_service.dart` | Monetization, entitlements, and RevenueCat integration |
| `lib/shared/theme/` | Design system — colors, typography, spacing, shadows, durations |
| `lib/app/router.dart` | Navigation graph and route definitions |
| `lib/features/paywall/` | Paywall UI and purchase logic |

When editing these files, check for downstream impact on providers that depend on them before committing.

---

## Quick Commands

```bash
flutter run                    # Run app
flutter test                   # All tests
flutter analyze                # Lint
dart format .                  # Format
./scripts/test_flake_audit.sh  # Flake detection
dart run build_runner build --delete-conflicting-outputs  # Regenerate freezed
```

---

## Skills Inventory

Skills live in `.claude/skills/{name}/SKILL.md`. Each skill has YAML frontmatter and a `## Prosepal Context` section.

Load a skill by referencing it in a prompt or by using the skill name in a slash command that supports it.

### CRO & Conversion (7)

| Skill | Purpose |
|-------|---------|
| `page-cro` | Full-page conversion rate analysis and recommendations |
| `paywall-upgrade-cro` | Paywall copy, layout, and pricing optimisation |
| `onboarding-cro` | Onboarding flow friction reduction |
| `signup-flow-cro` | Sign-up screen and auth flow conversion |
| `popup-cro` | Modal and bottom-sheet conversion tactics |
| `form-cro` | Input form completion and error-state optimisation |
| `churn-prevention` | Cancellation flow, win-back, and retention messaging |

### Content & Copy (4)

| Skill | Purpose |
|-------|---------|
| `copywriting` | Persuasive copy for screens, buttons, and headlines |
| `copy-editing` | Proofreading and tone consistency |
| `social-content` | App Store screenshots, social posts, and short-form content |
| `ad-creative` | Paid ad copy and creative briefs |

### SEO & Discovery (4)

| Skill | Purpose |
|-------|---------|
| `seo-audit` | On-page and technical SEO review |
| `schema-markup` | Structured data for rich results |
| `programmatic-seo` | Template-driven page generation for long-tail keywords |
| `ai-seo` | Optimising content for AI-powered search surfaces |

### Marketing Strategy (5)

| Skill | Purpose |
|-------|---------|
| `marketing-ideas` | Brainstorm growth and acquisition ideas |
| `marketing-psychology` | Behavioural and persuasion frameworks |
| `launch-strategy` | Go-to-market sequencing and launch planning |
| `email-sequence` | Drip/onboarding email copy and flow design |
| `product-marketing-context` | Positioning, messaging, and competitive framing |

### Growth & Analytics (4)

| Skill | Purpose |
|-------|---------|
| `referral-program` | Referral mechanic design and copy |
| `ab-test-setup` | Experiment design, hypothesis, and success metrics |
| `analytics-tracking` | Event taxonomy, tracking plan, and implementation review |
| `paid-ads` | Campaign structure, targeting, and bid strategy |

### Pricing & Monetization (2)

| Skill | Purpose |
|-------|---------|
| `pricing-strategy` | Price point selection and packaging |
| `competitor-alternatives` | Competitive landscape and positioning against alternatives |

### Engineering (2)

| Skill | Purpose |
|-------|---------|
| `tdd` | Test-driven development guidance and test-first workflow |
| `prd-to-issues` | Break down a PRD into scoped, actionable GitHub issues |

### Content Strategy (1)

| Skill | Purpose |
|-------|---------|
| `content-strategy` | Editorial planning, content pillars, and distribution |

### Accessibility (1)

| Skill | Purpose |
|-------|---------|
| `accessibility` | WCAG compliance, semantic labels, and contrast review |

---

## Slash Commands

Commands live in `.claude/commands/`. Load a command by typing `/command-name` at the start of a message.

| Command | Role | Purpose | Writes Code? |
|---------|------|---------|-------------|
| `/plan` | Architect | Design sessions and feature planning | No |
| `/audit` | Reviewer | Deep code analysis and pattern review | No |
| `/security` | Security Engineer | Vulnerability and auth flow review | No |
| `/test` | Test Engineer | Coverage analysis and test authoring | Yes |
| `/debug` | Debugger | Diagnose and fix issues | Yes |
| `/pr` | Release Engineer | Generate pull request description | No |
| `/pre-launch` | Release Manager | App Store / Play Store readiness check | No |
| `/new-app` | Scaffolder | Create a new app from the blueprint | Yes |
| `/marketing` | Growth Marketer | Content generation, ASO, analytics | No |
| `/web` | Web Developer | Landing pages, SEO, performance | Yes |
| `/cleanup` | Code Janitor | Dead code, unused deps, lint clean-up | No |

---

## Canonical Docs

| Doc | Purpose |
|-----|---------|
| `docs/NEXT_RELEASE_BRIEF.md` | Release scope and gates |
| `docs/BACKLOG.md` | Outstanding work (only burn-down source) |
| `docs/DOCS_POLICY.md` | Documentation rules |
| `docs/TEST_STRATEGY.md` | Testing approach |
| `docs/SUPABASE_TESTS.md` | Supabase verification |
| `docs/MARKETING.md` | Marketing strategy and playbook |
