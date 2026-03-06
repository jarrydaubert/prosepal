---
description: Deep security review using Prosepal's threat model and release constraints
argument-hint: [scope]
---

# /sec-review - Security Review

Run a deep security review of the codebase or a specific area, using Prosepal's actual threat model and release constraints.

Rules:
- Do not write or modify code in this mode.
- Output findings directly in chat.
- Findings must be prioritized by exploitability and impact.
- Reference file locations and lines.
- Read the relevant security source-of-truth docs first:
  - `AGENTS.md`
  - `docs/SECURITY.md`
  - `docs/DEVOPS.md`
  - `docs/NEXT_RELEASE_BRIEF.md`
  - `docs/IDENTITY_MAPPING.md`
  - `docs/REVENUECAT_POLICY.md`
  - `docs/REMOTE_CONFIG.md`
  - `docs/BACKLOG.md`
- Report only new, regressed, or still-unmitigated risks.
- Prefer concrete evidence from code, scripts, workflows, config, and tests.
- If no findings are discovered, say so explicitly and list residual risk or unverified surfaces.

## Usage
```
/sec-review [scope]
```

**Examples:**
- `/sec-review` - Full security sweep
- `/sec-review auth` - Focus on authentication
- `/sec-review api` - Focus on API/network layer

## Review Approach

1. Map the scope to the repo threat model:
   - auth/account takeover
   - payment/entitlement integrity
   - AI abuse/cost controls
   - data exposure/logging/privacy
   - repo/workflow secret safety
2. Inspect real enforcement points:
   - client code
   - Supabase policies/functions
   - RevenueCat flows
   - Firebase/App Check/Remote Config assumptions
   - workflows/scripts
3. Verify both prevention and containment:
   - guardrails
   - kill switches
   - logging/diagnostics
   - rollback paths

## Security Checklist

### Authentication & Authorization
- [ ] Auth state checked before protected routes
- [ ] Session handling (refresh, expiry, logout scope)
- [ ] OAuth flows use nonce/state parameters
- [ ] Biometric authentication properly gated
- [ ] Social-only auth policy is preserved where intended
- [ ] Sensitive operations use the intended re-auth path
- [ ] Auth failures do not leak sensitive provider details

### Data Protection
- [ ] Sensitive data encrypted at rest (use flutter_secure_storage)
- [ ] No PII in logs or crash reports
- [ ] HTTPS enforced (network_security_config, ATS)
- [ ] Input sanitized before use in queries/prompts
- [ ] Support diagnostics redact tokens and sensitive user content
- [ ] Analytics/Crashlytics user identity is set/cleared correctly
- [ ] User content is not emitted to telemetry unintentionally

### API Security
- [ ] API keys not hardcoded in repo
- [ ] Public keys have API/app restrictions (bundle/package/SHA/referrer as applicable)
- [ ] Rate limiting implemented
- [ ] Request/response validation
- [ ] Server-synced timestamps use UTC (rate limiting, usage tracking, session expiry)
- [ ] Timeouts prevent hanging
- [ ] AI provider posture matches App Check and abuse-control expectations
- [ ] Release/runtime config cannot silently weaken protections

### Client Security
- [ ] Code obfuscation enabled (ProGuard/R8)
- [ ] Debug features disabled in release
- [ ] Screenshot prevention where needed
- [ ] Deep links validated before navigation
- [ ] iOS/Android release builds do not rely on unsafe/manual config paths
- [ ] No client-side-only enforcement for premium-critical behavior

### Database/Backend Security (Supabase)
- [ ] RLS enabled on ALL tables
- [ ] No permissive INSERT/UPDATE policies on sensitive tables (user_usage, entitlements)
- [ ] Sensitive writes via RPC only (SECURITY DEFINER functions)
- [ ] Direct table grants match RLS intent (no GRANT INSERT/UPDATE if RPC-only)
- [ ] Anonymous (`anon`) role has minimal permissions
- [ ] Service role key only used server-side (edge functions)
- [ ] Edge functions validate JWT before operations
- [ ] Webhook endpoints validate shared secrets
- [ ] CORS not using wildcard in production edge functions
- [ ] Free-tier abuse controls remain server-authoritative where intended
- [ ] Account deletion path enforces auth and performs safe cleanup

### Identity / Payments / Entitlements
- [ ] RevenueCat App User ID policy matches `docs/REVENUECAT_POLICY.md`
- [ ] Anonymous purchase -> login reconciliation is correct
- [ ] User switch / sign-out returns RevenueCat to persisted anonymous ID
- [ ] Entitlement refresh points match documented policy
- [ ] Identity mapping matches `docs/IDENTITY_MAPPING.md` across Supabase, RevenueCat, Analytics, and Crashlytics
- [ ] Diagnostics would reveal identity divergence clearly

### AI / Remote Config / Abuse Controls
- [ ] Remote Config keys and schema assumptions match `docs/REMOTE_CONFIG.md`
- [ ] `ai_enabled`, `paywall_enabled`, and `premium_enabled` kill switches exist and are respected
- [ ] `ai_model` and fallback models are allowlisted and pinned appropriately
- [ ] No secrets are stored in Remote Config
- [ ] App Check posture is not weakened on AI-critical flows
- [ ] Abuse/cost controls remain aligned with `docs/DEVOPS.md`

### Repository / CI / Release Security
- [ ] Secret-history protections are in place and relevant changes respect them
- [ ] Workflow security posture matches `docs/DEVOPS.md` (pinned actions, token permissions, selected actions only)
- [ ] CodeQL / workflow scanning coverage remains intact where relevant
- [ ] Release preflight would still block missing or placeholder runtime config
- [ ] Public-repo hygiene is preserved for new files, scripts, and docs

### Architecture Best Practices
- [ ] Premium features enforced server-side (not just hidden in UI)
- [ ] Sensitive logic server-side (pricing, credits, usage counting)
- [ ] Scan release bundles/APKs for leaked keys before publish
- [ ] Dependencies up to date (check `flutter pub outdated`)
- [ ] No trust boundary is crossed accidentally by convenience logic
- [ ] Error, fallback, and retry paths fail secure

### OWASP Mobile Top 10
1. Improper Platform Usage
2. Insecure Data Storage
3. Insecure Communication
4. Insecure Authentication
5. Insufficient Cryptography
6. Insecure Authorization
7. Client Code Quality
8. Code Tampering
9. Reverse Engineering
10. Extraneous Functionality

## Output Format

```markdown
## Security Findings
1. [CRITICAL/HIGH/MEDIUM] [Issue title]
   - Location: path:line
   - Evidence: ...
   - Impact: ...
   - Fix: ...

## Open Questions
- ...

## Residual Risk
- ...

## Backlog Additions (only if new)
- [item + one-line DoD]
```
