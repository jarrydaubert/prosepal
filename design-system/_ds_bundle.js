/* @ds-bundle: {"format":3,"namespace":"ProsePalDesignSystem_019e02","components":[{"name":"Avatar","sourcePath":"components/core/Avatar.jsx"},{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"Divider","sourcePath":"components/core/Divider.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"ListRow","sourcePath":"components/core/ListRow.jsx"},{"name":"Meter","sourcePath":"components/core/Meter.jsx"},{"name":"SegmentedControl","sourcePath":"components/core/SegmentedControl.jsx"},{"name":"Switch","sourcePath":"components/core/Switch.jsx"},{"name":"ToneChip","sourcePath":"components/core/ToneChip.jsx"},{"name":"NavBar","sourcePath":"components/ios/NavBar.jsx"},{"name":"PhoneFrame","sourcePath":"components/ios/PhoneFrame.jsx"},{"name":"StatusBar","sourcePath":"components/ios/PhoneFrame.jsx"},{"name":"HomeIndicator","sourcePath":"components/ios/PhoneFrame.jsx"},{"name":"TabBar","sourcePath":"components/ios/TabBar.jsx"},{"name":"EmptyState","sourcePath":"components/product/EmptyState.jsx"},{"name":"OnboardingCard","sourcePath":"components/product/OnboardingCard.jsx"},{"name":"Paywall","sourcePath":"components/product/Paywall.jsx"},{"name":"TrustNote","sourcePath":"components/product/TrustNote.jsx"},{"name":"UsageCard","sourcePath":"components/product/UsageCard.jsx"},{"name":"DraftCard","sourcePath":"components/writing/DraftCard.jsx"},{"name":"GenerationState","sourcePath":"components/writing/GenerationState.jsx"},{"name":"RefineBar","sourcePath":"components/writing/RefineBar.jsx"},{"name":"ToneSelector","sourcePath":"components/writing/ToneSelector.jsx"},{"name":"WritingCanvas","sourcePath":"components/writing/WritingCanvas.jsx"}],"sourceHashes":{"components/core/Avatar.jsx":"a6192ddb175b","components/core/Badge.jsx":"0bd4b7f9c095","components/core/Button.jsx":"fdad93afae54","components/core/Card.jsx":"e4e9085e2575","components/core/Divider.jsx":"ebd319b94478","components/core/IconButton.jsx":"4844fefe3972","components/core/ListRow.jsx":"7fe835da6388","components/core/Meter.jsx":"55d459df8638","components/core/SegmentedControl.jsx":"08b13b25dc9c","components/core/Switch.jsx":"0d4ed1126799","components/core/ToneChip.jsx":"87cb42f4e5b4","components/ios/NavBar.jsx":"6311f3d3d453","components/ios/PhoneFrame.jsx":"9eb6da383a79","components/ios/TabBar.jsx":"f93a3dc582fa","components/product/EmptyState.jsx":"7d6f9dedc554","components/product/OnboardingCard.jsx":"202e97f9b5d3","components/product/Paywall.jsx":"e9db7badfd18","components/product/TrustNote.jsx":"f198c0d6c278","components/product/UsageCard.jsx":"82c6f6a53361","components/writing/DraftCard.jsx":"d9dc6b29d98b","components/writing/GenerationState.jsx":"ba66637dac31","components/writing/RefineBar.jsx":"f07c3dde4737","components/writing/ToneSelector.jsx":"b8f52cb6f740","components/writing/WritingCanvas.jsx":"630bb3966739","ui_kits/_shared/frame.jsx":"0efab8622df3","ui_kits/prosepal-glass/screens.jsx":"f4b7f99f0cc9","ui_kits/prosepal-minimalist/screens.jsx":"29be50034738","ui_kits/prosepal-modern/screens.jsx":"d3dad191d34c","ui_kits/prosepal-notebook/screens.jsx":"74dc5d0dae32","ui_kits/prosepal-studio/screens.jsx":"590a21736c6a","ui_kits/prosepal/reg.jsx":"09887808e743","ui_kits/prosepal/screens-1.jsx":"d9cf2d659caa","ui_kits/prosepal/screens-2.jsx":"602031aeb787","ui_kits/prosepal/screens-3.jsx":"cec2c7d7ad92","ui_kits/prosepal/screens-4.jsx":"2d8750b43b79"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.ProsePalDesignSystem_019e02 = window.ProsePalDesignSystem_019e02 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Avatar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal Avatar — initials or image. Soft clay tint by default.
 */
function Avatar({
  src = null,
  name = "",
  size = "md",
  className = "",
  ...rest
}) {
  const initials = name.split(/\s+/).filter(Boolean).slice(0, 2).map(w => w[0]).join("").toUpperCase();
  const cls = ["pp-avatar", size !== "md" ? `pp-avatar--${size}` : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("span", _extends({
    className: cls
  }, rest), src ? /*#__PURE__*/React.createElement("img", {
    src: src,
    alt: name
  }) : initials || "·");
}
Object.assign(__ds_scope, { Avatar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Avatar.jsx", error: String((e && e.message) || e) }); }

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal Badge — a small status/label pill. Optional leading dot.
 */
function Badge({
  tone = "neutral",
  dot = false,
  icon = null,
  className = "",
  children,
  ...rest
}) {
  const cls = ["pp-badge", tone !== "neutral" ? `pp-badge--${tone}` : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("span", _extends({
    className: cls
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    className: "pp-badge__dot",
    "aria-hidden": "true"
  }), icon && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      lineHeight: 0,
      fontSize: "1.05em"
    }
  }, icon), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal Button — capsule, semibold, calm press-shrink.
 * Variants: primary · secondary · neutral · ghost · outline · danger
 */
function Button({
  variant = "primary",
  size = "lg",
  block = false,
  loading = false,
  disabled = false,
  icon = null,
  iconTrailing = null,
  className = "",
  children,
  ...rest
}) {
  const cls = ["pp-btn", `pp-btn--${variant}`, `pp-btn--${size}`, block ? "pp-btn--block" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("button", _extends({
    className: cls,
    disabled: disabled || loading,
    "aria-busy": loading || undefined
  }, rest), loading ? /*#__PURE__*/React.createElement("span", {
    className: "pp-spinner",
    "aria-hidden": "true"
  }) : icon && /*#__PURE__*/React.createElement("span", {
    className: "pp-btn__icon",
    "aria-hidden": "true"
  }, icon), children && /*#__PURE__*/React.createElement("span", {
    className: "pp-btn__label"
  }, children), iconTrailing && !loading && /*#__PURE__*/React.createElement("span", {
    className: "pp-btn__icon",
    "aria-hidden": "true"
  }, iconTrailing));
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal Card — the soft paper surface everything sits on.
 * Variants: default · flat · raised · inset.
 */
function Card({
  variant = "default",
  pad = "none",
  interactive = false,
  as: Tag = "div",
  className = "",
  style,
  children,
  ...rest
}) {
  const cls = ["pp-card", variant !== "default" ? `pp-card--${variant}` : "", pad === "md" ? "pp-card--pad" : pad === "lg" ? "pp-card--pad-lg" : "", interactive ? "pp-card--interactive" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement(Tag, _extends({
    className: cls,
    style: style
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/Divider.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal Divider — hairline separator, optionally with a centered label.
 */
function Divider({
  label = null,
  className = "",
  ...rest
}) {
  if (label) {
    return /*#__PURE__*/React.createElement("div", _extends({
      className: ["pp-divider--label", className].filter(Boolean).join(" ")
    }, rest), label);
  }
  return /*#__PURE__*/React.createElement("hr", _extends({
    className: ["pp-divider", className].filter(Boolean).join(" ")
  }, rest));
}
Object.assign(__ds_scope, { Divider });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Divider.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal IconButton — a circular tap target for nav & toolbar glyphs.
 * Variants: plain · filled · accent.
 */
function IconButton({
  icon,
  label,
  variant = "plain",
  size = "md",
  disabled = false,
  className = "",
  ...rest
}) {
  const cls = ["pp-iconbtn", variant !== "plain" ? `pp-iconbtn--${variant}` : "", size !== "md" ? `pp-iconbtn--${size}` : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("button", _extends({
    className: cls,
    "aria-label": label,
    disabled: disabled
  }, rest), /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      lineHeight: 0,
      display: "inline-flex"
    }
  }, icon));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/ListRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal ListRow — a grouped settings/menu row. Wrap rows in
 * <div className="pp-listgroup"> for the inset card look.
 */
function ListRow({
  lead = null,
  title,
  subtitle = null,
  trailing = null,
  chevron = false,
  onClick,
  className = "",
  ...rest
}) {
  const tap = !!onClick;
  const cls = ["pp-row", tap ? "pp-row--tap" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("div", _extends({
    className: cls,
    onClick: onClick,
    role: tap ? "button" : undefined
  }, rest), lead && /*#__PURE__*/React.createElement("span", {
    className: "pp-row__lead",
    "aria-hidden": "true"
  }, lead), /*#__PURE__*/React.createElement("span", {
    className: "pp-row__body"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-row__title"
  }, title), subtitle && /*#__PURE__*/React.createElement("span", {
    className: "pp-row__sub"
  }, subtitle)), trailing && /*#__PURE__*/React.createElement("span", {
    className: "pp-row__trail"
  }, trailing), chevron && /*#__PURE__*/React.createElement("span", {
    className: "pp-row__chevron",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("i", {
    className: "ph ph-caret-right"
  })));
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/core/Meter.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal Meter — usage / progress bar (refines used, voice match, etc).
 */
function Meter({
  value = 0,
  max = 100,
  tone = "accent",
  thin = false,
  className = "",
  ...rest
}) {
  const pct = Math.max(0, Math.min(100, value / max * 100));
  const fillCls = ["pp-meter__fill", tone !== "accent" ? `pp-meter__fill--${tone}` : ""].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-meter", thin ? "pp-meter--thin" : "", className].filter(Boolean).join(" "),
    role: "progressbar",
    "aria-valuenow": value,
    "aria-valuemax": max
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "pp-meter__track"
  }, /*#__PURE__*/React.createElement("div", {
    className: fillCls,
    style: {
      width: `${pct}%`
    }
  })));
}
Object.assign(__ds_scope, { Meter });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Meter.jsx", error: String((e && e.message) || e) }); }

// components/core/SegmentedControl.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal SegmentedControl — iOS pill switcher.
 * Controlled: `items` of { value, label, icon? }, `value`, `onChange`.
 */
function SegmentedControl({
  items = [],
  value,
  onChange,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-segmented", className].filter(Boolean).join(" "),
    role: "tablist"
  }, rest), items.map(it => /*#__PURE__*/React.createElement("button", {
    key: it.value,
    type: "button",
    role: "tab",
    "aria-selected": value === it.value,
    className: "pp-segmented__item",
    onClick: () => onChange && onChange(it.value)
  }, it.icon && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      lineHeight: 0,
      fontSize: 16
    }
  }, it.icon), it.label)));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/core/Switch.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal Switch — the iOS toggle. Controlled via `checked` + `onChange`.
 */
function Switch({
  checked = false,
  onChange,
  disabled = false,
  label,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": checked,
    "aria-label": label,
    disabled: disabled,
    className: ["pp-switch", className].filter(Boolean).join(" "),
    onClick: () => onChange && onChange(!checked)
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "pp-switch__knob",
    "aria-hidden": "true"
  }));
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Switch.jsx", error: String((e && e.message) || e) }); }

// components/core/ToneChip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal ToneChip — a selectable capsule for tone/style selection.
 * Use inside ToneSelector or anywhere a soft single/multi choice is needed.
 */
function ToneChip({
  selected = false,
  icon = null,
  ghost = false,
  className = "",
  onClick,
  children,
  ...rest
}) {
  const cls = ["pp-chip", ghost ? "pp-chip--ghost" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    className: cls,
    "aria-pressed": selected,
    onClick: onClick
  }, rest), icon && /*#__PURE__*/React.createElement("span", {
    className: "pp-chip__icon",
    "aria-hidden": "true"
  }, icon), children);
}
Object.assign(__ds_scope, { ToneChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/ToneChip.jsx", error: String((e && e.message) || e) }); }

// components/ios/NavBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal NavBar — iOS navigation bar. Inline title by default,
 * or `large` for the large-title style used on top-level screens.
 */
function NavBar({
  title,
  largeTitle,
  leading,
  trailing,
  large = false,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-navbar", className].filter(Boolean).join(" ")
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "pp-navbar__top"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-navbar__lead"
  }, leading), !large && title && /*#__PURE__*/React.createElement("span", {
    className: "pp-navbar__inline-title"
  }, title), /*#__PURE__*/React.createElement("span", {
    className: "pp-navbar__trail"
  }, trailing)), large && (largeTitle || title) && /*#__PURE__*/React.createElement("div", {
    className: "pp-navbar__largetitle"
  }, largeTitle || title));
}
Object.assign(__ds_scope, { NavBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/ios/NavBar.jsx", error: String((e && e.message) || e) }); }

// components/ios/PhoneFrame.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal PhoneFrame — an iPhone shell (Dynamic Island, rounded
 * screen) for presenting ProsePal mockups. Fill it with a StatusBar,
 * NavBar, screen content, TabBar and HomeIndicator.
 */
function PhoneFrame({
  screenBg,
  className = "",
  style,
  children,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-phone", className].filter(Boolean).join(" "),
    style: style
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "pp-phone__island",
    "aria-hidden": "true"
  }), /*#__PURE__*/React.createElement("div", {
    className: "pp-phone__screen",
    style: screenBg ? {
      background: screenBg
    } : undefined
  }, children));
}

/** The iOS status bar (time + signal/wifi/battery). */
function StatusBar({
  time = "9:41",
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-statusbar", className].filter(Boolean).join(" ")
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "pp-statusbar__time"
  }, time), /*#__PURE__*/React.createElement("span", {
    className: "pp-statusbar__icons",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("i", {
    className: "ph-fill ph-cell-signal-full"
  }), /*#__PURE__*/React.createElement("i", {
    className: "ph-fill ph-wifi-high"
  }), /*#__PURE__*/React.createElement("i", {
    className: "ph-fill ph-battery-full"
  })));
}

/** The iOS home indicator pill. */
function HomeIndicator({
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-home", className].filter(Boolean).join(" ")
  }, rest));
}
Object.assign(__ds_scope, { PhoneFrame, StatusBar, HomeIndicator });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/ios/PhoneFrame.jsx", error: String((e && e.message) || e) }); }

// components/ios/TabBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal TabBar — bottom tab bar with optional center "compose" FAB.
 * items: { value, label, icon, fab? }
 */
function TabBar({
  items = [],
  value,
  onChange,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-tabbar", className].filter(Boolean).join(" "),
    role: "tablist"
  }, rest), items.map(it => /*#__PURE__*/React.createElement("button", {
    key: it.value,
    type: "button",
    role: "tab",
    "aria-selected": value === it.value,
    className: ["pp-tab", it.fab ? "pp-tab--fab" : ""].filter(Boolean).join(" "),
    onClick: () => onChange && onChange(it.value)
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-tab__icon",
    "aria-hidden": "true"
  }, it.icon), !it.fab && /*#__PURE__*/React.createElement("span", null, it.label))));
}
Object.assign(__ds_scope, { TabBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/ios/TabBar.jsx", error: String((e && e.message) || e) }); }

// components/product/EmptyState.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal EmptyState — a calm, encouraging blank. Never a dead end.
 */
function EmptyState({
  icon,
  title,
  body,
  action = null,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-empty", className].filter(Boolean).join(" ")
  }, rest), icon && /*#__PURE__*/React.createElement("div", {
    className: "pp-empty__icon",
    "aria-hidden": "true"
  }, icon), title && /*#__PURE__*/React.createElement("div", {
    className: "pp-empty__title"
  }, title), body && /*#__PURE__*/React.createElement("p", {
    className: "pp-empty__body"
  }, body), action && /*#__PURE__*/React.createElement("div", {
    className: "pp-empty__action"
  }, action));
}
Object.assign(__ds_scope, { EmptyState });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/product/EmptyState.jsx", error: String((e && e.message) || e) }); }

