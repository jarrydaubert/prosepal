Capsule action button — the main way to commit an action in ProsePal; semibold label, gentle press-shrink, clay-filled when primary.

```jsx
<Button variant="primary" size="xl" icon={<i className="ph ph-feather" />}>
  Refine my message
</Button>
<Button variant="secondary">Save draft</Button>
<Button variant="ghost" size="md">Not now</Button>
```

- **variant**: `primary` (clay fill) · `secondary` (clay tint) · `neutral` (grey fill) · `ghost` (text only) · `outline` · `danger`.
- **size**: `sm` 32 · `md` 44 · `lg` 52 · `xl` 58 (primary CTA).
- Use `block` for full-width sheet CTAs. `loading` swaps the icon for a spinner.
- One primary per screen. Pair a primary with a ghost for the dismiss action — never two primaries.
