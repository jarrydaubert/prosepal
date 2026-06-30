iOS navigation bar. Use `large` + `largeTitle` on top-level screens; plain `title` with a back chevron on pushed screens.

```jsx
<NavBar large largeTitle="Drafts"
        trailing={<IconButton icon={<i className="ph ph-magnifying-glass" />} label="Search" />} />
<NavBar title="Refine"
        leading={<button className="pp-navbar__btn"><i className="ph ph-caret-left" /> Drafts</button>}
        trailing={<button className="pp-navbar__btn">Done</button>} />
```

Trailing actions use `.pp-navbar__btn` (text) — clay-tinted, regular weight, like native bar buttons.
