import React from "react";

/**
 * ProsePal Avatar — initials or image. Soft clay tint by default.
 */
export function Avatar({ src = null, name = "", size = "md", className = "", ...rest }) {
  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0])
    .join("")
    .toUpperCase();
  const cls = ["pp-avatar", size !== "md" ? `pp-avatar--${size}` : "", className]
    .filter(Boolean)
    .join(" ");
  return (
    <span className={cls} {...rest}>
      {src ? <img src={src} alt={name} /> : (initials || "·")}
    </span>
  );
}
