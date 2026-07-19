# Accessibility Standard

Accessibility is part of the product contract, not a final visual-polish
pass. Every touched release surface should remain usable with Apple’s standard
accessibility settings.

## Required behaviours

- VoiceOver exposes meaningful labels, values, hints where useful, and a logical
  navigation order.
- Dynamic Type keeps the core writing path usable at accessibility sizes without
  clipping controls or covering content.
- Interactive targets meet Apple’s expected touch size and do not rely on colour
  alone.
- Text and controls retain sufficient contrast in supported appearances.
- Reduce Motion removes or simplifies nonessential movement.
- Reduce Transparency replaces translucent control surfaces with readable
  opaque alternatives.
- Keyboard and focus behaviour preserves a complete route through input,
  drafting, actions, sheets, and Settings.
- Compact and regular widths keep all release actions reachable.

## Implementation guidance

- Prefer standard SwiftUI controls and semantic text styles.
- Give icon-only controls explicit accessibility labels.
- Use identifiers for release-critical UI automation, not as a substitute for
  labels a user can understand.
- Avoid fixed heights and fixed font sizes for body, title, or action text.
- Test custom rails, cards, and overlays at the largest accessibility size.
- Honour environment values instead of creating a separate inaccessible
  animation or transparency system.

## Release matrix

At minimum, exercise:

- first run and person entry;
- Moment setup and Write Draft;
- generated draft actions and rewrite decision controls;
- offline/error recovery;
- Paywall and restore entry;
- destructive confirmations;
- Settings and privacy controls; and
- any widget, control, or Share Extension included in the candidate.

Use supported small and large iPhones plus a regular-width layout. Physical
VoiceOver and keyboard evidence remains necessary even when simulator and
automated checks pass.

## Evidence

Record the device/OS, accessibility setting, path exercised, outcome, and any
privacy-safe screenshot or video reference. Do not place user content in tracked
evidence. Unresolved failures belong in [BACKLOG.md](../BACKLOG.md).

## Apple references

- [Accessibility](https://developer.apple.com/accessibility/)
- [Human Interface Guidelines: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
