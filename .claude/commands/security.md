---
description: Security-focused review with OWASP checklist
argument-hint: [scope]
---

# /security - Security Review

**CRITICAL INSTRUCTIONS - READ FIRST:**
- Do NOT use the EnterPlanMode tool
- Do NOT save anything to ~/.claude/plans/
- Do NOT create any files
- Output ALL findings directly in this conversation as markdown

Run a security-focused review of the codebase or specific area.

**Rules:**
- DO NOT write or modify code
- OUTPUT directly in the chat response
- DO identify vulnerabilities and risks
- DO recommend fixes with specific guidance
- DO reference file locations and line numbers
- LEAVE implementation to the builder session

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
- [ ] API keys not hardcoded (use dart-define or Remote Config)
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
- [ ] Consider second AI audit for critical flows

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

```
## Security Findings

### Critical
- [Issue]: [Location] - [Impact] - [Fix]

### High
...

### Recommendations
...
```

Reference: `docs/BACKLOG.md` Architecture Audit section for known issues.
