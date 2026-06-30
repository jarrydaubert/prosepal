import * as React from "react";

/** Small pill for status, plan tier, or a "voice kept" marker. */
export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  /** @default "neutral" */
  tone?: "neutral" | "accent" | "voice" | "info" | "warning" | "danger" | "outline";
  /** Leading status dot. */
  dot?: boolean;
  /** Optional leading icon. */
  icon?: React.ReactNode;
  children?: React.ReactNode;
}

export declare function Badge(props: BadgeProps): JSX.Element;
