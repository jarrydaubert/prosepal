import * as React from "react";

/** Subscription / usage state — plan, allowance used, quiet upgrade path. */
export interface UsageCardProps {
  /** @default "Free" */
  plan?: string;
  used?: number;
  total?: number;
  /** @default "refines" */
  unit?: string;
  /** @default "this week" */
  period?: string;
  /** Reset hint, e.g. "resets Mon". */
  reset?: React.ReactNode;
  /** Optional CTA (e.g. an Upgrade Button). */
  action?: React.ReactNode;
  className?: string;
}
export declare function UsageCard(props: UsageCardProps): JSX.Element;