// components/product/OnboardingCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal OnboardingCard — a single welcome / teaching moment.
 * One idea, one medallion, one clear action.
 */
function OnboardingCard({
  icon,
  eyebrow,
  title,
  body,
  actions,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-onboard", className].filter(Boolean).join(" ")
  }, rest), icon && /*#__PURE__*/React.createElement("div", {
    className: "pp-onboard__medallion",
    "aria-hidden": "true"
  }, icon), eyebrow && /*#__PURE__*/React.createElement("div", {
    className: "pp-onboard__eyebrow"
  }, eyebrow), title && /*#__PURE__*/React.createElement("h2", {
    className: "pp-onboard__title"
  }, title), body && /*#__PURE__*/React.createElement("p", {
    className: "pp-onboard__body"
  }, body), actions && /*#__PURE__*/React.createElement("div", {
    className: "pp-onboard__actions"
  }, actions));
}
Object.assign(__ds_scope, { OnboardingCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/product/OnboardingCard.jsx", error: String((e && e.message) || e) }); }

// components/product/Paywall.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal Paywall — the upgrade preview. Leads with the felt value
 * ("unlimited refines, every voice"), not a feature dump. Calm.
 */
function Paywall({
  icon = /*#__PURE__*/React.createElement("i", {
    className: "ph ph-feather"
  }),
  title = "ProsePal Pro",
  sub,
  features = [],
  plans = [],
  value,
  onSelect,
  cta = "Start free trial",
  onCta,
  fine,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-paywall", className].filter(Boolean).join(" ")
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "pp-paywall__hero"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pp-paywall__crest",
    "aria-hidden": "true"
  }, icon), /*#__PURE__*/React.createElement("h2", {
    className: "pp-paywall__title"
  }, title), sub && /*#__PURE__*/React.createElement("p", {
    className: "pp-paywall__sub"
  }, sub)), features.length > 0 && /*#__PURE__*/React.createElement("ul", {
    className: "pp-paywall__features"
  }, features.map((f, i) => /*#__PURE__*/React.createElement("li", {
    key: i
  }, /*#__PURE__*/React.createElement("span", {
    className: "ic",
    "aria-hidden": "true"
  }, f.icon || /*#__PURE__*/React.createElement("i", {
    className: "ph ph-check"
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "ft-t"
  }, f.title), f.sub && /*#__PURE__*/React.createElement("div", {
    className: "ft-s"
  }, f.sub))))), plans.length > 0 && /*#__PURE__*/React.createElement("div", {
    className: "pp-plans"
  }, plans.map(p => /*#__PURE__*/React.createElement("button", {
    key: p.id,
    type: "button",
    className: "pp-plan",
    "aria-pressed": value === p.id,
    onClick: () => onSelect && onSelect(p.id)
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-plan__radio",
    "aria-hidden": "true"
  }), /*#__PURE__*/React.createElement("span", {
    className: "pp-plan__body"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-plan__name"
  }, p.name, p.badge && /*#__PURE__*/React.createElement("span", {
    className: "pp-badge pp-badge--voice",
    style: {
      marginLeft: 8
    }
  }, p.badge)), p.meta && /*#__PURE__*/React.createElement("span", {
    className: "pp-plan__meta"
  }, p.meta)), /*#__PURE__*/React.createElement("span", {
    className: "pp-plan__price"
  }, /*#__PURE__*/React.createElement("b", null, p.price), /*#__PURE__*/React.createElement("span", null, p.per))))), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block",
    onClick: onCta
  }, cta), fine && /*#__PURE__*/React.createElement("div", {
    className: "pp-paywall__fine"
  }, fine));
}
Object.assign(__ds_scope, { Paywall });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/product/Paywall.jsx", error: String((e && e.message) || e) }); }

// components/product/TrustNote.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal TrustNote — privacy / trust reassurance. Sage-tinted,
 * quietly confident. Use a list of points or a single line.
 */
function TrustNote({
  icon = /*#__PURE__*/React.createElement("i", {
    className: "ph ph-lock-simple"
  }),
  title,
  body,
  points = null,
  inline = false,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-trust", inline ? "pp-trust--inline" : "", className].filter(Boolean).join(" ")
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "pp-trust__icon",
    "aria-hidden": "true"
  }, icon), /*#__PURE__*/React.createElement("div", null, title && /*#__PURE__*/React.createElement("div", {
    className: "pp-trust__title"
  }, title), body && /*#__PURE__*/React.createElement("div", {
    className: "pp-trust__body"
  }, body), points && /*#__PURE__*/React.createElement("ul", {
    className: "pp-trust__list"
  }, points.map((p, i) => /*#__PURE__*/React.createElement("li", {
    key: i
  }, /*#__PURE__*/React.createElement("i", {
    className: "ph ph-check"
  }), p)))));
}
Object.assign(__ds_scope, { TrustNote });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/product/TrustNote.jsx", error: String((e && e.message) || e) }); }

// components/product/UsageCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal UsageCard — subscription / usage state. Shows the plan,
 * how much of the period's allowance is used, and a quiet upgrade path.
 */
function UsageCard({
  plan = "Free",
  used = 0,
  total = 10,
  unit = "refines",
  period = "this week",
  reset = null,
  action = null,
  className = "",
  ...rest
}) {
  const low = total - used <= Math.max(1, Math.round(total * 0.25));
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-card", "pp-usage", className].filter(Boolean).join(" ")
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "pp-usage__head"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pp-usage__plan"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-usage__planname"
  }, plan, " plan"), /*#__PURE__*/React.createElement("span", {
    className: "pp-badge " + (plan === "Free" ? "pp-badge--outline" : "pp-badge--accent")
  }, plan === "Free" ? "Free" : "Pro")), /*#__PURE__*/React.createElement("span", {
    className: "pp-usage__period"
  }, period)), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "pp-usage__count",
    style: {
      marginBottom: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-usage__countnum"
  }, /*#__PURE__*/React.createElement("b", null, Math.max(0, total - used)), " of ", total, " ", unit, " left"), reset && /*#__PURE__*/React.createElement("span", {
    className: "pp-usage__reset"
  }, reset)), /*#__PURE__*/React.createElement(__ds_scope.Meter, {
    value: used,
    max: total,
    tone: low ? "warning" : "accent"
  })), action);
}
Object.assign(__ds_scope, { UsageCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/product/UsageCard.jsx", error: String((e && e.message) || e) }); }

// components/writing/DraftCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal DraftCard — a generated draft. The draft text is the
 * hero; meta sits quietly above, actions quietly below. ProsePal
 * never claims your words — the "voice kept" marker reassures.
 */
function DraftCard({
  label = "Draft",
  tones = [],
  voiceNote = null,
  variants = null,
  raised = false,
  actions = null,
  children,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-draft", raised ? "pp-draft--raised" : "", className].filter(Boolean).join(" ")
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "pp-draft__head"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pp-draft__meta"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-draft__label"
  }, label), tones.map(t => /*#__PURE__*/React.createElement("span", {
    key: t,
    className: "pp-badge pp-badge--accent"
  }, t))), variants && /*#__PURE__*/React.createElement("div", {
    className: "pp-draft__variants",
    "aria-label": `Variant ${variants.current} of ${variants.total}`
  }, Array.from({
    length: variants.total
  }).map((_, i) => /*#__PURE__*/React.createElement("span", {
    key: i,
    className: "dot" + (i === variants.current - 1 ? " dot--on" : "")
  })))), /*#__PURE__*/React.createElement("div", {
    className: "pp-draft__body"
  }, children), voiceNote && /*#__PURE__*/React.createElement("div", {
    className: "pp-draft__voice"
  }, /*#__PURE__*/React.createElement("i", {
    className: "ph ph-seal-check"
  }), voiceNote), actions && /*#__PURE__*/React.createElement("div", {
    className: "pp-draft__foot"
  }, actions));
}
Object.assign(__ds_scope, { DraftCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/writing/DraftCard.jsx", error: String((e && e.message) || e) }); }

// components/writing/GenerationState.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal GenerationState — the calm "thinking" state. A breathing
 * clay orb, a reassuring status line, and shimmering draft lines.
 */
function GenerationState({
  label = "Finding the right words…",
  lines = 4,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-gen", className].filter(Boolean).join(" "),
    role: "status",
    "aria-live": "polite"
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "pp-gen__status"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-gen__orb",
    "aria-hidden": "true"
  }), label), /*#__PURE__*/React.createElement("div", {
    className: "pp-gen__lines",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pp-skel pp-skel--title"
  }), Array.from({
    length: Math.max(1, lines)
  }).map((_, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    className: "pp-skel",
    style: {
      width: i === lines - 1 ? "64%" : "100%"
    }
  }))));
}
Object.assign(__ds_scope, { GenerationState });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/writing/GenerationState.jsx", error: String((e && e.message) || e) }); }

// components/writing/RefineBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal RefineBar — quick one-tap edits applied to an existing
 * draft (Warmer, Shorter, Sharper…). Floats above the draft.
 * `actions`: { id, label, icon }.
 */
function RefineBar({
  actions = [],
  onAction,
  lead = true,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-refine", className].filter(Boolean).join(" ")
  }, rest), lead && /*#__PURE__*/React.createElement("span", {
    className: "pp-refine__lead",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("i", {
    className: "ph ph-magic-wand"
  })), /*#__PURE__*/React.createElement("div", {
    className: "pp-refine__scroll"
  }, actions.map(a => /*#__PURE__*/React.createElement("button", {
    key: a.id,
    type: "button",
    className: "pp-chip",
    onClick: () => onAction && onAction(a.id)
  }, a.icon && /*#__PURE__*/React.createElement("span", {
    className: "pp-chip__icon",
    "aria-hidden": "true"
  }, a.icon), a.label))));
}
Object.assign(__ds_scope, { RefineBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/writing/RefineBar.jsx", error: String((e && e.message) || e) }); }

// components/writing/ToneSelector.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal ToneSelector — pick the goal for a piece of writing.
 * `options`: { id, label, icon }. Single or multi select.
 */
function ToneSelector({
  title = "How should it feel?",
  hint = null,
  options = [],
  value = [],
  onChange,
  multi = true,
  scroll = false,
  className = "",
  ...rest
}) {
  const sel = Array.isArray(value) ? value : [value];
  const toggle = id => {
    if (!onChange) return;
    if (multi) {
      onChange(sel.includes(id) ? sel.filter(x => x !== id) : [...sel, id]);
    } else {
      onChange([id]);
    }
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-tones", className].filter(Boolean).join(" ")
  }, rest), /*#__PURE__*/React.createElement("div", {
    className: "pp-tones__head"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pp-tones__title"
  }, title), hint && /*#__PURE__*/React.createElement("span", {
    className: "pp-tones__hint"
  }, hint)), /*#__PURE__*/React.createElement("div", {
    className: scroll ? "pp-tones__scroll" : "pp-tones__row"
  }, options.map(o => /*#__PURE__*/React.createElement(__ds_scope.ToneChip, {
    key: o.id,
    selected: sel.includes(o.id),
    icon: o.icon,
    onClick: () => toggle(o.id)
  }, o.label))));
}
Object.assign(__ds_scope, { ToneSelector });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/writing/ToneSelector.jsx", error: String((e && e.message) || e) }); }

// components/writing/WritingCanvas.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ProsePal WritingCanvas — the paper surface where the user writes.
 * Their words are the hero: set in the reading serif, generously led.
 */
function WritingCanvas({
  value,
  onChange,
  placeholder = "Write what's on your mind…",
  prompt = null,
  count = null,
  tools = null,
  actions = null,
  focus = false,
  rows = 4,
  className = "",
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    className: ["pp-canvas", focus ? "pp-canvas--focus" : "", className].filter(Boolean).join(" ")
  }, rest), prompt && /*#__PURE__*/React.createElement("div", {
    className: "pp-canvas__prompt"
  }, prompt), /*#__PURE__*/React.createElement("textarea", {
    className: "pp-canvas__field",
    value: value,
    onChange: e => onChange && onChange(e.target.value),
    placeholder: placeholder,
    rows: rows
  }), /*#__PURE__*/React.createElement("div", {
    className: "pp-canvas__foot"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pp-canvas__tools"
  }, tools), /*#__PURE__*/React.createElement("div", {
    className: "pp-canvas__send"
  }, count != null && /*#__PURE__*/React.createElement("span", {
    className: "pp-canvas__count"
  }, count), actions)));
}
Object.assign(__ds_scope, { WritingCanvas });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/writing/WritingCanvas.jsx", error: String((e && e.message) || e) }); }

