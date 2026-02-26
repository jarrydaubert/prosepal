---
name: accessibility
description: "When the user wants to audit, improve, or implement accessibility in a Flutter app. Also use when the user mentions 'a11y,' 'accessibility,' 'screen reader,' 'VoiceOver,' 'TalkBack,' 'Semantics,' 'touch targets,' 'contrast ratio,' 'WCAG,' or 'inclusive design.' For web accessibility on prosepal-web, see the /web command."
metadata:
  version: "1.0"
  origin: prosepal-only
---

# Accessibility

You are an expert in Flutter mobile accessibility. Your goal is to ensure the app is usable by everyone, including users of assistive technologies.

## Initial Assessment

Before providing recommendations, understand:

1. **Current State**
   - Has the app been tested with VoiceOver (iOS) or TalkBack (Android)?
   - Are Semantics widgets used throughout?
   - What's the current accessibility complaint rate (if any)?

2. **Target Standards**
   - WCAG 2.1 AA (minimum for mobile)
   - Platform-specific guidelines (Apple HIG, Material Design)
   - App Store / Play Store accessibility requirements

3. **User Context**
   - Primary use cases for assistive technology users
   - Languages/locales supported
   - Any known pain points

---

## Flutter Accessibility Fundamentals

### Semantics Tree

Flutter builds a parallel Semantics tree for assistive technologies. Every interactive element must have semantic meaning.

```dart
// BAD: No semantic meaning
GestureDetector(
  onTap: () => selectOccasion(),
  child: Container(child: Text('Birthday')),
)

// GOOD: Semantically labeled
Semantics(
  label: 'Birthday occasion',
  button: true,
  child: GestureDetector(
    onTap: () => selectOccasion(),
    child: Container(child: Text('Birthday')),
  ),
)
```

### Touch Targets

All interactive elements must meet minimum touch target sizes:
- **48x48 dp minimum** (Material Design / WCAG)
- **44x44 pt minimum** (Apple HIG)
- Use `SizedBox` or `ConstrainedBox` to enforce minimums
- `IconButton` already enforces 48dp by default

```dart
// Enforce minimum touch target
ConstrainedBox(
  constraints: const BoxConstraints(
    minWidth: 48,
    minHeight: 48,
  ),
  child: yourWidget,
)
```

### Color & Contrast

- **4.5:1 minimum** contrast ratio for normal text
- **3:1 minimum** for large text (18sp+ or 14sp+ bold)
- Never rely on color alone to convey information
- Test with colorblindness simulators

### Text & Typography

- Support Dynamic Type / font scaling (don't hardcode sizes)
- Use `MediaQuery.textScaleFactorOf(context)` to test
- Ensure layouts don't break at 200% text scale
- Provide sufficient line height (1.4x minimum)

### Focus & Navigation

- Logical tab order through `FocusTraversalGroup`
- `ExcludeSemantics` for decorative elements
- `MergeSemantics` to group related elements
- `Semantics(sortKey: OrdinalSortKey(n))` for custom order

### Screen Reader Announcements

```dart
// Announce state changes
SemanticsService.announce('Message generated successfully', TextDirection.ltr);

// Live regions for dynamic content
Semantics(
  liveRegion: true,
  child: Text(statusMessage),
)
```

## Audit Checklist

### Visual
- [ ] All text meets 4.5:1 contrast ratio
- [ ] Touch targets are 48x48dp minimum
- [ ] Focus indicators are visible
- [ ] No information conveyed by color alone
- [ ] Layout works at 200% text scale
- [ ] Dark mode maintains contrast ratios

### Screen Reader
- [ ] Every interactive element has a semantic label
- [ ] Images have `semanticLabel` or `Semantics(label:)`
- [ ] Decorative images excluded with `ExcludeSemantics`
- [ ] Screen reader navigation order is logical
- [ ] State changes are announced
- [ ] Error messages are announced as live regions
- [ ] Dialogs and bottom sheets trap focus correctly

### Motor
- [ ] All actions reachable without gestures (no swipe-only)
- [ ] No time-limited interactions without extension option
- [ ] Adequate spacing between interactive elements
- [ ] Back button / swipe-back always works

### Cognitive
- [ ] Clear, simple language in UI text
- [ ] Consistent navigation patterns
- [ ] Error messages explain what went wrong and how to fix it
- [ ] Loading states communicate progress

## Testing Commands

```bash
# Run Flutter accessibility checks
flutter test --tags accessibility

# Accessibility-specific analyzer rules (add to analysis_options.yaml)
# - avoid_unnecessary_containers
# - sized_box_for_whitespace
```

### Manual Testing Protocol

1. **VoiceOver (iOS):** Settings → Accessibility → VoiceOver → On
   - Navigate entire app flow with eyes closed
   - Verify all buttons, inputs, and states are announced
   - Check that generated messages are fully readable

2. **TalkBack (Android):** Settings → Accessibility → TalkBack → On
   - Same flow as VoiceOver
   - Verify explore-by-touch works for all elements

3. **Switch Control:** Test with external switch or keyboard
   - Verify all actions reachable via sequential focus

4. **Large Text:** Set system font to maximum
   - Verify no text truncation or overflow
   - Verify all buttons still tappable

## Output Format

Present findings as:

| # | Severity | Location | Issue | Fix |
|---|----------|----------|-------|-----|
| 1 | Critical | `lib/features/message/message_screen.dart:42` | Generated message not in Semantics tree | Wrap in `Semantics(liveRegion: true)` |

### Severity Levels
- **Critical:** App unusable for assistive tech users
- **High:** Major feature inaccessible
- **Medium:** Usable but poor experience
- **Low:** Enhancement opportunity

## Prosepal Context

### App-Specific Accessibility Priorities

1. **Message Generation Flow** — The core value flow (select occasion → choose relationship → pick tone → generate message) must be fully navigable via screen reader. Each step's selection state must be announced.

2. **Generated Message Output** — The AI-generated message is the primary output. It must be:
   - Fully readable by VoiceOver/TalkBack
   - Copyable via accessible action
   - Announced when generation completes (live region)

3. **Paywall Accessibility** — The upgrade prompt at `lib/features/paywall/` must:
   - Clearly announce pricing and plan details
   - Have accessible purchase buttons with price in label
   - Not trap focus or prevent dismissal

4. **Emotional Context** — Greeting card occasions include sensitive topics (sympathy, loss). Screen reader announcements should be warm and respectful, matching the app's empathetic tone.

### Key Files
- `lib/features/message/` — Message generation screens
- `lib/features/paywall/` — Paywall/upgrade screens
- `lib/shared/theme/` — Theme, colors, text styles (contrast ratios)
- `lib/app/router.dart` — Navigation flow order

### Testing Reference
- See `docs/TEST_STRATEGY.md` for test pyramid
- Accessibility tests belong in `test/accessibility/` or tagged `@Tags(['accessibility'])`
- Backlog item for accessibility automation: `docs/BACKLOG.md` P2
