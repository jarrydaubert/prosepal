import React from "react";

/**
 * ProsePal DraftCard — a generated draft. The draft text is the
 * hero; meta sits quietly above, actions quietly below. ProsePal
 * never claims your words — the "voice kept" marker reassures.
 */
export function DraftCard({
  label = "Draft",
  tones = [],
  voiceNote = null,
  variants = null,
  raised = false,
  actions = null,
  children,
  className = "",
  ...rest
}) {
  return (
    <div className={["pp-draft", raised ? "pp-draft--raised" : "", className].filter(Boolean).join(" ")} {...rest}>
      <div className="pp-draft__head">
        <div className="pp-draft__meta">
          <span className="pp-draft__label">{label}</span>
          {tones.map((t) => (
            <span key={t} className="pp-badge pp-badge--accent">{t}</span>
          ))}
        </div>
        {variants && (
          <div className="pp-draft__variants" aria-label={`Variant ${variants.current} of ${variants.total}`}>
            {Array.from({ length: variants.total }).map((_, i) => (
              <span key={i} className={"dot" + (i === variants.current - 1 ? " dot--on" : "")} />
            ))}
          </div>
        )}
      </div>
      <div className="pp-draft__body">{children}</div>
      {voiceNote && (
        <div className="pp-draft__voice"><i className="ph ph-seal-check" />{voiceNote}</div>
      )}
      {actions && <div className="pp-draft__foot">{actions}</div>}
    </div>
  );
}
