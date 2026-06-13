# ProsePal Native (SwiftUI) UX/UI Audit

## Context

Goal: a full UX/UI audit of the native SwiftUI rewrite (`ios-native-rewrite-prosepal-ios`, worktree `/private/tmp/prosepal-ios-native-worktree`), not the Flutter app. Every screen and the overall flow are reviewed against current Apple best practices.

Decisions from the user that frame this audit:

- Design bar = iOS 26 Liquid Glass (the current Apple design language), with iOS 17 kept as the deployment floor.
- Deliverable = a written audit only. No code changes.

## What Was Reviewed

- `prosepal-ios/Sources/ProsePalUI/ProsePalRootView.swift` — 4,031 lines, the entire UI lives in this one file (app model + every screen + design tokens).
- Design-intent docs: `NATIVE_UX_DIRECTION.md`, `NATIVE_PRODUCT_NORTH_STAR.md`, `NATIVE_UI_POLISH_REPORT.md`, `ARCHITECTURE.md`, `REWRITE_PLAN.md`, `MIGRATION_NOTES.md`.
- Platform: iOS 17.0 min (`ProsePal.xcodeproj`), SPM, Swift 5.10.

## Best-Practice Sources

Current as of June 2026:

- iOS 26 Liquid Glass — material reserved for the navigation/control layer floating above opaque content; standard components inherit glass automatically when built with the Xcode 26 SDK. Sources: Apple/dev community guides, Donny Wals — opting out, Kodeco intro.
- Backward compatibility: building on the iOS 26 SDK with an iOS 17 deployment target is supported; `UIDesignRequiresCompatibility` opt-out exists but Apple is removing it — do not rely on it.
- App Store Review 3.1.2 (subscriptions): paywall must clearly show price, period, and functional Terms/Privacy links. Sources: Adapty 2026 checklist, RevenueCat rejection guide, Apple guidelines.
- Account deletion 5.1.1(v): apps supporting account creation must offer in-app account deletion.

> Note: findings are from source + HIG/App Review research. The user chose written audit only, not on-device verification, so items tagged `[verify on device]` need a simulator/device pass (iOS 26 + Accessibility Inspector) to confirm rendered behavior. Optional follow-up tooling: `/gstack-ios-design-review`, `/gstack-ios-qa`.

## Severity Legend

- P0 — Release blocker / App Review risk
- P1 — High (accessibility, core UX, design-language readiness)
- P2 — Native-ness & consistency
- P3 — Polish

## P0 — Release Blockers / Compliance

1. **Paywall Terms & Privacy are non-tappable text.** `PaywallSheet` renders `Text("Terms")` / `Text("Privacy Policy")` as a plain non-interactive `HStack` around lines 2801–2807. App Review 3.1.2 requires functional links to Terms/EULA and Privacy Policy on the paywall.
   - Fix: make them tappable `Link`s to `SettingsExternalLinks.terms` / `.privacy`. Those URLs already exist around lines 3248–3249.

2. **Subscription disclosure completeness.** The paywall shows "Auto-renews. Cancel anytime in App Store settings." That is good, but price + billing period must be unmistakable adjacent to the CTA. Today price/period live only inside the selectable plan rows (`product.displayPrice` + `durationLabel`).
   - Fix: surface the selected plan's "price / period" directly beside "Continue with Premium," and confirm `displayPrice` includes the period. `[verify on device]`

3. **Delete Account is a placeholder.** `deleteAccountPlaceholder()` only shows a notice, wired from Settings. With Sign in with Apple present, App Store Review 5.1.1(v) requires real in-app account deletion before App Store release.
   - Fix: implement a real account deletion path before submission. Likely tracked as `N-IOS-07`; flagged here as a release gate.

4. **About section is dishonest / placeholder.** `aboutSection` shows `Version = "Native iOS"` and `Writing = "Online generation"`. The north-star doc explicitly wants real Version + Build.
   - Fix: bind to `CFBundleShortVersionString` / `CFBundleVersion`.

## P1 — High: Accessibility & Design-Language Readiness

