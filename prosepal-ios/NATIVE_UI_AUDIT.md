# ProsePal Native (SwiftUI) — UX/UI Audit

## Context

Goal: a full UX/UI audit of the **native SwiftUI rewrite** (branch `ios-native-rewrite-prosepal-ios`, worktree `/private/tmp/prosepal-ios-native-worktree`), **not** the Flutter app. Every screen and the overall flow are reviewed against current Apple best practices.

Decisions from the user that frame this audit:
- **Design bar = iOS 26 Liquid Glass** (the current Apple design language), with iOS 17 kept as the deployment floor.
- This began as a written audit and is now the living implementation tracker for the native UI polish work.

### What was reviewed
- `prosepal-ios/Sources/ProsePalUI/ProsePalRootView.swift` — **4,031 lines, the entire UI lives in this one file** (app model + every screen + design tokens).
- Design-intent docs: `NATIVE_UX_DIRECTION.md`, `NATIVE_PRODUCT_NORTH_STAR.md`, `NATIVE_UI_POLISH_REPORT.md`, `ARCHITECTURE.md`, `REWRITE_PLAN.md`, `MIGRATION_NOTES.md`.
- Platform: **iOS 17.0 min** (`ProsePal.xcodeproj`), SPM, Swift 5.10.

### Best-practice sources (current, June 2026)
- iOS 26 Liquid Glass — material reserved for the *navigation/control layer* floating above opaque content; standard components inherit glass automatically when built with the Xcode 26 SDK. ([Apple/dev community guides](https://dev.to/arshtechpro/ios-26-sdk-is-now-mandatory-here-is-what-actually-changes-for-your-app-39m4), [Donny Wals — opting out](https://www.donnywals.com/opting-your-app-out-of-the-liquid-glass-redesign-with-xcode-26/), [Kodeco intro](https://www.kodeco.com/49905345-an-introduction-to-liquid-glass-for-ios-26))
- Backward compat: building on the iOS 26 SDK with an iOS 17 deployment target is supported; `UIDesignRequiresCompatibility` opt-out exists but Apple is removing it — do **not** rely on it.
- App Store Review **3.1.2** (subscriptions): paywall must clearly show price, period, and functional Terms/Privacy links. ([Adapty 2026 checklist](https://adapty.io/blog/how-to-pass-app-store-review/), [RevenueCat rejection guide](https://www.revenuecat.com/blog/growth/the-ultimate-guide-to-app-store-rejections/), [Apple guidelines](https://developer.apple.com/app-store/review/guidelines/))
- Account deletion **5.1.1(v)**: apps supporting account creation must offer in-app account deletion.

> Note: findings are from source + HIG/App Review research. The user chose "written audit only" (not on-device verification), so items tagged **[verify on device]** need a simulator/device pass (iOS 26 + Accessibility Inspector) to confirm rendered behavior. Optional follow-up tooling: `/gstack-ios-design-review`, `/gstack-ios-qa`.

---

## Severity legend
- **P0 — Release blocker / App Review risk**
- **P1 — High (accessibility, core UX, design-language readiness)**
- **P2 — Native-ness & consistency**
- **P3 — Polish**

---

## Implementation tracker

| Area | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Paywall Terms and Privacy links | Done | `387d6f0`, `115129f` | Paywall and sign-in/settings legal destinations use real `Link`s. |
| Paywall selected price/period disclosure | Done | `387d6f0`; `SettingsParityStateTests.testPremiumRenewalDisclosureIncludesSelectedPlanPriceAndPeriod` | Still needs visual verification with real StoreKit products. |
| About Version + Build | Done | `SettingsParityStateTests.testAboutUsesClientContextVersionAndGatewayRuntime` | Uses app `ClientContext` instead of placeholder copy. |
| Account action honesty | Done | `311ad17` | Export/Delete no longer pretend to complete; real deletion remains a release gate. |
| Real in-app account deletion | Partial | This slice | Native client now calls the ProsePal `delete-user` Edge Function and clears local signed-in state after success; still needs staging/prod deployment verification and Apple revocation secret checks. |
| Cancellable writing overlay | Done | `609354b`; `UsagePolicyTests.testCancelGenerationStopsInFlightRequestWithoutShowingResults` | Slow gateway calls can be cancelled from the blocking overlay. |
| Notice/VoiceOver announcement | Done | `4b1902f`; `announceAccessibilityNotice(_:)` | Notices announce title only; no user content. |
| Onboarding contrast | Done | `1c8bbb8` | Benefit detail contrast raised on the navy onboarding background. |
| Result actions use native buttons | Done | `0dd4fa3` | Removed bespoke `ResultActionLabel` chrome. |
| Picker affordance and haptics | Done | `fc078d1` | Sheet affordance uses disclosure chevron; occasion picker haptics aligned. |
| Message editor cancel/placeholder/count | Done | `32526f4`, this slice | Avoids destructive "Done" ambiguity, uses "Message Editor", and gives editing context. |
| Generation mode selector | Done | `f7cda58` | Two-option selector no longer uses a horizontal scroll view. |
| Settings external destinations | Done | `115129f` | External rows use native `Link` while preserving safe diagnostics. |
| Settings row native-ness | Done | `115129f`, this slice | Settings links and action rows now use native `Link`/`Button` row behavior instead of suppressing it with plain styling. |
| Coral contrast on small foreground text | Done | `4b1902f`, `0dd4fa3`, `1c8bbb8`, this slice | Explicit small coral foreground uses now use `prosePalCoralDark`; verify with Accessibility Inspector before release. |
| Sticky action bars / Liquid Glass migration | Partial | This slice | Sticky controls use adaptive glass/glassProminent styles and tabs use the modern Tab API where available; still needs iOS 26 visual QA. |
| Compose form native structure | Done | This slice | Create now uses grouped native `Form` sections for inputs/style/error state while preserving the same recipient-first flow; accessibility Dynamic Type uses an inline Write action to avoid CTA overlap. |
| Create header duplication | Done | This slice | Create keeps its navigation identity but uses inline display so the content header owns the screen. |
| Compose error placement | Done | This slice | Generation failures now show a short top notice while preserving the inline retry card. |
| Multiline context newline behavior | Done | This slice | Context now uses a compact `TextEditor`; include/avoid remain quick single-line fields. |
| Messages/versions terminology | Done | This slice | User-facing quota/result/editor copy now uses messages, versions, and Message Editor. Internal model names still use `MessageDraft` until a safe refactor. |
| Tone safety | Done | This slice; `UsagePolicyTests` | Sensitive occasions show gentle/work-safe tones first and place risky tones behind "More tones." |
| Paywall Standard escape hatch | Done | This slice; `UsagePolicyTests` | The paywall hides "Use Standard" when the authoritative free-message limit is exhausted. |
| Starter occasion duplication | Done | This slice | Starter chips no longer duplicate the currently selected moment. |

---

## P0 — Release blockers / compliance

1. **Done — Paywall Terms & Privacy are tappable.** `PaywallSheet` now uses `Link`s to `SettingsExternalLinks.terms` / `.privacy`.
2. **Done — Subscription disclosure completeness.** Selected plan price/period is surfaced adjacent to the CTA via `premiumRenewalDisclosureText`. **[verify on device with real StoreKit products]**
3. **Partial — Delete Account has native client support.** The app now confirms deletion, calls the ProsePal `delete-user` Edge Function with the signed-in user token, and clears local signed-in state after success. App Review readiness still requires deployed backend verification and Apple token-revocation secret checks.
4. **Done — About section uses real runtime values.** `aboutSection` binds to `appVersionDisplayText` and `writingRuntimeDisplayText`.

---

## P1 — High: accessibility & design-language readiness

### Liquid Glass readiness (the headline strategic finding)
The app is part-way through the Liquid Glass migration:
- **Mostly addressed — bespoke control chrome has been reduced.** Results, sticky bars, settings actions, paywall plan rows, and the Create action zone now lean on native button styles/adaptive control surfaces. Picker rows still use custom row content inside native lists, which is acceptable if iOS 26 visual QA confirms the result.
- **Partial — Sticky action bars now adapt toward Liquid Glass.** Compose, Results, and Draft Editor controls use shared adaptive styles: `glass` / `glassProminent` on iOS 26 and bordered fallbacks on iOS 17. This still needs iOS 26 visual QA before the broader glass migration is considered complete.
- **Partial — Tabs use the modern API where available.** `AppTabsView` now uses the Tab content-builder API on supported OS versions, keeps the iOS 17 fallback, and enables scroll-down minimisation on iOS 26. Visual behavior still needs iOS 26 device/simulator QA.
- **Mostly addressed — Create content is now opaque grouped form content.** Reserve future glass work for the control layer, tab/navigation surfaces, and transient overlays.

Recommended direction (no opt-out flag):
- Build on the **Xcode 26 SDK**, keep iOS 17 floor, do **not** set `UIDesignRequiresCompatibility`.
- Reserve glass for the **navigation/control layer** (toolbars, tab bar, floating action bars, the writing-overlay badge); keep content cards opaque.
- Replace bespoke buttons with native styles + `.tint(Color.prosePalCoral)`; adopt `.buttonStyle(.glass)` / `.glassProminent` behind `if #available(iOS 26)` with a `.bordered`/`.borderedProminent` fallback for iOS 17.
- Verify **Reduce Transparency** and **Increase Contrast** fallbacks for all glass/material surfaces. **[verify on device]**

### Color & contrast (WCAG AA)
- **Mostly addressed — small foreground coral uses have moved to `prosePalCoralDark`.** Keep verifying with Accessibility Inspector because native tint rendering can shift under glass/vibrancy.
- **Done — onboarding low-contrast text raised.** Benefit detail/progress text now use stronger white opacity on the navy launch/onboarding surface.

### Other P1
- **Done — Writing overlay can be cancelled.** `WritingProgressOverlay` includes a Cancel affordance and tests cover cancellation.
- **Done — Toast notices announce to VoiceOver.** Notices post privacy-safe accessibility announcements.
- **Onboarding forces `.preferredColorScheme(.dark)`** (L1189) and the brand backdrops are always dark regardless of system appearance. Acceptable as a branded launch, but confirm it's intentional and that the hardcoded coral/navy palette has no light-mode-only assumptions elsewhere.

---

## P2 — Native-ness & consistency

- **Done — Compose now uses a native grouped `Form`.** The Create screen keeps its custom emotional header, but the functional inputs now live in native `Section`s so iOS owns row spacing, dividers, scrolling, and keyboard behavior.
- **Done — Settings rows lean further into native list behavior.** `SettingsView` keeps its compact `SettingsRow` content, but links/actions now use native `Link`/`Button` row behavior instead of suppressing it with plain styling.
- **Done — Selection affordance mismatch fixed.** Summary rows open sheets and use a disclosure chevron.
- **Done — Picker haptics aligned.** Occasion, relationship, and tone/style pickers all fire selection feedback.
- **Done — Message editor avoids destructive Done ambiguity.** The editor uses Cancel plus explicit Copy/Share/Save actions.
- **Done — Result actions use native button styles.** Copy remains primary; Share/Edit/Save adapt across width and Dynamic Type.
- **Done — Settings Writing section simplified.** Spelling and default tone remain; generation lane controls live in the Create action zone where they belong.

---

## P3 — Polish

- **Done — Generation mode no longer appears as a locked peer control.** Free users see Standard as implied; Premium users get the real Standard/Premium segmented control in the action zone.
- **Done — Three stacked headers on Create reduced.** The Create tab keeps its navigation identity, but the nav title uses inline display so the content header owns the screen.
- **Done — Generation errors surface immediately.** Failures still show the inline retry card, and now also raise a short top notice so the user is not left hunting mid-scroll for the problem.
- **Done — Message editor has placeholder and character count.**
- **Done — Compose context supports multiline entry.** The context field now uses a compact `TextEditor`, while include/avoid stay as quick single-line fields.

---

## What's already good (keep)
- Picker sheets (Occasion/Relationship/Tone): searchable grouped `List`, checkmark selection, `ContentUnavailableView.search`, medium/large detents — strong native pattern.
- No provider/model names anywhere in user-facing copy (matches the north-star non-negotiable).
- Dynamic Type handled well: `@ScaledMetric`, `ViewThatFits`, accessibility-size branches in result actions, `minimumScaleFactor`.
- `textSelection(.enabled)` on generated/saved text; `ShareLink` for sharing; haptics on copy/save; Reduce Motion respected in animations.
- Saved list: native `List`, `.searchable`, swipe-to-delete, `NavigationLink` detail, destructive `confirmationDialog`. Delete-by-filtered-offset is correctly resolved by id (safe while searching).
- Settings correctly hides `runtimeReadinessSection` behind `#if DEBUG`; biometric lock gated on sign-in; restore/Use-Standard/Sign-in-with-Apple paths present and not forced.

---

## Suggested remediation sequencing (for a later, separate effort)
1. **Device QA pass** — iPhone 14 Pro/real device, Dynamic Type, keyboard, VoiceOver, Reduce Motion/Transparency.
2. **StoreKit product-loading fix** — products still need to load locally before the paywall can be fully validated.
3. **Backend release gates** — deployed account deletion verification, entitlement usage truth, and App Review notes.
4. **Liquid Glass visual QA** — build with the current SDK, verify native controls/glass on supported OS, and keep iOS 17 fallback readable.
5. **File split/refactor** — reduce `ProsePalRootView.swift` after the visual direction is stable.
- Worth noting as an enabler: the entire UI is one 4,031-line file. Splitting per-screen files would materially de-risk all of the above.

## Verification (when fixes are eventually made)
- Build on Xcode 26 SDK; run on an **iOS 26 simulator** and an **iOS 17 device/sim** to confirm both the glass look and the fallback.
- Accessibility Inspector: contrast audit, VoiceOver pass on toast + paywall, Dynamic Type at AX5, Reduce Transparency + Increase Contrast.
- App Review dry-run against the 3.1.2 subscription checklist and 5.1.1(v) account-deletion requirement.

## Current Implementation Brief
- Use `NATIVE_UX_IMPLEMENTATION_HANDOFF.md` for the next native UI slices.
- Keep this audit as the implementation tracker for previously identified
  UI/accessibility/App Review risks.
