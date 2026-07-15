/* ProsePal flagship — Account & system surfaces.
   Glass nav/chrome; content on opaque cream (no ruled lines). */
(function () {
  const { Ic, Status, Home, Phone } = window.KIT;
  const { WASH, GNav } = window.PPK;

  // ---- Settings / account ----
  function Settings() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav large serif title="Settings"
          lead={<button className="pp-navbar__btn">Done</button>} />
        <div className="pp-screen-body" style={{ padding: "2px 18px 20px", display: "flex", flexDirection: "column", gap: 18 }}>
          <div className="pc-profile">
            <span className="pp-avatar pp-avatar--lg">MO</span>
            <div style={{ flex: 1 }}>
              <div className="pc-profile__name">Maya Okafor</div>
              <div className="pc-profile__mail">maya.okafor@icloud.com</div>
            </div>
            <span className="pp-badge pp-badge--accent">Pro</span>
          </div>

          <div className="pc-group">
            <div className="pc-group__h">Writing</div>
            <div className="pp-listgroup">
              <div className="pp-row pp-row--tap"><span className="pp-row__lead">{Ic("paint-brush-broad")}</span><span className="pp-row__body"><span className="pp-row__title">Default tone</span><span className="pp-row__sub">Diplomatic · Warm</span></span><span className="pp-row__trail">Edit</span><span className="pp-row__chevron">{Ic("caret-right")}</span></div>
              <div className="pp-row"><span className="pp-row__lead">{Ic("user-focus")}</span><span className="pp-row__body"><span className="pp-row__title">Voice profile</span><span className="pp-row__sub">Learns how you write</span></span><span className="pp-switch" aria-checked="true" role="switch"><span className="pp-switch__knob" /></span></div>
              <div className="pp-row pp-row--tap"><span className="pp-row__lead">{Ic("textbox")}</span><span className="pp-row__body"><span className="pp-row__title">Reading text size</span></span><span className="pp-row__trail">Medium</span><span className="pp-row__chevron">{Ic("caret-right")}</span></div>
            </div>
          </div>

          <div className="pc-group">
            <div className="pc-group__h">Privacy</div>
            <div className="pp-listgroup">
              <div className="pp-row"><span className="pp-row__lead">{Ic("lock-simple")}</span><span className="pp-row__body"><span className="pp-row__title">Private mode</span><span className="pp-row__sub">Keep drafts on this device</span></span><span className="pp-switch" aria-checked="true" role="switch"><span className="pp-switch__knob" /></span></div>
              <div className="pp-row pp-row--tap"><span className="pp-row__lead">{Ic("shield-check")}</span><span className="pp-row__body"><span className="pp-row__title">Privacy &amp; data</span></span><span className="pp-row__chevron">{Ic("caret-right")}</span></div>
            </div>
          </div>

          <div className="pc-group">
            <div className="pc-group__h">Subscription</div>
            <div className="pp-listgroup">
              <div className="pp-row pp-row--tap"><span className="pp-row__lead">{Ic("seal-check")}</span><span className="pp-row__body"><span className="pp-row__title">ProsePal Pro</span><span className="pp-row__sub">Renews Mar 14, 2027</span></span><span className="pp-row__chevron">{Ic("caret-right")}</span></div>
              <div className="pp-row pp-row--tap"><span className="pp-row__lead">{Ic("lifebuoy")}</span><span className="pp-row__body"><span className="pp-row__title">Help &amp; support</span></span><span className="pp-row__chevron">{Ic("caret-right")}</span></div>
            </div>
          </div>
          <button className="pp-btn pp-btn--ghost pp-btn--md" style={{ color: "var(--danger)", alignSelf: "center" }}>Sign out</button>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Privacy & data ----
  function Privacy() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="Privacy &amp; data"
          lead={<button className="pp-navbar__btn">{Ic("caret-left")} Settings</button>} />
        <div className="pp-screen-body" style={{ padding: "8px 18px 20px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div className="pp-trust">
            <span className="pp-trust__icon">{Ic("lock-simple")}</span>
            <div>
              <div className="pp-trust__title">Your writing stays yours</div>
              <div className="pp-trust__body">ProsePal processes drafts privately. Your words are never used to train models, and you can erase them at any time.</div>
            </div>
          </div>
          <div className="pc-group">
            <div className="pc-group__h">Controls</div>
            <div className="pp-listgroup">
              <div className="pp-row"><span className="pp-row__lead">{Ic("device-mobile")}</span><span className="pp-row__body"><span className="pp-row__title">On-device drafts</span><span className="pp-row__sub">Process without leaving your iPhone</span></span><span className="pp-switch" aria-checked="true" role="switch"><span className="pp-switch__knob" /></span></div>
              <div className="pp-row"><span className="pp-row__lead">{Ic("chart-line")}</span><span className="pp-row__body"><span className="pp-row__title">Anonymous diagnostics</span><span className="pp-row__sub">Help improve ProsePal</span></span><span className="pp-switch" aria-checked="false" role="switch"><span className="pp-switch__knob" /></span></div>
            </div>
          </div>
          <div className="pc-group">
            <div className="pc-group__h">Your data</div>
            <div className="pp-listgroup">
              <div className="pp-row pp-row--tap"><span className="pp-row__lead">{Ic("export")}</span><span className="pp-row__body"><span className="pp-row__title">Export all drafts</span></span><span className="pp-row__chevron">{Ic("caret-right")}</span></div>
              <div className="pp-row pp-row--tap"><span className="pp-row__lead" style={{ color: "var(--danger)" }}>{Ic("trash")}</span><span className="pp-row__body"><span className="pp-row__title" style={{ color: "var(--danger)" }}>Delete all drafts</span></span><span className="pp-row__chevron">{Ic("caret-right")}</span></div>
            </div>
          </div>
          <p style={{ font: "400 12px/1.5 var(--font-ui)", color: "var(--text-quaternary)", textAlign: "center", padding: "0 12px" }}>Read our <a href="#" style={{ color: "var(--text-tertiary)" }}>Privacy Policy</a>. ProsePal is designed to collect as little as possible.</p>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Subscription — Free ----
  function SubFree() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="Your plan" lead={<button className="pp-navbar__btn">{Ic("caret-left")} Settings</button>} />
        <div className="pp-screen-body" style={{ padding: "8px 18px 20px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div className="pp-card pp-usage">
            <div className="pp-usage__head">
              <div className="pp-usage__plan"><span className="pp-usage__planname">Free plan</span><span className="pp-badge pp-badge--outline">Free</span></div>
              <span className="pp-usage__period">current allowance</span>
            </div>
            <div>
              <div className="pp-usage__count" style={{ marginBottom: 8 }}><span className="pp-usage__countnum">Usage updates after ProsePal syncs your allowance.</span></div>
            </div>
          </div>
          <div className="pc-upsell">
            <div className="pc-upsell__h"><span className="pc-crest" style={{ width: 44, height: 44, fontSize: 21, borderRadius: 14 }}>{Ic("feather")}</span><div><div style={{ font: "600 16px var(--font-ui)", color: "var(--text)" }}>Go further with Pro</div><div style={{ font: "400 13px var(--font-ui)", color: "var(--text-tertiary)" }}>For the messages that matter most</div></div></div>
            <ul className="pc-upsell__list">
              <li>{Ic("arrow-circle-up")} More drafts &amp; refines</li>
              <li>{Ic("book-bookmark")} A voice profile that's yours</li>
              <li>{Ic("sliders")} Every tone &amp; length</li>
            </ul>
            <button className="pp-btn pp-btn--primary pp-btn--lg pp-btn--block">See Pro</button>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Subscription — Pro ----
  function SubPro() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="Your plan" lead={<button className="pp-navbar__btn">{Ic("caret-left")} Settings</button>} />
        <div className="pp-screen-body" style={{ padding: "8px 18px 20px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div className="pc-proCard">
            <div className="pc-proCard__crest">{Ic("seal-check")}</div>
            <div className="pc-proCard__name">ProsePal Pro</div>
            <div className="pc-proCard__sub">Yearly · renews Mar 14, 2027</div>
            <div className="pc-proCard__price">$39.99<span>/yr</span></div>
          </div>
          <div className="pc-group">
            <div className="pc-group__h">Included</div>
            <div className="pp-listgroup">
              <div className="pp-row"><span className="pp-row__lead" style={{ color: "var(--voice)" }}>{Ic("arrow-circle-up")}</span><span className="pp-row__body"><span className="pp-row__title">Higher writing limits</span></span><span className="pp-row__trail" style={{ color: "var(--voice)" }}>{Ic("check")}</span></div>
              <div className="pp-row"><span className="pp-row__lead" style={{ color: "var(--voice)" }}>{Ic("user-focus")}</span><span className="pp-row__body"><span className="pp-row__title">Voice profile</span><span className="pp-row__sub">Active &amp; learning</span></span><span className="pp-row__trail" style={{ color: "var(--voice)" }}>{Ic("check")}</span></div>
            </div>
          </div>
          <div className="pp-listgroup">
            <div className="pp-row pp-row--tap"><span className="pp-row__lead">{Ic("receipt")}</span><span className="pp-row__body"><span className="pp-row__title">Manage subscription</span></span><span className="pp-row__chevron">{Ic("caret-right")}</span></div>
          </div>
        </div>
        <Home />
      </Phone>
    );
  }

  // ---- Paywall (the upgrade preview) ----
  function Paywall() {
    return (
      <Phone bg={WASH}>
        <Status />
        <GNav title="" lead={<button className="pp-navbar__btn pp-navbar__btn--icon">{Ic("x")}</button>} trail={<button className="pp-navbar__btn">Restore</button>} />
        <div className="pp-screen-body" style={{ padding: "0 18px" }}>
          <div className="pp-paywall" style={{ padding: "10px 4px 16px", gap: 16 }}>
            <div className="pp-paywall__hero">
              <div className="pc-crest" style={{ width: 64, height: 64, fontSize: 30 }}>{Ic("feather")}</div>
              <h2 className="pp-paywall__title" style={{ fontFamily: "var(--font-reading)", fontStyle: "italic", fontWeight: 400 }}>A room of your own.</h2>
              <p className="pp-paywall__sub">More drafts and refines, every register of tone, and a voice profile that remembers how you write.</p>
            </div>
            <div className="pc-panel" style={{ padding: "4px 16px" }}>
              <ul className="pp-paywall__features" style={{ margin: "13px 0" }}>
                <li><span className="ic">{Ic("arrow-circle-up")}</span><div><div className="ft-t">More drafts and refines</div><div className="ft-s">Higher limits for the messages you shape</div></div></li>
                <li><span className="ic">{Ic("book-bookmark")}</span><div><div className="ft-t">Your voice profile</div><div className="ft-s">ProsePal learns your cadence over time</div></div></li>
                <li><span className="ic">{Ic("lock-simple")}</span><div><div className="ft-t">Kept private</div><div className="ft-s">Your pages never train a model</div></div></li>
              </ul>
            </div>
            <div className="pp-plans">
              <button className="pc-plan" aria-pressed="true">
                <span className="pc-plan__radio" />
                <span className="pc-plan__body"><b>Yearly<span className="pp-badge pp-badge--voice" style={{ marginLeft: 8, verticalAlign: "1px" }}>Best value</span></b><span>$3.33 / month, billed yearly</span></span>
                <span className="pc-plan__price"><b>$39.99</b><span>/yr</span></span>
              </button>
              <button className="pc-plan">
                <span className="pc-plan__radio" />
                <span className="pc-plan__body"><b>Monthly</b><span>Billed monthly</span></span>
                <span className="pc-plan__price"><b>$5.99</b><span>/mo</span></span>
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

  window.PPReg.add("Account & system", "Glass nav over opaque cream lists — no ruled lines on system surfaces", [
    ["12", "Settings", Settings],
    ["13", "Privacy & data", Privacy],
    ["14", "Plan · Free", SubFree],
    ["15", "Plan · Pro", SubPro],
    ["16", "Paywall", Paywall],
  ]);
})();
