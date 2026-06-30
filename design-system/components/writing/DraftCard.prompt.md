Presents a draft ProsePal wrote. The prose leads; tone tags and the "voice kept" marker reassure; the footer offers Copy / Refine / Use.

```jsx
<DraftCard
  tones={["Warmer", "Concise"]}
  voiceNote="Your voice, kept"
  variants={{ current: 2, total: 3 }}
  actions={<>
    <button className="pp-draftbtn"><i className="ph ph-copy" /> Copy</button>
    <button className="pp-draftbtn"><i className="ph ph-arrow-clockwise" /> Try again</button>
    <span className="pp-spacer" />
    <button className="pp-draftbtn pp-draftbtn--accent"><i className="ph ph-check" /> Use this</button>
  </>}
>
  <p>Hi Daniel — thank you for thinking of me…</p>
</DraftCard>
```

Keep footer to ≤ 4 actions; the primary (Use/Insert) sits far-right in clay.
