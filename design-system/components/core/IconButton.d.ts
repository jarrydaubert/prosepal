import * as React from "react";

/** A circular icon-only control for nav bars and toolbars. */
export interface IconButtonProps extends Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, "children"> {
  /** Icon node (a Phosphor <i/> or SVG). */
  icon: React.ReactNode;
  /** Required accessible label. */
  label: string;
  /** @default "plain" */
  variant?: "plain" | "filled" | "accent";
  /** @default "md" */
  size?: "sm" | "md" | "lg";
}

export declare function IconButton(props: IconButtonProps): JSX.Element;
