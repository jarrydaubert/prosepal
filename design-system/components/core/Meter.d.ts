/** Slim progress/usage bar — refine quota, voice-match score, upload, etc. */
export interface MeterProps {
  value?: number;
  max?: number;
  /** @default "accent" */
  tone?: "accent" | "voice" | "warning";
  /** 5px instead of 8px track. */
  thin?: boolean;
  className?: string;
}

export declare function Meter(props: MeterProps): JSX.Element;
