---
description: Verify app ready for store submission
argument-hint: [app-name]
---

# /pre-launch - Pre-Launch Verification

**CRITICAL INSTRUCTIONS - READ FIRST:**
- Do NOT use the EnterPlanMode tool
- Do NOT save anything to ~/.claude/plans/
- Output ALL verification results directly in this conversation as markdown

Verify the app is ready for App Store / Play Store submission.

## Usage
```
/pre-launch [app-name]
```

**Example:**
- `/pre-launch prosepal`

## Verification Steps

### 1. Code Quality
```bash
flutter analyze
flutter test
dart format --set-exit-if-changed .
```

### 2. Critical Issues Check
- [ ] No CRITICAL items open in `docs/BACKLOG.md`
- [ ] All P0 items resolved
- [ ] No hardcoded test/debug values in release code

### 3. Security Verification
- [ ] API keys via dart-define (not hardcoded)
- [ ] ProGuard/R8 enabled for Android release
- [ ] HTTPS-only enforced
- [ ] Debug logging disabled in release
- [ ] `*.jks` and `*.keystore` in .gitignore
- [ ] No secrets in git history (`git log -p | grep -i "secret\|key\|password"`)

### 3b. Database Security (Supabase)
- [ ] RLS enabled on ALL tables
- [ ] Sensitive tables (user_usage, user_entitlements) block direct writes
- [ ] Edge function CORS restricted (not wildcard in production)
- [ ] Webhook secrets configured
- [ ] Leaked password protection enabled (if on paid plan)

### 4. Store Requirements

**iOS (App Store Connect):**
- [ ] Bundle ID matches everywhere
- [ ] App icons at all required sizes
- [ ] Privacy policy URL configured
- [ ] App Store screenshots ready
- [ ] Privacy nutrition labels accurate
- [ ] Sign in with Apple works (if Google auth exists)

**Android (Play Console):**
- [ ] Package name matches everywhere
- [ ] Signing key configured
- [ ] Privacy policy URL in store listing
- [ ] Target API level meets Play Store requirements
- [ ] Data safety section accurate

### 5. Functionality Verification
- [ ] Fresh install flow works
- [ ] Sign in (all providers) works
- [ ] Core feature works end-to-end
- [ ] Purchase flow works (sandbox)
- [ ] Restore purchases works
- [ ] Account deletion works

### 6. Documentation
- [ ] App Store ID added to code (after approval)
- [ ] Version bumped in pubspec.yaml
- [ ] BACKLOG.md updated with any deferred items

## Reference
Full checklist: `docs/LAUNCH_CHECKLIST.md`
