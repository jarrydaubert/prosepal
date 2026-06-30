A selectable tone/style capsule. The building block of the tone selector; also good for filters and quick options.

```jsx
<ToneChip icon={<i className="ph ph-heart" />} selected>Warmer</ToneChip>
<ToneChip icon={<i className="ph ph-scissors" />}>Shorter</ToneChip>
<ToneChip ghost icon={<i className="ph ph-plus" />}>Custom tone</ToneChip>
```

Selected chips take a clay tint. Use `ghost` for an "add your own" affordance.
