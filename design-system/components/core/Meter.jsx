import React from "react";

/**
 * ProsePal Meter — usage / progress bar (refines used, voice match, etc).
 */
export function Meter({ value = 0, max = 100, tone = "accent", thin = false, className = "", ...rest }) {
  const pct = Math.max(0, Math.min(100, (value / max) * 100));
  const fillCls = ["pp-meter__fill", tone !== "accent" ? `pp-meter__fill--${tone}` : ""]
    .filter(Boolean)
    .join(" ");
  return (
    <div
      className={["pp-meter", thin ? "pp-meter--thin" : "", className].filter(Boolean).join(" ")}
      role="progressbar"
      aria-valuenow={value}
      aria-valuemax={max}
      {...rest}
    >
      <div className="pp-meter__track">
        <div className={fillCls} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}
