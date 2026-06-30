import React from "react";
import { Meter } from "../core/Meter.jsx";

/**
 * ProsePal UsageCard — subscription / usage state. Shows the plan,
 * how much of the period's allowance is used, and a quiet upgrade path.
 */
export function UsageCard({
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
  return (
    <div className={["pp-card", "pp-usage", className].filter(Boolean).join(" ")} {...rest}>
      <div className="pp-usage__head">
        <div className="pp-usage__plan">
          <span className="pp-usage__planname">{plan} plan</span>
          <span className={"pp-badge " + (plan === "Free" ? "pp-badge--outline" : "pp-badge--accent")}>
            {plan === "Free" ? "Free" : "Pro"}
          </span>
        </div>
        <span className="pp-usage__period">{period}</span>
      </div>
      <div>
        <div className="pp-usage__count" style={{ marginBottom: 8 }}>
          <span className="pp-usage__countnum"><b>{Math.max(0, total - used)}</b> of {total} {unit} left</span>
          {reset && <span className="pp-usage__reset">{reset}</span>}
        </div>
        <Meter value={used} max={total} tone={low ? "warning" : "accent"} />
      </div>
      {action}
    </div>
  );
}
