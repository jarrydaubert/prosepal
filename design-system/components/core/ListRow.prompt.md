Grouped iOS list row for settings, history, and menus. Group rows inside `pp-listgroup` for the inset-card look.

```jsx
<div className="pp-listgroup">
  <ListRow lead={<i className="ph ph-lock-simple" />} title="Private mode"
           trailing={<Switch checked={on} onChange={setOn} label="Private" />} />
  <ListRow title="Default tone" subtitle="Warm · Concise" trailing="Edit" chevron onClick={openTones} />
</div>
```

Hairline separators auto-inset between rows. Use `chevron` for navigation, `trailing` for values/controls.
