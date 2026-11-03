import * as React from "react";

export interface RefineAction {
  id: string;
  label: string;
  icon?: React.ReactNode;
}

/** Floating bar of one-tap refinements applied to a draft. */
export interface RefineBarProps {
  actions: RefineAction[];
  onAction?: (id: string) => void;
  /** Show the leading wand glyph. @default true */
  lead?: boolean;
  className?: string;
}
export declare function RefineBar(props: RefineBarProps): JSX.Element;
