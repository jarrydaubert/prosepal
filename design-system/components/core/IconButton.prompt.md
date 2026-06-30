Circular icon-only control for nav bars, toolbars, and the writing canvas — always pass a `label` for accessibility.

```jsx
<IconButton icon={<i className="ph ph-list" />} label="Menu" />
<IconButton icon={<i className="ph ph-arrow-up" />} label="Send" variant="accent" />
<IconButton icon={<i className="ph ph-bookmark-simple" />} label="Save" variant="filled" size="sm" />
```

- **plain** for nav glyphs · **filled** for secondary toolbar actions · **accent** for the single send/commit glyph.
- Sizes map to 32 / 44 / 52 px. Keep tap targets ≥ 44 in product chrome.
