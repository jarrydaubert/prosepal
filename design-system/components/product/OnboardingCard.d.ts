import * as React from "react";

/** A single welcome / teaching panel — one idea, one action. */
export interface OnboardingCardProps {
  icon?: React.ReactNode;
  eyebrow?: React.ReactNode;
  title?: React.ReactNode;
  body?: React.ReactNode;
  /** Stacked action buttons (primary first, then ghost). */
  actions?: React.ReactNode;
  className?: string;
}
export declare function OnboardingCard(props: OnboardingCardProps): JSX.Element;
