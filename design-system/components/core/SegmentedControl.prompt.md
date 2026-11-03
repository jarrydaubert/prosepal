iOS segmented control for 2–4 exclusive views (e.g. Draft / Original, or length presets).

```jsx
<SegmentedControl
  value={view}
  onChange={setView}
  items={[{ value: "draft", label: "Draft" }, { value: "original", label: "Original" }]}
/>
```

Keep labels to one word. For more than ~4 options use a list or selector instead.
