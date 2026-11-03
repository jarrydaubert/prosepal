import React from "react";

/**
 * ProsePal IconButton — a circular tap target for nav & toolbar glyphs.
 * Variants: plain · filled · accent.
 */
export function IconButton({
  icon,
  label,
  variant = "plain",
  size = "md",
  disabled = false,
  className = "",
  ...rest
}) {
  const cls = [
    "pp-iconbtn",
    variant !== "plain" ? `pp-iconbtn--${variant}` : "",
    size !== "md" ? `pp-iconbtn--${size}` : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <button className={cls} aria-label={label} disabled={disabled} {...rest}>
      <span aria-hidden="true" style={{ lineHeight: 0, display: "inline-flex" }}>{icon}</span>
    </button>
  );
}
