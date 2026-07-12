# ProsePal — Design System

> **ProsePal** is a premium, native-iOS **writing companion**. It helps people shape rough thoughts into polished prose — clearer, warmer, sharper, more beautifully written — **without losing their own voice**. It is a calm writing studio, not a chatbot; an editor and writing partner, not an "AI assistant."

This repository is the design system: foundations (color, type, spacing, motion), reusable iOS components, foundation specimen cards, and five comparative visual directions for the product. It is built to be handed to a SwiftUI developer.

> **★ Decided direction:** *a warm literary writing companion inside a premium modern iOS interface* — the blend of **B (Warm literary notebook)** and **C (Premium glassy iOS 26)**. Literary cream paper + serif prose carry the writing; premium glass carries the chrome. The canonical screen kit is **`ui_kits/prosepal/`**; its `.dir-prosepal` block is the production theme. The five lettered kits remain as the exploration that led here.

**Namespace (for cards / consumers):** `window.ProsePalDesignSystem_019e02`

---

## Sources

ProsePal’s visual system was originally explored from scratch. The active native
implementation now lives in `../prosepal-ios/Sources/ProsePalUI/`. Use this
bundle as visual source and historical rationale, then verify current behaviour
against the SwiftUI app and
[native architecture](../docs/engineering/architecture.md).

- Codebase: `../prosepal-ios/`
- Figma: _none provided_
- Brand / copy decks: _none provided_

### Font substitutions

ProsePal is designed around **Apple's native faces**. For the web design system to render, each is mapped to the closest embeddable Google font. On a real Apple device the genuine face renders via the `-apple-system` fallback.

| Role | Production (iOS) | Web stand-in | Token |
|---|---|---|---|
| Interface | **SF Pro Text / Display** | **Geist** | `--font-ui`, `--font-display` |
| Reading / editorial | **New York** | **Newsreader** | `--font-reading` |
| Metadata / mono | **SF Mono** | **Geist Mono** | `--font-mono` |

**Icons:** ProsePal should ship **SF Symbols** (regular weight). The web stand-in is **Phosphor Icons** (regular), loaded from CDN. → _If you'd prefer different web fonts or a licensed icon set, send them and I'll swap them in._

---

## CONTENT FUNDAMENTALS

ProsePal's words are part of the product. The copy should feel like it was written by a thoughtful editor — calm, literate, encouraging, never hyped.

**Voice.** A trusted writing partner sitting beside you. Warm, precise, quietly confident. It respects the user's intelligence and their authorship. It never brags about being "AI."

**Person & address.** Second person — **"you"**, "your voice", "your draft". ProsePal refers to itself rarely and modestly ("ProsePal", not "I"/"the AI"). The relationship is *you write → it helps*, never *it generates → you accept*.

**Casing.** **Sentence case** everywhere — buttons, titles, nav. No Title Case, no ALL CAPS except the tiny tracked eyebrow labels (`YOUR VOICE, KEPT`). Real punctuation; em dashes welcome.

**Tone & length.** Short, human, specific. Verbs over nouns ("Find the right words", not "Word optimization"). Reassure rather than sell. Concrete over clever.

**Emoji.** **None in product UI.** ProsePal's warmth comes from typography and language, not emoji. (Marketing may use them sparingly; the app does not.)

**Examples**

- ✓ "Say it like you mean it." (welcome headline, serif)
- ✓ "Your voice, kept." (the core promise; appears on drafts)
- ✓ "Find the right words." · "Write the rough version — we'll help." · "How should it feel?"
- ✓ Tone labels: *Warmer · More concise · Confident · Heartfelt · Diplomatic*
- ✓ Reassurance: "Drafts are processed privately and never used to train models."
- ✗ "Generate AI content instantly!" · "Powered by GPT-4 🤖" · "Unleash next-gen productivity" · "Your prompt has been processed."

**Microcopy patterns.** Generation states are warm and specific, rotating phrases like *"Finding the right words…"*, *"Reading your note…"*, *"Keeping your voice…"* — never a bare spinner or "Loading". Empty states encourage a first step. Paywalls state value plainly; no countdowns or guilt.

---

## VISUAL FOUNDATIONS

The whole system is built on one idea: **paper & ink**. Warm, calm, premium; the user's writing is always the hero, surrounded by generous whitespace.

**Color.** A warm-neutral foundation — off-white *paper* surfaces and warm near-black *ink* text (everything carries a subtle warm hue; nothing is pure grey or pure black, even in dark mode). The signature accent is **Clay** (`--clay-500`, a refined terracotta-rose) — a deliberate, custom tint chosen *because* it is neither generic-Apple-blue nor AI-green. Two supporting hues: **Ink-blue** for trust/links and **Sage** for the recurring *"your voice, kept"* marker and success. Color is used sparingly — mostly ink on paper, with clay reserved for the single primary action on a screen. See `tokens/colors.css`.

**Type.** Three voices. **Newsreader** (serif) is the editorial soul — headlines, big moments, and crucially the **user's writing and ProsePal's drafts**, so writing always *looks like writing*. **Geist** (sans) is the native UI voice, on the iOS ramp (17px body). **Geist Mono** carries quiet metadata — word counts, timings, quotas. The reading face is set ~19px with 1.66 line-height and oldstyle figures. Override `--canvas-font` per direction to make the writing surface sans (more "native") instead of serif.

**Spacing.** A 4px grid with a 20px screen gutter. Generous by default — whitespace is the primary material, not a leftover. Sections breathe (28–40px); related items sit close (8–16px).

**Radius.** Soft, continuous iOS curvature. **Buttons are full capsules.** Cards use large radii (22px); sheets larger (28px); the writing surface is gently rounded (20px) so it reads as a sheet of paper, not a box.

