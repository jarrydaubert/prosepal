import React from "react";

/**
 * ProsePal EmptyState — a calm, encouraging blank. Never a dead end.
 */
export function EmptyState({ icon, title, body, action = null, className = "", ...rest }) {
  return (
    <div className={["pp-empty", className].filter(Boolean).join(" ")} {...rest}>
      {icon && <div className="pp-empty__icon" aria-hidden="true">{icon}</div>}
      {title && <div className="pp-empty__title">{title}</div>}
      {body && <p className="pp-empty__body">{body}</p>}
      {action && <div className="pp-empty__action">{action}</div>}
    </div>
  );
}
