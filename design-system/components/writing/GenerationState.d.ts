/** The "thinking" state — breathing orb, status line, shimmering lines. */
export interface GenerationStateProps {
  /** @default "Finding the right words…" */
  label?: string;
  /** Skeleton line count. @default 4 */
  lines?: number;
  className?: string;
}
export declare function GenerationState(props: GenerationStateProps): JSX.Element;