// ui_kits/_shared/frame.jsx
try { (() => {
/* Shared UI-kit helpers for ProsePal directions.
   Plain global-React functions assigned to window.KIT — intentionally
   NOT exported, so the design-system compiler does not bundle them.
   Screens read: const { Ic, Phone, Status, Home, Nav, Tab } = window.KIT; */
(function () {
  const Ic = (n, w) => /*#__PURE__*/React.createElement("i", {
    className: "ph " + (w || "ph") + " ph-" + n,
    "aria-hidden": "true"
  });
  function Status({
    time = "9:41"
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "pp-statusbar"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-statusbar__time"
    }, time), /*#__PURE__*/React.createElement("span", {
      className: "pp-statusbar__icons"
    }, /*#__PURE__*/React.createElement("i", {
      className: "ph-fill ph-cell-signal-full"
    }), /*#__PURE__*/React.createElement("i", {
      className: "ph-fill ph-wifi-high"
    }), /*#__PURE__*/React.createElement("i", {
      className: "ph-fill ph-battery-full"
    })));
  }
  function Home() {
    return /*#__PURE__*/React.createElement("div", {
      className: "pp-home"
    });
  }
  function Phone({
    children,
    bg,
    className = ""
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "pp-phone " + className
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-phone__island"
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-phone__screen",
      style: bg ? {
        background: bg
      } : undefined
    }, children));
  }
  function Nav({
    title,
    large,
    lead,
    trail
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "pp-navbar"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-navbar__top"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__lead"
    }, lead), !large && title && /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__inline-title"
    }, title), /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__trail"
    }, trail)), large && title && /*#__PURE__*/React.createElement("div", {
      className: "pp-navbar__largetitle"
    }, title));
  }
  function Tab({
    active = "new"
  }) {
    const items = [{
      v: "drafts",
      label: "Drafts",
      icon: "cards"
    }, {
      v: "new",
      label: "",
      icon: "feather",
      fab: true
    }, {
      v: "library",
      label: "Library",
      icon: "bookmarks-simple"
    }];
    return /*#__PURE__*/React.createElement("div", {
      className: "pp-tabbar"
    }, items.map(it => /*#__PURE__*/React.createElement("button", {
      key: it.v,
      className: "pp-tab" + (it.fab ? " pp-tab--fab" : ""),
      "aria-selected": active === it.v
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tab__icon"
    }, Ic(it.icon, active === it.v && !it.fab ? "ph-fill" : "ph")), !it.fab && /*#__PURE__*/React.createElement("span", null, it.label))));
  }
  window.KIT = {
    Ic,
    Status,
    Home,
    Phone,
    Nav,
    Tab
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/_shared/frame.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal-glass/screens.jsx
try { (() => {
/* Direction C — Premium glassy iOS 26. Translucent glass panels
   floating over a soft warm wash; vibrant-but-calm. Self-rendering. */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone
  } = window.KIT;
  const ROUGH = "can we push our call to thursday? something came up and i dont want to rush it";

  // Glass-styled chrome (overrides the opaque defaults)
  function GNav({
    title,
    large,
    lead,
    trail
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "g-nav"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-navbar__top"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__lead"
    }, lead), !large && title && /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__inline-title"
    }, title), /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__trail"
    }, trail)), large && title && /*#__PURE__*/React.createElement("div", {
      className: "pp-navbar__largetitle"
    }, title));
  }
  function GTab() {
    return /*#__PURE__*/React.createElement("div", {
      className: "g-tabwrap"
    }, /*#__PURE__*/React.createElement("div", {
      className: "g-tab"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-tab",
      "aria-selected": "false"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tab__icon"
    }, Ic("cards")), /*#__PURE__*/React.createElement("span", null, "Drafts")), /*#__PURE__*/React.createElement("button", {
      className: "pp-tab pp-tab--fab"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tab__icon"
    }, Ic("feather"))), /*#__PURE__*/React.createElement("button", {
      className: "pp-tab",
      "aria-selected": "true"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tab__icon"
    }, Ic("bookmarks-simple", "ph-fill")), /*#__PURE__*/React.createElement("span", null, "Library"))));
  }
  function Onboard() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--g-wash)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column",
        padding: "0 24px 10px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
        gap: 6
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "g-orb"
    }, Ic("feather")), /*#__PURE__*/React.createElement("h1", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 42,
        fontWeight: 500,
        lineHeight: 1.05,
        letterSpacing: "-0.015em",
        margin: "22px 0 6px",
        color: "var(--text)"
      }
    }, "Words that", /*#__PURE__*/React.createElement("br", null), "carry weight."), /*#__PURE__*/React.createElement("p", {
      className: "pp-onboard__body"
    }, "A calmer way to write the message you've been putting off \u2014 clearer, kinder, and still yours.")), /*#__PURE__*/React.createElement("div", {
      className: "g-panel",
      style: {
        padding: 14,
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Get started"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 7,
        color: "var(--text-secondary)",
        font: "500 13px var(--font-ui)"
      }
    }, Ic("lock-simple"), " Private by default"))), /*#__PURE__*/React.createElement(Home, null));
  }
  function Workspace() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--g-wash)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      large: true,
      title: "Compose",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("list")),
      trail: /*#__PURE__*/React.createElement("span", {
        className: "pp-avatar pp-avatar--sm"
      }, "MO")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "2px 18px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "g-panel g-canvas"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__prompt"
    }, "What do you want to say?"), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__field kit-text",
      style: {
        minHeight: 96
      }
    }, ROUGH), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__foot",
      style: {
        borderTopColor: "var(--glass-stroke-soft)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__tools"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn pp-iconbtn--sm"
    }, Ic("microphone")), /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn pp-iconbtn--sm"
    }, Ic("paperclip"))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--md"
    }, Ic("feather"), /*#__PURE__*/React.createElement("span", null, "Refine")))), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tones__title"
    }, "How should it feel?")), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row"
    }, /*#__PURE__*/React.createElement("button", {
      className: "g-chip",
      "aria-pressed": "true"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "g-chip"
    }, Ic("clock"), " Relaxed"), /*#__PURE__*/React.createElement("button", {
      className: "g-chip",
      "aria-pressed": "true"
    }, Ic("scissors"), " Brief"), /*#__PURE__*/React.createElement("button", {
      className: "g-chip"
    }, Ic("flag-banner"), " Direct"))), /*#__PURE__*/React.createElement("div", {
      className: "g-panel",
      style: {
        padding: "12px 16px",
        display: "flex",
        alignItems: "center",
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("span", {
      className: "g-mini-meter"
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: "30%"
      }
    })), /*#__PURE__*/React.createElement("span", {
      style: {
        font: "500 13px var(--font-ui)",
        color: "var(--text-secondary)",
        whiteSpace: "nowrap"
      }
    }, "7 of 10 refines"))), /*#__PURE__*/React.createElement(GTab, null), /*#__PURE__*/React.createElement(Home, null));
  }
  function Draft() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--g-wash)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "Draft",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Compose"),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("share-network"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "4px 18px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "g-panel g-draft"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__head",
      style: {
        paddingTop: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__meta"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-draft__label"
    }, "Draft"), /*#__PURE__*/React.createElement("span", {
      className: "g-badge"
    }, "Warmer"), /*#__PURE__*/React.createElement("span", {
      className: "g-badge"
    }, "Brief")), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__variants"
    }, /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot dot--on"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__body",
      style: {
        fontSize: 20
      }
    }, /*#__PURE__*/React.createElement("p", null, "Hi! Would Thursday work instead of our call? Something's come up, and I'd rather give this the time it deserves than rush it.")), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__voice"
    }, Ic("seal-check"), " Your voice, kept"), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__foot",
      style: {
        borderTopColor: "var(--glass-stroke-soft)"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn"
    }, Ic("copy"), " Copy"), /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn"
    }, Ic("arrow-clockwise"), " Again"), /*#__PURE__*/React.createElement("span", {
      className: "pp-spacer"
    }), /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn pp-draftbtn--accent"
    }, Ic("check"), " Use this"))), /*#__PURE__*/React.createElement("div", {
      className: "g-floatbar"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-refine__lead"
    }, Ic("magic-wand")), /*#__PURE__*/React.createElement("div", {
      className: "pp-refine__scroll"
    }, /*#__PURE__*/React.createElement("button", {
      className: "g-chip"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "g-chip"
    }, Ic("scissors"), " Shorter"), /*#__PURE__*/React.createElement("button", {
      className: "g-chip"
    }, Ic("sparkle"), " Sharper")))), /*#__PURE__*/React.createElement(Home, null));
  }
  function Refine() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--g-wash)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "Refine",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn",
        style: {
          fontWeight: 600,
          color: "var(--accent-text)"
        }
      }, "Done")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "6px 18px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "g-seg"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-segmented__item",
      "aria-selected": "true"
    }, "Draft"), /*#__PURE__*/React.createElement("button", {
      className: "pp-segmented__item"
    }, "Changes"), /*#__PURE__*/React.createElement("button", {
      className: "pp-segmented__item"
    }, "Original")), /*#__PURE__*/React.createElement("div", {
      className: "g-panel g-canvas"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__field kit-text",
      style: {
        minHeight: 130,
        fontSize: 20
      }
    }, "Hi! Would Thursday work instead of our call? Something's come up, and I'd rather give this the time it deserves than rush it.")), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tones__title",
      style: {
        fontSize: 15
      }
    }, "Adjust the tone")), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row"
    }, /*#__PURE__*/React.createElement("button", {
      className: "g-chip",
      "aria-pressed": "true"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "g-chip"
    }, Ic("scissors"), " Shorter"), /*#__PURE__*/React.createElement("button", {
      className: "g-chip"
    }, Ic("briefcase"), " Formal"), /*#__PURE__*/React.createElement("button", {
      className: "g-chip"
    }, Ic("smiley"), " Playful")))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 18px 14px"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--lg pp-btn--block"
    }, Ic("check"), " Use this draft")), /*#__PURE__*/React.createElement(Home, null));
  }
  function Upgrade() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--g-wash)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("x")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, "Restore")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "0 16px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall",
      style: {
        padding: "12px 6px 18px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__hero"
    }, /*#__PURE__*/React.createElement("div", {
      className: "g-orb",
      style: {
        width: 64,
        height: 64,
        fontSize: 30
      }
    }, Ic("feather")), /*#__PURE__*/React.createElement("h2", {
      className: "pp-paywall__title"
    }, "Write without limits"), /*#__PURE__*/React.createElement("p", {
      className: "pp-paywall__sub"
    }, "Unlimited refines, every tone, and a private voice profile that's yours alone.")), /*#__PURE__*/React.createElement("div", {
      className: "g-panel",
      style: {
        padding: "6px 16px"
      }
    }, /*#__PURE__*/React.createElement("ul", {
      className: "pp-paywall__features",
      style: {
        margin: "12px 0"
      }
    }, /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("infinity")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Unlimited refines"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "Polish as much as you like"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("user-focus")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Your voice profile"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "ProsePal learns how you sound"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("lock-simple")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Private by default"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "Nothing trains on your words"))))), /*#__PURE__*/React.createElement("div", {
      className: "pp-plans"
    }, /*#__PURE__*/React.createElement("button", {
      className: "g-plan",
      "aria-pressed": "true"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__name"
    }, "Yearly", /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--voice",
      style: {
        marginLeft: 8
      }
    }, "Save 40%")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__meta"
    }, "$3.33 / month")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__price"
    }, /*#__PURE__*/React.createElement("b", null, "$39.99"), /*#__PURE__*/React.createElement("span", null, "/yr"))), /*#__PURE__*/React.createElement("button", {
      className: "g-plan"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__name"
    }, "Monthly")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__price"
    }, /*#__PURE__*/React.createElement("b", null, "$5.99"), /*#__PURE__*/React.createElement("span", null, "/mo")))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Start 7-day free trial"), /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__fine"
    }, "Cancel anytime \xB7 ", /*#__PURE__*/React.createElement("a", {
      href: "#"
    }, "Terms"), " \xB7 ", /*#__PURE__*/React.createElement("a", {
      href: "#"
    }, "Privacy")))), /*#__PURE__*/React.createElement(Home, null));
  }
  const SCREENS = [["01", "Welcome", Onboard], ["02", "Compose", Workspace], ["03", "Draft result", Draft], ["04", "Refine", Refine], ["05", "Upgrade", Upgrade]];
  function App() {
    return /*#__PURE__*/React.createElement("div", {
      className: "kit-rail"
    }, SCREENS.map(([step, label, C]) => /*#__PURE__*/React.createElement("div", {
      className: "kit-screen",
      key: step
    }, /*#__PURE__*/React.createElement(C, null), /*#__PURE__*/React.createElement("div", {
      className: "kit-caption"
    }, /*#__PURE__*/React.createElement("span", {
      className: "kit-step"
    }, step), /*#__PURE__*/React.createElement("span", {
      className: "kit-label"
    }, label)))));
  }
  ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal-glass/screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal-minimalist/screens.jsx
try { (() => {
/* Direction A — Apple-native minimalist. Default tokens; native sans
   writing surface; maximum restraint. Self-rendering (no exports). */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone,
    Nav,
    Tab
  } = window.KIT;
  const ROUGH = "hey daniel, thanks for the invite but i cant make it sunday, maybe another time";
  function Onboard() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column",
        padding: "0 24px 8px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
        gap: 4
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-onboard__medallion",
      style: {
        marginBottom: 22
      }
    }, Ic("feather")), /*#__PURE__*/React.createElement("div", {
      className: "pp-onboard__eyebrow"
    }, "Welcome to ProsePal"), /*#__PURE__*/React.createElement("h1", {
      className: "pp-onboard__title",
      style: {
        fontSize: 40
      }
    }, "Say it like", /*#__PURE__*/React.createElement("br", null), "you mean it."), /*#__PURE__*/React.createElement("p", {
      className: "pp-onboard__body"
    }, "Write the rough version. ProsePal helps you make it clearer, warmer, sharper \u2014 in your own voice.")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10,
        paddingBottom: 8
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Get started"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--ghost pp-btn--lg pp-btn--block"
    }, "I already have an account"), /*#__PURE__*/React.createElement("div", {
      className: "pp-trust pp-trust--inline",
      style: {
        marginTop: 6,
        justifyContent: "center"
      }
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-trust__icon"
    }, Ic("lock-simple")), /*#__PURE__*/React.createElement("div", {
      className: "pp-trust__title",
      style: {
        fontWeight: 500
      }
    }, "Private by default \u2014 your words stay yours")))), /*#__PURE__*/React.createElement(Home, null));
  }
  function Workspace() {
    const tones = [{
      id: "warm",
      label: "Warmer",
      icon: "heart",
      on: true
    }, {
      id: "concise",
      label: "More concise",
      icon: "scissors",
      on: true
    }, {
      id: "confident",
      label: "Confident",
      icon: "flag-banner"
    }, {
      id: "formal",
      label: "Formal",
      icon: "briefcase"
    }];
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      large: true,
      title: "New draft",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("list")),
      trail: /*#__PURE__*/React.createElement("span", {
        className: "pp-avatar pp-avatar--sm"
      }, "MO")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "2px 20px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 22
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__prompt"
    }, "What do you want to say?"), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__field kit-text"
    }, ROUGH), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__foot"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__tools"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn pp-iconbtn--sm"
    }, Ic("microphone")), /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn pp-iconbtn--sm"
    }, Ic("paperclip"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__send"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-canvas__count"
    }, "14 words"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--md"
    }, Ic("feather"), /*#__PURE__*/React.createElement("span", null, "Refine"))))), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tones__title"
    }, "How should it feel?"), /*#__PURE__*/React.createElement("span", {
      className: "pp-tones__hint"
    }, "Pick a few")), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row"
    }, tones.map(t => /*#__PURE__*/React.createElement("button", {
      key: t.id,
      className: "pp-chip",
      "aria-pressed": !!t.on
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-chip__icon"
    }, Ic(t.icon)), t.label)))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        color: "var(--text-tertiary)",
        font: "400 13px var(--font-ui)"
      }
    }, Ic("lightning"), /*#__PURE__*/React.createElement("span", {
      className: "pp-mono",
      style: {
        fontSize: 12
      }
    }, "7 of 10 free refines left this week"))), /*#__PURE__*/React.createElement(Tab, {
      active: "new"
    }), /*#__PURE__*/React.createElement(Home, null));
  }
  function Draft() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "Draft",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " New"),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("share-network"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "4px 20px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-card pp-card--inset pp-card--pad",
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 6
      }
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-draft__label"
    }, "Your message"), /*#__PURE__*/React.createElement("div", {
      style: {
        font: "400 15px var(--font-ui)",
        color: "var(--text-tertiary)",
        lineHeight: 1.5
      }
    }, ROUGH)), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft pp-draft--raised"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__head"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__meta"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-draft__label"
    }, "Draft"), /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--accent"
    }, "Warmer"), /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--accent"
    }, "Concise")), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__variants"
    }, /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot dot--on"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__body"
    }, /*#__PURE__*/React.createElement("p", null, "Hi Daniel \u2014 thank you so much for the invitation. I won't be able to make it on Sunday, but I'd genuinely love to find another time soon."), /*#__PURE__*/React.createElement("p", null, "Maybe coffee next week?")), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__voice"
    }, Ic("seal-check"), " Your voice, kept"), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__foot"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn"
    }, Ic("copy"), " Copy"), /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn"
    }, Ic("arrow-clockwise"), " Try again"), /*#__PURE__*/React.createElement("span", {
      className: "pp-spacer"
    }), /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn pp-draftbtn--accent"
    }, Ic("check"), " Use this")))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 16px 10px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-refine"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-refine__lead"
    }, Ic("magic-wand")), /*#__PURE__*/React.createElement("div", {
      className: "pp-refine__scroll"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("scissors"), " Shorter"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("sparkle"), " Sharper")))), /*#__PURE__*/React.createElement(Home, null));
  }
  function Refine() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "Refine",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn",
        style: {
          fontWeight: 600,
          color: "var(--accent-text)"
        }
      }, "Done")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "6px 20px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-segmented"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-segmented__item",
      "aria-selected": "true"
    }, "Draft"), /*#__PURE__*/React.createElement("button", {
      className: "pp-segmented__item"
    }, "Changes"), /*#__PURE__*/React.createElement("button", {
      className: "pp-segmented__item"
    }, "Original")), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas pp-canvas--focus"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__field kit-text",
      style: {
        minHeight: 150
      }
    }, "Hi Daniel \u2014 thank you so much for the invitation. I won't be able to make it on Sunday, but I'd genuinely love to find another time soon. Maybe coffee next week?"), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__foot"
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: "400 13px var(--font-ui)",
        color: "var(--text-tertiary)"
      }
    }, "Tap a word to rephrase it"), /*#__PURE__*/React.createElement("span", {
      className: "pp-canvas__count"
    }, "28 words"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tones__title",
      style: {
        fontSize: 15
      }
    }, "Adjust the tone")), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-chip",
      "aria-pressed": "true"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("scissors"), " Shorter"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("briefcase"), " Formal"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("smiley"), " Playful"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip pp-chip--ghost"
    }, Ic("plus"), " Custom")))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "10px 20px 12px",
        borderTop: "0.5px solid var(--separator)"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--lg pp-btn--block"
    }, Ic("check"), " Use this draft")), /*#__PURE__*/React.createElement(Home, null));
  }
  function Upgrade() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("x")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, "Restore")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__hero"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__crest"
    }, Ic("feather")), /*#__PURE__*/React.createElement("h2", {
      className: "pp-paywall__title"
    }, "Write without limits"), /*#__PURE__*/React.createElement("p", {
      className: "pp-paywall__sub"
    }, "Unlimited refines, every tone, and your own private voice profile.")), /*#__PURE__*/React.createElement("ul", {
      className: "pp-paywall__features"
    }, /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("infinity")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Unlimited refines"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "Polish as many messages as you like"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("user-focus")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Your voice profile"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "ProsePal learns how you sound"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("lock-simple")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Private by default"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "Nothing ever trains on your words")))), /*#__PURE__*/React.createElement("div", {
      className: "pp-plans"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-plan",
      "aria-pressed": "true"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__name"
    }, "Yearly", /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--voice",
      style: {
        marginLeft: 8
      }
    }, "Save 40%")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__meta"
    }, "$3.33 / month, billed yearly")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__price"
    }, /*#__PURE__*/React.createElement("b", null, "$39.99"), /*#__PURE__*/React.createElement("span", null, "/yr"))), /*#__PURE__*/React.createElement("button", {
      className: "pp-plan"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__name"
    }, "Monthly"), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__meta"
    }, "Billed monthly")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__price"
    }, /*#__PURE__*/React.createElement("b", null, "$5.99"), /*#__PURE__*/React.createElement("span", null, "/mo")))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Start 7-day free trial"), /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__fine"
    }, "Cancel anytime \xB7 ", /*#__PURE__*/React.createElement("a", {
      href: "#"
    }, "Terms"), " \xB7 ", /*#__PURE__*/React.createElement("a", {
      href: "#"
    }, "Privacy")))), /*#__PURE__*/React.createElement(Home, null));
  }
  const SCREENS = [["01", "Welcome", Onboard], ["02", "Workspace", Workspace], ["03", "Draft result", Draft], ["04", "Refine", Refine], ["05", "Upgrade", Upgrade]];
  function App() {
    return /*#__PURE__*/React.createElement("div", {
      className: "kit-rail"
    }, SCREENS.map(([step, label, C]) => /*#__PURE__*/React.createElement("div", {
      className: "kit-screen",
      key: step
    }, /*#__PURE__*/React.createElement(C, null), /*#__PURE__*/React.createElement("div", {
      className: "kit-caption"
    }, /*#__PURE__*/React.createElement("span", {
      className: "kit-step"
    }, step), /*#__PURE__*/React.createElement("span", {
      className: "kit-label"
    }, label)))));
  }
  ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal-minimalist/screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal-modern/screens.jsx
