import * as React from "react";

/**
 * The primary action control — a calm iOS capsule button.
 */
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Visual weight. @default "primary" */
  variant?: "primary" | "secondary" | "neutral" | "ghost" | "outline" | "danger";
  /** Control height. @default "lg" */
  size?: "sm" | "md" | "lg" | "xl";
  /** Stretch to fill the container width. */
  block?: boolean;
  /** Show a spinner and disable interaction. */
  loading?: boolean;
  /** Leading icon node (e.g. a Phosphor <i/>). */
  icon?: React.ReactNode;
  /** Trailing icon node. */
  iconTrailing?: React.ReactNode;
  children?: React.ReactNode;
}

export declare function Button(props: ButtonProps): JSX.Element;
