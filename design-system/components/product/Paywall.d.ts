import * as React from "react";

export interface PaywallFeature {
  icon?: React.ReactNode;
  title: React.ReactNode;
  sub?: React.ReactNode;
}
export interface PaywallPlan {
  id: string;
  name: React.ReactNode;
  meta?: React.ReactNode;
  price: React.ReactNode;
  per?: React.ReactNode;
  /** Small sage badge, e.g. "Save 40%". */
  badge?: React.ReactNode;
}

/** The upgrade preview — value-led, calm, with selectable plans. */
export interface PaywallProps {
  icon?: React.ReactNode;
  /** @default "ProsePal Pro" */
  title?: React.ReactNode;
  sub?: React.ReactNode;
  features?: PaywallFeature[];
  plans?: PaywallPlan[];
  /** Selected plan id. */
  value?: string;
  onSelect?: (id: string) => void;
  /** @default "Start free trial" */
  cta?: React.ReactNode;
  onCta?: () => void;
  /** Fine print (restore, terms). */
  fine?: React.ReactNode;
  className?: string;
}
export declare function Paywall(props: PaywallProps): JSX.Element;
