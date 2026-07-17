A floating capsule of quick, one-tap refinements applied to the current draft. Distinct from `ToneSelector` (which sets the goal up front) — each tap here re-edits the existing text.

```jsx
<RefineBar
  onAction={refine}
  actions={[
    { id: "warmer", label: "Warmer", icon: <i className="ph ph-heart" /> },
    { id: "shorter", label: "Shorter", icon: <i className="ph ph-scissors" /> },
    { id: "sharper", label: "Sharper", icon: <i className="ph ph-sparkle" /> },
    { id: "simpler", label: "Simpler", icon: <i className="ph ph-waveform" /> },
  ]}
/>
```

Sits just above the keyboard / draft. Scrolls horizontally; keep the leading wand for the "AI edit" cue.
