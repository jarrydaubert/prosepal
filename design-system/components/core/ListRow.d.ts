import * as React from "react";

/** A grouped iOS list row. Wrap a set in `<div class="pp-listgroup">`. */
export interface ListRowProps extends Omit<React.HTMLAttributes<HTMLDivElement>, "title"> {
  /** Leading icon/avatar node. */
  lead?: React.ReactNode;
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  /** Trailing value / control (text, Switch, Badge). */
  trailing?: React.ReactNode;
  /** Show a disclosure chevron. */
  chevron?: boolean;
  onClick?: () => void;
}

export declare function ListRow(props: ListRowProps): JSX.Element;
