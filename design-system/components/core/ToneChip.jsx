import React from "react";

/**
 * ProsePal ToneChip — a selectable capsule for tone/style selection.
 * Use inside ToneSelector or anywhere a soft single/multi choice is needed.
 */
export function ToneChip({
  selected = false,
  icon = null,
  ghost = false,
  className = "",
  onClick,
  children,
  ...rest
}) {
  const cls = ["pp-chip", ghost ? "pp-chip--ghost" : "", className].filter(Boolean).join(" ");
  return (
    <button
      type="button"
      className={cls}
      aria-pressed={selected}
      onClick={onClick}
      {...rest}
    >
      {icon && <span className="pp-chip__icon" aria-hidden="true">{icon}</span>}
      {children}
    </button>
  );
}
