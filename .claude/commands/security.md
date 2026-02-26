---
description: Security-focused review with OWASP checklist
argument-hint: [scope]
---

# /security - Security Review

Run a security-focused review of the codebase or specific area.

Rules:
- Do not write or modify code in this mode.
- Output findings directly in chat.
- Findings must be prioritized by exploitability and impact.
- Reference file locations and lines.
- Cross-check known items in `docs/BACKLOG.md` and report only new/regressed risks.

## Usage
```
/security [scope]
```

**Examples:**
- `/security` - Full security sweep
- `/security auth` - Focus on authentication
- `/security api` - Focus on API/network layer

## Security Checklist

### Authentication & Authorization
- [ ] Auth state checked before protected routes
- [ ] Session handling (refresh, expiry, logout scope)
- [ ] OAuth flows use nonce/state parameters
- [ ] Biometric authentication properly gated

### Data Protection
- [ ] Sensitive data encrypted at rest (use flutter_secure_storage)
- [ ] No PII in logs or crash reports
- [ ] HTTPS enforced (network_security_config, ATS)
- [ ] Input sanitized before use in queries/prompts

### API Security
- [ ] API keys not hardcoded in repo
- [ ] Public keys have API/app restrictions (bundle/package/SHA/referrer as applicable)
- [ ] Rate limiting implemented
- [ ] Request/response validation
- [ ] Timeouts prevent hanging

### Client Security
- [ ] Code obfuscation enabled (ProGuard/R8)
- [ ] Debug features disabled in release
- [ ] Screenshot prevention where needed
- [ ] Deep links validated before navigation

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

### Architecture Best Practices
- [ ] No direct client-to-database connections (use middleware/RPC/edge functions)
- [ ] Premium features enforced server-side (not just hidden in UI)
- [ ] Sensitive logic server-side (pricing, credits, usage counting)
- [ ] Scan release bundles/APKs for leaked keys before publish
- [ ] Dependencies up to date (check `flutter pub outdated`)
- [ ] App Check / abuse controls aligned with `docs/DEVOPS.md`

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
   - Impact: ...
   - Fix: ...

## Residual Risk
- ...

## Backlog Additions (only if new)
- [item + one-line DoD]
```
