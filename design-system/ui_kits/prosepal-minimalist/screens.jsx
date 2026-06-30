/* Direction A — Apple-native minimalist. Default tokens; native sans
   writing surface; maximum restraint. Self-rendering (no exports). */
(function () {
  const { Ic, Status, Home, Phone, Nav, Tab } = window.KIT;
  const ROUGH = "hey daniel, thanks for the invite but i cant make it sunday, maybe another time";

  function Onboard() {
    return (
      <Phone>
        <Status />
        <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column", padding: "0 24px 8px" }}>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", textAlign: "center", gap: 4 }}>
            <div className="pp-onboard__medallion" style={{ marginBottom: 22 }}>{Ic("feather")}</div>
            <div className="pp-onboard__eyebrow">Welcome to ProsePal</div>
            <h1 className="pp-onboard__title" style={{ fontSize: 40 }}>Say it like<br />you mean it.</h1>
            <p className="pp-onboard__body">Write the rough version. ProsePal helps you make it clearer, warmer, sharper — in your own voice.</p>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10, paddingBottom: 8 }}>
            <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Get started</button>
            <button className="pp-btn pp-btn--ghost pp-btn--lg pp-btn--block">I already have an account</button>
            <div className="pp-trust pp-trust--inline" style={{ marginTop: 6, justifyContent: "center" }}>
              <span className="pp-trust__icon">{Ic("lock-simple")}</span>
              <div className="pp-trust__title" style={{ fontWeight: 500 }}>Private by default — your words stay yours</div>
            </div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Workspace() {
    const tones = [
      { id: "warm", label: "Warmer", icon: "heart", on: true },
      { id: "concise", label: "More concise", icon: "scissors", on: true },
      { id: "confident", label: "Confident", icon: "flag-banner" },
      { id: "formal", label: "Formal", icon: "briefcase" },
    ];
    return (
      <Phone>
        <Status />
        <Nav large title="New draft"
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("list")}</button>}
          trail={<span className="pp-avatar pp-avatar--sm">MO</span>} />
        <div className="pp-screen-body" style={{ padding: "2px 20px 16px", display: "flex", flexDirection: "column", gap: 22 }}>
          <div className="pp-canvas">
            <div className="pp-canvas__prompt">What do you want to say?</div>
            <div className="pp-canvas__field kit-text">{ROUGH}</div>
            <div className="pp-canvas__foot">
              <div className="pp-canvas__tools">
                <button className="pp-iconbtn pp-iconbtn--sm">{Ic("microphone")}</button>
                <button className="pp-iconbtn pp-iconbtn--sm">{Ic("paperclip")}</button>
              </div>
              <div className="pp-canvas__send">
                <span className="pp-canvas__count">14 words</span>
                <button className="pp-btn pp-btn--primary pp-btn--md">{Ic("feather")}<span>Refine</span></button>
              </div>
            </div>
          </div>
          <div className="pp-tones">
            <div className="pp-tones__head"><span className="pp-tones__title">How should it feel?</span><span className="pp-tones__hint">Pick a few</span></div>
            <div className="pp-tones__row">
              {tones.map((t) => (
                <button key={t.id} className="pp-chip" aria-pressed={!!t.on}><span className="pp-chip__icon">{Ic(t.icon)}</span>{t.label}</button>
              ))}
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, color: "var(--text-tertiary)", font: "400 13px var(--font-ui)" }}>
            {Ic("lightning")}<span className="pp-mono" style={{ fontSize: 12 }}>7 of 10 free refines left this week</span>
          </div>
        </div>
        <Tab active="new" />
        <Home />
      </Phone>
    );
  }

  function Draft() {
    return (
      <Phone>
        <Status />
        <Nav title="Draft"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")} New</button>}
          trail={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("share-network")}</button>} />
        <div className="pp-screen-body" style={{ padding: "4px 20px 14px", display: "flex", flexDirection: "column", gap: 14 }}>
          <div className="pp-card pp-card--inset pp-card--pad" style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            <span className="pp-draft__label">Your message</span>
            <div style={{ font: "400 15px var(--font-ui)", color: "var(--text-tertiary)", lineHeight: 1.5 }}>{ROUGH}</div>
          </div>
          <div className="pp-draft pp-draft--raised">
            <div className="pp-draft__head">
              <div className="pp-draft__meta">
                <span className="pp-draft__label">Draft</span>
                <span className="pp-badge pp-badge--accent">Warmer</span>
                <span className="pp-badge pp-badge--accent">Concise</span>
              </div>
              <div className="pp-draft__variants"><span className="dot" /><span className="dot dot--on" /><span className="dot" /></div>
            </div>
            <div className="pp-draft__body">
              <p>Hi Daniel — thank you so much for the invitation. I won't be able to make it on Sunday, but I'd genuinely love to find another time soon.</p>
              <p>Maybe coffee next week?</p>
            </div>
            <div className="pp-draft__voice">{Ic("seal-check")} Your voice, kept</div>
            <div className="pp-draft__foot">
              <button className="pp-draftbtn">{Ic("copy")} Copy</button>
              <button className="pp-draftbtn">{Ic("arrow-clockwise")} Try again</button>
              <span className="pp-spacer" />
              <button className="pp-draftbtn pp-draftbtn--accent">{Ic("check")} Use this</button>
            </div>
          </div>
        </div>
        <div style={{ padding: "0 16px 10px" }}>
          <div className="pp-refine">
            <span className="pp-refine__lead">{Ic("magic-wand")}</span>
            <div className="pp-refine__scroll">
              <button className="pp-chip">{Ic("heart")} Warmer</button>
              <button className="pp-chip">{Ic("scissors")} Shorter</button>
              <button className="pp-chip">{Ic("sparkle")} Sharper</button>
            </div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Refine() {
    return (
      <Phone>
        <Status />
        <Nav title="Refine"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")}</button>}
          trail={<button className="pp-navbar__btn" style={{ fontWeight: 600, color: "var(--accent-text)" }}>Done</button>} />
        <div className="pp-screen-body" style={{ padding: "6px 20px 14px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div className="pp-segmented">
            <button className="pp-segmented__item" aria-selected="true">Draft</button>
            <button className="pp-segmented__item">Changes</button>
            <button className="pp-segmented__item">Original</button>
          </div>
          <div className="pp-canvas pp-canvas--focus">
            <div className="pp-canvas__field kit-text" style={{ minHeight: 150 }}>
              Hi Daniel — thank you so much for the invitation. I won't be able to make it on Sunday, but I'd genuinely love to find another time soon. Maybe coffee next week?
            </div>
            <div className="pp-canvas__foot">
              <span style={{ font: "400 13px var(--font-ui)", color: "var(--text-tertiary)" }}>Tap a word to rephrase it</span>
              <span className="pp-canvas__count">28 words</span>
            </div>
          </div>
          <div className="pp-tones">
            <div className="pp-tones__head"><span className="pp-tones__title" style={{ fontSize: 15 }}>Adjust the tone</span></div>
            <div className="pp-tones__row">
              <button className="pp-chip" aria-pressed="true">{Ic("heart")} Warmer</button>
              <button className="pp-chip">{Ic("scissors")} Shorter</button>
              <button className="pp-chip">{Ic("briefcase")} Formal</button>
              <button className="pp-chip">{Ic("smiley")} Playful</button>
              <button className="pp-chip pp-chip--ghost">{Ic("plus")} Custom</button>
            </div>
          </div>
        </div>
        <div style={{ padding: "10px 20px 12px", borderTop: "0.5px solid var(--separator)" }}>
          <button className="pp-btn pp-btn--primary pp-btn--lg pp-btn--block">{Ic("check")} Use this draft</button>
        </div>
        <Home />
      </Phone>
    );
  }

  function Upgrade() {
    return (
      <Phone>
        <Status />
        <Nav title=""
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("x")}</button>}
          trail={<button className="pp-navbar__btn">Restore</button>} />
        <div className="pp-screen-body">
          <div className="pp-paywall">
            <div className="pp-paywall__hero">
              <div className="pp-paywall__crest">{Ic("feather")}</div>
              <h2 className="pp-paywall__title">Write without limits</h2>
              <p className="pp-paywall__sub">Unlimited refines, every tone, and your own private voice profile.</p>
            </div>
            <ul className="pp-paywall__features">
              <li><span className="ic">{Ic("infinity")}</span><div><div className="ft-t">Unlimited refines</div><div className="ft-s">Polish as many messages as you like</div></div></li>
              <li><span className="ic">{Ic("user-focus")}</span><div><div className="ft-t">Your voice profile</div><div className="ft-s">ProsePal learns how you sound</div></div></li>
              <li><span className="ic">{Ic("lock-simple")}</span><div><div className="ft-t">Private by default</div><div className="ft-s">Nothing ever trains on your words</div></div></li>
            </ul>
            <div className="pp-plans">
              <button className="pp-plan" aria-pressed="true">
                <span className="pp-plan__radio" />
                <span className="pp-plan__body"><span className="pp-plan__name">Yearly<span className="pp-badge pp-badge--voice" style={{ marginLeft: 8 }}>Save 40%</span></span><span className="pp-plan__meta">$3.33 / month, billed yearly</span></span>
                <span className="pp-plan__price"><b>$39.99</b><span>/yr</span></span>
              </button>
              <button className="pp-plan">
                <span className="pp-plan__radio" />
                <span className="pp-plan__body"><span className="pp-plan__name">Monthly</span><span className="pp-plan__meta">Billed monthly</span></span>
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
    ["02", "Workspace", Workspace],
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
