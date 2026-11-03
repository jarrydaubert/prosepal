/* ProsePal flagship — shared kit chrome + section registry.
   Loaded after frame.jsx, before the screen files and render.jsx.
   Exposes window.PPK (chrome helpers) and window.PPReg (sections). */
(function () {
  const { Ic, Status, Home } = window.KIT;
  const WASH = "var(--pp-wash)";

  // ---- Glass navigation bar (large or inline) ----
  function GNav({ title, large, lead, trail, serif }) {
    return (
      <div className="pc-nav">
        <div className="pp-navbar__top">
          <span className="pp-navbar__lead">{lead}</span>
          {!large && title && <span className="pp-navbar__inline-title">{title}</span>}
          <span className="pp-navbar__trail">{trail}</span>
        </div>
        {large && title && (
          <div className="pp-navbar__largetitle" style={serif ? { fontFamily: "var(--font-reading)", fontWeight: 500 } : undefined}>{title}</div>
        )}
      </div>
    );
  }

  // ---- Glass floating dock (tab bar) ----
  function Dock({ active = "drafts" }) {
    const items = [
      { v: "drafts", label: "Drafts", icon: "cards" },
      { v: "new", label: "", icon: "feather", fab: true },
      { v: "library", label: "Library", icon: "bookmarks-simple" },
    ];
    return (
      <div className="pc-dockwrap">
        <div className="pc-dock">
          {items.map((it) => (
            <button key={it.v} className={"pp-tab" + (it.fab ? " pp-tab--fab" : "")} aria-selected={active === it.v}>
              <span className="pp-tab__icon">{Ic(it.icon, active === it.v && !it.fab ? "ph-fill" : "ph")}</span>
              {!it.fab && <span>{it.label}</span>}
            </button>
          ))}
        </div>
      </div>
    );
  }

  // ---- Bottom glass sheet (share, options) over a dimmed screen ----
  function Sheet({ children, title, onGrab = true }) {
    return (
      <div className="pc-sheet">
        {onGrab && <div className="pc-sheet__grab" />}
        {title && <div className="pc-sheet__title">{title}</div>}
        {children}
      </div>
    );
  }

  // ---- Glass toast (confirmation) ----
  function Toast({ icon = "check-circle", children, tone }) {
    return (
      <div className={"pc-toast" + (tone ? " pc-toast--" + tone : "")}>
        <span className="pc-toast__icon">{Ic(icon, "ph-fill")}</span>
        <span>{children}</span>
      </div>
    );
  }

  // ---- Glass status banner (offline / error) pinned under the nav ----
  function Banner({ icon = "wifi-slash", tone = "warning", title, action }) {
    return (
      <div className={"pc-banner pc-banner--" + tone}>
        <span className="pc-banner__icon">{Ic(icon)}</span>
        <span className="pc-banner__body">{title}</span>
        {action && <button className="pc-banner__action">{action}</button>}
      </div>
    );
  }

  window.PPK = { WASH, GNav, Dock, Sheet, Toast, Banner };

  // ---- Section registry ----
  const reg = {
    sections: [],
    add(name, subtitle, items) { this.sections.push({ name, subtitle, items }); },
    render() {
      const root = ReactDOM.createRoot(document.getElementById("root"));
      const self = this;
      function Page() {
        return (
          <div className="pp-sections">
            {self.sections.map((sec, si) => (
              <section className="pp-section" key={si}>
                <div className="pp-section__h">
                  <span className="pp-section__n">{String(si + 1).padStart(2, "0")} · {sec.name}</span>
                  {sec.subtitle && <span className="pp-section__s">{sec.subtitle}</span>}
                </div>
                <div className="pp-section__row">
                  {sec.items.map(([step, label, C], i) => (
                    <div className="kit-screen" key={i}>
                      <C />
                      <div className="kit-caption"><span className="kit-step">{step}</span><span className="kit-label">{label}</span></div>
                    </div>
                  ))}
                </div>
              </section>
            ))}
          </div>
        );
      }
      root.render(<Page />);
    },
  };
  window.PPReg = reg;
})();
