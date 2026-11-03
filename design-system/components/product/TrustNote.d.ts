import * as React from "react";

/** Privacy / trust reassurance block — sage-tinted, confident, quiet. */
export interface TrustNoteProps {
  /** @default a lock glyph */
  icon?: React.ReactNode;
  title?: React.ReactNode;
  body?: React.ReactNode;
  /** Optional checklist of reassurances. */
  points?: React.ReactNode[];
  /** Compact single-row variant. */
  inline?: boolean;
  className?: string;
}
export declare function TrustNote(props: TrustNoteProps): JSX.Element;