try { (() => {
/* Direction E — Modern AI productivity, but elegant and human.
   More structured: sections, suggestion cards, light data, a touch
   of ink-blue. Still warm, never a dashboard. Self-rendering. */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone,
    Nav,
    Tab
  } = window.KIT;
  const ROUGH = "following up on my application from 2 weeks ago, still really interested in the role and wanted to check on next steps";
  function Onboard() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg-grouped)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column",
        padding: "8px 22px 12px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        gap: 18
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-logo"
    }, Ic("feather")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h1", {
      style: {
        font: "700 33px/1.1 var(--font-display)",
        letterSpacing: "-0.025em",
        color: "var(--text)"
      }
    }, "Your writing,", /*#__PURE__*/React.createElement("br", null), "leveled up."), /*#__PURE__*/React.createElement("p", {
      style: {
        font: "400 16px/1.5 var(--font-ui)",
        color: "var(--text-secondary)",
        marginTop: 10,
        maxWidth: "32ch"
      }
    }, "ProsePal turns rough notes into clear, confident messages \u2014 in seconds, in your voice.")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 9
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-bullet"
    }, Ic("lightning"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("b", null, "Refine in one tap"), /*#__PURE__*/React.createElement("span", null, "Warmer, shorter, sharper \u2014 instantly"))), /*#__PURE__*/React.createElement("div", {
      className: "e-bullet"
    }, Ic("user-focus"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("b", null, "Learns your voice"), /*#__PURE__*/React.createElement("span", null, "Sounds like you, not a template"))), /*#__PURE__*/React.createElement("div", {
      className: "e-bullet"
    }, Ic("shield-check"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("b", null, "Private by default"), /*#__PURE__*/React.createElement("span", null, "Your words never train a model"))))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Create free account"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--ghost pp-btn--lg pp-btn--block"
    }, "Sign in"))), /*#__PURE__*/React.createElement(Home, null));
  }
  function Workspace() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg-grouped)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      large: true,
      title: "Compose",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("squares-four")),
      trail: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("button", {
        className: "pp-iconbtn"
      }, Ic("clock-counter-clockwise")), /*#__PURE__*/React.createElement("span", {
        className: "pp-avatar pp-avatar--sm"
      }, "MO"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "2px 18px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-seg"
    }, /*#__PURE__*/React.createElement("button", {
      className: "e-seg__i e-seg__i--on"
    }, Ic("chat-teardrop-text"), " Message"), /*#__PURE__*/React.createElement("button", {
      className: "e-seg__i"
    }, Ic("envelope-simple"), " Email"), /*#__PURE__*/React.createElement("button", {
      className: "e-seg__i"
    }, Ic("article"), " Post")), /*#__PURE__*/React.createElement("div", {
      className: "e-card e-canvas"
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-canvas__label"
    }, "Your draft"), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__field kit-text",
      style: {
        fontFamily: "var(--font-ui)",
        fontSize: 16,
        lineHeight: 1.5,
        minHeight: 84
      }
    }, ROUGH), /*#__PURE__*/React.createElement("div", {
      className: "e-canvas__foot"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-canvas__count"
    }, "23 words"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--md"
    }, Ic("magic-wand"), /*#__PURE__*/React.createElement("span", null, "Refine")))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "e-section-h"
    }, "Goals"), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row",
      style: {
        marginTop: 9
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "e-chip e-chip--on"
    }, Ic("flag-banner"), " Professional"), /*#__PURE__*/React.createElement("button", {
      className: "e-chip e-chip--on"
    }, Ic("clock"), " Follow-up"), /*#__PURE__*/React.createElement("button", {
      className: "e-chip"
    }, Ic("scissors"), " Concise"), /*#__PURE__*/React.createElement("button", {
      className: "e-chip"
    }, Ic("smiley"), " Friendly"))), /*#__PURE__*/React.createElement("div", {
      className: "e-tip"
    }, Ic("sparkle"), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("b", null, "Suggested:"), " a polite nudge that restates your interest and asks for a timeline."))), /*#__PURE__*/React.createElement(Tab, {
      active: "new"
    }), /*#__PURE__*/React.createElement(Home, null));
  }
  function Draft() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg-grouped)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "Results",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Compose"),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-iconbtn"
      }, Ic("sliders-horizontal"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "4px 18px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-result-head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "e-section-h"
    }, "3 options"), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__variants"
    }, /*#__PURE__*/React.createElement("span", {
      className: "dot dot--on"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "e-card e-draft e-draft--on"
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-draft__top"
    }, /*#__PURE__*/React.createElement("span", {
      className: "e-badge e-badge--blue"
    }, "Recommended"), /*#__PURE__*/React.createElement("span", {
      className: "e-draft__tone"
    }, "Professional \xB7 Concise")), /*#__PURE__*/React.createElement("div", {
      className: "e-draft__body"
    }, "Hi Sarah, I wanted to follow up on my application from two weeks ago \u2014 I'm still very interested in the role. Could you share what the next steps look like? Happy to provide anything else you need."), /*#__PURE__*/React.createElement("div", {
      className: "e-draft__foot"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-draft__voice",
      style: {
        margin: 0
      }
    }, Ic("seal-check"), " Your voice, kept"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 4
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "e-iconpill"
    }, Ic("copy")), /*#__PURE__*/React.createElement("button", {
      className: "e-iconpill e-iconpill--accent"
    }, Ic("check"), " Use")))), /*#__PURE__*/React.createElement("div", {
      className: "e-card e-draft"
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-draft__top"
    }, /*#__PURE__*/React.createElement("span", {
      className: "e-draft__tone"
    }, "Warm \xB7 Brief")), /*#__PURE__*/React.createElement("div", {
      className: "e-draft__body",
      style: {
        color: "var(--text-secondary)"
      }
    }, "Hi Sarah! Just checking in on my application from a couple weeks back \u2014 still really excited about the role. Any update on next steps?"))), /*#__PURE__*/React.createElement(Home, null));
  }
  function Refine() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg-grouped)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "Refine",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn",
        style: {
          fontWeight: 600,
          color: "var(--accent-text)"
        }
      }, "Save")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "6px 18px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-seg"
    }, /*#__PURE__*/React.createElement("button", {
      className: "e-seg__i e-seg__i--on"
    }, "Edited"), /*#__PURE__*/React.createElement("button", {
      className: "e-seg__i"
    }, "Changes"), /*#__PURE__*/React.createElement("button", {
      className: "e-seg__i"
    }, "Original")), /*#__PURE__*/React.createElement("div", {
      className: "e-card e-canvas"
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-diff kit-text"
    }, /*#__PURE__*/React.createElement("span", {
      className: "e-del"
    }, "following up on my application"), " ", /*#__PURE__*/React.createElement("span", {
      className: "e-add"
    }, "I wanted to follow up on my application from two weeks ago"), " \u2014 I'm still very interested in the role.")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "e-section-h"
    }, "Quick refinements"), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row",
      style: {
        marginTop: 9
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "e-chip e-chip--on"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "e-chip"
    }, Ic("scissors"), " Shorter"), /*#__PURE__*/React.createElement("button", {
      className: "e-chip"
    }, Ic("translate"), " Simpler"), /*#__PURE__*/React.createElement("button", {
      className: "e-chip"
    }, Ic("flag-banner"), " Assertive"))), /*#__PURE__*/React.createElement("div", {
      className: "e-meter-card"
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-meter-row"
    }, /*#__PURE__*/React.createElement("span", null, "Clarity"), /*#__PURE__*/React.createElement("span", {
      className: "e-meter"
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: "92%"
      }
    }))), /*#__PURE__*/React.createElement("div", {
      className: "e-meter-row"
    }, /*#__PURE__*/React.createElement("span", null, "Warmth"), /*#__PURE__*/React.createElement("span", {
      className: "e-meter"
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: "68%",
        background: "var(--voice)"
      }
    }))))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 18px 14px"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--lg pp-btn--block"
    }, Ic("check"), " Use this draft")), /*#__PURE__*/React.createElement(Home, null));
  }
  function Upgrade() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg-grouped)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("x")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, "Restore")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "0 18px 12px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        textAlign: "center",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 6,
        paddingTop: 4
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-logo",
      style: {
        width: 56,
        height: 56,
        fontSize: 26
      }
    }, Ic("feather")), /*#__PURE__*/React.createElement("h2", {
      style: {
        font: "700 28px/1.1 var(--font-display)",
        letterSpacing: "-0.02em",
        color: "var(--text)",
        marginTop: 6
      }
    }, "Upgrade to Pro"), /*#__PURE__*/React.createElement("p", {
      style: {
        font: "400 15px/1.5 var(--font-ui)",
        color: "var(--text-secondary)",
        maxWidth: "30ch"
      }
    }, "Everything you need to write better, faster, every day.")), /*#__PURE__*/React.createElement("div", {
      className: "e-compare"
    }, /*#__PURE__*/React.createElement("div", {
      className: "e-compare__row e-compare__row--head"
    }, /*#__PURE__*/React.createElement("span", null, "\xA0"), /*#__PURE__*/React.createElement("span", null, "Free"), /*#__PURE__*/React.createElement("span", {
      className: "e-pro"
    }, "Pro")), /*#__PURE__*/React.createElement("div", {
      className: "e-compare__row"
    }, /*#__PURE__*/React.createElement("span", null, "Refines / week"), /*#__PURE__*/React.createElement("span", null, "10"), /*#__PURE__*/React.createElement("span", {
      className: "e-pro"
    }, "\u221E")), /*#__PURE__*/React.createElement("div", {
      className: "e-compare__row"
    }, /*#__PURE__*/React.createElement("span", null, "Tones & lengths"), /*#__PURE__*/React.createElement("span", null, "3"), /*#__PURE__*/React.createElement("span", {
      className: "e-pro"
    }, "All")), /*#__PURE__*/React.createElement("div", {
      className: "e-compare__row"
    }, /*#__PURE__*/React.createElement("span", null, "Voice profile"), /*#__PURE__*/React.createElement("span", null, Ic("minus")), /*#__PURE__*/React.createElement("span", {
      className: "e-pro"
    }, Ic("check"))), /*#__PURE__*/React.createElement("div", {
      className: "e-compare__row"
    }, /*#__PURE__*/React.createElement("span", null, "Long-form & email"), /*#__PURE__*/React.createElement("span", null, Ic("minus")), /*#__PURE__*/React.createElement("span", {
      className: "e-pro"
    }, Ic("check")))), /*#__PURE__*/React.createElement("div", {
      className: "e-plans"
    }, /*#__PURE__*/React.createElement("button", {
      className: "e-plan e-plan--on"
    }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("b", null, "Yearly"), /*#__PURE__*/React.createElement("span", null, "$39.99/yr \xB7 $3.33/mo")), /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--voice"
    }, "Save 40%")), /*#__PURE__*/React.createElement("button", {
      className: "e-plan"
    }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("b", null, "Monthly"), /*#__PURE__*/React.createElement("span", null, "$5.99/mo"))))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 18px 14px"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Start 7-day free trial")), /*#__PURE__*/React.createElement(Home, null));
  }
  const SCREENS = [["01", "Welcome", Onboard], ["02", "Compose", Workspace], ["03", "Results", Draft], ["04", "Refine", Refine], ["05", "Upgrade", Upgrade]];
  function App() {
    return /*#__PURE__*/React.createElement("div", {
      className: "kit-rail"
    }, SCREENS.map(([step, label, C]) => /*#__PURE__*/React.createElement("div", {
      className: "kit-screen",
      key: step
    }, /*#__PURE__*/React.createElement(C, null), /*#__PURE__*/React.createElement("div", {
      className: "kit-caption"
    }, /*#__PURE__*/React.createElement("span", {
      className: "kit-step"
    }, step), /*#__PURE__*/React.createElement("span", {
      className: "kit-label"
    }, label)))));
  }
  ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal-modern/screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal-notebook/screens.jsx
