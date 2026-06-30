import * as React from "react";

/** Soft rounded surface — the paper everything in ProsePal rests on. */
export interface CardProps extends React.HTMLAttributes<HTMLElement> {
  /** @default "default" (hairline + soft shadow) */
  variant?: "default" | "flat" | "raised" | "inset";
  /** Built-in padding. @default "none" */
  pad?: "none" | "md" | "lg";
  /** Adds hover-lift + press feedback. */
  interactive?: boolean;
  /** Render as another element/tag. @default "div" */
  as?: keyof JSX.IntrinsicElements;
}

export declare function Card(props: CardProps): JSX.Element;
