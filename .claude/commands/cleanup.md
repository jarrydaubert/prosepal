---
description: Find dead native code, stale dependencies, and orphaned surfaces
argument-hint: [scope]
---

# /cleanup - Dead Code and Dependency Audit

Run a read-only cleanup audit of the native Swift package, Xcode targets,
Supabase backend, scripts, tests, and active documentation.

## Rules

- Do not modify code in this mode.
- Prioritize high-confidence removals and cite every reference search performed.
- Do not flag Apple/Xcode convention entry points, SwiftUI previews, protocol
  witnesses, generated build output, migration history, or archived docs as
  unused merely because static search cannot see their runtime registration.
- Cross-check `docs/BACKLOG.md`; propose only new work.

## Scope

- `prosepal-ios/Sources/` and `prosepal-ios/Tests/`
- Xcode app, widget, share-extension, and control targets
- `supabase/functions/`, `supabase/migrations/`, and their tests
- `scripts/` and `.github/workflows/`
- active `docs/`, `.claude/commands/`, and `.agents/skills/`

## Checklist

- Unused imports, private declarations, files, assets, and localization keys.
- Protocol methods or service boundaries with no caller or test.
- Dead SwiftUI navigation destinations, controls, sheets, and extension entry
  points.
- Package or target dependencies that are declared but unused.
- Orphaned tests and source-grep tests that should become behavioral coverage.
- Superseded scripts, workflow steps, config keys, RPCs, and edge-function paths.
- Active docs or agent instructions that reference archived architecture.

Use `rg`/`rg --files`, compiler diagnostics, package/Xcode configuration, and
tests together; a text search alone is not proof of dead code.

## Output

```markdown
## Cleanup Findings
1. [HIGH/MEDIUM/LOW] Issue title
   - Type: dead code / dependency / route / test / script / documentation
   - Location: path:line
   - Evidence: ...
   - Confidence: high/medium
   - Safe action: ...

## Quick Wins
- ...

## Backlog Additions (new work only)
- [item and testable definition of done]
```
