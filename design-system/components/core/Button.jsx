import React from "react";

/**
 * ProsePal Button — capsule, semibold, calm press-shrink.
 * Variants: primary · secondary · neutral · ghost · outline · danger
 */
export function Button({
  variant = "primary",
  size = "lg",
  block = false,
  loading = false,
  disabled = false,
  icon = null,
  iconTrailing = null,
  className = "",
  children,
  ...rest
}) {
  const cls = [
    "pp-btn",
    `pp-btn--${variant}`,
    `pp-btn--${size}`,
    block ? "pp-btn--block" : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <button className={cls} disabled={disabled || loading} aria-busy={loading || undefined} {...rest}>
      {loading ? (
        <span className="pp-spinner" aria-hidden="true" />
      ) : (
        icon && <span className="pp-btn__icon" aria-hidden="true">{icon}</span>
      )}
      {children && <span className="pp-btn__label">{children}</span>}
      {iconTrailing && !loading && (
        <span className="pp-btn__icon" aria-hidden="true">{iconTrailing}</span>
      )}
    </button>
  );
}
