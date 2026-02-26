---
description: Deep code/architecture audit of a system or file
argument-hint: [target]
---

# /audit - Deep Code Audit

Run a comprehensive audit of the specified system or file.

Rules:
- Do not write or modify code in this mode.
- Output findings directly in chat.
- Prioritize bug/regression/risk findings over style opinions.
- Reference file locations and lines.
- Cross-check against `docs/BACKLOG.md` and only raise new or regressed issues.

## Usage
```
/audit [target]
```

**Examples:**
- `/audit auth` - Audit authentication system
- `/audit payments` - Audit subscription/RevenueCat integration
- `/audit lib/core/services/ai_service.dart` - Audit specific file

## Audit Checklist (Risk First)

When auditing, focus on:

### Security
- [ ] Input validation and sanitization
- [ ] Auth state verified before sensitive operations
- [ ] No hardcoded secrets
- [ ] Error messages don't leak internal details
- [ ] Rate limiting in place

### Resilience
- [ ] Timeouts on network calls
- [ ] Graceful degradation on service failure
- [ ] Retry logic with backoff where appropriate
- [ ] Offline behavior handled

### Best Practices
- [ ] Follows existing patterns in codebase
- [ ] Proper error typing (not generic catch)
- [ ] Resources disposed properly
- [ ] Tests exist for critical paths
- [ ] Behavior changes include updated tests

### Database/Backend (Supabase)
- [ ] RLS policies match intended access patterns
- [ ] Sensitive tables use RPC-only writes (no direct INSERT/UPDATE)
- [ ] Table grants don't exceed RLS intent
- [ ] Edge functions validate auth before operations
- [ ] No service_role key in client code

### Release Readiness
- [ ] Change aligns with release constraints in `docs/NEXT_RELEASE_BRIEF.md`
- [ ] Operational implications align with `docs/DEVOPS.md`

## Output Format

Use this structure:

```markdown
## Findings
1. [CRITICAL/HIGH/MEDIUM] [Issue title]
   - Location: path:line
   - Why it matters: ...
   - Suggested fix: ...

## Open Questions
- ...

## Backlog Additions (only if new)
- [item + one-line DoD]
```
