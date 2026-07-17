Translucent bottom tab bar. ProsePal uses Drafts · (compose FAB) · Library, with Settings tucked in the nav bar.

```jsx
<TabBar value={tab} onChange={setTab} items={[
  { value: "drafts", label: "Drafts", icon: <i className="ph ph-cards" /> },
  { value: "new", label: "", icon: <i className="ph ph-feather" />, fab: true },
  { value: "library", label: "Library", icon: <i className="ph ph-bookmarks-simple" /> },
]} />
```

Set `fab: true` on the center compose item to raise it into the clay circle.
