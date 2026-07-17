/* ProsePal flagship — Sheets, overlays & states.
   Overlays are glass; the writing behind stays literary cream. */
(function () {
  const { Ic, Status, Home, Phone } = window.KIT;
  const { WASH, GNav, Sheet, Toast, Banner } = window.PPK;

  // A quiet cream draft, used as the backdrop behind overlays
  function DraftBackdrop({ dim }) {
    return (
      <>
        <GNav title="A draft" lead={<button className="pp-navbar__btn">{Ic("caret-left")} Today</button>} trail={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("bookmark-simple")}</button>} />
        <div className="pp-screen-body" style={{ padding: "4px 18px 14px", filter: dim ? "saturate(0.96)" : "none" }}>
          <div className="pc-draft">
            <div className="pc-draft__head"><span className="pc-draft__label">Diplomatic &amp; warm</span><div className="pp-draft__variants"><span className="dot dot--on" /><span className="dot" /><span className="dot" /></div></div>
            <div className="pc-draft__body">
              <p>Dear Mr. Alvarez,</p>
              <p>After six happy years, we've decided not to renew our lease when it ends in August. It wasn't an easy choice — and we wanted to tell you early.</p>
            </div>
            <div className="pc-draft__voice">{Ic("seal-check")} Still unmistakably you</div>
          </div>
        </div>
      </>
    );
  }

  // ---- Share / insert sheet (glass, over dimmed draft) ----
  function ShareSheet() {
    const dests = [
      { i: "chat-circle", l: "Messages", c: "var(--success)" },
      { i: "envelope-simple", l: "Mail", c: "var(--info)" },
      { i: "notebook", l: "Notes", c: "var(--warning)" },
      { i: "dots-three-circle", l: "More", c: "var(--text-tertiary)" },
    ];
    return (
      <Phone bg={WASH}>
        <Status />
        <DraftBackdrop dim />
        <div className="pc-scrim" />
        <div className="pc-sheetwrap">
          <Sheet title="Use this draft">
            <div className="pc-sheet__preview">
              <div className="pc-sheet__previewlabel">{Ic("seal-check")} Diplomatic &amp; warm · your voice kept</div>
              <div className="pc-sheet__previewtxt">"Dear Mr. Alvarez, After six happy years, we've decided not to renew our lease…"</div>
            </div>
            <div className="pc-sheet__dests">
              {dests.map((d, i) => (
                <button className="pc-dest" key={i}><span className="pc-dest__icon" style={{ color: d.c }}>{Ic(d.i)}</span><span>{d.l}</span></button>
              ))}
            </div>
            <div className="pp-listgroup" style={{ background: "transparent" }}>
              <button className="pc-sheetrow"><span className="pc-sheetrow__icon">{Ic("copy")}</span>Copy to clipboard<span className="pc-spacer" />{Ic("caret-right")}</button>
              <button className="pc-sheetrow"><span className="pc-sheetrow__icon">{Ic("bookmark-simple")}</span>Save to drafts<span className="pc-spacer" />{Ic("caret-right")}</button>
            </div>
            <button className="pp-btn pp-btn--neutral pp-btn--lg pp-btn--block" style={{ marginTop: 4 }}>Cancel</button>
          </Sheet>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Copied toast ----
  function CopiedToast() {
    return (
      <Phone bg={WASH}>
        <Status />
        <DraftBackdrop />
        <div className="pc-toastwrap"><Toast icon="check-circle">Copied — your voice and all</Toast></div>
        <Home />
      </Phone>
    );
  }

  // ---- Offline / connection ----
  function Offline() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav large serif title="Today" lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("list")}</button>} trail={<span className="pp-avatar pp-avatar--sm">MO</span>} />
        <div style={{ padding: "0 18px" }}><Banner icon="cloud-slash" tone="warning" title="You're offline — drafts are saved here and will sync later" /></div>
        <div className="pp-screen-body" style={{ padding: "12px 18px 16px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div className="pc-page">
            <div className="pc-prompt">The note</div>
            <div className="pc-ruled kit-text">telling my landlord were not renewing the lease. weve been here six years…</div>
            <div className="pc-page__foot">
              <span style={{ font: "400 13px var(--font-ui)", color: "var(--text-tertiary)" }}>Saved locally</span>
              <button className="pp-btn pp-btn--neutral pp-btn--md" disabled>{Ic("feather")}<span>Refine when online</span></button>
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, color: "var(--text-tertiary)", font: "400 13px var(--font-ui)" }}>{Ic("arrows-clockwise")} Retrying connection…</div>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Generation error (couldn't finish) ----
  function GenError() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="A draft" lead={<button className="pp-navbar__btn">{Ic("caret-left")} Today</button>} />
        <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column", padding: "0 18px 16px" }}>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", textAlign: "center", gap: 8, padding: "0 22px" }}>
            <span style={{ width: 60, height: 60, borderRadius: 18, display: "grid", placeItems: "center", fontSize: 28, background: "var(--warning-soft)", color: "var(--warning)" }}>{Ic("cloud-warning")}</span>
            <div style={{ fontFamily: "var(--font-reading)", fontSize: 23, fontWeight: 500, color: "var(--text)", marginTop: 8 }}>That didn't go through</div>
            <p style={{ font: "400 15px/1.5 var(--font-ui)", color: "var(--text-tertiary)", maxWidth: "26ch" }}>We couldn't finish your draft just now. Your note is safe — nothing was lost.</p>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <button className="pp-btn pp-btn--primary pp-btn--lg pp-btn--block">{Ic("arrow-clockwise")} Try again</button>
            <button className="pp-btn pp-btn--ghost pp-btn--md pp-btn--block">Back to your note</button>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Quota reached (free limit) ----
  function Quota() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="" lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("x")}</button>} />
        <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column", padding: "0 18px 16px" }}>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", textAlign: "center", gap: 7, padding: "0 18px" }}>
            <div className="pc-crest" style={{ width: 60, height: 60, fontSize: 28 }}>{Ic("hourglass-medium")}</div>
            <h2 style={{ fontFamily: "var(--font-reading)", fontSize: 26, fontWeight: 500, color: "var(--text)", marginTop: 12 }}>Draft limit reached</h2>
            <p style={{ font: "400 15px/1.55 var(--font-ui)", color: "var(--text-secondary)", maxWidth: "28ch" }}>The service supplies the current allowance message. Pro offers higher writing limits.</p>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <button className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block">{Ic("feather")} View Pro options</button>
            <button className="pp-btn pp-btn--ghost pp-btn--md pp-btn--block">Back to your note</button>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  window.PPReg.add("Sheets & states", "Overlays are glass; errors & empties stay warm and reassuring", [
    ["17", "Share / insert", ShareSheet],
    ["18", "Copied toast", CopiedToast],
    ["19", "Offline", Offline],
    ["20", "Generation error", GenError],
    ["21", "Quota reached", Quota],
  ]);

  // All sections registered — render the rail.
  window.PPReg.render();
})();
