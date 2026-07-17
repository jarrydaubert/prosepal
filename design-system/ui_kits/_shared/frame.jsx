/* Shared UI-kit helpers for ProsePal directions.
   Plain global-React functions assigned to window.KIT — intentionally
   NOT exported, so the design-system compiler does not bundle them.
   Screens read: const { Ic, Phone, Status, Home, Nav, Tab } = window.KIT; */
(function () {
  const Ic = (n, w) => <i className={"ph " + (w || "ph") + " ph-" + n} aria-hidden="true" />;

  function Status({ time = "9:41" }) {
    return (
      <div className="pp-statusbar">
        <span className="pp-statusbar__time">{time}</span>
        <span className="pp-statusbar__icons">
          <i className="ph-fill ph-cell-signal-full" />
          <i className="ph-fill ph-wifi-high" />
          <i className="ph-fill ph-battery-full" />
        </span>
      </div>
    );
  }

  function Home() { return <div className="pp-home" />; }

  function Phone({ children, bg, className = "" }) {
    return (
      <div className={"pp-phone " + className}>
        <div className="pp-phone__island" />
        <div className="pp-phone__screen" style={bg ? { background: bg } : undefined}>
          {children}
        </div>
      </div>
    );
  }

  function Nav({ title, large, lead, trail }) {
    return (
      <div className="pp-navbar">
        <div className="pp-navbar__top">
          <span className="pp-navbar__lead">{lead}</span>
          {!large && title && <span className="pp-navbar__inline-title">{title}</span>}
          <span className="pp-navbar__trail">{trail}</span>
        </div>
        {large && title && <div className="pp-navbar__largetitle">{title}</div>}
      </div>
    );
  }

  function Tab({ active = "new" }) {
    const items = [
      { v: "drafts", label: "Drafts", icon: "cards" },
      { v: "new", label: "", icon: "feather", fab: true },
      { v: "library", label: "Library", icon: "bookmarks-simple" },
    ];
    return (
      <div className="pp-tabbar">
        {items.map((it) => (
          <button key={it.v} className={"pp-tab" + (it.fab ? " pp-tab--fab" : "")} aria-selected={active === it.v}>
            <span className="pp-tab__icon">{Ic(it.icon, active === it.v && !it.fab ? "ph-fill" : "ph")}</span>
            {!it.fab && <span>{it.label}</span>}
          </button>
        ))}
      </div>
    );
  }

  window.KIT = { Ic, Status, Home, Phone, Nav, Tab };
})();
