import React from "react";

/**
 * ProsePal GenerationState — the calm "thinking" state. A breathing
 * clay orb, a reassuring status line, and shimmering draft lines.
 */
export function GenerationState({ label = "Finding the right words…", lines = 4, className = "", ...rest }) {
  return (
    <div className={["pp-gen", className].filter(Boolean).join(" ")} role="status" aria-live="polite" {...rest}>
      <div className="pp-gen__status">
        <span className="pp-gen__orb" aria-hidden="true" />
        {label}
      </div>
      <div className="pp-gen__lines" aria-hidden="true">
        <div className="pp-skel pp-skel--title" />
        {Array.from({ length: Math.max(1, lines) }).map((_, i) => (
          <div key={i} className="pp-skel" style={{ width: i === lines - 1 ? "64%" : "100%" }} />
        ))}
      </div>
    </div>
  );
}
