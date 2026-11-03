import * as React from "react";

/** A calm, encouraging empty state — invites the first action. */
export interface EmptyStateProps {
  icon?: React.ReactNode;
  title?: React.ReactNode;
  body?: React.ReactNode;
  action?: React.ReactNode;
  className?: string;
}
export declare function EmptyState(props: EmptyStateProps): JSX.Element;