**Borders & separators.** Hairlines do most of the structural work — 0.5px warm separators, inset list dividers — rather than heavy boxes. Cards = a hairline + a soft shadow, never a hard outline.

**Shadows / elevation.** Soft, diffuse, **warm-tinted** (clay-ink, not neutral grey), low opacity — two stacked layers (ambient + key) for depth without grey halos. Premium means barely-there. A single accent glow exists only for the active/generating state. A separate **glass** set (blur + translucent fill + light stroke) powers the iOS-26 direction.

**Backgrounds.** Solid warm paper — **no photographic backgrounds, no busy patterns, no rainbow gradients.** The only gradients are tiny, tonal, same-hue clay washes on the app icon and paywall crest. Texture, where a direction wants it (notebook), is an extremely subtle ruled line or paper tint — never literal parchment.

**Motion.** Calm and Apple-native: gentle springs (`--ease-spring`), quick fades (150–240ms), and a small **press-shrink** (scale 0.97) on tap. Sheets present with `--ease-emph` over ~420ms. Nothing bounces hard. The *only* looping animation is the soft "breathing" orb + shimmer on the generation state. All motion respects `prefers-reduced-motion`.

**Interaction states.** Hover (where a pointer exists) = a quiet fill or one step darker on accent. **Press = scale 0.97 + slight opacity**, the dominant tactile cue on touch. Focus on the writing canvas = a soft clay ring (`box-shadow` with `--accent-soft`), never a harsh outline. Disabled = ~38% opacity.

**Cards & surfaces.** Rounded (22px), near-white on warm paper, hairline border + `--shadow-sm`. *Inset* variants (sunken, no shadow) hold quoted/source text. *Raised* variants (md shadow, no border) float a result.

**Transparency & blur.** Reserved for chrome that overlaps content — the translucent tab bar, sheets, and the entire glass direction. Body content stays opaque and legible.

**Imagery vibe.** ProsePal is largely image-free; warmth comes from type and clay. Where a user photo/avatar appears it's small and rounded; any imagery should feel warm and soft, never cold stock photography.

---

## ICONOGRAPHY

- **System:** **SF Symbols** in production (regular weight, the native iOS set). The web design system uses **Phosphor Icons** (regular) as the closest stand-in — geometric, humanist, rounded terminals, ~1.5px stroke, matching SF Symbols' friendliness. Loaded from CDN: `https://unpkg.com/@phosphor-icons/web@2.1.1/src/regular/style.css` (and `…/fill/style.css` for the active tab + status glyphs only). Usage in JSX: `<i className="ph ph-feather" />`.
- **Weights:** **Regular** almost everywhere; **Fill** only for the selected tab-bar item and the status-bar glyphs. Avoid bold/duotone — they read heavier than iOS.
- **No emoji as icons.** No multicolor icons. Icons are monochrome and inherit `currentColor`, so they tint with their context (ink, clay, sage).
- **Brand motif:** the **pilcrow ¶** (the editor's paragraph mark) is ProsePal's quiet signature — it appears as the tittle on the app icon and can mark section breaks. It nods to *editing*, avoiding quill/parchment cliché.
- **Key product glyphs:** `feather` (compose), `magic-wand` (refine), `heart` (warmer), `scissors` (shorter), `sparkle` (sharper), `seal-check` (voice kept), `lock-simple` (private), `microphone` (dictate), `cards` (drafts), `bookmarks-simple` (library), `arrow-clockwise` (try again), `user-focus` (voice profile), `infinity` (unlimited).
- **Logo assets:** `assets/app-icon.svg`, `assets/logo-wordmark.svg`, `assets/logo-wordmark-dark.svg`. _SVG text references Newsreader; outline to paths before shipping to production._

---

## Index / manifest

**Foundations**
- `styles.css` — the single entry point consumers link (an `@import` manifest only).
- `tokens/` — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `radius.css`, `elevation.css`, `motion.css`, `base.css`.
- `components.css` — the `.pp-*` interactive class layer (imported by `styles.css`).

**Components** (`window.ProsePalDesignSystem_019e02`) — each is `Name.jsx` + `Name.d.ts` + `Name.prompt.md`
- `components/core/` — Button, IconButton, Card, Badge, ToneChip, Switch, SegmentedControl, ListRow, Meter, Avatar, Divider
- `components/ios/` — PhoneFrame (+ StatusBar, HomeIndicator), NavBar, TabBar
- `components/writing/` — WritingCanvas, DraftCard, ToneSelector, RefineBar, GenerationState
- `components/product/` — OnboardingCard, TrustNote, EmptyState, UsageCard, Paywall

**Foundation cards** — `guidelines/*.card.html` (Design System tab: Colors, Type, Spacing, Brand)

**Visual directions** — `ui_kits/`
- **★ `prosepal/` — THE decided direction (B ∩ C): a warm literary writing companion inside a premium modern iOS interface.** Six screens. Its `.dir-prosepal` block is the production theme.
- The exploration (archived): `prosepal-minimalist/` (A), `prosepal-notebook/` (B), `prosepal-glass/` (C), `prosepal-studio/` (D), `prosepal-modern/` (E)

**Assets** — `assets/` (logo + app icon). **Skill** — `SKILL.md`.

---

## How directions are themed

The five directions are **one foundation, five themes**. Each UI kit wraps its screens in a `.dir-*` class that overrides a handful of CSS variables — `--accent`, `--canvas-font`, `--radius-card`, surfaces — so the same `.pp-*` components restyle automatically, plus a little direction-specific CSS for unique treatments (glass, ruled paper). This is the cheapest possible path from "pick a direction" to "ship it."
