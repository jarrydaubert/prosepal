import React from "react";

/**
 * ProsePal NavBar — iOS navigation bar. Inline title by default,
 * or `large` for the large-title style used on top-level screens.
 */
export function NavBar({ title, largeTitle, leading, trailing, large = false, className = "", ...rest }) {
  return (
    <div className={["pp-navbar", className].filter(Boolean).join(" ")} {...rest}>
      <div className="pp-navbar__top">
        <span className="pp-navbar__lead">{leading}</span>
        {!large && title && <span className="pp-navbar__inline-title">{title}</span>}
        <span className="pp-navbar__trail">{trailing}</span>
      </div>
      {large && (largeTitle || title) && (
        <div className="pp-navbar__largetitle">{largeTitle || title}</div>
      )}
    </div>
  );
}
