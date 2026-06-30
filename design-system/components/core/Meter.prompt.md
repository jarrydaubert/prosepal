Thin progress bar for usage quotas and scores. Animates its fill width.

```jsx
<Meter value={7} max={10} tone="warning" />      {/* 7 of 10 refines used */}
<Meter value={92} tone="voice" thin />            {/* voice-match score */}
```

Use `voice` (sage) for "your voice" scores, `warning` (amber) when a quota runs low.
