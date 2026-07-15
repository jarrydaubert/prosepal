import React from "react";
import { Meter } from "../core/Meter.jsx";

/**
 * ProsePal UsageCard — subscription / usage state. Shows approved structured
 * allowance metadata when supplied, and otherwise stays explicitly unknown.
 */
export function UsageCard({
  plan = "Free",
  used = null,
  total = null,
  unit = "messages",
  period = null,
  reset = null,
  action = null,
  className = "",
  ...rest
}) {
  const hasUsage = Number.isFinite(used) && Number.isFinite(total) && total > 0;
  const low = hasUsage && total - used <= Math.max(1, Math.round(total * 0.25));
  return (
    <div className={["pp-card", "pp-usage", className].filter(Boolean).join(" ")} {...rest}>
      <div className="pp-usage__head">
        <div className="pp-usage__plan">
          <span className="pp-usage__planname">{plan} plan</span>
          <span className={"pp-badge " + (plan === "Free" ? "pp-badge--outline" : "pp-badge--accent")}>
            {plan === "Free" ? "Free" : "Pro"}
          </span>
        </div>
        {period && <span className="pp-usage__period">{period}</span>}
      </div>
      <div>
        <div className="pp-usage__count" style={{ marginBottom: 8 }}>
          <span className="pp-usage__countnum">
            {hasUsage ? <><b>{Math.max(0, total - used)}</b> of {total} {unit} left</> : "Usage details unavailable"}
          </span>
          {hasUsage && reset && <span className="pp-usage__reset">{reset}</span>}
        </div>
        {hasUsage && <Meter value={used} max={total} tone={low ? "warning" : "accent"} />}
      </div>
      {action}
    </div>
  );
}
