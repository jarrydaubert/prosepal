/* Direction D — Calm private writing studio. Dark-first, focused,
   monochrome with a single clay accent. Chrome recedes; the page is
   the whole screen. Self-rendering. */
(function () {
  const { Ic, Status, Home, Phone } = window.KIT;
  const ROUGH = "thinking about what to say at grandmas birthday. she taught me to cook, always believed in me, want to get this right";

  function Onboard() {
    return (
      <Phone>
        <div data-theme="dark" className="d-screen">
          <Status />
          <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column", padding: "0 28px 12px" }}>
            <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", gap: 8 }}>
              <div className="d-dot" />
              <h1 style={{ fontFamily: "var(--font-reading)", fontSize: 40, fontWeight: 500, lineHeight: 1.08, letterSpacing: "-0.015em", color: "var(--text)", marginTop: 18 }}>A quiet room<br />for your words.</h1>
              <p style={{ fontFamily: "var(--font-ui)", fontSize: 17, lineHeight: 1.55, color: "var(--text-secondary)", maxWidth: "30ch" }}>No feeds. No noise. Just you, the page, and a thoughtful editor when you want one.</p>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Enter the studio</button>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, color: "var(--text-tertiary)", font: "500 13px var(--font-ui)" }}>{Ic("lock-simple")} Everything stays on your device</div>
            </div>
          </div>
          <Home />
        </div>
      </Phone>
    );
  }

  function Workspace() {
    return (
      <Phone>
        <div data-theme="dark" className="d-screen">
          <Status />
          <div className="d-bar">
            <button className="pp-iconbtn">{Ic("list")}</button>
            <span className="d-bar__title">Untitled</span>
            <button className="pp-iconbtn">{Ic("circle-half")}</button>
          </div>
          <div className="pp-screen-body" style={{ padding: "8px 28px 16px", display: "flex", flexDirection: "column" }}>
            <div className="d-write kit-text">{ROUGH}<span className="d-caret" /></div>
          </div>
          <div className="d-dock">
            <div className="d-dock__meta">{Ic("textbox")}<span className="pp-canvas__count" style={{ color: "var(--text-tertiary)" }}>24 words · draft</span></div>
            <button className="pp-btn pp-btn--primary pp-btn--md">{Ic("feather")}<span>Help me write</span></button>
          </div>
          <Home />
        </div>
      </Phone>
    );
  }

  function Draft() {
    return (
      <Phone>
        <div data-theme="dark" className="d-screen">
          <Status />
          <div className="d-bar">
            <button className="pp-iconbtn">{Ic("caret-left")}</button>
            <span className="d-bar__title">A toast</span>
            <button className="pp-iconbtn">{Ic("bookmark-simple")}</button>
          </div>
          <div className="pp-screen-body" style={{ padding: "6px 22px 14px", display: "flex", flexDirection: "column", gap: 14 }}>
            <div className="d-tabs"><span className="d-tab d-tab--on">Draft</span><span className="d-tab">Yours</span></div>
            <div className="d-draft">
              <div className="d-draft__body">
                <p>To Grandma — who taught me that a kitchen is just love you can taste.</p>
                <p>You believed in me before I knew how to believe in myself, and every good thing I've made started at your table. Happy birthday. I hope today tastes like all the ones you gave us.</p>
              </div>
              <div className="d-draft__voice">{Ic("seal-check")} Your voice, kept</div>
            </div>
            <div className="d-refine">
              <button className="d-rchip">{Ic("heart")} Warmer</button>
              <button className="d-rchip">{Ic("scissors")} Shorter</button>
              <button className="d-rchip">{Ic("smiley")} Lighter</button>
            </div>
          </div>
          <div className="d-dock">
            <button className="d-ghost">{Ic("arrow-clockwise")} Another</button>
            <button className="pp-btn pp-btn--primary pp-btn--md">{Ic("check")}<span>Use this</span></button>
          </div>
          <Home />
        </div>
      </Phone>
    );
  }

  function Refine() {
    return (
      <Phone>
        <div data-theme="dark" className="d-screen">
          <Status />
          <div className="d-bar">
            <button className="pp-iconbtn">{Ic("caret-left")}</button>
            <span className="d-bar__title">Revise</span>
            <button className="pp-iconbtn" style={{ color: "var(--accent-text)", fontSize: 15, width: "auto", padding: "0 6px" }}>Done</button>
          </div>
          <div className="pp-screen-body" style={{ padding: "8px 28px 16px", display: "flex", flexDirection: "column", gap: 18 }}>
            <div className="d-write kit-text" style={{ fontSize: 21 }}>
              You believed in me before I knew how to believe in myself, and every good thing I've made started at your <span className="d-mark">table</span>.
            </div>
            <div className="d-suggest">
              <div className="d-suggest__h">{Ic("magic-wand")} Replace "table"</div>
              <div className="d-suggest__row"><span className="d-pill d-pill--on">kitchen</span><span className="d-pill">counter</span><span className="d-pill">side</span></div>
            </div>
          </div>
          <div className="d-dock" style={{ gap: 8, overflowX: "auto" }}>
            <button className="d-rchip">{Ic("heart")} Warmer</button>
            <button className="d-rchip">{Ic("scissors")} Tighter</button>
            <button className="d-rchip">{Ic("book-open")} Richer</button>
          </div>
          <Home />
        </div>
      </Phone>
    );
  }

  function Upgrade() {
    return (
      <Phone>
        <div data-theme="dark" className="d-screen">
          <Status />
          <div className="d-bar"><button className="pp-iconbtn">{Ic("x")}</button><span className="d-bar__title" /><button className="pp-iconbtn" style={{ width: "auto", fontSize: 13, padding: "0 6px", color: "var(--text-tertiary)" }}>Restore</button></div>
          <div className="pp-screen-body" style={{ padding: "8px 28px 14px", display: "flex", flexDirection: "column", gap: 20 }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <div className="d-dot" />
              <h2 style={{ fontFamily: "var(--font-reading)", fontSize: 32, fontWeight: 500, letterSpacing: "-0.01em", color: "var(--text)", marginTop: 12 }}>The studio, always open.</h2>
              <p style={{ font: "400 16px/1.5 var(--font-ui)", color: "var(--text-secondary)" }}>More drafts and a private voice profile — for the price of a good notebook each month.</p>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div className="d-feat">{Ic("arrow-circle-up")}<span>Higher writing limits</span></div>
              <div className="d-feat">{Ic("user-focus")}<span>A voice profile that's yours</span></div>
              <div className="d-feat">{Ic("lock-simple")}<span>On-device &amp; private, always</span></div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              <button className="d-plan d-plan--on"><span className="pp-plan__radio" /><span style={{ flex: 1 }}><b>Yearly</b> · $3.33/mo</span><span className="pp-badge pp-badge--voice">Save 40%</span></button>
              <button className="d-plan"><span className="pp-plan__radio" /><span style={{ flex: 1 }}><b>Monthly</b></span><span style={{ color: "var(--text-tertiary)", fontSize: 14 }}>$5.99/mo</span></button>
            </div>
          </div>
          <div className="d-dock"><button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Start 7-day free trial</button></div>
          <Home />
        </div>
      </Phone>
    );
  }

  const SCREENS = [
    ["01", "Welcome", Onboard],
    ["02", "The studio", Workspace],
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
