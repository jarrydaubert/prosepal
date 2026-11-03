import React from "react";

/**
 * ProsePal Switch — the iOS toggle. Controlled via `checked` + `onChange`.
 */
export function Switch({ checked = false, onChange, disabled = false, label, className = "", ...rest }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      className={["pp-switch", className].filter(Boolean).join(" ")}
      onClick={() => onChange && onChange(!checked)}
      {...rest}
    >
      <span className="pp-switch__knob" aria-hidden="true" />
    </button>
  );
}
