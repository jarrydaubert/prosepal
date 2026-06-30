import * as React from "react";

/** iPhone presentation shell with Dynamic Island and rounded screen. */
export interface PhoneFrameProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Override the screen background (defaults to --bg). */
  screenBg?: string;
  children?: React.ReactNode;
}
export declare function PhoneFrame(props: PhoneFrameProps): JSX.Element;

export interface StatusBarProps extends React.HTMLAttributes<HTMLDivElement> {
  /** @default "9:41" */
  time?: string;
}
export declare function StatusBar(props: StatusBarProps): JSX.Element;

export declare function HomeIndicator(props: React.HTMLAttributes<HTMLDivElement>): JSX.Element;
