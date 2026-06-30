# ProsePal — Direction E: Modern AI productivity, elegant

> Fast and capable without feeling like a dashboard. Structured sections, **multiple ranked options**, light quality signals (clarity/warmth meters), and a supporting **ink-blue** — all kept warm by the clay system and humane copy.

**Screens:** `index.html` shows five on a pannable rail — Welcome · Workspace · Draft result · Refine · Upgrade.

**Files**
- `index.html` — the direction theme (`.dir-*` CSS-variable overrides + direction-specific classes) and page.
- `screens.jsx` — the five screen recreations (cosmetic; composed from the `.pp-*` system).
- Shares `../_shared/frame.jsx` (phone shell, status/nav/tab) and `../_shared/kit.css`.

**Theme.** `--radius-card: 18px`, `--canvas-font: var(--font-ui)`. Direction CSS adds `.e-card/.e-seg/.e-chip/.e-compare/.e-plan` etc. Ink-blue (`--info`) marks 'Recommended' and data.

**When to choose it.** The everyday-driver. Choose when throughput and feature density matter but you still want elegance.

> Recreation for comparison & SwiftUI handoff — not production logic. See `../README.md` for the full comparison.
