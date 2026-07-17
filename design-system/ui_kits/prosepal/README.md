# ProsePal — ★ The direction (B ∩ C)

> *A warm literary writing companion inside a premium modern iOS interface.* This is where ProsePal landed after the five-direction exploration — the blend of **B (Warm literary notebook)** and **C (Premium glassy iOS 26)**.

**Open `index.html`** for the canonical screen kit on a pannable rail: onboarding, writing, result/revise, library/history, account/system, and states.

## The blend, in one rule

| Layer | Treatment |
|---|---|
| **The writing** (note, draft, revise) | **Literary.** Serif (Newsreader/New York) on warm cream paper, faint ruled lines, a clay margin rule. **Opaque and crisp — never glass.** The writing is always the hero; text must stay razor-sharp. |
| **Everything that floats** (nav, dock, refine bar, tone chips, popover, plan cards) | **Premium glass.** Warm-tinted frost (`backdrop-filter`), light top edge, soft warm shadow — C's material, warmed toward cream. |
| **Accent** | B's deeper ink-clay (`oklch(0.520 0.110 40)`). |
| **The wash** behind the glass | Warm amber/cream with a whisper of sage — literary and calm, **not** the techy peach-pink of a generic glass UI. |

## Files
- `index.html` — the `.dir-prosepal` theme (token overrides + the literary/glass classes) and page.
- `screens-1.jsx` through `screens-4.jsx` — the screen recreations (cosmetic; built from the `.pp-*` system + the kit classes).
- Shares `../_shared/frame.jsx` (phone shell) and `../_shared/kit.css`.

## SwiftUI handoff

The `.dir-prosepal` block **is** the production theme — translate it directly:

- **Colors** → a theme struct: `--bg` (cream paper), `--surface`, `--accent` ink-clay, `--accent-soft`, separators. Plus the `--glass-*` set for `.ultraThinMaterial`-style surfaces (use SwiftUI `Material` + a warm tint overlay).
- **Writing surface** → `--canvas-font: New York`, 19px, line-height 34, the ruled-line background, the 3px leading clay rule, opaque.
- **Glass chrome** → `.regularMaterial` / `.ultraThinMaterial` with a warm tint, hairline light stroke, the soft warm shadow. Use for the nav bar, the floating dock, the refine bar, tone chips, the suggestion popover, and plan cards.
- **The wash** → a `LinearGradient` + a few low-opacity radial `RadialGradient`s behind the glass (warm amber, soft clay, a sage whisper).
- **Radius** → cards 20, pages 18, chips/dock capsule.

> Recreation for comparison & handoff — not production logic. See `../README.md` for how this relates to the A–E exploration.
