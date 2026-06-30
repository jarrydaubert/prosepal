/* Direction B — Warm literary notebook. Cream paper, faint ruled
   lines, serif-forward, a deeper ink-clay accent. The writing
   surface reads like a fine notebook page. Self-rendering. */
(function () {
  const { Ic, Status, Home, Phone, Nav, Tab } = window.KIT;
  const ROUGH = "im writing to let the team know ill be stepping back from the project. its been a hard decision but i think its the right one for me right now.";

  function Onboard() {
    return (
      <Phone bg="var(--bg)">
        <Status />
        <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column", padding: "0 26px 8px" }}>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", textAlign: "center", gap: 6 }}>
            <div className="nb-crest">{Ic("feather")}</div>
            <div className="pp-onboard__eyebrow" style={{ color: "var(--accent-text)", marginTop: 20 }}>A writing companion</div>
            <h1 style={{ fontFamily: "var(--font-reading)", fontSize: 44, fontWeight: 500, lineHeight: 1.04, letterSpacing: "-0.015em", margin: "4px 0 6px", color: "var(--text)" }}>The blank page,<br /><span style={{ fontStyle: "italic", fontWeight: 400 }}>made kinder.</span></h1>
            <p className="pp-onboard__body" style={{ fontFamily: "var(--font-reading)", fontSize: 19, lineHeight: 1.55 }}>Bring the words you have. ProsePal helps you find the ones you're reaching for — and keeps them sounding like you.</p>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10, paddingBottom: 10 }}>
            <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Begin writing</button>
            <button className="pp-btn pp-btn--ghost pp-btn--lg pp-btn--block">I already have an account</button>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Workspace() {
    return (
      <Phone bg="var(--bg)">
        <Status />
        <Nav large title="Today"
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("list")}</button>}
          trail={<span className="pp-avatar pp-avatar--sm">MO</span>} />
        <div className="pp-screen-body" style={{ padding: "2px 20px 16px", display: "flex", flexDirection: "column", gap: 20 }}>
          <div className="nb-page">
            <div className="pp-canvas__prompt" style={{ color: "var(--accent-text)" }}>The note</div>
            <div className="nb-ruled kit-text">{ROUGH}</div>
            <div className="pp-canvas__foot" style={{ borderTopStyle: "dashed" }}>
              <div className="pp-canvas__tools">
                <button className="pp-iconbtn pp-iconbtn--sm">{Ic("microphone")}</button>
                <button className="pp-iconbtn pp-iconbtn--sm">{Ic("text-aa")}</button>
              </div>
              <button className="pp-btn pp-btn--primary pp-btn--md">{Ic("feather")}<span>Help me write</span></button>
            </div>
          </div>
          <div className="pp-tones">
            <div className="pp-tones__head"><span className="pp-tones__title" style={{ fontFamily: "var(--font-reading)", fontSize: 21 }}>How should it read?</span></div>
            <div className="pp-tones__row">
              <button className="pp-chip" aria-pressed="true">{Ic("scales")} Diplomatic</button>
              <button className="pp-chip" aria-pressed="true">{Ic("heart")} Warm</button>
              <button className="pp-chip">{Ic("feather")} Graceful</button>
              <button className="pp-chip">{Ic("flag-banner")} Firm</button>
            </div>
          </div>
        </div>
        <Tab active="new" />
        <Home />
      </Phone>
    );
  }

  function Draft() {
    return (
      <Phone bg="var(--bg)">
        <Status />
        <Nav title="A draft"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")} Today</button>}
          trail={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("bookmark-simple")}</button>} />
        <div className="pp-screen-body" style={{ padding: "4px 20px 14px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div className="nb-draft">
            <div className="pp-draft__head" style={{ paddingTop: 16 }}>
              <div className="pp-draft__meta">
                <span className="pp-draft__label" style={{ fontFamily: "var(--font-reading)", fontStyle: "italic", textTransform: "none", fontSize: 15, letterSpacing: 0, color: "var(--accent-text)" }}>Diplomatic &amp; warm</span>
              </div>
              <div className="pp-draft__variants"><span className="dot dot--on" /><span className="dot" /><span className="dot" /></div>
            </div>
            <div className="pp-draft__body" style={{ fontSize: 20 }}>
              <p>To the team,</p>
              <p>After a great deal of thought, I've decided to step back from the project. It wasn't an easy decision — this work has meant a lot to me — but it's the right one for me right now.</p>
              <p>Thank you for the care you've each put in. I'll do everything I can to make the handover smooth.</p>
            </div>
            <div className="pp-draft__voice">{Ic("seal-check")} Still unmistakably you</div>
            <div className="pp-draft__foot" style={{ borderTopStyle: "dashed" }}>
              <button className="pp-draftbtn">{Ic("copy")} Copy</button>
              <button className="pp-draftbtn">{Ic("arrow-clockwise")} Another</button>
              <span className="pp-spacer" />
              <button className="pp-draftbtn pp-draftbtn--accent">{Ic("check")} Keep this</button>
            </div>
          </div>
        </div>
        <div style={{ padding: "0 16px 12px" }}>
          <div className="pp-refine">
            <span className="pp-refine__lead">{Ic("magic-wand")}</span>
            <div className="pp-refine__scroll">
              <button className="pp-chip">{Ic("scales")} Softer</button>
              <button className="pp-chip">{Ic("scissors")} Shorter</button>
              <button className="pp-chip">{Ic("flag-banner")} Firmer</button>
            </div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Refine() {
    return (
      <Phone bg="var(--bg)">
        <Status />
        <Nav title="Revise"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")}</button>}
          trail={<button className="pp-navbar__btn" style={{ fontWeight: 600, color: "var(--accent-text)" }}>Done</button>} />
        <div className="pp-screen-body" style={{ padding: "6px 20px 14px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div className="nb-page" style={{ flex: "none" }}>
            <div className="nb-ruled kit-text" style={{ minHeight: 168 }}>
              After a great deal of thought, I've decided to step back from the project. It wasn't an easy decision — this work has meant a lot to me — but it's the right one for me right now.
            </div>
          </div>
          <div className="nb-margin">
            <span className="nb-margin__icon">{Ic("note-pencil")}</span>
            <div>
              <div style={{ font: "600 14px var(--font-ui)", color: "var(--text)" }}>Margin note</div>
              <div style={{ fontFamily: "var(--font-reading)", fontSize: 16, fontStyle: "italic", color: "var(--text-secondary)", lineHeight: 1.5, marginTop: 2 }}>"It wasn't an easy decision" softens the news without losing your resolve.</div>
            </div>
          </div>
          <div className="pp-tones">
            <div className="pp-tones__row">
              <button className="pp-chip" aria-pressed="true">{Ic("heart")} Warmer</button>
              <button className="pp-chip">{Ic("scissors")} Tighter</button>
              <button className="pp-chip">{Ic("book-open")} Richer</button>
              <button className="pp-chip pp-chip--ghost">{Ic("plus")} Custom</button>
            </div>
          </div>
        </div>
        <div style={{ padding: "10px 20px 12px", borderTop: "0.5px dashed var(--border)" }}>
          <button className="pp-btn pp-btn--primary pp-btn--lg pp-btn--block">{Ic("check")} Keep this draft</button>
        </div>
        <Home />
      </Phone>
    );
  }

  function Upgrade() {
    return (
      <Phone bg="var(--bg)">
        <Status />
        <Nav title=""
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("x")}</button>}
          trail={<button className="pp-navbar__btn">Restore</button>} />
        <div className="pp-screen-body">
          <div className="pp-paywall">
            <div className="pp-paywall__hero">
              <div className="nb-crest" style={{ width: 64, height: 64, fontSize: 30 }}>{Ic("feather")}</div>
              <h2 className="pp-paywall__title" style={{ fontStyle: "italic", fontWeight: 400 }}>A study of your own</h2>
              <p className="pp-paywall__sub">Unlimited drafts, every register of tone, and a voice profile that remembers how you write.</p>
            </div>
            <ul className="pp-paywall__features">
              <li><span className="ic">{Ic("infinity")}</span><div><div className="ft-t">Unlimited drafts</div><div className="ft-s">Write and revise without counting</div></div></li>
              <li><span className="ic">{Ic("book-bookmark")}</span><div><div className="ft-t">Your voice profile</div><div className="ft-s">ProsePal learns your cadence over time</div></div></li>
              <li><span className="ic">{Ic("lock-simple")}</span><div><div className="ft-t">Kept private</div><div className="ft-s">Your pages never train a model</div></div></li>
            </ul>
            <div className="pp-plans">
              <button className="pp-plan" aria-pressed="true">
                <span className="pp-plan__radio" />
                <span className="pp-plan__body"><span className="pp-plan__name">Yearly<span className="pp-badge pp-badge--voice" style={{ marginLeft: 8 }}>Best value</span></span><span className="pp-plan__meta">$3.33 / month</span></span>
                <span className="pp-plan__price"><b>$39.99</b><span>/yr</span></span>
              </button>
              <button className="pp-plan">
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
    ["02", "The page", Workspace],
    ["03", "Draft result", Draft],
    ["04", "Revise", Refine],
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
