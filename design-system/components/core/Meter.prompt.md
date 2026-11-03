Thin progress bar for usage quotas and scores. Animates its fill width.

```jsx
<Meter value={0.7} max={1} tone="warning" />      {/* Use only for measured, non-quota progress */}
<Meter value={92} tone="voice" thin />            {/* voice-match score */}
```

Use `voice` (sage) for "your voice" scores, `warning` (amber) when a quota runs low.
