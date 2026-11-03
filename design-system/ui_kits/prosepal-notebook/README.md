# ProsePal — Direction B: Warm literary notebook

> For writing something that matters. Creamier paper, a deeper ink-clay accent, the user's words set in **serif on faint ruled lines**, and editor's **margin notes**. Literary with zero quill/parchment cliché.

**Screens:** `index.html` shows five on a pannable rail — Welcome · Workspace · Draft result · Refine · Upgrade.

**Files**
- `index.html` — the direction theme (`.dir-*` CSS-variable overrides + direction-specific classes) and page.
- `screens.jsx` — the five screen recreations (cosmetic; composed from the `.pp-*` system).
- Shares `../_shared/frame.jsx` (phone shell, status/nav/tab) and `../_shared/kit.css`.

**Theme.** Cream `--bg`/`--surface`, deeper `--accent` (oklch 0.52 0.11 40), `--canvas-font` serif, `--radius-card: 16px`. Plus `.nb-page` (ruled lines via repeating gradient), `.nb-draft` (warm left margin rule), `.nb-margin` (annotation).

**When to choose it.** The most on-brand for 'a writing companion, not a chatbot.' Great for heartfelt/long-form messages.

> Recreation for comparison & SwiftUI handoff — not production logic. See `../README.md` for the full comparison.
