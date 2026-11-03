import React from "react";
import { ToneChip } from "../core/ToneChip.jsx";

/**
 * ProsePal ToneSelector — pick the goal for a piece of writing.
 * `options`: { id, label, icon }. Single or multi select.
 */
export function ToneSelector({
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
  const toggle = (id) => {
    if (!onChange) return;
    if (multi) {
      onChange(sel.includes(id) ? sel.filter((x) => x !== id) : [...sel, id]);
    } else {
      onChange([id]);
    }
  };
  return (
    <div className={["pp-tones", className].filter(Boolean).join(" ")} {...rest}>
      <div className="pp-tones__head">
        <span className="pp-tones__title">{title}</span>
        {hint && <span className="pp-tones__hint">{hint}</span>}
      </div>
      <div className={scroll ? "pp-tones__scroll" : "pp-tones__row"}>
        {options.map((o) => (
          <ToneChip
            key={o.id}
            selected={sel.includes(o.id)}
            icon={o.icon}
            onClick={() => toggle(o.id)}
          >
            {o.label}
          </ToneChip>
        ))}
      </div>
    </div>
  );
}