try { (() => {
/* Direction B — Warm literary notebook. Cream paper, faint ruled
   lines, serif-forward, a deeper ink-clay accent. The writing
   surface reads like a fine notebook page. Self-rendering. */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone,
    Nav,
    Tab
  } = window.KIT;
  const ROUGH = "im writing to let the team know ill be stepping back from the project. its been a hard decision but i think its the right one for me right now.";
  function Onboard() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column",
        padding: "0 26px 8px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
        gap: 6
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "nb-crest"
    }, Ic("feather")), /*#__PURE__*/React.createElement("div", {
      className: "pp-onboard__eyebrow",
      style: {
        color: "var(--accent-text)",
        marginTop: 20
      }
    }, "A writing companion"), /*#__PURE__*/React.createElement("h1", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 44,
        fontWeight: 500,
        lineHeight: 1.04,
        letterSpacing: "-0.015em",
        margin: "4px 0 6px",
        color: "var(--text)"
      }
    }, "The blank page,", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
      style: {
        fontStyle: "italic",
        fontWeight: 400
      }
    }, "made kinder.")), /*#__PURE__*/React.createElement("p", {
      className: "pp-onboard__body",
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 19,
        lineHeight: 1.55
      }
    }, "Bring the words you have. ProsePal helps you find the ones you're reaching for \u2014 and keeps them sounding like you.")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10,
        paddingBottom: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Begin writing"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--ghost pp-btn--lg pp-btn--block"
    }, "I already have an account"))), /*#__PURE__*/React.createElement(Home, null));
  }
  function Workspace() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      large: true,
      title: "Today",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("list")),
      trail: /*#__PURE__*/React.createElement("span", {
        className: "pp-avatar pp-avatar--sm"
      }, "MO")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "2px 20px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 20
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "nb-page"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__prompt",
      style: {
        color: "var(--accent-text)"
      }
    }, "The note"), /*#__PURE__*/React.createElement("div", {
      className: "nb-ruled kit-text"
    }, ROUGH), /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__foot",
      style: {
        borderTopStyle: "dashed"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-canvas__tools"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn pp-iconbtn--sm"
    }, Ic("microphone")), /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn pp-iconbtn--sm"
    }, Ic("text-aa"))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--md"
    }, Ic("feather"), /*#__PURE__*/React.createElement("span", null, "Help me write")))), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tones__title",
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 21
      }
    }, "How should it read?")), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-chip",
      "aria-pressed": "true"
    }, Ic("scales"), " Diplomatic"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip",
      "aria-pressed": "true"
    }, Ic("heart"), " Warm"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("feather"), " Graceful"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("flag-banner"), " Firm")))), /*#__PURE__*/React.createElement(Tab, {
      active: "new"
    }), /*#__PURE__*/React.createElement(Home, null));
  }
  function Draft() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "A draft",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Today"),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("bookmark-simple"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "4px 20px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "nb-draft"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__head",
      style: {
        paddingTop: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__meta"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-draft__label",
      style: {
        fontFamily: "var(--font-reading)",
        fontStyle: "italic",
        textTransform: "none",
        fontSize: 15,
        letterSpacing: 0,
        color: "var(--accent-text)"
      }
    }, "Diplomatic & warm")), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__variants"
    }, /*#__PURE__*/React.createElement("span", {
      className: "dot dot--on"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__body",
      style: {
        fontSize: 20
      }
    }, /*#__PURE__*/React.createElement("p", null, "To the team,"), /*#__PURE__*/React.createElement("p", null, "After a great deal of thought, I've decided to step back from the project. It wasn't an easy decision \u2014 this work has meant a lot to me \u2014 but it's the right one for me right now."), /*#__PURE__*/React.createElement("p", null, "Thank you for the care you've each put in. I'll do everything I can to make the handover smooth.")), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__voice"
    }, Ic("seal-check"), " Still unmistakably you"), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__foot",
      style: {
        borderTopStyle: "dashed"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn"
    }, Ic("copy"), " Copy"), /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn"
    }, Ic("arrow-clockwise"), " Another"), /*#__PURE__*/React.createElement("span", {
      className: "pp-spacer"
    }), /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn pp-draftbtn--accent"
    }, Ic("check"), " Keep this")))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 16px 12px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-refine"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-refine__lead"
    }, Ic("magic-wand")), /*#__PURE__*/React.createElement("div", {
      className: "pp-refine__scroll"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("scales"), " Softer"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("scissors"), " Shorter"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("flag-banner"), " Firmer")))), /*#__PURE__*/React.createElement(Home, null));
  }
  function Refine() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "Revise",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn",
        style: {
          fontWeight: 600,
          color: "var(--accent-text)"
        }
      }, "Done")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "6px 20px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "nb-page",
      style: {
        flex: "none"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "nb-ruled kit-text",
      style: {
        minHeight: 168
      }
    }, "After a great deal of thought, I've decided to step back from the project. It wasn't an easy decision \u2014 this work has meant a lot to me \u2014 but it's the right one for me right now.")), /*#__PURE__*/React.createElement("div", {
      className: "nb-margin"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nb-margin__icon"
    }, Ic("note-pencil")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        font: "600 14px var(--font-ui)",
        color: "var(--text)"
      }
    }, "Margin note"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 16,
        fontStyle: "italic",
        color: "var(--text-secondary)",
        lineHeight: 1.5,
        marginTop: 2
      }
    }, "\"It wasn't an easy decision\" softens the news without losing your resolve."))), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-chip",
      "aria-pressed": "true"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("scissors"), " Tighter"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip"
    }, Ic("book-open"), " Richer"), /*#__PURE__*/React.createElement("button", {
      className: "pp-chip pp-chip--ghost"
    }, Ic("plus"), " Custom")))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "10px 20px 12px",
        borderTop: "0.5px dashed var(--border)"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--lg pp-btn--block"
    }, Ic("check"), " Keep this draft")), /*#__PURE__*/React.createElement(Home, null));
  }
  function Upgrade() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: "var(--bg)"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(Nav, {
      title: "",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("x")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, "Restore")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__hero"
    }, /*#__PURE__*/React.createElement("div", {
      className: "nb-crest",
      style: {
        width: 64,
        height: 64,
        fontSize: 30
      }
    }, Ic("feather")), /*#__PURE__*/React.createElement("h2", {
      className: "pp-paywall__title",
      style: {
        fontStyle: "italic",
        fontWeight: 400
      }
    }, "A study of your own"), /*#__PURE__*/React.createElement("p", {
      className: "pp-paywall__sub"
    }, "Unlimited drafts, every register of tone, and a voice profile that remembers how you write.")), /*#__PURE__*/React.createElement("ul", {
      className: "pp-paywall__features"
    }, /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("infinity")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Unlimited drafts"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "Write and revise without counting"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("book-bookmark")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Your voice profile"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "ProsePal learns your cadence over time"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("lock-simple")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Kept private"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "Your pages never train a model")))), /*#__PURE__*/React.createElement("div", {
      className: "pp-plans"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-plan",
      "aria-pressed": "true"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__name"
    }, "Yearly", /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--voice",
      style: {
        marginLeft: 8
      }
    }, "Best value")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__meta"
    }, "$3.33 / month")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__price"
    }, /*#__PURE__*/React.createElement("b", null, "$39.99"), /*#__PURE__*/React.createElement("span", null, "/yr"))), /*#__PURE__*/React.createElement("button", {
      className: "pp-plan"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__name"
    }, "Monthly")), /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__price"
    }, /*#__PURE__*/React.createElement("b", null, "$5.99"), /*#__PURE__*/React.createElement("span", null, "/mo")))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Start 7-day free trial"), /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__fine"
    }, "Cancel anytime \xB7 ", /*#__PURE__*/React.createElement("a", {
      href: "#"
    }, "Terms"), " \xB7 ", /*#__PURE__*/React.createElement("a", {
      href: "#"
    }, "Privacy")))), /*#__PURE__*/React.createElement(Home, null));
  }
  const SCREENS = [["01", "Welcome", Onboard], ["02", "The page", Workspace], ["03", "Draft result", Draft], ["04", "Revise", Refine], ["05", "Upgrade", Upgrade]];
  function App() {
    return /*#__PURE__*/React.createElement("div", {
      className: "kit-rail"
    }, SCREENS.map(([step, label, C]) => /*#__PURE__*/React.createElement("div", {
      className: "kit-screen",
      key: step
    }, /*#__PURE__*/React.createElement(C, null), /*#__PURE__*/React.createElement("div", {
      className: "kit-caption"
    }, /*#__PURE__*/React.createElement("span", {
      className: "kit-step"
    }, step), /*#__PURE__*/React.createElement("span", {
      className: "kit-label"
    }, label)))));
  }
  ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal-notebook/screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal-studio/screens.jsx
