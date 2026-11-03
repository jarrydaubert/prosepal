The writing surface — the product's center of gravity. A paper card with the user's words in the reading serif, a quiet footer for tools, count, and the send/refine action.

```jsx
<WritingCanvas
  value={text} onChange={setText}
  prompt="What do you want to say?"
  count="48 words"
  tools={<><IconButton icon={<i className="ph ph-microphone" />} label="Dictate" />
           <IconButton icon={<i className="ph ph-paperclip" />} label="Attach" /></>}
  actions={<Button size="md" icon={<i className="ph ph-feather" />}>Refine</Button>}
/>
```

- Override `--canvas-font: var(--font-ui)` on a wrapper for a more native/minimalist direction.
- Use `focus` to show the clay focus ring while editing.
