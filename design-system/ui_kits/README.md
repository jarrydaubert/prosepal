# ProsePal — Visual directions

> **★ Decided direction (B ∩ C): `prosepal/`** — *a warm literary writing companion inside a premium modern iOS interface.* The five lettered directions below were the exploration; this is where it landed. Open **`prosepal/index.html`** for the canonical screen kit.

## The blend, in one rule

- **The writing is literary.** Serif prose on warm cream paper, faint ruled lines, a clay margin rule. Opaque, crisp, the hero — **never glass** (text must stay razor-sharp).
- **Everything that floats over it is glass.** Nav, dock, refine bar, tone chips, popovers, plan cards — warm-tinted frost, light edge, soft shadow.
- **Accent** is B's deeper ink-clay. **The wash** behind the glass is warm amber/cream with a whisper of sage — literary and calm, never the techy peach-pink of a generic glass UI.

`prosepal/` is `{ index.html, screens-1.jsx ... screens-4.jsx, README.md }`. Its `.dir-prosepal` block is the production theme — hand the token overrides (`--bg`, `--accent`, the `--glass-*` set, `--canvas-font`, the `--pp-wash`) straight to a SwiftUI theme struct.

---

## The exploration (archived for reference)

Five distinct visual directions for ProsePal, built on **one shared foundation** (`/styles.css` + the `.pp-*` components). Each direction is a theme — a small set of CSS-variable overrides on a `.dir-*` wrapper, plus a little direction-specific CSS — so the same components restyle automatically. Open each `index.html` to see five screens (welcome → workspace → draft → refine → upgrade) on a pannable rail.

| | Direction | Folder | The idea | Fed into the blend |
|---|---|---|---|---|
| **A** | Apple-native minimalist | `prosepal-minimalist/` | Maximum restraint; first-party Apple feel. | restraint, hairlines |
| **B** | Warm literary notebook | `prosepal-notebook/` | Cream paper, serif on ruled lines, margin notes. | **the writing soul** ★ |
| **C** | Premium glassy iOS 26 | `prosepal-glass/` | Translucent glass over a soft warm wash. | **the glass chrome** ★ |
| **D** | Calm private writing studio | `prosepal-studio/` | Dark-first focus mode. | — |
| **E** | Modern AI productivity, elegant | `prosepal-modern/` | Structured sections, ranked options. | — |

## How to read these

Each archived exploration folder is `{ index.html, screens.jsx }`; the decided `prosepal/` kit uses `{ index.html, screens-1.jsx ... screens-4.jsx, README.md }`. All kits share `../_shared/{frame.jsx, kit.css}` (the phone shell + page chrome). The screens are cosmetic recreations — buttons don't route — meant for **comparison and SwiftUI handoff**, not production logic.

## How theming works (for the developer)

The whole point: pick a direction and you mostly change tokens, not components. Example (Direction B):

```css
.dir-notebook {
  --bg: oklch(0.957 0.018 80);      /* creamier paper      */
  --accent: oklch(0.520 0.110 40);  /* deeper ink-clay     */
  --canvas-font: var(--font-reading);
  --radius-card: 16px;
}
```

In SwiftUI these map to a single theme struct (a `Color` set + the writing-surface font + corner radius). The component anatomy — capsule buttons, hairline cards, the writing canvas, the draft card with its "voice kept" marker — stays identical across all five.

## Recommendation

**A** and **E** are the safest production bets (A for "premium calm", E for "capable daily driver"). **B** and **D** are the most distinctive and on-brand for "a writing companion, not a chatbot." **C** is the most forward-looking but depends on real material blur. Mix is possible: e.g. ship **A**'s restraint with **B**'s serif writing surface.
