# ProsePal — Direction A: Apple-native minimalist

> The system at its calmest. System controls, hairlines, generous air, one clay action per screen — a refined first-party Apple app. The writing surface uses the **native sans** (`--canvas-font: var(--font-ui)`) so it feels iOS-native rather than literary.

**Screens:** `index.html` shows five on a pannable rail — Welcome · Workspace · Draft result · Refine · Upgrade.

**Files**
- `index.html` — the direction theme (`.dir-*` CSS-variable overrides + direction-specific classes) and page.
- `screens.jsx` — the five screen recreations (cosmetic; composed from the `.pp-*` system).
- Shares `../_shared/frame.jsx` (phone shell, status/nav/tab) and `../_shared/kit.css`.

**Theme.** Default tokens, unchanged. Only override: `--canvas-font: var(--font-ui)`.

**When to choose it.** The safest premium-calm production bet. Choose when ProsePal should disappear and let the writing lead.

> Recreation for comparison & SwiftUI handoff — not production logic. See `../README.md` for the full comparison.
