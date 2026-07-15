/* ProsePal flagship — Onboarding (4 panels) + Writing surface. */
(function () {
  const { Ic, Status, Home, Phone } = window.KIT;
  const { WASH, GNav, Dock } = window.PPK;
  const ROUGH = "telling my landlord were not renewing the lease. weve been here six years, want to be kind but clear about it.";

  // ---- Onboarding shell: glass progress dots + footer ----
  function OnbShell({ step, children, footer }) {
    return (
      <Phone bg={WASH}>
        <Status />
        <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column", padding: "8px 26px 14px" }}>
          <div className="pc-onb-dots">
            {[0, 1, 2, 3].map((i) => <span key={i} className={"pc-onb-dot" + (i === step ? " on" : "")} />)}
          </div>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", textAlign: "center", gap: 6 }}>
            {children}
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>{footer}</div>
        </div>
        <Home />
      </Phone>
    );
  }

  function Welcome() {
    return (
      <OnbShell step={0}
        footer={<>
          <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Begin writing</button>
          <button className="pp-btn pp-btn--ghost pp-btn--lg pp-btn--block">I already have an account</button>
        </>}>
        <div className="pc-crest">{Ic("feather")}</div>
        <div className="pp-onboard__eyebrow" style={{ color: "var(--accent-text)", marginTop: 22 }}>Welcome to ProsePal</div>
        <h1 className="pc-onb-title">Find the words<br />you <span className="i">mean.</span></h1>
        <p className="pc-onb-body">Bring the rough version. ProsePal helps you shape it — clearer, warmer, truer — and keeps it sounding like you.</p>
      </OnbShell>
    );
  }

  function OnbHow() {
    return (
      <OnbShell step={1}
        footer={<button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Next</button>}>
        <div className="pc-onb-demo">
          <div className="pc-onb-demo__row"><span className="pc-onb-demo__tag">You write</span><div className="pc-onb-demo__rough">cant make sunday, sorry</div></div>
          <div className="pc-onb-demo__arrow">{Ic("arrow-down")}</div>
          <div className="pc-onb-demo__row"><span className="pc-onb-demo__tag pc-onb-demo__tag--clay">ProsePal</span><div className="pc-onb-demo__fine">I'm so sorry, but I won't be able to make it on Sunday.</div></div>
        </div>
        <h1 className="pc-onb-title" style={{ fontSize: 34, marginTop: 22 }}>Rough in,<br /><span className="i">right words out.</span></h1>
        <p className="pc-onb-body">Type how you'd say it to yourself. Choose a tone. ProsePal does the polishing.</p>
      </OnbShell>
    );
  }

  function OnbPrivacy() {
    return (
      <OnbShell step={2}
        footer={<button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">Next</button>}>
        <div className="pc-crest" style={{ background: "linear-gradient(158deg, var(--voice), oklch(0.44 0.05 158))" }}>{Ic("lock-simple")}</div>
        <h1 className="pc-onb-title" style={{ fontSize: 34, marginTop: 22 }}>Your words<br /><span className="i">stay yours.</span></h1>
        <p className="pc-onb-body">Drafts are processed privately and never used to train models. Delete anything, anytime.</p>
        <ul className="pc-onb-list">
          <li>{Ic("check")} On-device drafts by default</li>
          <li>{Ic("check")} No training on your text</li>
          <li>{Ic("check")} Export or erase in one tap</li>
        </ul>
      </OnbShell>
    );
  }

  function OnbReady() {
    return (
      <OnbShell step={3}
        footer={<>
          <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">{Ic("bell")} Turn on gentle reminders</button>
          <button className="pp-btn pp-btn--ghost pp-btn--lg pp-btn--block">Maybe later</button>
        </>}>
        <div className="pc-crest">{Ic("paper-plane-tilt")}</div>
        <h1 className="pc-onb-title" style={{ fontSize: 36, marginTop: 22 }}>You're <span className="i">ready.</span></h1>
        <p className="pc-onb-body">Want a quiet nudge when a message has been waiting? No noise — just a hand when you need one.</p>
      </OnbShell>
    );
  }

  // ---- Writing: the ruled cream page (composing) ----
  function ThePage() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav large serif title="Today"
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("list")}</button>}
          trail={<span className="pp-avatar pp-avatar--sm">MO</span>} />
        <div className="pp-screen-body" style={{ padding: "2px 18px 16px", display: "flex", flexDirection: "column", gap: 18 }}>
          <div className="pc-page">
            <div className="pc-prompt">The note</div>
            <div className="pc-ruled kit-text">{ROUGH}</div>
            <div className="pc-page__foot">
              <div style={{ display: "flex", gap: 2 }}>
                <button className="pp-iconbtn pp-iconbtn--sm">{Ic("microphone")}</button>
                <button className="pp-iconbtn pp-iconbtn--sm">{Ic("text-aa")}</button>
              </div>
              <button className="pp-btn pp-btn--primary pp-btn--md">{Ic("feather")}<span>Help me write</span></button>
            </div>
          </div>
          <div className="pp-tones">
            <div className="pp-tones__head"><span className="pp-tones__title" style={{ fontFamily: "var(--font-reading)", fontSize: 21, fontWeight: 500 }}>How should it read?</span><span className="pp-tones__hint">Pick a few</span></div>
            <div className="pp-tones__row">
              <button className="pc-chip" aria-pressed="true">{Ic("scales")} Diplomatic</button>
              <button className="pc-chip" aria-pressed="true">{Ic("heart")} Warm</button>
              <button className="pc-chip">{Ic("feather")} Graceful</button>
              <button className="pc-chip">{Ic("flag-banner")} Firm</button>
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, color: "var(--text-tertiary)" }}>
            {Ic("sparkle")}<span style={{ fontFamily: "var(--font-mono)", fontSize: 12 }}>Allowance managed by ProsePal</span>
          </div>
        </div>
        <Dock active="new" />
        <Home />
      </Phone>
    );
  }

  function Generating() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="Writing…" lead={<button className="pp-navbar__btn">{Ic("caret-left")} Today</button>} />
        <div className="pp-screen-body" style={{ padding: "6px 18px 16px", display: "flex", flexDirection: "column", gap: 14 }}>
          <div className="pp-card pp-card--inset pp-card--pad" style={{ display: "flex", flexDirection: "column", gap: 5 }}>
            <span className="pc-prompt" style={{ color: "var(--text-tertiary)" }}>Your note</span>
            <div style={{ fontFamily: "var(--font-reading)", fontSize: 16, color: "var(--text-tertiary)", lineHeight: 1.5 }}>{ROUGH}</div>
          </div>
          <div className="pc-page" style={{ paddingTop: 20 }}>
            <div className="pp-gen" style={{ padding: 0, gap: 18 }}>
              <div className="pp-gen__status"><span className="pp-gen__orb" />Finding the right words…</div>
              <div className="pp-gen__lines">
                <div className="pp-skel pp-skel--title" />
                <div className="pp-skel" style={{ width: "100%" }} />
                <div className="pp-skel" style={{ width: "96%" }} />
                <div className="pp-skel" style={{ width: "100%" }} />
                <div className="pp-skel" style={{ width: "58%" }} />
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 7, color: "var(--voice)", font: "400 13px var(--font-ui)" }}>{Ic("seal-check")} Keeping your voice</div>
            </div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  window.PPReg.add("Onboarding", "First run — welcome, how it works, the privacy promise, ready", [
    ["01", "Welcome", Welcome],
    ["02", "How it works", OnbHow],
    ["03", "Privacy promise", OnbPrivacy],
    ["04", "Ready", OnbReady],
  ]);
  window.PPReg.add("Writing", "Ruled cream = composing & drafting (the note is the hero)", [
    ["05", "The page", ThePage],
    ["06", "Generating", Generating],
  ]);
})();
