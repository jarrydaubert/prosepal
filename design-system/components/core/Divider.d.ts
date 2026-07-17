import * as React from "react";

/** Hairline separator; pass `label` for a centered "or" style divider. */
export interface DividerProps extends React.HTMLAttributes<HTMLElement> {
  label?: React.ReactNode;
}

export declare function Divider(props: DividerProps): JSX.Element;
