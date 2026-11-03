Sets the goal for a piece — the tone & style ProsePal should aim for. Built from `ToneChip`s; single or multi select.

```jsx
<ToneSelector
  title="How should it feel?"
  hint="Pick a few"
  value={tones} onChange={setTones}
  options={[
    { id: "warm", label: "Warmer", icon: <i className="ph ph-heart" /> },
    { id: "concise", label: "More concise", icon: <i className="ph ph-scissors" /> },
    { id: "confident", label: "Confident", icon: <i className="ph ph-flag-banner" /> },
    { id: "formal", label: "More formal", icon: <i className="ph ph-briefcase" /> },
  ]}
/>
```

Use `scroll` for a single-line horizontal rail in compact spots. Pairs above the WritingCanvas or inside a tone sheet.
