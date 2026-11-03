import React from "react";

/**
 * ProsePal RefineBar — quick one-tap edits applied to an existing
 * draft (Warmer, Shorter, Sharper…). Floats above the draft.
 * `actions`: { id, label, icon }.
 */
export function RefineBar({ actions = [], onAction, lead = true, className = "", ...rest }) {
  return (
    <div className={["pp-refine", className].filter(Boolean).join(" ")} {...rest}>
      {lead && <span className="pp-refine__lead" aria-hidden="true"><i className="ph ph-magic-wand" /></span>}
      <div className="pp-refine__scroll">
        {actions.map((a) => (
          <button key={a.id} type="button" className="pp-chip" onClick={() => onAction && onAction(a.id)}>
            {a.icon && <span className="pp-chip__icon" aria-hidden="true">{a.icon}</span>}
            {a.label}
          </button>
        ))}
      </div>
    </div>
  );
}
