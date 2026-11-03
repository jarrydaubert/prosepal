import React from "react";

/**
 * ProsePal Badge — a small status/label pill. Optional leading dot.
 */
export function Badge({ tone = "neutral", dot = false, icon = null, className = "", children, ...rest }) {
  const cls = ["pp-badge", tone !== "neutral" ? `pp-badge--${tone}` : "", className]
    .filter(Boolean)
    .join(" ");
  return (
    <span className={cls} {...rest}>
      {dot && <span className="pp-badge__dot" aria-hidden="true" />}
      {icon && <span aria-hidden="true" style={{ lineHeight: 0, fontSize: "1.05em" }}>{icon}</span>}
      {children}
    </span>
  );
}
