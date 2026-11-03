/* ProsePal flagship — Result & revise + Library & history. */
(function () {
  const { Ic, Status, Home, Phone } = window.KIT;
  const { WASH, GNav, Dock } = window.PPK;

  // ---- Draft result: CLEAN unruled cream (polished output) ----
  function Draft() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="A draft"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")} Today</button>}
          trail={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("bookmark-simple")}</button>} />
        <div className="pp-screen-body" style={{ padding: "4px 18px 14px", display: "flex", flexDirection: "column", gap: 13 }}>
          <div className="pc-draft">
            <div className="pc-draft__head">
              <span className="pc-draft__label">Diplomatic &amp; warm</span>
              <div className="pp-draft__variants"><span className="dot dot--on" /><span className="dot" /><span className="dot" /></div>
            </div>
            <div className="pc-draft__body">
              <p>Dear Mr. Alvarez,</p>
              <p>After six happy years, we've decided not to renew our lease when it ends in August. It wasn't an easy choice — this home has meant a great deal to us — and we wanted to tell you early so the timing is gentle on your side.</p>
              <p>Thank you for being so good to us.</p>
            </div>
            <div className="pc-draft__voice">{Ic("seal-check")} Still unmistakably you</div>
            <div className="pc-draft__foot">
              <button className="pp-draftbtn">{Ic("copy")} Copy</button>
              <button className="pp-draftbtn">{Ic("arrow-clockwise")} Another</button>
              <span className="pc-spacer" />
              <button className="pp-draftbtn pp-draftbtn--accent">{Ic("check")} Keep this</button>
            </div>
          </div>
          <div className="pc-margin">
            <span className="pc-margin__icon">{Ic("note-pencil")}</span>
            <div><b>Margin note</b><p>"It wasn't an easy choice" softens the news without blurring your decision.</p></div>
          </div>
        </div>
        <div style={{ padding: "0 16px 12px" }}>
          <div className="pc-floatbar">
            <span className="pc-floatbar__lead">{Ic("magic-wand")}</span>
            <div className="pc-floatbar__scroll">
              <button className="pc-chip">{Ic("heart")} Warmer</button>
              <button className="pc-chip">{Ic("scissors")} Shorter</button>
              <button className="pc-chip">{Ic("scales")} Softer</button>
              <button className="pc-chip">{Ic("flag-banner")} Firmer</button>
            </div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Revise: ruled (active editing) + glass suggestion ----
  function Revise() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="Revise"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")}</button>}
          trail={<button className="pp-navbar__btn" style={{ fontWeight: 600, color: "var(--accent-text)" }}>Done</button>} />
        <div className="pp-screen-body" style={{ padding: "6px 18px 14px", display: "flex", flexDirection: "column", gap: 14 }}>
          <div className="pc-seg">
            <button className="pc-seg__i pc-seg__i--on">Draft</button>
            <button className="pc-seg__i">Changes</button>
            <button className="pc-seg__i">Original</button>
          </div>
          <div className="pc-page">
            <div className="pc-ruled kit-text" style={{ minHeight: 136 }}>
              After six <span className="pc-mark">happy</span> years, we've decided not to renew our lease when it ends in August. It wasn't an easy choice — this home has meant a great deal to us.
            </div>
          </div>
          <div className="pc-suggest">
            <div className="pc-suggest__h">{Ic("magic-wand")} Replace "happy"</div>
            <div className="pc-suggest__row">
              <span className="pc-pill pc-pill--on">good</span>
              <span className="pc-pill">wonderful</span>
              <span className="pc-pill">settled</span>
              <span className="pc-pill">grateful</span>
            </div>
          </div>
          <div className="pp-tones__row">
            <button className="pc-chip" aria-pressed="true">{Ic("heart")} Warmer</button>
            <button className="pc-chip">{Ic("scissors")} Tighter</button>
            <button className="pc-chip">{Ic("book-open")} Richer</button>
          </div>
        </div>
        <div style={{ padding: "10px 18px 12px", borderTop: "0.5px dashed var(--border)" }}>
          <button className="pp-btn pp-btn--primary pp-btn--lg pp-btn--block">{Ic("check")} Keep this draft</button>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Drafts library: clean cream cards on the wash ----
  const LIB = [
    { t: "To Mr. Alvarez — lease", s: "Diplomatic · Warm", excerpt: "After six happy years, we've decided not to renew…", tone: "Kept", when: "Just now", glyph: "house-line" },
    { t: "Reply to Daniel", s: "Warm · Brief", excerpt: "Thank you so much for the invitation — I won't be able…", tone: "Used", when: "Yesterday", glyph: "chat-circle" },
    { t: "Resignation note", s: "Diplomatic", excerpt: "After a great deal of thought, I've decided to step back…", tone: "Draft", when: "Mon", glyph: "briefcase" },
    { t: "Grandma's birthday toast", s: "Heartfelt", excerpt: "To Grandma — who taught me that a kitchen is just love…", tone: "Used", when: "Last week", glyph: "cake" },
  ];
  function Library() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav large serif title="Drafts"
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("list")}</button>}
          trail={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("magnifying-glass")}</button>} />
        <div className="pp-screen-body" style={{ padding: "0 18px 16px", display: "flex", flexDirection: "column", gap: 11 }}>
          <div className="pc-libfilter">
            <button className="pc-chip" aria-pressed="true">All</button>
            <button className="pc-chip">Kept</button>
            <button className="pc-chip">Used</button>
            <button className="pc-chip">Drafts</button>
          </div>
          {LIB.map((d, i) => (
            <div className="pc-libcard" key={i}>
              <div className="pc-libcard__top">
                <span className="pc-libcard__icon">{Ic(d.glyph)}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="pc-libcard__t">{d.t}</div>
                  <div className="pc-libcard__s">{d.s}</div>
                </div>
                <span className={"pp-badge " + (d.tone === "Kept" ? "pp-badge--voice" : d.tone === "Used" ? "pp-badge--accent" : "pp-badge--outline")}>{d.tone}</span>
              </div>
              <div className="pc-libcard__excerpt">{d.excerpt}</div>
              <div className="pc-libcard__when">{Ic("clock")}<span style={{ fontFamily: "var(--font-mono)", fontSize: 11 }}>{d.when}</span></div>
            </div>
          ))}
        </div>
        <Dock active="drafts" />
        <Home />
      </Phone>
    );
  }

  // ---- Draft history: version timeline for one draft ----
  function History() {
    const versions = [
      { tone: "Diplomatic & warm", note: "Current", txt: "After six happy years, we've decided not to renew our lease…", on: true },
      { tone: "Softer", note: "10:24", txt: "We've had six wonderful years here, and after a lot of thought…" },
      { tone: "Firmer", note: "10:21", txt: "This is to confirm we won't be renewing our lease in August." },
      { tone: "Your note", note: "Original", txt: "telling my landlord were not renewing the lease…", orig: true },
    ];
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="Version history"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")} Draft</button>} />
        <div className="pp-screen-body" style={{ padding: "8px 18px 18px" }}>
          <div className="pc-timeline">
            {versions.map((v, i) => (
              <div className={"pc-tl" + (v.on ? " pc-tl--on" : "")} key={i}>
                <span className="pc-tl__node">{v.orig ? Ic("pencil-simple") : Ic("feather")}</span>
                <div className="pc-tl__card">
                  <div className="pc-tl__head"><span className="pc-tl__tone">{v.tone}</span><span className="pc-tl__when">{v.note}</span></div>
                  <div className={"pc-tl__txt" + (v.orig ? " pc-tl__txt--orig" : "")}>{v.txt}</div>
                  {v.on && <div className="pc-tl__badge">{Ic("check")} Showing now</div>}
                  {!v.on && !v.orig && <button className="pc-tl__restore">{Ic("arrow-counter-clockwise")} Restore</button>}
                </div>
              </div>
            ))}
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Library empty state (first run) ----
  function LibraryEmpty() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav large serif title="Drafts"
          lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("list")}</button>} />
        <div className="pp-screen-body" style={{ display: "flex", flexDirection: "column" }}>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", textAlign: "center", padding: "0 36px", gap: 8 }}>
            <span style={{ fontSize: 46, color: "var(--accent)", opacity: 0.55, lineHeight: 0 }}>{Ic("cards-three")}</span>
            <div style={{ fontFamily: "var(--font-reading)", fontSize: 23, fontWeight: 500, color: "var(--text)", marginTop: 8 }}>Nothing here yet</div>
            <p style={{ font: "400 15px/1.5 var(--font-ui)", color: "var(--text-tertiary)", maxWidth: "26ch" }}>Every message you shape with ProsePal lands here — ready to revisit, reuse, or refine.</p>
            <button className="pp-btn pp-btn--primary pp-btn--lg" style={{ marginTop: 14 }}>{Ic("feather")} Write your first</button>
          </div>
        </div>
        <Dock active="drafts" />
        <Home />
      </Phone>
    );
  }

  window.PPReg.add("Result & revise", "Clean cream = polished output; revise returns to ruled (active editing)", [
    ["07", "Draft result", Draft],
    ["08", "Revise", Revise],
  ]);
  window.PPReg.add("Library & history", "Saved work — subtle paper cards, version timeline, empty state", [
    ["09", "Drafts library", Library],
    ["10", "Version history", History],
    ["11", "Empty library", LibraryEmpty],
  ]);
})();
