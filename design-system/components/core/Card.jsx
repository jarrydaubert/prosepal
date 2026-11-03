import React from "react";

/**
 * ProsePal Card — the soft paper surface everything sits on.
 * Variants: default · flat · raised · inset.
 */
export function Card({
  variant = "default",
  pad = "none",
  interactive = false,
  as: Tag = "div",
  className = "",
  style,
  children,
  ...rest
}) {
  const cls = [
    "pp-card",
    variant !== "default" ? `pp-card--${variant}` : "",
    pad === "md" ? "pp-card--pad" : pad === "lg" ? "pp-card--pad-lg" : "",
    interactive ? "pp-card--interactive" : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <Tag className={cls} style={style} {...rest}>
      {children}
    </Tag>
  );
}
