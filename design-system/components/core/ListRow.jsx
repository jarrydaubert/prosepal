import React from "react";

/**
 * ProsePal ListRow — a grouped settings/menu row. Wrap rows in
 * <div className="pp-listgroup"> for the inset card look.
 */
export function ListRow({
  lead = null,
  title,
  subtitle = null,
  trailing = null,
  chevron = false,
  onClick,
  className = "",
  ...rest
}) {
  const tap = !!onClick;
  const cls = ["pp-row", tap ? "pp-row--tap" : "", className].filter(Boolean).join(" ");
  return (
    <div className={cls} onClick={onClick} role={tap ? "button" : undefined} {...rest}>
      {lead && <span className="pp-row__lead" aria-hidden="true">{lead}</span>}
      <span className="pp-row__body">
        <span className="pp-row__title">{title}</span>
        {subtitle && <span className="pp-row__sub">{subtitle}</span>}
      </span>
      {trailing && <span className="pp-row__trail">{trailing}</span>}
      {chevron && <span className="pp-row__chevron" aria-hidden="true"><i className="ph ph-caret-right" /></span>}
    </div>
  );
}