try { (() => {
/* Direction D — Calm private writing studio. Dark-first, focused,
   monochrome with a single clay accent. Chrome recedes; the page is
   the whole screen. Self-rendering. */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone
  } = window.KIT;
  const ROUGH = "thinking about what to say at grandmas birthday. she taught me to cook, always believed in me, want to get this right";
  function Onboard() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement("div", {
      "data-theme": "dark",
      className: "d-screen"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column",
        padding: "0 28px 12px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        gap: 8
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-dot"
    }), /*#__PURE__*/React.createElement("h1", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 40,
        fontWeight: 500,
        lineHeight: 1.08,
        letterSpacing: "-0.015em",
        color: "var(--text)",
        marginTop: 18
      }
    }, "A quiet room", /*#__PURE__*/React.createElement("br", null), "for your words."), /*#__PURE__*/React.createElement("p", {
      style: {
        fontFamily: "var(--font-ui)",
        fontSize: 17,
        lineHeight: 1.55,
        color: "var(--text-secondary)",
        maxWidth: "30ch"
      }
    }, "No feeds. No noise. Just you, the page, and a thoughtful editor when you want one.")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Enter the studio"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        color: "var(--text-tertiary)",
        font: "500 13px var(--font-ui)"
      }
    }, Ic("lock-simple"), " Everything stays on your device"))), /*#__PURE__*/React.createElement(Home, null)));
  }
  function Workspace() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement("div", {
      "data-theme": "dark",
      className: "d-screen"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "d-bar"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn"
    }, Ic("list")), /*#__PURE__*/React.createElement("span", {
      className: "d-bar__title"
    }, "Untitled"), /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn"
    }, Ic("circle-half"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "8px 28px 16px",
        display: "flex",
        flexDirection: "column"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-write kit-text"
    }, ROUGH, /*#__PURE__*/React.createElement("span", {
      className: "d-caret"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "d-dock"
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-dock__meta"
    }, Ic("textbox"), /*#__PURE__*/React.createElement("span", {
      className: "pp-canvas__count",
      style: {
        color: "var(--text-tertiary)"
      }
    }, "24 words \xB7 draft")), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--md"
    }, Ic("feather"), /*#__PURE__*/React.createElement("span", null, "Help me write"))), /*#__PURE__*/React.createElement(Home, null)));
  }
  function Draft() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement("div", {
      "data-theme": "dark",
      className: "d-screen"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "d-bar"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn"
    }, Ic("caret-left")), /*#__PURE__*/React.createElement("span", {
      className: "d-bar__title"
    }, "A toast"), /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn"
    }, Ic("bookmark-simple"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "6px 22px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-tabs"
    }, /*#__PURE__*/React.createElement("span", {
      className: "d-tab d-tab--on"
    }, "Draft"), /*#__PURE__*/React.createElement("span", {
      className: "d-tab"
    }, "Yours")), /*#__PURE__*/React.createElement("div", {
      className: "d-draft"
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-draft__body"
    }, /*#__PURE__*/React.createElement("p", null, "To Grandma \u2014 who taught me that a kitchen is just love you can taste."), /*#__PURE__*/React.createElement("p", null, "You believed in me before I knew how to believe in myself, and every good thing I've made started at your table. Happy birthday. I hope today tastes like all the ones you gave us.")), /*#__PURE__*/React.createElement("div", {
      className: "d-draft__voice"
    }, Ic("seal-check"), " Your voice, kept")), /*#__PURE__*/React.createElement("div", {
      className: "d-refine"
    }, /*#__PURE__*/React.createElement("button", {
      className: "d-rchip"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "d-rchip"
    }, Ic("scissors"), " Shorter"), /*#__PURE__*/React.createElement("button", {
      className: "d-rchip"
    }, Ic("smiley"), " Lighter"))), /*#__PURE__*/React.createElement("div", {
      className: "d-dock"
    }, /*#__PURE__*/React.createElement("button", {
      className: "d-ghost"
    }, Ic("arrow-clockwise"), " Another"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--md"
    }, Ic("check"), /*#__PURE__*/React.createElement("span", null, "Use this"))), /*#__PURE__*/React.createElement(Home, null)));
  }
  function Refine() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement("div", {
      "data-theme": "dark",
      className: "d-screen"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "d-bar"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn"
    }, Ic("caret-left")), /*#__PURE__*/React.createElement("span", {
      className: "d-bar__title"
    }, "Revise"), /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn",
      style: {
        color: "var(--accent-text)",
        fontSize: 15,
        width: "auto",
        padding: "0 6px"
      }
    }, "Done")), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "8px 28px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 18
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-write kit-text",
      style: {
        fontSize: 21
      }
    }, "You believed in me before I knew how to believe in myself, and every good thing I've made started at your ", /*#__PURE__*/React.createElement("span", {
      className: "d-mark"
    }, "table"), "."), /*#__PURE__*/React.createElement("div", {
      className: "d-suggest"
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-suggest__h"
    }, Ic("magic-wand"), " Replace \"table\""), /*#__PURE__*/React.createElement("div", {
      className: "d-suggest__row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "d-pill d-pill--on"
    }, "kitchen"), /*#__PURE__*/React.createElement("span", {
      className: "d-pill"
    }, "counter"), /*#__PURE__*/React.createElement("span", {
      className: "d-pill"
    }, "side")))), /*#__PURE__*/React.createElement("div", {
      className: "d-dock",
      style: {
        gap: 8,
        overflowX: "auto"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "d-rchip"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "d-rchip"
    }, Ic("scissors"), " Tighter"), /*#__PURE__*/React.createElement("button", {
      className: "d-rchip"
    }, Ic("book-open"), " Richer")), /*#__PURE__*/React.createElement(Home, null)));
  }
  function Upgrade() {
    return /*#__PURE__*/React.createElement(Phone, null, /*#__PURE__*/React.createElement("div", {
      "data-theme": "dark",
      className: "d-screen"
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "d-bar"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn"
    }, Ic("x")), /*#__PURE__*/React.createElement("span", {
      className: "d-bar__title"
    }), /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn",
      style: {
        width: "auto",
        fontSize: 13,
        padding: "0 6px",
        color: "var(--text-tertiary)"
      }
    }, "Restore")), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "8px 28px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 20
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 8
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-dot"
    }), /*#__PURE__*/React.createElement("h2", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 32,
        fontWeight: 500,
        letterSpacing: "-0.01em",
        color: "var(--text)",
        marginTop: 12
      }
    }, "The studio, always open."), /*#__PURE__*/React.createElement("p", {
      style: {
        font: "400 16px/1.5 var(--font-ui)",
        color: "var(--text-secondary)"
      }
    }, "Unlimited drafts and a private voice profile \u2014 for the price of a good notebook each month.")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "d-feat"
    }, Ic("infinity"), /*#__PURE__*/React.createElement("span", null, "Unlimited refines & drafts")), /*#__PURE__*/React.createElement("div", {
      className: "d-feat"
    }, Ic("user-focus"), /*#__PURE__*/React.createElement("span", null, "A voice profile that's yours")), /*#__PURE__*/React.createElement("div", {
      className: "d-feat"
    }, Ic("lock-simple"), /*#__PURE__*/React.createElement("span", null, "On-device & private, always"))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "d-plan d-plan--on"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("b", null, "Yearly"), " \xB7 $3.33/mo"), /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--voice"
    }, "Save 40%")), /*#__PURE__*/React.createElement("button", {
      className: "d-plan"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("b", null, "Monthly")), /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-tertiary)",
        fontSize: 14
      }
    }, "$5.99/mo")))), /*#__PURE__*/React.createElement("div", {
      className: "d-dock"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Start 7-day free trial")), /*#__PURE__*/React.createElement(Home, null)));
  }
  const SCREENS = [["01", "Welcome", Onboard], ["02", "The studio", Workspace], ["03", "Draft result", Draft], ["04", "Revise", Refine], ["05", "Upgrade", Upgrade]];
  function App() {
    return /*#__PURE__*/React.createElement("div", {
      className: "kit-rail"
    }, SCREENS.map(([step, label, C]) => /*#__PURE__*/React.createElement("div", {
      className: "kit-screen",
      key: step
    }, /*#__PURE__*/React.createElement(C, null), /*#__PURE__*/React.createElement("div", {
      className: "kit-caption"
    }, /*#__PURE__*/React.createElement("span", {
      className: "kit-step"
    }, step), /*#__PURE__*/React.createElement("span", {
      className: "kit-label"
    }, label)))));
  }
  ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal-studio/screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal/reg.jsx
try { (() => {
/* ProsePal flagship — shared kit chrome + section registry.
   Loaded after frame.jsx, before the screen files and render.jsx.
   Exposes window.PPK (chrome helpers) and window.PPReg (sections). */
(function () {
  const {
    Ic,
    Status,
    Home
  } = window.KIT;
  const WASH = "var(--pp-wash)";

  // ---- Glass navigation bar (large or inline) ----
  function GNav({
    title,
    large,
    lead,
    trail,
    serif
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "pc-nav"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-navbar__top"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__lead"
    }, lead), !large && title && /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__inline-title"
    }, title), /*#__PURE__*/React.createElement("span", {
      className: "pp-navbar__trail"
    }, trail)), large && title && /*#__PURE__*/React.createElement("div", {
      className: "pp-navbar__largetitle",
      style: serif ? {
        fontFamily: "var(--font-reading)",
        fontWeight: 500
      } : undefined
    }, title));
  }

  // ---- Glass floating dock (tab bar) ----
  function Dock({
    active = "drafts"
  }) {
    const items = [{
      v: "drafts",
      label: "Drafts",
      icon: "cards"
    }, {
      v: "new",
      label: "",
      icon: "feather",
      fab: true
    }, {
      v: "library",
      label: "Library",
      icon: "bookmarks-simple"
    }];
    return /*#__PURE__*/React.createElement("div", {
      className: "pc-dockwrap"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-dock"
    }, items.map(it => /*#__PURE__*/React.createElement("button", {
      key: it.v,
      className: "pp-tab" + (it.fab ? " pp-tab--fab" : ""),
      "aria-selected": active === it.v
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tab__icon"
    }, Ic(it.icon, active === it.v && !it.fab ? "ph-fill" : "ph")), !it.fab && /*#__PURE__*/React.createElement("span", null, it.label)))));
  }

  // ---- Bottom glass sheet (share, options) over a dimmed screen ----
  function Sheet({
    children,
    title,
    onGrab = true
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "pc-sheet"
    }, onGrab && /*#__PURE__*/React.createElement("div", {
      className: "pc-sheet__grab"
    }), title && /*#__PURE__*/React.createElement("div", {
      className: "pc-sheet__title"
    }, title), children);
  }

  // ---- Glass toast (confirmation) ----
  function Toast({
    icon = "check-circle",
    children,
    tone
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "pc-toast" + (tone ? " pc-toast--" + tone : "")
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-toast__icon"
    }, Ic(icon, "ph-fill")), /*#__PURE__*/React.createElement("span", null, children));
  }

  // ---- Glass status banner (offline / error) pinned under the nav ----
  function Banner({
    icon = "wifi-slash",
    tone = "warning",
    title,
    action
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "pc-banner pc-banner--" + tone
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-banner__icon"
    }, Ic(icon)), /*#__PURE__*/React.createElement("span", {
      className: "pc-banner__body"
    }, title), action && /*#__PURE__*/React.createElement("button", {
      className: "pc-banner__action"
    }, action));
  }
  window.PPK = {
    WASH,
    GNav,
    Dock,
    Sheet,
    Toast,
    Banner
  };

  // ---- Section registry ----
  const reg = {
    sections: [],
    add(name, subtitle, items) {
      this.sections.push({
        name,
        subtitle,
        items
      });
    },
    render() {
      const root = ReactDOM.createRoot(document.getElementById("root"));
      const self = this;
      function Page() {
        return /*#__PURE__*/React.createElement("div", {
          className: "pp-sections"
        }, self.sections.map((sec, si) => /*#__PURE__*/React.createElement("section", {
          className: "pp-section",
          key: si
        }, /*#__PURE__*/React.createElement("div", {
          className: "pp-section__h"
        }, /*#__PURE__*/React.createElement("span", {
          className: "pp-section__n"
        }, String(si + 1).padStart(2, "0"), " \xB7 ", sec.name), sec.subtitle && /*#__PURE__*/React.createElement("span", {
          className: "pp-section__s"
        }, sec.subtitle)), /*#__PURE__*/React.createElement("div", {
          className: "pp-section__row"
        }, sec.items.map(([step, label, C], i) => /*#__PURE__*/React.createElement("div", {
          className: "kit-screen",
          key: i
        }, /*#__PURE__*/React.createElement(C, null), /*#__PURE__*/React.createElement("div", {
          className: "kit-caption"
        }, /*#__PURE__*/React.createElement("span", {
          className: "kit-step"
        }, step), /*#__PURE__*/React.createElement("span", {
          className: "kit-label"
        }, label))))))));
      }
      root.render(/*#__PURE__*/React.createElement(Page, null));
    }
  };
  window.PPReg = reg;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal/reg.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal/screens-1.jsx
