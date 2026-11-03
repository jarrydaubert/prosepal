/* Direction C — Premium glassy iOS 26. Translucent glass panels
   floating over a soft warm wash; vibrant-but-calm. Self-rendering. */
(function () {
  const { Ic, Status, Home, Phone } = window.KIT;
  const ROUGH = "can we push our call to thursday? something came up and i dont want to rush it";

  // Glass-styled chrome (overrides the opaque defaults)
  function GNav({ title, large, lead, trail }) {
    return (
      <div className="g-nav">
        <div className="pp-navbar__top">
          <span className="pp-navbar__lead">{lead}</span>
          {!large && title && <span className="pp-navbar__inline-title">{title}</span>}
          <span className="pp-navbar__trail">{trail}</span>
        </div>
        {large && title && <div className="pp-navbar__largetitle">{title}</div>}
      </div>
    );
  }
  function GTab() {
    return (
      <div className="g-tabwrap">
        <div className="g-tab">
          <button className="pp-tab" aria-selected="false"><span className="pp-tab__icon">{Ic("cards")}</span><span>Drafts</span></button>
          <button className="pp-tab pp-tab--fab"><span className="pp-tab__icon">{Ic("feather")}</span></button>
          <button className="pp-tab" aria-selected="true"><span className="pp-tab__icon">{Ic("bookmarks-simple", "ph-fill")}</span><span>Library</span></button>
        </div>
      </div>
    );
  }

  function Onboard() {
    return (
      <Phone bg="var(--g-wash)">
        <Status />
        <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column", padding: "0 24px 10px" }}>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", textAlign: "center", gap: 6 }}>
            <div className="g-orb">{Ic("feather")}</div>
            <h1 style={{ fontFamily: "var(--font-reading)", fontSize: 42, fontWeight: 500, lineHeight: 1.05, letterSpacing: "-0.015em", margin: "22px 0 6px", color: "var(--text)" }}>Words that<br />carry weight.</h1>
            <p className="pp-onboard__body">A calmer way to write the message you've been putting off — clearer, kinder, and still yours.</p>
          </div>
          <div className="g-panel" style={{ padding: 14, display: "flex", flexDirection: "column", gap: 10 }}>
            <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Get started</button>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 7, color: "var(--text-secondary)", font: "500 13px var(--font-ui)" }}>{Ic("lock-simple")} Private by default</div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Workspace() {
    return (
      <Phone bg="var(--g-wash)">
        <Status />
        <GNav large title="Compose"
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("list")}</button>}
          trail={<span className="pp-avatar pp-avatar--sm">MO</span>} />
        <div className="pp-screen-body" style={{ padding: "2px 18px 16px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div className="g-panel g-canvas">
            <div className="pp-canvas__prompt">What do you want to say?</div>
            <div className="pp-canvas__field kit-text" style={{ minHeight: 96 }}>{ROUGH}</div>
            <div className="pp-canvas__foot" style={{ borderTopColor: "var(--glass-stroke-soft)" }}>
              <div className="pp-canvas__tools">
                <button className="pp-iconbtn pp-iconbtn--sm">{Ic("microphone")}</button>
                <button className="pp-iconbtn pp-iconbtn--sm">{Ic("paperclip")}</button>
              </div>
              <button className="pp-btn pp-btn--primary pp-btn--md">{Ic("feather")}<span>Refine</span></button>
            </div>
          </div>
          <div className="pp-tones">
            <div className="pp-tones__head"><span className="pp-tones__title">How should it feel?</span></div>
            <div className="pp-tones__row">
              <button className="g-chip" aria-pressed="true">{Ic("heart")} Warmer</button>
              <button className="g-chip">{Ic("clock")} Relaxed</button>
              <button className="g-chip" aria-pressed="true">{Ic("scissors")} Brief</button>
              <button className="g-chip">{Ic("flag-banner")} Direct</button>
            </div>
          </div>
          <div className="g-panel" style={{ padding: "12px 16px", display: "flex", alignItems: "center", gap: 12 }}>
            <span style={{ font: "500 13px var(--font-ui)", color: "var(--text-secondary)" }}>Allowance managed by ProsePal</span>
          </div>
        </div>
        <GTab />
        <Home />
      </Phone>
    );
  }

  function Draft() {
    return (
      <Phone bg="var(--g-wash)">
        <Status />
        <GNav title="Draft"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")} Compose</button>}
          trail={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("share-network")}</button>} />
        <div className="pp-screen-body" style={{ padding: "4px 18px 14px", display: "flex", flexDirection: "column", gap: 14 }}>
          <div className="g-panel g-draft">
            <div className="pp-draft__head" style={{ paddingTop: 16 }}>
              <div className="pp-draft__meta">
                <span className="pp-draft__label">Draft</span>
                <span className="g-badge">Warmer</span>
                <span className="g-badge">Brief</span>
              </div>
              <div className="pp-draft__variants"><span className="dot" /><span className="dot dot--on" /><span className="dot" /></div>
            </div>
            <div className="pp-draft__body" style={{ fontSize: 20 }}>
              <p>Hi! Would Thursday work instead of our call? Something's come up, and I'd rather give this the time it deserves than rush it.</p>
            </div>
            <div className="pp-draft__voice">{Ic("seal-check")} Your voice, kept</div>
            <div className="pp-draft__foot" style={{ borderTopColor: "var(--glass-stroke-soft)" }}>
              <button className="pp-draftbtn">{Ic("copy")} Copy</button>
              <button className="pp-draftbtn">{Ic("arrow-clockwise")} Again</button>
              <span className="pp-spacer" />
              <button className="pp-draftbtn pp-draftbtn--accent">{Ic("check")} Use this</button>
            </div>
          </div>
          <div className="g-floatbar">
            <span className="pp-refine__lead">{Ic("magic-wand")}</span>
            <div className="pp-refine__scroll">
              <button className="g-chip">{Ic("heart")} Warmer</button>
              <button className="g-chip">{Ic("scissors")} Shorter</button>
              <button className="g-chip">{Ic("sparkle")} Sharper</button>
            </div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Refine() {
    return (
      <Phone bg="var(--g-wash)">
        <Status />
        <GNav title="Refine"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")}</button>}
          trail={<button className="pp-navbar__btn" style={{ fontWeight: 600, color: "var(--accent-text)" }}>Done</button>} />
        <div className="pp-screen-body" style={{ padding: "6px 18px 14px", display: "flex", flexDirection: "column", gap: 14 }}>
          <div className="g-seg">
            <button className="pp-segmented__item" aria-selected="true">Draft</button>
            <button className="pp-segmented__item">Changes</button>
            <button className="pp-segmented__item">Original</button>
          </div>
          <div className="g-panel g-canvas">
            <div className="pp-canvas__field kit-text" style={{ minHeight: 130, fontSize: 20 }}>
              Hi! Would Thursday work instead of our call? Something's come up, and I'd rather give this the time it deserves than rush it.
            </div>
          </div>
          <div className="pp-tones">
            <div className="pp-tones__head"><span className="pp-tones__title" style={{ fontSize: 15 }}>Adjust the tone</span></div>
            <div className="pp-tones__row">
              <button className="g-chip" aria-pressed="true">{Ic("heart")} Warmer</button>
              <button className="g-chip">{Ic("scissors")} Shorter</button>
              <button className="g-chip">{Ic("briefcase")} Formal</button>
              <button className="g-chip">{Ic("smiley")} Playful</button>
            </div>
          </div>
        </div>
        <div style={{ padding: "0 18px 14px" }}>
          <button className="pp-btn pp-btn--primary pp-btn--lg pp-btn--block">{Ic("check")} Use this draft</button>
        </div>
        <Home />
      </Phone>
    );
  }

  function Upgrade() {
    return (
      <Phone bg="var(--g-wash)">
        <Status />
        <GNav title=""
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("x")}</button>}
          trail={<button className="pp-navbar__btn">Restore</button>} />
        <div className="pp-screen-body" style={{ padding: "0 16px" }}>
          <div className="pp-paywall" style={{ padding: "12px 6px 18px" }}>
            <div className="pp-paywall__hero">
              <div className="g-orb" style={{ width: 64, height: 64, fontSize: 30 }}>{Ic("feather")}</div>
              <h2 className="pp-paywall__title">More room to write</h2>
              <p className="pp-paywall__sub">More drafts and refines, every tone, and a private voice profile that's yours alone.</p>
            </div>
            <div className="g-panel" style={{ padding: "6px 16px" }}>
              <ul className="pp-paywall__features" style={{ margin: "12px 0" }}>
                <li><span className="ic">{Ic("arrow-circle-up")}</span><div><div className="ft-t">Higher writing limits</div><div className="ft-s">More room to shape important messages</div></div></li>
                <li><span className="ic">{Ic("user-focus")}</span><div><div className="ft-t">Your voice profile</div><div className="ft-s">ProsePal learns how you sound</div></div></li>
                <li><span className="ic">{Ic("lock-simple")}</span><div><div className="ft-t">Private by default</div><div className="ft-s">Nothing trains on your words</div></div></li>
              </ul>
            </div>
            <div className="pp-plans">
              <button className="g-plan" aria-pressed="true">
                <span className="pp-plan__radio" />
                <span className="pp-plan__body"><span className="pp-plan__name">Yearly<span className="pp-badge pp-badge--voice" style={{ marginLeft: 8 }}>Save 40%</span></span><span className="pp-plan__meta">$3.33 / month</span></span>
                <span className="pp-plan__price"><b>$39.99</b><span>/yr</span></span>
              </button>
              <button className="g-plan">
                <span className="pp-plan__radio" />
                <span className="pp-plan__body"><span className="pp-plan__name">Monthly</span></span>
                <span className="pp-plan__price"><b>$5.99</b><span>/mo</span></span>
              </button>
            </div>
            <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Start 7-day free trial</button>
            <div className="pp-paywall__fine">Cancel anytime · <a href="#">Terms</a> · <a href="#">Privacy</a></div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  const SCREENS = [
    ["01", "Welcome", Onboard],
    ["02", "Compose", Workspace],
    ["03", "Draft result", Draft],
    ["04", "Refine", Refine],
    ["05", "Upgrade", Upgrade],
  ];

  function App() {
    return (
      <div className="kit-rail">
        {SCREENS.map(([step, label, C]) => (
          <div className="kit-screen" key={step}>
            <C />
            <div className="kit-caption"><span className="kit-step">{step}</span><span className="kit-label">{label}</span></div>
          </div>
        ))}
      </div>
    );
  }

  ReactDOM.createRoot(document.getElementById("root")).render(<App />);
})();
