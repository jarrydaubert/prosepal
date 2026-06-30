import React from "react";

/**
 * ProsePal WritingCanvas — the paper surface where the user writes.
 * Their words are the hero: set in the reading serif, generously led.
 */
export function WritingCanvas({
  value,
  onChange,
  placeholder = "Write what's on your mind…",
  prompt = null,
  count = null,
  tools = null,
  actions = null,
  focus = false,
  rows = 4,
  className = "",
  ...rest
}) {
  return (
    <div className={["pp-canvas", focus ? "pp-canvas--focus" : "", className].filter(Boolean).join(" ")} {...rest}>
      {prompt && <div className="pp-canvas__prompt">{prompt}</div>}
      <textarea
        className="pp-canvas__field"
        value={value}
        onChange={(e) => onChange && onChange(e.target.value)}
        placeholder={placeholder}
        rows={rows}
      />
      <div className="pp-canvas__foot">
        <div className="pp-canvas__tools">{tools}</div>
        <div className="pp-canvas__send">
          {count != null && <span className="pp-canvas__count">{count}</span>}
          {actions}
        </div>
      </div>
    </div>
  );
}