### Liquid Glass Readiness

The app is currently built in a pre-Liquid-Glass idiom and much of its bespoke chrome will fight the new design language rather than inherit it:

- Hand-rolled buttons everywhere (`.buttonStyle(.plain)` on selection rows, lane cards, result actions via `ResultActionLabel`, paywall plan rows, every Settings row). These bypass the system styling that would otherwise pick up Liquid Glass automatically.
- Sticky action bars use `.background(.bar)` + a manual `Divider` overlay (`Compose` generate button, Results action bar, `DraftEditorSheet`). On iOS 26 a `safeAreaInset` bar of native buttons floats as glass; the `.bar` + `Divider` pattern is the old look.
- `TabView` uses the legacy `.tabItem` / `.tag` API. iOS 26 floats the tab bar as glass and supports scroll-minimize behavior; verify under the new SDK and consider the modern Tab API.
- Mixed, inconsistent container materials on one screen. Compose stacks a custom coral-gradient card, `ModernPanel`, `.regularMaterial`, and secondary grouped background cards.

Recommended direction:

- Build on the Xcode 26 SDK, keep iOS 17 floor, do not set `UIDesignRequiresCompatibility`.
- Reserve glass for the navigation/control layer: toolbars, tab bar, floating action bars, the writing-overlay badge.
- Keep content cards opaque.
- Replace bespoke buttons with native styles + `.tint(Color.prosePalCoral)`.
- Adopt `.buttonStyle(.glass)` / `.glassProminent` behind `#available(iOS 26)` with a `.bordered` / `.borderedProminent` fallback for iOS 17.
- Verify Reduce Transparency and Increase Contrast fallbacks for all glass/material surfaces. `[verify on device]`

### Color & Contrast

- Coral `#D4736B` on light backgrounds is used for small text and icons: summary footnote, `ResultActionLabel` secondary text/icon, `SelectionSummaryButton` icon. `#D4736B` on white is approximately 3.3:1, which fails WCAG AA 4.5:1 for normal text.
  - Fix: use coral only for large text / fills / tint; darken to `prosePalCoralDark` (`#A5564F`) for small-text foreground, or pair with a darker surface. `[verify with contrast checker]`

- Onboarding low-contrast text: benefit detail at `.white.opacity(0.52)` on navy and progress context at `.white.opacity(0.72)` likely fail AA.
  - Fix: raise opacity / use a semantic secondary that meets contrast.

### Other P1

- **Writing overlay cannot be cancelled.** `WritingProgressOverlay` is a full-screen blocking overlay with a spinner and no Cancel/abort. A slow gateway leaves the user trapped until success/timeout.
  - Fix: add a Cancel affordance that aborts the in-flight `generate()` task.

- **Toast (`NoticeBanner`) is not announced to VoiceOver.** It is a top overlay that auto-dismisses in 1.7 seconds with no accessibility announcement, so screen-reader users miss "Copied", "Saved", and "Signed in."
  - Fix: post an accessibility announcement. Also reconsider redundancy: cards already show inline "Copied"/"Saved" states.

- **Onboarding forces `.preferredColorScheme(.dark)`.** The brand backdrops are always dark regardless of system appearance. This is acceptable as a branded launch if intentional, but confirm hardcoded coral/navy palette has no light-mode-only assumptions elsewhere.

## P2 — Native-Ness & Consistency

- **Compose is a hand-built form, not a native Form.** The whole Create screen is custom panels inside a `ScrollView`. A native `Form` / inset-grouped `List` would give consistent spacing, dividers, and automatic Liquid Glass grouping. Bare `TextField`s sit inside custom panels separated by manual `Divider`s.

- **Settings rows are bespoke.** `SettingsView` correctly uses a native `List` + `Section`s, but every row is a custom `SettingsRow` inside `Button(.plain)`, losing native chevrons, row highlight, and glass treatment.
  - Fix: prefer `NavigationLink` / native `Label` rows; reserve custom rows for genuinely custom content.

