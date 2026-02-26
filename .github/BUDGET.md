# GitHub Actions Budget (Free Tier - Private Repos)

## Monthly Allowance: 2,000 minutes

## Multipliers
| Runner | Multiplier | Example |
|--------|------------|---------|
| Linux | 1x | 5 mins = 5 mins |
| macOS | 10x | 5 mins = 50 mins |
| Windows | 2x | 5 mins = 10 mins |

## Per-Push Cost (main branch)

| Job | Runner | Time | Billed |
|-----|--------|------|--------|
| Analyze & Test | Linux | ~2 min | 2 min |
| Build iOS | macOS | ~8 min | 80 min |
| Build Android | Linux | ~5 min | 5 min |
| **Total** | | | **~87 min** |

## Per-PR Cost

| Job | Runner | Time | Billed |
|-----|--------|------|--------|
| Analyze & Test | Linux | ~2 min | 2 min |
| **Total** | | | **~2 min** |

## Monthly Estimates

| Scenario | Pushes/PRs | Cost | Remaining |
|----------|------------|------|-----------|
| Light (10 pushes, 5 PRs) | 10 + 5 | 880 min | 1,120 min |
| Medium (20 pushes, 10 PRs) | 20 + 10 | 1,760 min | 240 min |
| Heavy (30 pushes, 15 PRs) | 30 + 15 | 2,640 min | ⚠️ Over! |

## Tips to Save Minutes

1. **Batch commits** - Push once with multiple commits, not per-commit
2. **Draft PRs** - CI doesn't run on draft PRs
3. **Skip CI** - Add `[skip ci]` to commit message for docs-only changes
4. **Local testing** - Run `flutter analyze && flutter test` before pushing

## Emergency: Disable iOS builds temporarily

Change `if:` condition in ci.yml:
```yaml
if: false  # Temporarily disabled
```
