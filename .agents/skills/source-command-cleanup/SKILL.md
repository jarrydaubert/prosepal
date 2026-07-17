---
name: source-command-cleanup
description: Find dead native code, stale dependencies, and orphaned surfaces
---

# Source Command Cleanup

Use this skill when the user asks to run the migrated source command `cleanup`.

Run a read-only cleanup audit of the native Swift package, Xcode targets,
Supabase backend, scripts, tests, and active documentation. Do not modify code.
Prioritize high-confidence removals, cite reference searches, and cross-check
`docs/BACKLOG.md` before proposing new work.

Inspect:

- `prosepal-ios/Sources/` and `prosepal-ios/Tests/`;
- app, widget, share-extension, and control targets;
- `supabase/functions/`, migrations, and tests;
- `scripts/` and `.github/workflows/`;
- active docs and repo-local agent instructions.

Look for unused declarations, files, assets, localization keys, dependencies,
navigation surfaces, tests, scripts, config keys, RPCs, edge paths, and stale
architecture references. Do not flag Apple/Xcode convention entry points,
SwiftUI previews, protocol witnesses, generated output, migration history, or
archived docs merely because static search cannot see runtime registration.

Use `rg`, compiler diagnostics, package/Xcode configuration, and tests together;
a text search alone is not proof of dead code.

Report each finding with severity, type, location, evidence, confidence, and a
safe action. Add only genuinely new work to the backlog.
