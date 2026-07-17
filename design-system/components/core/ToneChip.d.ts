import * as React from "react";

/** A soft selectable capsule — the atom of tone & style choice. */
export interface ToneChipProps extends Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, "children"> {
  /** Selected (pressed) state — clay tint. */
  selected?: boolean;
  /** Leading icon node. */
  icon?: React.ReactNode;
  /** Dashed "add" affordance. */
  ghost?: boolean;
  children?: React.ReactNode;
}

export declare function ToneChip(props: ToneChipProps): JSX.Element;
