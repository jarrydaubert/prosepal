---
description: Deep code/architecture audit of a system or file
argument-hint: [target]
---

# /audit - Deep Code Audit

Run a deep, risk-first audit of the specified system, feature, workflow, or file.

Rules:
- Do not write or modify code in this mode.
- Output findings directly in chat.
- Prioritize bug/regression/risk findings over style opinions.
- Reference file locations and lines.
- Read the relevant source-of-truth docs before concluding anything:
  - `AGENTS.md`
  - `docs/NEXT_RELEASE_BRIEF.md`
  - `docs/DEVOPS.md`
  - `docs/BACKLOG.md`
  - plus any feature-specific runbooks relevant to the target
- Cross-check against `docs/BACKLOG.md` and report only new, regressed, or still-unmitigated issues.
- Prefer evidence over speculation. If something cannot be verified from code, tests, scripts, or docs, say that clearly.
- If no findings are discovered, say so explicitly and list residual risks or unverified areas.

## Usage
```
/audit [target]
```

**Examples:**
- `/audit auth` - Audit authentication system
- `/audit payments` - Audit subscription/RevenueCat integration
- `/audit lib/core/services/ai_service.dart` - Audit specific file

## Audit Approach

1. Identify the exact scope:
   - system, feature, workflow, file, or PR-sized change
2. Read the relevant source-of-truth docs first.
3. Inspect the real implementation and tests:
   - code
   - workflows/scripts
   - related docs/runbooks
4. Evaluate behavior, not just code shape:
   - happy path
   - failure path
   - recovery path
   - release impact
5. Report only the highest-signal findings.

## Audit Checklist (Risk First, Prosepal-Specific)

When auditing, focus on:

### Product-Critical Flows
- [ ] Auth flow behavior matches `docs/NEXT_RELEASE_BRIEF.md`
- [ ] Purchase flow preserves anonymous purchase support where required
- [ ] Restore/account-linking flow matches `docs/REVENUECAT_POLICY.md`
- [ ] Identity transitions match `docs/IDENTITY_MAPPING.md`
- [ ] AI generation behavior matches current model/runtime-control policy
- [ ] App startup/routing remains deterministic under degraded conditions

### Correctness And Regressions
- [ ] Behavior is coherent across code, tests, and docs
- [ ] Existing invariants are preserved
- [ ] Failure states produce the intended user-visible outcome
- [ ] Cache/state invalidation is correct after auth, restore, sign-out, and retry paths
- [ ] Analytics/diagnostics remain aligned with actual runtime behavior

### Security And Abuse Resistance
- [ ] Input validation and sanitization
- [ ] Auth state verified before sensitive operations
- [ ] No hardcoded secrets
- [ ] Error messages don't leak internal details
- [ ] Rate limiting in place
- [ ] Sensitive user content is not logged
- [ ] Auth/payment/AI flows remain deterministic and testable

### Resilience
- [ ] Timeouts on network calls
- [ ] Graceful degradation on service failure
- [ ] Retry logic with backoff where appropriate
- [ ] Offline behavior handled
- [ ] Startup timeouts/fallbacks do not route users incorrectly
- [ ] Device/network/provider failures do not leave entitlement or auth state inconsistent

### Testing And Validation
- [ ] Follows existing patterns in codebase
- [ ] Proper error typing (not generic catch)
- [ ] Resources disposed properly
- [ ] Tests exist for critical paths
- [ ] Behavior changes include updated tests
- [ ] Relevant validation aligns with:
  - `flutter analyze`
  - `flutter test`
  - `./scripts/test_critical_smoke.sh`
  - any target-specific scripts/workflows from `docs/DEVOPS.md`

### UI / Release Confidence
- [ ] Core screen behavior remains aligned with the current design baseline
- [ ] No obvious launch/auth/paywall flow regressions
- [ ] If UI behavior changed, visual regression and parity implications are considered
- [ ] iOS build/runtime assumptions are compatible with release-preflight rules

### Database/Backend (Supabase)
- [ ] RLS policies match intended access patterns
- [ ] Sensitive tables use RPC-only writes (no direct INSERT/UPDATE)
- [ ] Table grants don't exceed RLS intent
- [ ] Edge functions validate auth before operations
- [ ] No service_role key in client code
- [ ] Usage, entitlement, and abuse-control paths remain server-authoritative where required

### Payments / Identity / Telemetry
- [ ] RevenueCat App User ID policy is preserved (`docs/REVENUECAT_POLICY.md`)
- [ ] Anonymous and authenticated identity transitions are correct (`docs/IDENTITY_MAPPING.md`)
- [ ] Entitlement refresh happens at the right points
- [ ] Telemetry user IDs set/clear consistently on auth changes
- [ ] Diagnostics would expose identity divergence clearly if it occurred

### AI / Runtime Controls
- [ ] Remote Config assumptions match `docs/REMOTE_CONFIG.md`
- [ ] Kill switches and allowlist assumptions are preserved
- [ ] Pinned model and fallback behavior remain coherent
- [ ] App Check / abuse-control posture is not weakened accidentally

### Release Readiness
- [ ] Change aligns with release constraints in `docs/NEXT_RELEASE_BRIEF.md`
- [ ] Operational implications align with `docs/DEVOPS.md`
- [ ] Release preflight, secret-safety, and launch/auth parity implications are considered
- [ ] Any new operational burden is documented or called out

## Severity Guidance

Use severity based on user impact and release risk:
- `CRITICAL`: auth/payment/security break, data exposure, entitlement corruption, release blocker
- `HIGH`: likely user-facing regression in core flow, broken recovery path, major reliability risk
- `MEDIUM`: meaningful gap, weak guardrail, or missing validation that could hide a real bug

## Output Format

Use this structure:

```markdown
## Findings
1. [CRITICAL/HIGH/MEDIUM] [Issue title]
   - Location: path:line
   - Evidence: ...
   - Why it matters: ...
   - Suggested fix: ...

## Open Questions
- ...

## Residual Risk
- ...

## Backlog Additions (only if new)
- [item + one-line DoD]
```
