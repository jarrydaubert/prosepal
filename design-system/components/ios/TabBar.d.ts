import * as React from "react";

export interface TabItem {
  value: string;
  label: string;
  icon: React.ReactNode;
  /** Render as the raised center compose button. */
  fab?: boolean;
}

/** Bottom tab bar; translucent, with an optional center compose FAB. */
export interface TabBarProps {
  items: TabItem[];
  value: string;
  onChange?: (value: string) => void;
  className?: string;
}
export declare function TabBar(props: TabBarProps): JSX.Element;
