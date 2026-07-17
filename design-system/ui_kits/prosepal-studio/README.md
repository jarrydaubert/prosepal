# ProsePal — Direction D: Calm private writing studio

> A focus mode for words that matter. **Dark-first** warm charcoal, near-monochrome with one clay accent. Chrome recedes to a minimal top bar and a floating dock; the page is the experience. Private by design.

**Screens:** `index.html` shows five on a pannable rail — Welcome · Workspace · Draft result · Refine · Upgrade.

**Files**
- `index.html` — the direction theme (`.dir-*` CSS-variable overrides + direction-specific classes) and page.
- `screens.jsx` — the five screen recreations (cosmetic; composed from the `.pp-*` system).
- Shares `../_shared/frame.jsx` (phone shell, status/nav/tab) and `../_shared/kit.css`.

**Theme.** Each screen wraps content in `[data-theme="dark"]`. `.d-screen` fills the frame; `.d-write` is full-screen serif; `.d-dock` floats actions; `.d-bar` is minimal chrome.

**When to choose it.** The most distinctive and intimate. Choose for a premium, distraction-free positioning.

> Recreation for comparison & SwiftUI handoff — not production logic. See `../README.md` for the full comparison.
