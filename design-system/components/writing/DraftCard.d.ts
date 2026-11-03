import * as React from "react";

/** A ProsePal-generated draft. Text is the hero; meta + actions stay quiet. */
export interface DraftCardProps {
  /** Eyebrow label. @default "Draft" */
  label?: React.ReactNode;
  /** Tone tags shown as small clay badges. */
  tones?: string[];
  /** Reassurance line, e.g. "Your voice, kept". */
  voiceNote?: React.ReactNode;
  /** Variant pager, e.g. { current: 2, total: 3 }. */
  variants?: { current: number; total: number };
  /** Stronger shadow for a floating/result presentation. */
  raised?: boolean;
  /** Footer action buttons (use `.pp-draftbtn`). */
  actions?: React.ReactNode;
  /** The draft body (wrap paragraphs in <p>). */
  children?: React.ReactNode;
  className?: string;
}
export declare function DraftCard(props: DraftCardProps): JSX.Element;