try { (() => {
/* ProsePal flagship — Onboarding (4 panels) + Writing surface. */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone
  } = window.KIT;
  const {
    WASH,
    GNav,
    Dock
  } = window.PPK;
  const ROUGH = "telling my landlord were not renewing the lease. weve been here six years, want to be kind but clear about it.";

  // ---- Onboarding shell: glass progress dots + footer ----
  function OnbShell({
    step,
    children,
    footer
  }) {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column",
        padding: "8px 26px 14px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-onb-dots"
    }, [0, 1, 2, 3].map(i => /*#__PURE__*/React.createElement("span", {
      key: i,
      className: "pc-onb-dot" + (i === step ? " on" : "")
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "center",
        textAlign: "center",
        gap: 6
      }
    }, children), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, footer)), /*#__PURE__*/React.createElement(Home, null));
  }
  function Welcome() {
    return /*#__PURE__*/React.createElement(OnbShell, {
      step: 0,
      footer: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("button", {
        className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
      }, "Begin writing"), /*#__PURE__*/React.createElement("button", {
        className: "pp-btn pp-btn--ghost pp-btn--lg pp-btn--block"
      }, "I already have an account"))
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-crest"
    }, Ic("feather")), /*#__PURE__*/React.createElement("div", {
      className: "pp-onboard__eyebrow",
      style: {
        color: "var(--accent-text)",
        marginTop: 22
      }
    }, "Welcome to ProsePal"), /*#__PURE__*/React.createElement("h1", {
      className: "pc-onb-title"
    }, "Find the words", /*#__PURE__*/React.createElement("br", null), "you ", /*#__PURE__*/React.createElement("span", {
      className: "i"
    }, "mean.")), /*#__PURE__*/React.createElement("p", {
      className: "pc-onb-body"
    }, "Bring the rough version. ProsePal helps you shape it \u2014 clearer, warmer, truer \u2014 and keeps it sounding like you."));
  }
  function OnbHow() {
    return /*#__PURE__*/React.createElement(OnbShell, {
      step: 1,
      footer: /*#__PURE__*/React.createElement("button", {
        className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
      }, "Next")
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-onb-demo"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-onb-demo__row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-onb-demo__tag"
    }, "You write"), /*#__PURE__*/React.createElement("div", {
      className: "pc-onb-demo__rough"
    }, "cant make sunday, sorry")), /*#__PURE__*/React.createElement("div", {
      className: "pc-onb-demo__arrow"
    }, Ic("arrow-down")), /*#__PURE__*/React.createElement("div", {
      className: "pc-onb-demo__row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-onb-demo__tag pc-onb-demo__tag--clay"
    }, "ProsePal"), /*#__PURE__*/React.createElement("div", {
      className: "pc-onb-demo__fine"
    }, "I'm so sorry, but I won't be able to make it on Sunday."))), /*#__PURE__*/React.createElement("h1", {
      className: "pc-onb-title",
      style: {
        fontSize: 34,
        marginTop: 22
      }
    }, "Rough in,", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
      className: "i"
    }, "right words out.")), /*#__PURE__*/React.createElement("p", {
      className: "pc-onb-body"
    }, "Type how you'd say it to yourself. Choose a tone. ProsePal does the polishing."));
  }
  function OnbPrivacy() {
    return /*#__PURE__*/React.createElement(OnbShell, {
      step: 2,
      footer: /*#__PURE__*/React.createElement("button", {
        className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
      }, "Next")
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-crest",
      style: {
        background: "linear-gradient(158deg, var(--voice), oklch(0.44 0.05 158))"
      }
    }, Ic("lock-simple")), /*#__PURE__*/React.createElement("h1", {
      className: "pc-onb-title",
      style: {
        fontSize: 34,
        marginTop: 22
      }
    }, "Your words", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
      className: "i"
    }, "stay yours.")), /*#__PURE__*/React.createElement("p", {
      className: "pc-onb-body"
    }, "Drafts are processed privately and never used to train models. Delete anything, anytime."), /*#__PURE__*/React.createElement("ul", {
      className: "pc-onb-list"
    }, /*#__PURE__*/React.createElement("li", null, Ic("check"), " On-device drafts by default"), /*#__PURE__*/React.createElement("li", null, Ic("check"), " No training on your text"), /*#__PURE__*/React.createElement("li", null, Ic("check"), " Export or erase in one tap")));
  }
  function OnbReady() {
    return /*#__PURE__*/React.createElement(OnbShell, {
      step: 3,
      footer: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("button", {
        className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
      }, Ic("bell"), " Turn on gentle reminders"), /*#__PURE__*/React.createElement("button", {
        className: "pp-btn pp-btn--ghost pp-btn--lg pp-btn--block"
      }, "Maybe later"))
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-crest"
    }, Ic("paper-plane-tilt")), /*#__PURE__*/React.createElement("h1", {
      className: "pc-onb-title",
      style: {
        fontSize: 36,
        marginTop: 22
      }
    }, "You're ", /*#__PURE__*/React.createElement("span", {
      className: "i"
    }, "ready.")), /*#__PURE__*/React.createElement("p", {
      className: "pc-onb-body"
    }, "Want a quiet nudge when a message has been waiting? No noise \u2014 just a hand when you need one."));
  }

  // ---- Writing: the ruled cream page (composing) ----
  function ThePage() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      large: true,
      serif: true,
      title: "Today",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("list")),
      trail: /*#__PURE__*/React.createElement("span", {
        className: "pp-avatar pp-avatar--sm"
      }, "MO")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "2px 18px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 18
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-page"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-prompt"
    }, "The note"), /*#__PURE__*/React.createElement("div", {
      className: "pc-ruled kit-text"
    }, ROUGH), /*#__PURE__*/React.createElement("div", {
      className: "pc-page__foot"
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 2
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn pp-iconbtn--sm"
    }, Ic("microphone")), /*#__PURE__*/React.createElement("button", {
      className: "pp-iconbtn pp-iconbtn--sm"
    }, Ic("text-aa"))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--md"
    }, Ic("feather"), /*#__PURE__*/React.createElement("span", null, "Help me write")))), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-tones__title",
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 21,
        fontWeight: 500
      }
    }, "How should it read?"), /*#__PURE__*/React.createElement("span", {
      className: "pp-tones__hint"
    }, "Pick a few")), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pc-chip",
      "aria-pressed": "true"
    }, Ic("scales"), " Diplomatic"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip",
      "aria-pressed": "true"
    }, Ic("heart"), " Warm"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, Ic("feather"), " Graceful"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, Ic("flag-banner"), " Firm"))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        color: "var(--text-tertiary)"
      }
    }, Ic("sparkle"), /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: "var(--font-mono)",
        fontSize: 12
      }
    }, "7 of 10 free refines left this week"))), /*#__PURE__*/React.createElement(Dock, {
      active: "new"
    }), /*#__PURE__*/React.createElement(Home, null));
  }
  function Generating() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "Writing\u2026",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Today")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "6px 18px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-card pp-card--inset pp-card--pad",
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 5
      }
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-prompt",
      style: {
        color: "var(--text-tertiary)"
      }
    }, "Your note"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 16,
        color: "var(--text-tertiary)",
        lineHeight: 1.5
      }
    }, ROUGH)), /*#__PURE__*/React.createElement("div", {
      className: "pc-page",
      style: {
        paddingTop: 20
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-gen",
      style: {
        padding: 0,
        gap: 18
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-gen__status"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-gen__orb"
    }), "Finding the right words\u2026"), /*#__PURE__*/React.createElement("div", {
      className: "pp-gen__lines"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-skel pp-skel--title"
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-skel",
      style: {
        width: "100%"
      }
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-skel",
      style: {
        width: "96%"
      }
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-skel",
      style: {
        width: "100%"
      }
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-skel",
      style: {
        width: "58%"
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 7,
        color: "var(--voice)",
        font: "400 13px var(--font-ui)"
      }
    }, Ic("seal-check"), " Keeping your voice")))), /*#__PURE__*/React.createElement(Home, null));
  }
  window.PPReg.add("Onboarding", "First run — welcome, how it works, the privacy promise, ready", [["01", "Welcome", Welcome], ["02", "How it works", OnbHow], ["03", "Privacy promise", OnbPrivacy], ["04", "Ready", OnbReady]]);
  window.PPReg.add("Writing", "Ruled cream = composing & drafting (the note is the hero)", [["05", "The page", ThePage], ["06", "Generating", Generating]]);
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal/screens-1.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal/screens-2.jsx
try { (() => {
/* ProsePal flagship — Result & revise + Library & history. */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone
  } = window.KIT;
  const {
    WASH,
    GNav,
    Dock
  } = window.PPK;

  // ---- Draft result: CLEAN unruled cream (polished output) ----
  function Draft() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "A draft",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Today"),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("bookmark-simple"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "4px 18px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 13
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-draft"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-draft__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-draft__label"
    }, "Diplomatic & warm"), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__variants"
    }, /*#__PURE__*/React.createElement("span", {
      className: "dot dot--on"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "pc-draft__body"
    }, /*#__PURE__*/React.createElement("p", null, "Dear Mr. Alvarez,"), /*#__PURE__*/React.createElement("p", null, "After six happy years, we've decided not to renew our lease when it ends in August. It wasn't an easy choice \u2014 this home has meant a great deal to us \u2014 and we wanted to tell you early so the timing is gentle on your side."), /*#__PURE__*/React.createElement("p", null, "Thank you for being so good to us.")), /*#__PURE__*/React.createElement("div", {
      className: "pc-draft__voice"
    }, Ic("seal-check"), " Still unmistakably you"), /*#__PURE__*/React.createElement("div", {
      className: "pc-draft__foot"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn"
    }, Ic("copy"), " Copy"), /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn"
    }, Ic("arrow-clockwise"), " Another"), /*#__PURE__*/React.createElement("span", {
      className: "pc-spacer"
    }), /*#__PURE__*/React.createElement("button", {
      className: "pp-draftbtn pp-draftbtn--accent"
    }, Ic("check"), " Keep this"))), /*#__PURE__*/React.createElement("div", {
      className: "pc-margin"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-margin__icon"
    }, Ic("note-pencil")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("b", null, "Margin note"), /*#__PURE__*/React.createElement("p", null, "\"It wasn't an easy choice\" softens the news without blurring your decision.")))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 16px 12px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-floatbar"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-floatbar__lead"
    }, Ic("magic-wand")), /*#__PURE__*/React.createElement("div", {
      className: "pc-floatbar__scroll"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, Ic("scissors"), " Shorter"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, Ic("scales"), " Softer"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, Ic("flag-banner"), " Firmer")))), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Revise: ruled (active editing) + glass suggestion ----
  function Revise() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "Revise",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn",
        style: {
          fontWeight: 600,
          color: "var(--accent-text)"
        }
      }, "Done")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "6px 18px 14px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-seg"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pc-seg__i pc-seg__i--on"
    }, "Draft"), /*#__PURE__*/React.createElement("button", {
      className: "pc-seg__i"
    }, "Changes"), /*#__PURE__*/React.createElement("button", {
      className: "pc-seg__i"
    }, "Original")), /*#__PURE__*/React.createElement("div", {
      className: "pc-page"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-ruled kit-text",
      style: {
        minHeight: 136
      }
    }, "After six ", /*#__PURE__*/React.createElement("span", {
      className: "pc-mark"
    }, "happy"), " years, we've decided not to renew our lease when it ends in August. It wasn't an easy choice \u2014 this home has meant a great deal to us.")), /*#__PURE__*/React.createElement("div", {
      className: "pc-suggest"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-suggest__h"
    }, Ic("magic-wand"), " Replace \"happy\""), /*#__PURE__*/React.createElement("div", {
      className: "pc-suggest__row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-pill pc-pill--on"
    }, "good"), /*#__PURE__*/React.createElement("span", {
      className: "pc-pill"
    }, "wonderful"), /*#__PURE__*/React.createElement("span", {
      className: "pc-pill"
    }, "settled"), /*#__PURE__*/React.createElement("span", {
      className: "pc-pill"
    }, "grateful"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-tones__row"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pc-chip",
      "aria-pressed": "true"
    }, Ic("heart"), " Warmer"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, Ic("scissors"), " Tighter"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, Ic("book-open"), " Richer"))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "10px 18px 12px",
        borderTop: "0.5px dashed var(--border)"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--lg pp-btn--block"
    }, Ic("check"), " Keep this draft")), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Drafts library: clean cream cards on the wash ----
  const LIB = [{
    t: "To Mr. Alvarez — lease",
    s: "Diplomatic · Warm",
    excerpt: "After six happy years, we've decided not to renew…",
    tone: "Kept",
    when: "Just now",
    glyph: "house-line"
  }, {
    t: "Reply to Daniel",
    s: "Warm · Brief",
    excerpt: "Thank you so much for the invitation — I won't be able…",
    tone: "Used",
    when: "Yesterday",
    glyph: "chat-circle"
  }, {
    t: "Resignation note",
    s: "Diplomatic",
    excerpt: "After a great deal of thought, I've decided to step back…",
    tone: "Draft",
    when: "Mon",
    glyph: "briefcase"
  }, {
    t: "Grandma's birthday toast",
    s: "Heartfelt",
    excerpt: "To Grandma — who taught me that a kitchen is just love…",
    tone: "Used",
    when: "Last week",
    glyph: "cake"
  }];
  function Library() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      large: true,
      serif: true,
      title: "Drafts",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("list")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("magnifying-glass"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "0 18px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 11
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-libfilter"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pc-chip",
      "aria-pressed": "true"
    }, "All"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, "Kept"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, "Used"), /*#__PURE__*/React.createElement("button", {
      className: "pc-chip"
    }, "Drafts")), LIB.map((d, i) => /*#__PURE__*/React.createElement("div", {
      className: "pc-libcard",
      key: i
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-libcard__top"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-libcard__icon"
    }, Ic(d.glyph)), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-libcard__t"
    }, d.t), /*#__PURE__*/React.createElement("div", {
      className: "pc-libcard__s"
    }, d.s)), /*#__PURE__*/React.createElement("span", {
      className: "pp-badge " + (d.tone === "Kept" ? "pp-badge--voice" : d.tone === "Used" ? "pp-badge--accent" : "pp-badge--outline")
    }, d.tone)), /*#__PURE__*/React.createElement("div", {
      className: "pc-libcard__excerpt"
    }, d.excerpt), /*#__PURE__*/React.createElement("div", {
      className: "pc-libcard__when"
    }, Ic("clock"), /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: "var(--font-mono)",
        fontSize: 11
      }
    }, d.when))))), /*#__PURE__*/React.createElement(Dock, {
      active: "drafts"
    }), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Draft history: version timeline for one draft ----
  function History() {
    const versions = [{
      tone: "Diplomatic & warm",
      note: "Current",
      txt: "After six happy years, we've decided not to renew our lease…",
      on: true
    }, {
      tone: "Softer",
      note: "10:24",
      txt: "We've had six wonderful years here, and after a lot of thought…"
    }, {
      tone: "Firmer",
      note: "10:21",
      txt: "This is to confirm we won't be renewing our lease in August."
    }, {
      tone: "Your note",
      note: "Original",
      txt: "telling my landlord were not renewing the lease…",
      orig: true
    }];
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "Version history",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Draft")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "8px 18px 18px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-timeline"
    }, versions.map((v, i) => /*#__PURE__*/React.createElement("div", {
      className: "pc-tl" + (v.on ? " pc-tl--on" : ""),
      key: i
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-tl__node"
    }, v.orig ? Ic("pencil-simple") : Ic("feather")), /*#__PURE__*/React.createElement("div", {
      className: "pc-tl__card"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-tl__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-tl__tone"
    }, v.tone), /*#__PURE__*/React.createElement("span", {
      className: "pc-tl__when"
    }, v.note)), /*#__PURE__*/React.createElement("div", {
      className: "pc-tl__txt" + (v.orig ? " pc-tl__txt--orig" : "")
    }, v.txt), v.on && /*#__PURE__*/React.createElement("div", {
      className: "pc-tl__badge"
    }, Ic("check"), " Showing now"), !v.on && !v.orig && /*#__PURE__*/React.createElement("button", {
      className: "pc-tl__restore"
    }, Ic("arrow-counter-clockwise"), " Restore")))))), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Library empty state (first run) ----
  function LibraryEmpty() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      large: true,
      serif: true,
      title: "Drafts",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("list"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
        padding: "0 36px",
        gap: 8
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: 46,
        color: "var(--accent)",
        opacity: 0.55,
        lineHeight: 0
      }
    }, Ic("cards-three")), /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 23,
        fontWeight: 500,
        color: "var(--text)",
        marginTop: 8
      }
    }, "Nothing here yet"), /*#__PURE__*/React.createElement("p", {
      style: {
        font: "400 15px/1.5 var(--font-ui)",
        color: "var(--text-tertiary)",
        maxWidth: "26ch"
      }
    }, "Every message you shape with ProsePal lands here \u2014 ready to revisit, reuse, or refine."), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--lg",
      style: {
        marginTop: 14
      }
    }, Ic("feather"), " Write your first"))), /*#__PURE__*/React.createElement(Dock, {
      active: "drafts"
    }), /*#__PURE__*/React.createElement(Home, null));
  }
  window.PPReg.add("Result & revise", "Clean cream = polished output; revise returns to ruled (active editing)", [["07", "Draft result", Draft], ["08", "Revise", Revise]]);
  window.PPReg.add("Library & history", "Saved work — subtle paper cards, version timeline, empty state", [["09", "Drafts library", Library], ["10", "Version history", History], ["11", "Empty library", LibraryEmpty]]);
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal/screens-2.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal/screens-3.jsx
try { (() => {
/* ProsePal flagship — Account & system surfaces.
   Glass nav/chrome; content on opaque cream (no ruled lines). */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone
  } = window.KIT;
  const {
    WASH,
    GNav
  } = window.PPK;

  // ---- Settings / account ----
  function Settings() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      large: true,
      serif: true,
      title: "Settings",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, "Done")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "2px 18px 20px",
        display: "flex",
        flexDirection: "column",
        gap: 18
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-profile"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-avatar pp-avatar--lg"
    }, "MO"), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-profile__name"
    }, "Maya Okafor"), /*#__PURE__*/React.createElement("div", {
      className: "pc-profile__mail"
    }, "maya.okafor@icloud.com")), /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--accent"
    }, "Pro")), /*#__PURE__*/React.createElement("div", {
      className: "pc-group"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-group__h"
    }, "Writing"), /*#__PURE__*/React.createElement("div", {
      className: "pp-listgroup"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-row pp-row--tap"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("paint-brush-broad")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Default tone"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__sub"
    }, "Diplomatic \xB7 Warm")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__trail"
    }, "Edit"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__chevron"
    }, Ic("caret-right"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("user-focus")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Voice profile"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__sub"
    }, "Learns how you write")), /*#__PURE__*/React.createElement("span", {
      className: "pp-switch",
      "aria-checked": "true",
      role: "switch"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-switch__knob"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "pp-row pp-row--tap"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("textbox")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Reading text size")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__trail"
    }, "Medium"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__chevron"
    }, Ic("caret-right"))))), /*#__PURE__*/React.createElement("div", {
      className: "pc-group"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-group__h"
    }, "Privacy"), /*#__PURE__*/React.createElement("div", {
      className: "pp-listgroup"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("lock-simple")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Private mode"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__sub"
    }, "Keep drafts on this device")), /*#__PURE__*/React.createElement("span", {
      className: "pp-switch",
      "aria-checked": "true",
      role: "switch"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-switch__knob"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "pp-row pp-row--tap"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("shield-check")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Privacy & data")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__chevron"
    }, Ic("caret-right"))))), /*#__PURE__*/React.createElement("div", {
      className: "pc-group"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-group__h"
    }, "Subscription"), /*#__PURE__*/React.createElement("div", {
      className: "pp-listgroup"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-row pp-row--tap"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("seal-check")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "ProsePal Pro"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__sub"
    }, "Renews Mar 14, 2027")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__chevron"
    }, Ic("caret-right"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-row pp-row--tap"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("lifebuoy")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Help & support")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__chevron"
    }, Ic("caret-right"))))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--ghost pp-btn--md",
      style: {
        color: "var(--danger)",
        alignSelf: "center"
      }
    }, "Sign out")), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Privacy & data ----
  function Privacy() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "Privacy & data",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Settings")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "8px 18px 20px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-trust"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-trust__icon"
    }, Ic("lock-simple")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "pp-trust__title"
    }, "Your writing stays yours"), /*#__PURE__*/React.createElement("div", {
      className: "pp-trust__body"
    }, "ProsePal processes drafts privately. Your words are never used to train models, and you can erase them at any time."))), /*#__PURE__*/React.createElement("div", {
      className: "pc-group"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-group__h"
    }, "Controls"), /*#__PURE__*/React.createElement("div", {
      className: "pp-listgroup"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("device-mobile")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "On-device drafts"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__sub"
    }, "Process without leaving your iPhone")), /*#__PURE__*/React.createElement("span", {
      className: "pp-switch",
      "aria-checked": "true",
      role: "switch"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-switch__knob"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "pp-row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("chart-line")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Anonymous diagnostics"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__sub"
    }, "Help improve ProsePal")), /*#__PURE__*/React.createElement("span", {
      className: "pp-switch",
      "aria-checked": "false",
      role: "switch"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-switch__knob"
    }))))), /*#__PURE__*/React.createElement("div", {
      className: "pc-group"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-group__h"
    }, "Your data"), /*#__PURE__*/React.createElement("div", {
      className: "pp-listgroup"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-row pp-row--tap"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("export")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Export all drafts")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__chevron"
    }, Ic("caret-right"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-row pp-row--tap"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead",
      style: {
        color: "var(--danger)"
      }
    }, Ic("trash")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title",
      style: {
        color: "var(--danger)"
      }
    }, "Delete all drafts")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__chevron"
    }, Ic("caret-right"))))), /*#__PURE__*/React.createElement("p", {
      style: {
        font: "400 12px/1.5 var(--font-ui)",
        color: "var(--text-quaternary)",
        textAlign: "center",
        padding: "0 12px"
      }
    }, "Read our ", /*#__PURE__*/React.createElement("a", {
      href: "#",
      style: {
        color: "var(--text-tertiary)"
      }
    }, "Privacy Policy"), ". ProsePal is designed to collect as little as possible.")), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Subscription — Free ----
  function SubFree() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "Your plan",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Settings")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "8px 18px 20px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-card pp-usage"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-usage__head"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-usage__plan"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-usage__planname"
    }, "Free plan"), /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--outline"
    }, "Free")), /*#__PURE__*/React.createElement("span", {
      className: "pp-usage__period"
    }, "this week")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "pp-usage__count",
      style: {
        marginBottom: 8
      }
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-usage__countnum"
    }, /*#__PURE__*/React.createElement("b", null, "3"), " of 10 refines left"), /*#__PURE__*/React.createElement("span", {
      className: "pp-usage__reset",
      style: {
        fontFamily: "var(--font-mono)"
      }
    }, "resets Mon")), /*#__PURE__*/React.createElement("div", {
      className: "pp-meter"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-meter__track"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-meter__fill pp-meter__fill--warning",
      style: {
        width: "70%"
      }
    }))))), /*#__PURE__*/React.createElement("div", {
      className: "pc-upsell"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-upsell__h"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-crest",
      style: {
        width: 44,
        height: 44,
        fontSize: 21,
        borderRadius: 14
      }
    }, Ic("feather")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        font: "600 16px var(--font-ui)",
        color: "var(--text)"
      }
    }, "Go further with Pro"), /*#__PURE__*/React.createElement("div", {
      style: {
        font: "400 13px var(--font-ui)",
        color: "var(--text-tertiary)"
      }
    }, "For the messages that matter most"))), /*#__PURE__*/React.createElement("ul", {
      className: "pc-upsell__list"
    }, /*#__PURE__*/React.createElement("li", null, Ic("infinity"), " Unlimited refines & drafts"), /*#__PURE__*/React.createElement("li", null, Ic("book-bookmark"), " A voice profile that's yours"), /*#__PURE__*/React.createElement("li", null, Ic("sliders"), " Every tone & length")), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--lg pp-btn--block"
    }, "See Pro"))), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Subscription — Pro ----
  function SubPro() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "Your plan",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Settings")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "8px 18px 20px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-proCard"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-proCard__crest"
    }, Ic("seal-check")), /*#__PURE__*/React.createElement("div", {
      className: "pc-proCard__name"
    }, "ProsePal Pro"), /*#__PURE__*/React.createElement("div", {
      className: "pc-proCard__sub"
    }, "Yearly \xB7 renews Mar 14, 2027"), /*#__PURE__*/React.createElement("div", {
      className: "pc-proCard__price"
    }, "$39.99", /*#__PURE__*/React.createElement("span", null, "/yr"))), /*#__PURE__*/React.createElement("div", {
      className: "pc-group"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-group__h"
    }, "Included"), /*#__PURE__*/React.createElement("div", {
      className: "pp-listgroup"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead",
      style: {
        color: "var(--voice)"
      }
    }, Ic("infinity")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Unlimited refines")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__trail",
      style: {
        color: "var(--voice)"
      }
    }, Ic("check"))), /*#__PURE__*/React.createElement("div", {
      className: "pp-row"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead",
      style: {
        color: "var(--voice)"
      }
    }, Ic("user-focus")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Voice profile"), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__sub"
    }, "Active & learning")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__trail",
      style: {
        color: "var(--voice)"
      }
    }, Ic("check"))))), /*#__PURE__*/React.createElement("div", {
      className: "pp-listgroup"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-row pp-row--tap"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__lead"
    }, Ic("receipt")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__body"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pp-row__title"
    }, "Manage subscription")), /*#__PURE__*/React.createElement("span", {
      className: "pp-row__chevron"
    }, Ic("caret-right"))))), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Paywall (the upgrade preview) ----
  function Paywall() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("x")),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, "Restore")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "0 18px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall",
      style: {
        padding: "10px 4px 16px",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__hero"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-crest",
      style: {
        width: 64,
        height: 64,
        fontSize: 30
      }
    }, Ic("feather")), /*#__PURE__*/React.createElement("h2", {
      className: "pp-paywall__title",
      style: {
        fontFamily: "var(--font-reading)",
        fontStyle: "italic",
        fontWeight: 400
      }
    }, "A room of your own."), /*#__PURE__*/React.createElement("p", {
      className: "pp-paywall__sub"
    }, "Unlimited drafts, every register of tone, and a voice profile that remembers how you write.")), /*#__PURE__*/React.createElement("div", {
      className: "pc-panel",
      style: {
        padding: "4px 16px"
      }
    }, /*#__PURE__*/React.createElement("ul", {
      className: "pp-paywall__features",
      style: {
        margin: "13px 0"
      }
    }, /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("infinity")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Unlimited drafts"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "Write and revise without counting"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("book-bookmark")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Your voice profile"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "ProsePal learns your cadence over time"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
      className: "ic"
    }, Ic("lock-simple")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "ft-t"
    }, "Kept private"), /*#__PURE__*/React.createElement("div", {
      className: "ft-s"
    }, "Your pages never train a model"))))), /*#__PURE__*/React.createElement("div", {
      className: "pp-plans"
    }, /*#__PURE__*/React.createElement("button", {
      className: "pc-plan",
      "aria-pressed": "true"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      className: "pc-plan__body"
    }, /*#__PURE__*/React.createElement("b", null, "Yearly", /*#__PURE__*/React.createElement("span", {
      className: "pp-badge pp-badge--voice",
      style: {
        marginLeft: 8,
        verticalAlign: "1px"
      }
    }, "Best value")), /*#__PURE__*/React.createElement("span", null, "$3.33 / month, billed yearly")), /*#__PURE__*/React.createElement("span", {
      className: "pc-plan__price"
    }, /*#__PURE__*/React.createElement("b", null, "$39.99"), /*#__PURE__*/React.createElement("span", null, "/yr"))), /*#__PURE__*/React.createElement("button", {
      className: "pc-plan"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-plan__radio"
    }), /*#__PURE__*/React.createElement("span", {
      className: "pc-plan__body"
    }, /*#__PURE__*/React.createElement("b", null, "Monthly"), /*#__PURE__*/React.createElement("span", null, "Billed monthly")), /*#__PURE__*/React.createElement("span", {
      className: "pc-plan__price"
    }, /*#__PURE__*/React.createElement("b", null, "$5.99"), /*#__PURE__*/React.createElement("span", null, "/mo")))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, "Start 7-day free trial"), /*#__PURE__*/React.createElement("div", {
      className: "pp-paywall__fine"
    }, "Cancel anytime \xB7 ", /*#__PURE__*/React.createElement("a", {
      href: "#"
    }, "Terms"), " \xB7 ", /*#__PURE__*/React.createElement("a", {
      href: "#"
    }, "Privacy")))), /*#__PURE__*/React.createElement(Home, null));
  }
  window.PPReg.add("Account & system", "Glass nav over opaque cream lists — no ruled lines on system surfaces", [["12", "Settings", Settings], ["13", "Privacy & data", Privacy], ["14", "Plan · Free", SubFree], ["15", "Plan · Pro", SubPro], ["16", "Paywall", Paywall]]);
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal/screens-3.jsx", error: String((e && e.message) || e) }); }

