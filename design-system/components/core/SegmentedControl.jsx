import React from "react";

/**
 * ProsePal SegmentedControl — iOS pill switcher.
 * Controlled: `items` of { value, label, icon? }, `value`, `onChange`.
 */
export function SegmentedControl({ items = [], value, onChange, className = "", ...rest }) {
  return (
    <div className={["pp-segmented", className].filter(Boolean).join(" ")} role="tablist" {...rest}>
      {items.map((it) => (
        <button
          key={it.value}
          type="button"
          role="tab"
          aria-selected={value === it.value}
          className="pp-segmented__item"
          onClick={() => onChange && onChange(it.value)}
        >
          {it.icon && <span aria-hidden="true" style={{ lineHeight: 0, fontSize: 16 }}>{it.icon}</span>}
          {it.label}
        </button>
      ))}
    </div>
  );
}
