# ProsePal — Direction C: Premium glassy iOS 26

> Liquid-glass surfaces — translucent panels, real backdrop blur, light edge strokes — floating over a soft **warm wash**. Modern and tactile, kept calm by low chroma and the same clay accent.

**Screens:** `index.html` shows five on a pannable rail — Welcome · Workspace · Draft result · Refine · Upgrade.

**Files**
- `index.html` — the direction theme (`.dir-*` CSS-variable overrides + direction-specific classes) and page.
- `screens.jsx` — the five screen recreations (cosmetic; composed from the `.pp-*` system).
- Shares `../_shared/frame.jsx` (phone shell, status/nav/tab) and `../_shared/kit.css`.

**Theme.** `--g-wash` (warm radial-gradient stack) behind everything; `.g-panel/.g-nav/.g-tab/.g-chip/.g-plan` use `--glass-*` tokens (`backdrop-filter: var(--glass-blur)`). `--radius-card: 24px`.

**When to choose it.** The most forward-looking. Depends on real material blur — verify on-device. Beautiful for a flagship feel.

> Recreation for comparison & SwiftUI handoff — not production logic. See `../README.md` for the full comparison.
