import React from "react";

/**
 * ProsePal TabBar — bottom tab bar with optional center "compose" FAB.
 * items: { value, label, icon, fab? }
 */
export function TabBar({ items = [], value, onChange, className = "", ...rest }) {
  return (
    <div className={["pp-tabbar", className].filter(Boolean).join(" ")} role="tablist" {...rest}>
      {items.map((it) => (
        <button
          key={it.value}
          type="button"
          role="tab"
          aria-selected={value === it.value}
          className={["pp-tab", it.fab ? "pp-tab--fab" : ""].filter(Boolean).join(" ")}
          onClick={() => onChange && onChange(it.value)}
        >
          <span className="pp-tab__icon" aria-hidden="true">{it.icon}</span>
          {!it.fab && <span>{it.label}</span>}
        </button>
      ))}
    </div>
  );
}
