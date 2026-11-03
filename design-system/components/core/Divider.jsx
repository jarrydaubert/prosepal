import React from "react";

/**
 * ProsePal Divider — hairline separator, optionally with a centered label.
 */
export function Divider({ label = null, className = "", ...rest }) {
  if (label) {
    return (
      <div className={["pp-divider--label", className].filter(Boolean).join(" ")} {...rest}>
        {label}
      </div>
    );
  }
  return <hr className={["pp-divider", className].filter(Boolean).join(" ")} {...rest} />;
}
