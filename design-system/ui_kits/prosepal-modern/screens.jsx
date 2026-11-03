/* Direction E — Modern AI productivity, but elegant and human.
   More structured: sections, suggestion cards, light data, a touch
   of ink-blue. Still warm, never a dashboard. Self-rendering. */
(function () {
  const { Ic, Status, Home, Phone, Nav, Tab } = window.KIT;
  const ROUGH = "following up on my application from 2 weeks ago, still really interested in the role and wanted to check on next steps";

  function Onboard() {
    return (
      <Phone bg="var(--bg-grouped)">
        <Status />
        <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column", padding: "8px 22px 12px" }}>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", gap: 18 }}>
            <div className="e-logo">{Ic("feather")}</div>
            <div>
              <h1 style={{ font: "700 33px/1.1 var(--font-display)", letterSpacing: "-0.025em", color: "var(--text)" }}>Your writing,<br />leveled up.</h1>
              <p style={{ font: "400 16px/1.5 var(--font-ui)", color: "var(--text-secondary)", marginTop: 10, maxWidth: "32ch" }}>ProsePal turns rough notes into clear, confident messages — in seconds, in your voice.</p>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
              <div className="e-bullet">{Ic("lightning")}<div><b>Refine in one tap</b><span>Warmer, shorter, sharper — instantly</span></div></div>
              <div className="e-bullet">{Ic("user-focus")}<div><b>Learns your voice</b><span>Sounds like you, not a template</span></div></div>
              <div className="e-bullet">{Ic("shield-check")}<div><b>Private by default</b><span>Your words never train a model</span></div></div>
            </div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Create free account</button>
            <button className="pp-btn pp-btn--ghost pp-btn--lg pp-btn--block">Sign in</button>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Workspace() {
    return (
      <Phone bg="var(--bg-grouped)">
        <Status />
        <Nav large title="Compose"
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("squares-four")}</button>}
          trail={<><button className="pp-iconbtn">{Ic("clock-counter-clockwise")}</button><span className="pp-avatar pp-avatar--sm">MO</span></>} />
        <div className="pp-screen-body" style={{ padding: "2px 18px 16px", display: "flex", flexDirection: "column", gap: 14 }}>
          <div className="e-seg">
            <button className="e-seg__i e-seg__i--on">{Ic("chat-teardrop-text")} Message</button>
            <button className="e-seg__i">{Ic("envelope-simple")} Email</button>
            <button className="e-seg__i">{Ic("article")} Post</button>
          </div>
          <div className="e-card e-canvas">
            <div className="e-canvas__label">Your draft</div>
            <div className="pp-canvas__field kit-text" style={{ fontFamily: "var(--font-ui)", fontSize: 16, lineHeight: 1.5, minHeight: 84 }}>{ROUGH}</div>
            <div className="e-canvas__foot">
              <span className="pp-canvas__count">23 words</span>
              <button className="pp-btn pp-btn--primary pp-btn--md">{Ic("magic-wand")}<span>Refine</span></button>
            </div>
          </div>
          <div>
            <div className="e-section-h">Goals</div>
            <div className="pp-tones__row" style={{ marginTop: 9 }}>
              <button className="e-chip e-chip--on">{Ic("flag-banner")} Professional</button>
              <button className="e-chip e-chip--on">{Ic("clock")} Follow-up</button>
              <button className="e-chip">{Ic("scissors")} Concise</button>
              <button className="e-chip">{Ic("smiley")} Friendly</button>
            </div>
          </div>
          <div className="e-tip">{Ic("sparkle")}<span><b>Suggested:</b> a polite nudge that restates your interest and asks for a timeline.</span></div>
        </div>
        <Tab active="new" />
        <Home />
      </Phone>
    );
  }

  function Draft() {
    return (
      <Phone bg="var(--bg-grouped)">
        <Status />
        <Nav title="Results"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")} Compose</button>}
          trail={<button className="pp-iconbtn">{Ic("sliders-horizontal")}</button>} />
        <div className="pp-screen-body" style={{ padding: "4px 18px 14px", display: "flex", flexDirection: "column", gap: 12 }}>
          <div className="e-result-head">
            <span className="e-section-h">3 options</span>
            <div className="pp-draft__variants"><span className="dot dot--on" /><span className="dot" /><span className="dot" /></div>
          </div>
          <div className="e-card e-draft e-draft--on">
            <div className="e-draft__top"><span className="e-badge e-badge--blue">Recommended</span><span className="e-draft__tone">Professional · Concise</span></div>
            <div className="e-draft__body">Hi Sarah, I wanted to follow up on my application from two weeks ago — I'm still very interested in the role. Could you share what the next steps look like? Happy to provide anything else you need.</div>
            <div className="e-draft__foot"><span className="pp-draft__voice" style={{ margin: 0 }}>{Ic("seal-check")} Your voice, kept</span><div style={{ display: "flex", gap: 4 }}><button className="e-iconpill">{Ic("copy")}</button><button className="e-iconpill e-iconpill--accent">{Ic("check")} Use</button></div></div>
          </div>
          <div className="e-card e-draft">
            <div className="e-draft__top"><span className="e-draft__tone">Warm · Brief</span></div>
            <div className="e-draft__body" style={{ color: "var(--text-secondary)" }}>Hi Sarah! Just checking in on my application from a couple weeks back — still really excited about the role. Any update on next steps?</div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Refine() {
    return (
      <Phone bg="var(--bg-grouped)">
        <Status />
        <Nav title="Refine"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")}</button>}
          trail={<button className="pp-navbar__btn" style={{ fontWeight: 600, color: "var(--accent-text)" }}>Save</button>} />
        <div className="pp-screen-body" style={{ padding: "6px 18px 14px", display: "flex", flexDirection: "column", gap: 14 }}>
          <div className="e-seg">
            <button className="e-seg__i e-seg__i--on">Edited</button>
            <button className="e-seg__i">Changes</button>
            <button className="e-seg__i">Original</button>
          </div>
          <div className="e-card e-canvas">
            <div className="e-diff kit-text"><span className="e-del">following up on my application</span> <span className="e-add">I wanted to follow up on my application from two weeks ago</span> — I'm still very interested in the role.</div>
          </div>
          <div>
            <div className="e-section-h">Quick refinements</div>
            <div className="pp-tones__row" style={{ marginTop: 9 }}>
              <button className="e-chip e-chip--on">{Ic("heart")} Warmer</button>
              <button className="e-chip">{Ic("scissors")} Shorter</button>
              <button className="e-chip">{Ic("translate")} Simpler</button>
              <button className="e-chip">{Ic("flag-banner")} Assertive</button>
            </div>
          </div>
          <div className="e-meter-card">
            <div className="e-meter-row"><span>Clarity</span><span className="e-meter"><span style={{ width: "92%" }} /></span></div>
            <div className="e-meter-row"><span>Warmth</span><span className="e-meter"><span style={{ width: "68%", background: "var(--voice)" }} /></span></div>
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
      <Phone bg="var(--bg-grouped)">
        <Status />
        <Nav title=""
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("x")}</button>}
          trail={<button className="pp-navbar__btn">Restore</button>} />
        <div className="pp-screen-body" style={{ padding: "0 18px 12px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div style={{ textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center", gap: 6, paddingTop: 4 }}>
            <div className="e-logo" style={{ width: 56, height: 56, fontSize: 26 }}>{Ic("feather")}</div>
            <h2 style={{ font: "700 28px/1.1 var(--font-display)", letterSpacing: "-0.02em", color: "var(--text)", marginTop: 6 }}>Upgrade to Pro</h2>
            <p style={{ font: "400 15px/1.5 var(--font-ui)", color: "var(--text-secondary)", maxWidth: "30ch" }}>Everything you need to write better, faster, every day.</p>
          </div>
          <div className="e-compare">
            <div className="e-compare__row e-compare__row--head"><span>&nbsp;</span><span>Free</span><span className="e-pro">Pro</span></div>
            <div className="e-compare__row"><span>Refines / week</span><span>10</span><span className="e-pro">∞</span></div>
            <div className="e-compare__row"><span>Tones &amp; lengths</span><span>3</span><span className="e-pro">All</span></div>
            <div className="e-compare__row"><span>Voice profile</span><span>{Ic("minus")}</span><span className="e-pro">{Ic("check")}</span></div>
            <div className="e-compare__row"><span>Long-form &amp; email</span><span>{Ic("minus")}</span><span className="e-pro">{Ic("check")}</span></div>
          </div>
          <div className="e-plans">
            <button className="e-plan e-plan--on"><div><b>Yearly</b><span>$39.99/yr · $3.33/mo</span></div><span className="pp-badge pp-badge--voice">Save 40%</span></button>
            <button className="e-plan"><div><b>Monthly</b><span>$5.99/mo</span></div></button>
          </div>
        </div>
        <div style={{ padding: "0 18px 14px" }}>
          <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Start 7-day free trial</button>
        </div>
        <Home />
      </Phone>
    );
  }

  const SCREENS = [
    ["01", "Welcome", Onboard],
    ["02", "Compose", Workspace],
    ["03", "Results", Draft],
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
