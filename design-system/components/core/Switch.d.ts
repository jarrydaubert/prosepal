/** iOS-style toggle. Controlled — pass `checked` and handle `onChange`. */
export interface SwitchProps {
  checked?: boolean;
  onChange?: (next: boolean) => void;
  disabled?: boolean;
  /** Accessible label. */
  label?: string;
  className?: string;
}

export declare function Switch(props: SwitchProps): JSX.Element;
