import React from "react";

/**
 * ProsePal TrustNote — privacy / trust reassurance. Sage-tinted,
 * quietly confident. Use a list of points or a single line.
 */
export function TrustNote({ icon = <i className="ph ph-lock-simple" />, title, body, points = null, inline = false, className = "", ...rest }) {
  return (
    <div className={["pp-trust", inline ? "pp-trust--inline" : "", className].filter(Boolean).join(" ")} {...rest}>
      <span className="pp-trust__icon" aria-hidden="true">{icon}</span>
      <div>
        {title && <div className="pp-trust__title">{title}</div>}
        {body && <div className="pp-trust__body">{body}</div>}
        {points && (
          <ul className="pp-trust__list">
            {points.map((p, i) => (
              <li key={i}><i className="ph ph-check" />{p}</li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
