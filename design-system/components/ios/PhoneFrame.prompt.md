iPhone shell for presenting ProsePal screens in cards and UI kits. Compose chrome inside it.

```jsx
<PhoneFrame>
  <StatusBar />
  <NavBar largeTitle="Drafts" trailing={<i className="ph ph-magnifying-glass" />} large />
  <div className="pp-screen-body">…screen content…</div>
  <TabBar value={tab} onChange={setTab} items={tabs} />
  <HomeIndicator />
</PhoneFrame>
```

Screen is 390×844. Set `screenBg` for direction-specific canvases (e.g. glass wash, cream paper).
