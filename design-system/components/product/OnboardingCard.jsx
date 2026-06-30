import React from "react";

/**
 * ProsePal OnboardingCard — a single welcome / teaching moment.
 * One idea, one medallion, one clear action.
 */
export function OnboardingCard({ icon, eyebrow, title, body, actions, className = "", ...rest }) {
  return (
    <div className={["pp-onboard", className].filter(Boolean).join(" ")} {...rest}>
      {icon && <div className="pp-onboard__medallion" aria-hidden="true">{icon}</div>}
      {eyebrow && <div className="pp-onboard__eyebrow">{eyebrow}</div>}
      {title && <h2 className="pp-onboard__title">{title}</h2>}
      {body && <p className="pp-onboard__body">{body}</p>}
      {actions && <div className="pp-onboard__actions">{actions}</div>}
    </div>
  );
}
