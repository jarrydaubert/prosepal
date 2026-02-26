---
description: Deep code/architecture audit of a system or file
argument-hint: [target]
---

# /audit - Deep Code Audit

**CRITICAL INSTRUCTIONS - READ FIRST:**
- Do NOT use the EnterPlanMode tool
- Do NOT save anything to ~/.claude/plans/
- Do NOT create any files
- Output ALL audit findings directly in this conversation as markdown

Run a comprehensive audit of the specified system or file.

**Rules:**
- DO NOT write or modify code
- OUTPUT directly in the chat response
- DO identify issues, anti-patterns, and improvements
- DO reference file locations and line numbers
- LEAVE implementation to the builder session

## Usage
```
/audit [target]
```

**Examples:**
- `/audit auth` - Audit authentication system
- `/audit payments` - Audit subscription/RevenueCat integration
- `/audit lib/core/services/ai_service.dart` - Audit specific file

## Audit Checklist

When auditing, check for:

### Security
- [ ] Input validation and sanitization
- [ ] Auth state verified before sensitive operations
- [ ] No hardcoded secrets (use dart-define)
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

### Database/Backend (Supabase)
- [ ] RLS policies match intended access patterns
- [ ] Sensitive tables use RPC-only writes (no direct INSERT/UPDATE)
- [ ] Table grants don't exceed RLS intent
- [ ] Edge functions validate auth before operations
- [ ] No service_role key in client code

### Blueprint Impact
- [ ] Would this change be good for all future apps?
- [ ] Is it documented if non-obvious?
- [ ] Does it match `docs/ARCHITECTURE.md` patterns?

## Output Format

Provide findings as:

| Issue | Severity | Location | Recommendation |
|-------|----------|----------|----------------|
| ... | CRITICAL/HIGH/MEDIUM/LOW | file:line | ... |

Cross-reference against `docs/BACKLOG.md` - don't re-report known issues unless they've regressed.
