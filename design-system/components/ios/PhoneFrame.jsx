import React from "react";

/**
 * ProsePal PhoneFrame — an iPhone shell (Dynamic Island, rounded
 * screen) for presenting ProsePal mockups. Fill it with a StatusBar,
 * NavBar, screen content, TabBar and HomeIndicator.
 */
export function PhoneFrame({ screenBg, className = "", style, children, ...rest }) {
  return (
    <div className={["pp-phone", className].filter(Boolean).join(" ")} style={style} {...rest}>
      <div className="pp-phone__island" aria-hidden="true" />
      <div className="pp-phone__screen" style={screenBg ? { background: screenBg } : undefined}>
        {children}
      </div>
    </div>
  );
}

/** The iOS status bar (time + signal/wifi/battery). */
export function StatusBar({ time = "9:41", className = "", ...rest }) {
  return (
    <div className={["pp-statusbar", className].filter(Boolean).join(" ")} {...rest}>
      <span className="pp-statusbar__time">{time}</span>
      <span className="pp-statusbar__icons" aria-hidden="true">
        <i className="ph-fill ph-cell-signal-full" />
        <i className="ph-fill ph-wifi-high" />
        <i className="ph-fill ph-battery-full" />
      </span>
    </div>
  );
}

/** The iOS home indicator pill. */
export function HomeIndicator({ className = "", ...rest }) {
  return <div className={["pp-home", className].filter(Boolean).join(" ")} {...rest} />;
}
