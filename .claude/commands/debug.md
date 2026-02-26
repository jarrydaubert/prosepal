---
description: Systematic debugging session
argument-hint: [issue description]
---

# /debug - Debugging Session

**CRITICAL INSTRUCTIONS - READ FIRST:**
- Do NOT use the EnterPlanMode tool
- Do NOT save anything to ~/.claude/plans/
- Output ALL findings directly in this conversation as markdown

Start a systematic debugging session for an issue.

## Usage
```
/debug app crashes on launch
/debug auth not persisting after restart
/debug payment flow stuck on loading
```

## Debugging Process

### 1. Reproduce
- What are the exact steps?
- Does it happen consistently?
- What environment? (device, OS, build type)

### 2. Isolate
- When did it start working/breaking?
- What changed recently?
- Is it code, config, or external service?

### 3. Investigate
- Check logs (Crashlytics, console)
- Add strategic print statements
- Test with minimal reproduction

### 4. Hypothesize
Form 2-3 hypotheses ranked by likelihood:

| Hypothesis | Likelihood | How to Test |
|------------|------------|-------------|
| A: ... | High | ... |
| B: ... | Medium | ... |
| C: ... | Low | ... |

### 5. Test & Fix
- Test most likely hypothesis first
- Make minimal changes
- Verify fix doesn't break other things

### 6. Document
- What was the root cause?
- Should we add a test?
- Should we add logging?

## Useful Commands

```bash
# Flutter logs
flutter logs

# Run with verbose
flutter run -v

# Analyze for issues
flutter analyze

# Check for outdated deps
flutter pub outdated
```

## Common Culprits

| Symptom | Often Caused By |
|---------|-----------------|
| Crash on launch | Missing config, null safety, async init |
| Auth issues | Token expiry, session scope, keychain |
| Payment issues | Sandbox vs prod, entitlement ID, RC config |
| State issues | Provider lifecycle, missing dispose, race condition |
| RPC failures | RLS policy blocking, missing function grant |
| Edge function errors | Invalid JWT, missing env vars, CORS |

## Backend Debugging (Supabase)

```bash
# Check edge function logs
supabase functions logs [function-name]

# Check database logs (Dashboard > Logs > Postgres)
# Look for: RLS policy violations, query errors

# Test RPC as authenticated user (SQL Editor)
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub": "user-uuid-here"}';
SELECT * FROM your_rpc_function();
```

## Output Format

```markdown
## Debug: [Issue]

### Reproduction
1. [Step 1]
2. [Step 2]
→ Expected: [X]
→ Actual: [Y]

### Investigation
- Checked: [what you looked at]
- Found: [what you discovered]

### Root Cause
[The actual problem]

### Fix
[What to change]

### Prevention
- [ ] Add test for this case
- [ ] Add logging for early detection
```