// ui_kits/prosepal/screens-4.jsx
try { (() => {
/* ProsePal flagship — Sheets, overlays & states.
   Overlays are glass; the writing behind stays literary cream. */
(function () {
  const {
    Ic,
    Status,
    Home,
    Phone
  } = window.KIT;
  const {
    WASH,
    GNav,
    Sheet,
    Toast,
    Banner
  } = window.PPK;

  // A quiet cream draft, used as the backdrop behind overlays
  function DraftBackdrop({
    dim
  }) {
    return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(GNav, {
      title: "A draft",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Today"),
      trail: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("bookmark-simple"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "4px 18px 14px",
        filter: dim ? "saturate(0.96)" : "none"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-draft"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-draft__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-draft__label"
    }, "Diplomatic & warm"), /*#__PURE__*/React.createElement("div", {
      className: "pp-draft__variants"
    }, /*#__PURE__*/React.createElement("span", {
      className: "dot dot--on"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }), /*#__PURE__*/React.createElement("span", {
      className: "dot"
    }))), /*#__PURE__*/React.createElement("div", {
      className: "pc-draft__body"
    }, /*#__PURE__*/React.createElement("p", null, "Dear Mr. Alvarez,"), /*#__PURE__*/React.createElement("p", null, "After six happy years, we've decided not to renew our lease when it ends in August. It wasn't an easy choice \u2014 and we wanted to tell you early.")), /*#__PURE__*/React.createElement("div", {
      className: "pc-draft__voice"
    }, Ic("seal-check"), " Still unmistakably you"))));
  }

  // ---- Share / insert sheet (glass, over dimmed draft) ----
  function ShareSheet() {
    const dests = [{
      i: "chat-circle",
      l: "Messages",
      c: "var(--success)"
    }, {
      i: "envelope-simple",
      l: "Mail",
      c: "var(--info)"
    }, {
      i: "notebook",
      l: "Notes",
      c: "var(--warning)"
    }, {
      i: "dots-three-circle",
      l: "More",
      c: "var(--text-tertiary)"
    }];
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(DraftBackdrop, {
      dim: true
    }), /*#__PURE__*/React.createElement("div", {
      className: "pc-scrim"
    }), /*#__PURE__*/React.createElement("div", {
      className: "pc-sheetwrap"
    }, /*#__PURE__*/React.createElement(Sheet, {
      title: "Use this draft"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-sheet__preview"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-sheet__previewlabel"
    }, Ic("seal-check"), " Diplomatic & warm \xB7 your voice kept"), /*#__PURE__*/React.createElement("div", {
      className: "pc-sheet__previewtxt"
    }, "\"Dear Mr. Alvarez, After six happy years, we've decided not to renew our lease\u2026\"")), /*#__PURE__*/React.createElement("div", {
      className: "pc-sheet__dests"
    }, dests.map((d, i) => /*#__PURE__*/React.createElement("button", {
      className: "pc-dest",
      key: i
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-dest__icon",
      style: {
        color: d.c
      }
    }, Ic(d.i)), /*#__PURE__*/React.createElement("span", null, d.l)))), /*#__PURE__*/React.createElement("div", {
      className: "pp-listgroup",
      style: {
        background: "transparent"
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pc-sheetrow"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-sheetrow__icon"
    }, Ic("copy")), "Copy to clipboard", /*#__PURE__*/React.createElement("span", {
      className: "pc-spacer"
    }), Ic("caret-right")), /*#__PURE__*/React.createElement("button", {
      className: "pc-sheetrow"
    }, /*#__PURE__*/React.createElement("span", {
      className: "pc-sheetrow__icon"
    }, Ic("bookmark-simple")), "Save to drafts", /*#__PURE__*/React.createElement("span", {
      className: "pc-spacer"
    }), Ic("caret-right"))), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--neutral pp-btn--lg pp-btn--block",
      style: {
        marginTop: 4
      }
    }, "Cancel"))), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Copied toast ----
  function CopiedToast() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(DraftBackdrop, null), /*#__PURE__*/React.createElement("div", {
      className: "pc-toastwrap"
    }, /*#__PURE__*/React.createElement(Toast, {
      icon: "check-circle"
    }, "Copied \u2014 your voice and all")), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Offline / connection ----
  function Offline() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      large: true,
      serif: true,
      title: "Today",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("list")),
      trail: /*#__PURE__*/React.createElement("span", {
        className: "pp-avatar pp-avatar--sm"
      }, "MO")
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 18px"
      }
    }, /*#__PURE__*/React.createElement(Banner, {
      icon: "cloud-slash",
      tone: "warning",
      title: "You're offline \u2014 drafts are saved here and will sync later"
    })), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        padding: "12px 18px 16px",
        display: "flex",
        flexDirection: "column",
        gap: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-page"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-prompt"
    }, "The note"), /*#__PURE__*/React.createElement("div", {
      className: "pc-ruled kit-text"
    }, "telling my landlord were not renewing the lease. weve been here six years\u2026"), /*#__PURE__*/React.createElement("div", {
      className: "pc-page__foot"
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: "400 13px var(--font-ui)",
        color: "var(--text-tertiary)"
      }
    }, "Saved locally"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--neutral pp-btn--md",
      disabled: true
    }, Ic("feather"), /*#__PURE__*/React.createElement("span", null, "Refine when online")))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        color: "var(--text-tertiary)",
        font: "400 13px var(--font-ui)"
      }
    }, Ic("arrows-clockwise"), " Retrying connection\u2026")), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Generation error (couldn't finish) ----
  function GenError() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "A draft",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn"
      }, Ic("caret-left"), " Today")
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column",
        padding: "0 18px 16px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
        gap: 8,
        padding: "0 22px"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 60,
        height: 60,
        borderRadius: 18,
        display: "grid",
        placeItems: "center",
        fontSize: 28,
        background: "var(--warning-soft)",
        color: "var(--warning)"
      }
    }, Ic("cloud-warning")), /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 23,
        fontWeight: 500,
        color: "var(--text)",
        marginTop: 8
      }
    }, "That didn't go through"), /*#__PURE__*/React.createElement("p", {
      style: {
        font: "400 15px/1.5 var(--font-ui)",
        color: "var(--text-tertiary)",
        maxWidth: "26ch"
      }
    }, "We couldn't finish your draft just now. Your note is safe \u2014 nothing was lost.")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--lg pp-btn--block"
    }, Ic("arrow-clockwise"), " Try again"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--ghost pp-btn--md pp-btn--block"
    }, "Back to your note"))), /*#__PURE__*/React.createElement(Home, null));
  }

  // ---- Quota reached (free limit) ----
  function Quota() {
    return /*#__PURE__*/React.createElement(Phone, {
      bg: WASH
    }, /*#__PURE__*/React.createElement(Status, null), /*#__PURE__*/React.createElement(GNav, {
      title: "",
      lead: /*#__PURE__*/React.createElement("button", {
        className: "pp-navbar__btn pp-navbar__btn--icon"
      }, Ic("x"))
    }), /*#__PURE__*/React.createElement("div", {
      className: "pp-screen-body",
      style: {
        display: "flex",
        flexDirection: "column",
        padding: "0 18px 16px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
        gap: 7,
        padding: "0 18px"
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "pc-crest",
      style: {
        width: 60,
        height: 60,
        fontSize: 28
      }
    }, Ic("hourglass-medium")), /*#__PURE__*/React.createElement("h2", {
      style: {
        fontFamily: "var(--font-reading)",
        fontSize: 26,
        fontWeight: 500,
        color: "var(--text)",
        marginTop: 12
      }
    }, "You've used this week's ", /*#__PURE__*/React.createElement("span", {
      style: {
        fontStyle: "italic"
      }
    }, "ten.")), /*#__PURE__*/React.createElement("p", {
      style: {
        font: "400 15px/1.55 var(--font-ui)",
        color: "var(--text-secondary)",
        maxWidth: "28ch"
      }
    }, "Your free refines reset Monday. Or go Pro for unlimited \u2014 and never count again."), /*#__PURE__*/React.createElement("div", {
      className: "pc-quota-meter"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-meter__track"
    }, /*#__PURE__*/React.createElement("div", {
      className: "pp-meter__fill pp-meter__fill--warning",
      style: {
        width: "100%"
      }
    })), /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: "var(--font-mono)",
        fontSize: 11,
        color: "var(--text-tertiary)",
        marginTop: 6,
        display: "block"
      }
    }, "10 of 10 used"))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--primary pp-btn--xl pp-btn--block"
    }, Ic("feather"), " Go Pro \u2014 unlimited"), /*#__PURE__*/React.createElement("button", {
      className: "pp-btn pp-btn--ghost pp-btn--md pp-btn--block"
    }, "Wait until Monday"))), /*#__PURE__*/React.createElement(Home, null));
  }
  window.PPReg.add("Sheets & states", "Overlays are glass; errors & empties stay warm and reassuring", [["17", "Share / insert", ShareSheet], ["18", "Copied toast", CopiedToast], ["19", "Offline", Offline], ["20", "Generation error", GenError], ["21", "Quota reached", Quota]]);

  // All sections registered — render the rail.
  window.PPReg.render();
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/prosepal/screens-4.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Avatar = __ds_scope.Avatar;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Divider = __ds_scope.Divider;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.Meter = __ds_scope.Meter;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.ToneChip = __ds_scope.ToneChip;

__ds_ns.NavBar = __ds_scope.NavBar;

__ds_ns.PhoneFrame = __ds_scope.PhoneFrame;

__ds_ns.StatusBar = __ds_scope.StatusBar;

__ds_ns.HomeIndicator = __ds_scope.HomeIndicator;

__ds_ns.TabBar = __ds_scope.TabBar;

__ds_ns.EmptyState = __ds_scope.EmptyState;

__ds_ns.OnboardingCard = __ds_scope.OnboardingCard;

__ds_ns.Paywall = __ds_scope.Paywall;

__ds_ns.TrustNote = __ds_scope.TrustNote;

__ds_ns.UsageCard = __ds_scope.UsageCard;

__ds_ns.DraftCard = __ds_scope.DraftCard;

__ds_ns.GenerationState = __ds_scope.GenerationState;

__ds_ns.RefineBar = __ds_scope.RefineBar;

__ds_ns.ToneSelector = __ds_scope.ToneSelector;

__ds_ns.WritingCanvas = __ds_scope.WritingCanvas;

})();