- **Selection affordance mismatch.** `SelectionSummaryButton` shows `chevron.up.chevron.down`, which reads as a menu/stepper glyph, but opens a sheet.
  - Fix: use `chevron.right`, or make it an actual `Menu`.

- **Haptic inconsistency.** Relationship and Tone pickers fire `playSelectionFeedback()` on choose; the Occasion picker does not.
  - Fix: align occasion selection with relationship/tone feedback.

- **`DraftEditorSheet` "Done" does not commit.** The toolbar `Button("Done")` is in `.cancellationAction` and only dismisses; Save is a separate button. "Done" implying discard is confusing.
  - Fix: rename to "Cancel", or make "Done" save.

- **Result actions reimplement button chrome.** `ResultActionLabel` hand-draws fills/borders/sizing for Copy/Share/Edit/Save instead of native button styles. This is the main reason these will not inherit Liquid Glass and the source of the coral-contrast issue above.

- **Settings "Writing" section mixes three control idioms.** Segmented Spelling picker, a default-tone Picker, and lane-selection buttons sit in one section and feel visually inconsistent.

## P3 — Polish

- Generation-mode selector is a horizontal `ScrollView` for only two items: Standard/Premium. A segmented control or two inline cards reads better and avoids an unexpected scroll affordance.
- Three stacked headers on Create: tab label "Create" + nav title "Create" + intent header "Find the right words". Consider dropping the redundant nav title or reducing tab/intent duplication.
- Inline error block placement: the Compose error/"Try again" card renders mid-scroll between style controls and the sticky button, where it is easy to miss. Consider surfacing nearer the action or as an alert.
- `DraftEditor` / `TextEditor` has no placeholder and no character/length indicator.
- Compose detail `TextField`s all use `.submitLabel(.done)` and dismiss on submit, but the multiline context field with `.done` cannot easily insert newlines. Confirm that is intended.

## What Is Already Good

Keep these:

- Picker sheets (Occasion/Relationship/Tone): searchable grouped `List`, checkmark selection, `ContentUnavailableView.search`, medium/large detents — strong native pattern.
- No provider/model names anywhere in user-facing copy, matching the north-star non-negotiable.
- Dynamic Type handled well: `@ScaledMetric`, `ViewThatFits`, accessibility-size branches in result actions, `minimumScaleFactor`.
- `textSelection(.enabled)` on generated/saved text; `ShareLink` for sharing; haptics on copy/save; Reduce Motion respected in animations.
- Saved list: native `List`, `.searchable`, swipe-to-delete, `NavigationLink` detail, destructive `confirmationDialog`. Delete-by-filtered-offset is correctly resolved by id, safe while searching.
- Settings correctly hides `runtimeReadinessSection` behind `#if DEBUG`; biometric lock gated on sign-in; restore / Use Standard / Sign in with Apple paths present and not forced.

## Suggested Remediation Sequencing

For a later, separate effort:

1. P0 compliance: paywall links + price/period disclosure, real Version/Build, account deletion. These gate any App Store submission.
2. P1 accessibility: coral and onboarding contrast, toast announcement, cancellable writing overlay. These are independent of the glass migration; do first.
3. Liquid Glass migration: build on Xcode 26 SDK; convert sticky bars, buttons, tab bar; reconcile coral with vibrancy/contrast; verify Reduce Transparency.
4. P2 native-ness: Compose to Form, Settings rows, affordance/haptic/label fixes. Best folded into the glass migration.
5. P3 polish.

Worth noting as an enabler: the entire UI is one 4,031-line file. Splitting per-screen files would materially de-risk all of the above.

## Verification

When fixes are eventually made:

- Build on Xcode 26 SDK; run on an iOS 26 simulator and an iOS 17 device/simulator to confirm both the glass look and the fallback.
- Accessibility Inspector: contrast audit, VoiceOver pass on toast + paywall, Dynamic Type at AX5, Reduce Transparency + Increase Contrast.
- App Review dry-run against the 3.1.2 subscription checklist and 5.1.1(v) account-deletion requirement.
