---
name: prosepal-design
description: Use this skill to generate well-branded interfaces and assets for ProsePal — a premium, native-iOS AI writing companion — either for production or throwaway prototypes/mocks. Contains essential design guidelines, colors, type, fonts, assets, iOS UI components, and five comparative visual directions for prototyping.
user-invocable: true
---

# ProsePal Design System

Read **`readme.md`** at the root first — it holds the brand context, content fundamentals (voice & microcopy), visual foundations, and iconography. Then explore the files below.

ProsePal is a calm, premium iOS **writing companion** — an editor and writing partner, not a chatbot. The user's writing is always the hero. Warm "paper & ink" palette, a signature **clay** accent, serif (Newsreader/New York) for prose and Geist/SF Pro for UI. Sentence case, second person, no emoji in product.

## What's here
- **`styles.css`** — the single entry point. Link it and you get every token + the `.pp-*` component classes. (Tokens live in `tokens/`, component CSS in `components/*/*.css` via `components.css`.)
- **Components** (`window.ProsePalDesignSystem_019e02`) — React primitives in `components/{core,ios,writing,product}/`. Each has a `.d.ts` (props) and `.prompt.md` (usage). The writing-specific ones (WritingCanvas, DraftCard, ToneSelector, RefineBar, GenerationState) are the heart of the product.
- **Foundation cards** — `guidelines/*.card.html` (color, type, spacing, brand specimens).
- **Five visual directions** — `ui_kits/prosepal-{minimalist,notebook,glass,studio,modern}/`. Each is one foundation re-themed; see `ui_kits/README.md`.
- **Assets** — `assets/` (app icon, wordmark light/dark).

## How to use it
- **Visual artifacts** (slides, mocks, throwaway prototypes): copy the assets you need out of `assets/`, link `styles.css` (and Phosphor Icons + the Google fonts named in `tokens/fonts.css`), and build static HTML. The `ui_kits/_shared/frame.jsx` phone shell and any direction's `index.html` are good starting points — copy and adapt.
- **Production code**: read the token files and component `.prompt.md`s to become an expert in the brand, then map the directions to a SwiftUI theme (a `Color` set + writing-surface font + corner radius). Components are deliberately simple/cosmetic — reference their anatomy, don't lift them verbatim.
- **Pick a direction** before building screens — they are genuinely different products. A/E are the safe production bets; B/D the most on-brand; C the most forward-looking.

If invoked with no guidance, ask what the user wants to build, ask a few focused questions (which direction? which screens? production or mock?), then act as an expert ProsePal designer who outputs HTML artifacts **or** production-ready guidance.

## Font & icon substitutions
Web stand-ins for Apple faces: **Geist** (SF Pro), **Newsreader** (New York), **Geist Mono** (SF Mono); **Phosphor** (regular) for SF Symbols. Swap to the genuine faces/symbols in production. See `readme.md` → Sources.
