import * as React from "react";

export interface SegmentedItem {
  value: string;
  label: string;
  icon?: React.ReactNode;
}

/** iOS segmented pill — 2–4 mutually exclusive options. Controlled. */
export interface SegmentedControlProps {
  items: SegmentedItem[];
  value: string;
  onChange?: (value: string) => void;
  className?: string;
}

export declare function SegmentedControl(props: SegmentedControlProps): JSX.Element;
