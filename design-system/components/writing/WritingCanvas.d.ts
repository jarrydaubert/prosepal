import * as React from "react";

/** The writing input surface — a sheet of paper, not a chat box. */
export interface WritingCanvasProps {
  value?: string;
  onChange?: (value: string) => void;
  /** @default "Write what's on your mind…" */
  placeholder?: string;
  /** Optional eyebrow prompt above the field. */
  prompt?: React.ReactNode;
  /** Word/character count (mono, right of the footer). */
  count?: React.ReactNode;
  /** Leading footer tools (voice, attach…). */
  tools?: React.ReactNode;
  /** Trailing footer actions (the send/refine button). */
  actions?: React.ReactNode;
  /** Focused ring state. */
  focus?: boolean;
  rows?: number;
  className?: string;
}
export declare function WritingCanvas(props: WritingCanvasProps): JSX.Element;
