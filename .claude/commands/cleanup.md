---
description: Find dead code, unused imports, and stale dependencies in the Flutter codebase
---

# /cleanup - Dead Code & Dependency Audit

Find unused code, stale dependencies, and dead imports across the Flutter codebase.

Rules:
- Do not modify code in this mode.
- Output findings directly in chat.
- Prioritize high-confidence removals first.
- Do not report generated-code false positives.
- Cross-check known cleanup items in `docs/BACKLOG.md` and only add new items when needed.

## Scan Scope

### Directories to Audit
- `lib/app/` — App config, router, providers
- `lib/core/` — Services, models, constants
- `lib/features/` — Feature modules (screens, widgets, providers)
- `lib/shared/` — Shared widgets, theme, utilities
- `test/` — Test files (check for orphaned tests)

### Files to Ignore
- `.dart_tool/` — Dart tooling (generated)
- `build/` — Build outputs
- `*.g.dart` — json_serializable generated files
- `*.freezed.dart` — Freezed generated files
- `firebase_options.dart` — FlutterFire CLI generated
- `*.gen.dart` — Any other code-gen output

### Convention Entrypoints (Never Flag as Unused)
- `main.dart` — App entrypoint
- `**/barrel.dart` or `**/*_barrel.dart` — Barrel exports
- `lib/app/router.dart` — Route definitions
- `lib/app/providers.dart` — Root providers
- Files registered in `pubspec.yaml` assets

## Audit Checklist

### 1. Unused Imports
- Scan all `.dart` files in `lib/` for unused imports
- Run `flutter analyze` and extract unused-import warnings
- Flag imports that are only used in comments

### 2. Unused Code
- Classes, functions, variables, and mixins with no references
- Private members (`_name`) never used outside their file
- Public members never imported by any other file
- Dead feature flags or constants
- Unreachable code after early returns

### 3. Unused Dependencies
- Run `flutter pub deps` to list dependency tree
- Cross-reference `pubspec.yaml` dependencies with actual imports in `lib/`
- Flag packages declared but never imported
- Run `flutter pub outdated` to check for stale versions

### 4. Orphaned Tests
- Test files in `test/` with no corresponding source file in `lib/`
- Test files that import deleted or renamed classes
- Empty test files or test files with only skipped tests

### 5. Stale Barrel Exports
- Barrel files re-exporting symbols that no longer exist
- Barrel files exporting symbols not imported by any consumer

### 6. Dead Routes
- Routes defined in `router.dart` that no navigation action references
- Named routes never used in `context.go()`, `context.push()`, etc.

## False Positive Rules

Do NOT flag these as dead code:
- **Generated files** (`*.g.dart`, `*.freezed.dart`) — they reference source annotations
- **Provider overrides in test/** — used at test runtime even if no import chain from `lib/`
- **Barrel re-exports** — unless the exported symbol itself is dead
- **Riverpod providers** — may be referenced via `ref.watch()` / `ref.read()` dynamically
- **Extension methods** — may be used implicitly via imports
- **`@visibleForTesting` members** — used only in test/ by design

## Output Format

Use this structure:

```markdown
## Cleanup Findings
1. [HIGH/MEDIUM/LOW] [Issue title]
   - Type: unused import / dead code / unused dep / orphaned test / dead route
   - Location: path:line
   - Confidence: high/medium
   - Safe action: ...

## Quick Wins
- ...

## Backlog Additions (only if new)
- [item + one-line DoD]
```
