import * as React from "react";

export interface ToneOption {
  id: string;
  label: string;
  icon?: React.ReactNode;
}

/** Choose the goal/voice for a draft — single or multi select chips. */
export interface ToneSelectorProps {
  /** @default "How should it feel?" */
  title?: React.ReactNode;
  hint?: React.ReactNode;
  options: ToneOption[];
  /** Selected ids. */
  value?: string[];
  onChange?: (ids: string[]) => void;
  /** Allow multiple. @default true */
  multi?: boolean;
  /** Horizontal scroll row instead of wrap. */
  scroll?: boolean;
  className?: string;
}
export declare function ToneSelector(props: ToneSelectorProps): JSX.Element;
