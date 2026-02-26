---
description: Generate pull request with description
argument-hint: [base-branch]
---

# /pr - Create Pull Request

Generate a pull request for the current branch with auto-generated description.

## Usage
```
/pr           # PR to main
/pr develop   # PR to develop branch
```

## Process

1. **Analyze changes** from base branch
2. **Generate PR title** (concise, imperative)
3. **Generate description** with:
   - Summary (what changed)
   - Key changes (bullet points)
   - Testing notes
4. **Create PR** via `gh pr create`

## Output Format

```bash
gh pr create --title "Add biometric authentication" --body "$(cat <<'EOF'
## Summary
Added Face ID/Touch ID support for app unlock.

## Changes
- BiometricService with local_auth integration
- Lock screen with retry handling
- Settings toggle for biometric preference

## Testing
- [x] Face ID unlock works
- [x] Fallback to PIN works
- [x] Settings toggle persists

🤖 Generated with Claude Code
EOF
)"
```

## Notes
- Commits should already be pushed to remote
- Uses GitHub CLI (`gh`) - must be authenticated
- Won't force push or modify history
