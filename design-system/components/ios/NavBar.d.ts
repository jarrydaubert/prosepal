import * as React from "react";

/** iOS navigation bar — inline or large-title. */
export interface NavBarProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Inline (centered) title. */
  title?: React.ReactNode;
  /** Large title text (top-level screens). */
  largeTitle?: React.ReactNode;
  /** Leading slot (back chevron / menu). */
  leading?: React.ReactNode;
  /** Trailing slot (actions). */
  trailing?: React.ReactNode;
  /** Use the large-title layout. */
  large?: boolean;
}
export declare function NavBar(props: NavBarProps): JSX.Element;
