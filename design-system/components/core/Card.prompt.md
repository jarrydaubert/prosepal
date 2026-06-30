The base surface — rounded, hairline-bordered, softly shadowed. Compose draft cards, sheets, and rows on top of it.

```jsx
<Card pad="lg">Your draft appears here.</Card>
<Card variant="inset" pad="md">Quoted source text</Card>
<Card variant="raised" interactive>Tap to open</Card>
```

- **default** card on `--bg`; **flat** for nested blocks; **raised** for floating/sheet; **inset** for sunken quote/source areas.
- Use `interactive` only when the whole card is a tap target.
