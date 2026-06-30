import React from "react";

/**
 * ProsePal Paywall — the upgrade preview. Leads with the felt value
 * ("unlimited refines, every voice"), not a feature dump. Calm.
 */
export function Paywall({
  icon = <i className="ph ph-feather" />,
  title = "ProsePal Pro",
  sub,
  features = [],
  plans = [],
  value,
  onSelect,
  cta = "Start free trial",
  onCta,
  fine,
  className = "",
  ...rest
}) {
  return (
    <div className={["pp-paywall", className].filter(Boolean).join(" ")} {...rest}>
      <div className="pp-paywall__hero">
        <div className="pp-paywall__crest" aria-hidden="true">{icon}</div>
        <h2 className="pp-paywall__title">{title}</h2>
        {sub && <p className="pp-paywall__sub">{sub}</p>}
      </div>

      {features.length > 0 && (
        <ul className="pp-paywall__features">
          {features.map((f, i) => (
            <li key={i}>
              <span className="ic" aria-hidden="true">{f.icon || <i className="ph ph-check" />}</span>
              <div>
                <div className="ft-t">{f.title}</div>
                {f.sub && <div className="ft-s">{f.sub}</div>}
              </div>
            </li>
          ))}
        </ul>
      )}

      {plans.length > 0 && (
        <div className="pp-plans">
          {plans.map((p) => (
            <button key={p.id} type="button" className="pp-plan" aria-pressed={value === p.id} onClick={() => onSelect && onSelect(p.id)}>
              <span className="pp-plan__radio" aria-hidden="true" />
              <span className="pp-plan__body">
                <span className="pp-plan__name">{p.name}{p.badge && <span className="pp-badge pp-badge--voice" style={{ marginLeft: 8 }}>{p.badge}</span>}</span>
                {p.meta && <span className="pp-plan__meta">{p.meta}</span>}
              </span>
              <span className="pp-plan__price"><b>{p.price}</b><span>{p.per}</span></span>
            </button>
          ))}
        </div>
      )}

      <button type="button" className="pp-btn pp-btn--primary pp-btn--xl pp-btn--block" onClick={onCta}>{cta}</button>
      {fine && <div className="pp-paywall__fine">{fine}</div>}
    </div>
  );
}
