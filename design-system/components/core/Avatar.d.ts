/** Round avatar — image, or initials on a soft clay tint. */
export interface AvatarProps {
  src?: string | null;
  /** Full name → initials fallback. */
  name?: string;
  /** @default "md" (40px). sm 28 · lg 56 */
  size?: "sm" | "md" | "lg";
  className?: string;
}

export declare function Avatar(props: AvatarProps): JSX.Element;
