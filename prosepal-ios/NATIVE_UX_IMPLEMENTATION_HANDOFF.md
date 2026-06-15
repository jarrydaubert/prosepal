# ProsePal Native UX Implementation Handoff

Date: 2026-06-15
Target branch/worktree: `ios-native-rewrite-prosepal-ios` at `/private/tmp/prosepal-ios-native-worktree`
Scope: native SwiftUI app under `prosepal-ios/` only. Do not redesign or replace the production Flutter app.

## Use This As The Agent Brief

Implement the ProsePal native SwiftUI UX direction from the current review work. The goal is a calm, premium, modern iOS writing assistant: not an AI console, not a web form, not a paywall disguised as a control.

The core product job remains:

```text
Write a message for a real human occasion.
```

Everything else should serve that job.

## Source Context To Read First

Before editing code, read:

- `AGENTS.md`
- `prosepal-ios/README.md`
- `prosepal-ios/NATIVE_UX_DIRECTION.md`
- `prosepal-ios/NATIVE_UI_AUDIT.md`
- `prosepal-ios/NATIVE_UI_POLISH_REPORT.md`
- `prosepal-ios/NATIVE_PRODUCT_NORTH_STAR.md`
- `prosepal-ios/Sources/ProsePalUI/ProsePalRootView.swift`
- `prosepal-ios/Sources/ProsePalDomain/CardModels.swift`

The UI currently lives mostly in `ProsePalRootView.swift`. Treat that monolith as an implementation risk, not a pattern to extend indefinitely.

`NATIVE_UI_AUDIT.md` is the current UI implementation tracker. `NATIVE_UI_POLISH_REPORT.md` is a historical local implementation/evidence report, not the active source of truth, but it documents useful prior wins and validation evidence. Preserve its good outcomes unless this handoff explicitly supersedes them.

## Settled Decisions

These are the baseline decisions for implementation. Challenge only if the code proves a material risk.

1. Quota is measured in `messages`.
2. Each generated message returns `3 versions`.
3. The word `draft` is retired for new UI copy because it previously meant both quota units and returned options.
4. Free users do not get a `Standard | Premium` segmented control. Standard is implied.
5. A `Standard | Premium` segmented control renders only when Premium is unlocked and both choices are actually selectable.
6. Premium is a clear upgrade affordance when locked, never a peer form state.
7. The primary CTA label must match its action in every state.
8. Liquid Glass is progressive enhancement. Liquid-Glass-capable OSes adopt native materials; iOS 17-25 and Reduce Transparency use opaque fallbacks.
9. Privacy, accessibility, and App Review readiness are first-class requirements, not polish.
10. Provider names, model names, provider SDKs, and routing policy do not appear in user-facing UI.

## Desired Create Screen Shape

The current Create screen feels clunky because it treats every input as an equal card. The fix is hierarchy.

There are three layers:

1. Message setup: calm body content.
2. Action contract: usage, CTA, and Premium affordance near the button.
3. Account/status: ambient only, never a heavy card.

Target shape:

```text
ProsePal                         usage ring

Who's it for?                    Alex

Starter occasion chips           first session only, or Recents for returning users
                                 hide once an occasion is selected

Grouped list:
  Occasion                       Birthday
  Relationship                   Parent
  Tone + length                  Heartfelt · Short

Add details                      collapsed by default, info/privacy copy only when expanded

Floating action layer:
  3 free messages daily / 2 free messages left today / Premium active
  Write message
  Try Premium                    only when it is a secondary upgrade path
```

Keep content opaque. Reserve glass/native material for the floating control layer, tab/nav surfaces, and other true controls.

## Create Action Zone State Table

Implement these states exactly in spirit, even if final copy changes slightly:

| User state | Lane control | Status line | Primary CTA |
| --- | --- | --- | --- |
| Free, messages left | none, Standard implied | Before use: `3 free messages daily`; after use: `2 free messages left today` | `Write message` plus subtle `Try Premium` |
| Free, out of messages | none | `Out of free messages today` | `Unlock more messages` opens paywall |
| Usage loading | none | `Checking message limit...` | disabled until resolved |
| Usage unavailable | none | `Message limit unavailable` | allow `Write message`; fail gracefully if server rejects |
| Premium active | true `Standard | Premium` segmented control | `Premium active` | `Write message` |

Commercial honesty rules:

- No control opens the paywall unless its label or visible state signals upgrade/locked behavior.
- The CTA must not say `Write message` if tapping it opens a paywall.
- In the out-of-messages state, hide secondary `Try Premium`; the relabeled CTA is the one primary paywall path.
- Do not render one-option segmented controls.

## Terminology

Use this language consistently:

- Quota unit: `message` / `messages`
- Returned options: `version` / `versions`
- Generated result set: `3 versions`
- Saved content: `saved message`
- Editor: `Message editor`

Avoid new use of `draft` in user-facing copy unless a reviewer explicitly asks for it.

## Implementation Sequence

1. Establish shared state and terminology.
   - Create or extract a single usage/action-zone view model so Create, Settings, and Paywall cannot disagree.
   - Rename user-facing quota/result copy from drafts to messages/versions.

2. Reduce the `ProsePalRootView.swift` blast radius.
   - Extract per-screen or per-feature views before large redesigns where practical.
   - Start with Create/action-zone components, usage status, paywall, results cards, and settings rows.
   - Keep behavior covered by existing tests while extracting.

3. Rework Create hierarchy.
   - Replace stacked mixed-material cards with one focal recipient field, one grouped list, collapsed details, and a bottom action layer.
   - Merge tone and length into one visible row; the edit surface can still expose both clearly.
   - Add starter chips only when useful: first session before selection, or Recents for returning users. Hide them once an occasion is selected.

4. Fix Premium and usage behavior.
   - Apply the action-zone state table.
   - Remove locked Premium from peer segmented controls.
   - Ensure paywall entry points are honest and non-duplicative.

5. Modernize native controls.
   - Prefer SwiftUI-native controls, `List`, `Form`, `Section`, `Button`, `Link`, `ShareLink`, sheets, and searchable lists.
   - Avoid hand-drawn button chrome when native styles can do the job.
   - Add Liquid Glass only as progressive enhancement; keep readable opaque fallbacks.

6. Tighten Results and editor.
   - Results present `3 versions`.
   - Copy remains the primary payoff.
   - Native buttons replace bespoke result-action chrome.
   - `Message editor` must not use `Done` to discard changes. Either `Cancel` dismisses or `Done` commits/saves.

7. Finish compliance/trust gates.
   - Paywall Terms/Privacy are functional links.
   - Price and period are clear next to the subscription CTA.
   - Account deletion is real, in-app, and reachable.
   - Export is real or honestly unavailable, not fake-complete.
   - About uses real version/build.

## Preserve Existing Native Polish

Do not regress the improvements already recorded in `NATIVE_UI_AUDIT.md` and `NATIVE_UI_POLISH_REPORT.md`:

- Launch remains plain navy and fast; no marketing splash delay.
- First-run onboarding stays short, scroll-safe, and bottom-CTA-safe.
- Keyboard behavior remains usable: active fields stay visible and a compact Write action remains available while typing.
- Occasion, relationship, and tone remain searchable native sheets with grouped lists.
- Spelling remains a Settings writing preference, not extra Create-screen clutter.
- Generation remains gateway-only; no client-side template fallback and no provider/model names in UI.
- Results keep Copy as the primary payoff, with Share/Edit/Save still visible.
- Saved messages keep native list/search/detail/delete behavior.
- Diagnostics remain privacy-safe under `OSLog` subsystem `com.prosepal.native`; do not log user message content, generated content, tokens, provider payloads, or secrets.
- Preserve staging-only `PROSEPAL_DEV_GATEWAY_SECRET` / `X-ProsePal-Dev-Gateway-Secret` behavior if gateway plumbing is touched.
- Do not commit local evidence screenshots, Supabase temp/link state, Xcode `xcuserdata`, or Xcode run secrets.

## Accessibility Requirements

Do not ship the redesign without these:

- Dynamic Type: grouped rows, bottom action layer, chips, and result cards reflow at large accessibility sizes.
- VoiceOver: usage ring, usage line, Premium affordance, lane control, Copy action, notices, and progress/cancel states have clear labels.
- Reduce Transparency: floating action layer has an opaque fallback.
- Reduce Motion: writing animation and rotating status copy have a static fallback.
- Contrast: coral `#D4736B` is not used as small foreground text on light backgrounds. Use a darker text token or coral as a filled background with white text.
- Hit targets: compact usage ring and icon controls have at least platform-appropriate tap targets.

## Privacy And Safety Requirements

ProsePal asks for intimate context. Trust belongs in the flow.

- `Add details` stays collapsed by default.
- When details expand, show a concise privacy reassurance such as: `Details help personalize the message. You control what you include.`
- Manual save remains the default. Any auto-history must be explicit and opt-in.
- Diagnostics must not log recipient names, personal context, generated text, secrets, tokens, provider payloads, or user message content.
- Document third-party AI/data handling in App Review notes and privacy policy language. Keep provider/model names out of the product UI.

## Tone And Occasion Safety

Tone availability should be occasion-aware. Drive this from occasion group where possible.

Taxonomy tones are:

```text
heartfelt, casual, funny, formal, inspirational, playful, sarcastic, nostalgic, poetic
```

Suggested defaults:

| Occasion type | Default tones | Hidden or behind more |
| --- | --- | --- |
| Sympathy / condolence | heartfelt, formal, poetic, nostalgic | sarcastic, playful, funny, casual |
| Apology | heartfelt, formal, inspirational | funny, sarcastic, playful |
| Professional | heartfelt, formal, casual, inspirational | sarcastic, playful |
| Birthday / congrats / appreciation | all tones | none |

## Platform And App Review Grounding

Use current Apple guidance, not stale assumptions.

- iOS 17 remains the deployment floor.
- Liquid Glass is progressive enhancement on capable OS releases; older iOS and Reduce Transparency get opaque fallbacks.
- Build and test for iOS 27-ready resizable layouts: size classes, orientation changes, iPad, and iPhone app resizing.
- App Review 3.1.2: subscription value, price, period, renewal terms, restore, and legal links must be clear.
- App Review 5.1.1(v): account creation requires in-app account deletion.
- App metadata and privacy labels must accurately describe data collection, retention, deletion, and third-party sharing.

Official references:

- https://developer.apple.com/videos/play/wwdc2026/269/
- https://developer.apple.com/app-store/review/guidelines/

## Definition Of Done

The redesign is done when:

- Create no longer reads as a stack of equal cards.
- Free users never see locked Premium as an equal segment.
- Out-of-messages users get an honest `Unlock more messages` CTA.
- Usage copy is consistent across Create, Settings, and Paywall.
- Results say `versions`, not `drafts`.
- Details are collapsed by default and carry a privacy moment only when expanded.
- Native controls replace bespoke chrome where practical.
- Liquid Glass-capable OSes look modern, and older/Reduce Transparency fallbacks stay readable.
- App Review blockers are fixed or explicitly outside the release.
- Accessibility passes are verified on device/simulator.

## Suggested Validation

Run relevant native tests after each meaningful slice:

```bash
cd /private/tmp/prosepal-ios-native-worktree/prosepal-ios
swift test
```

Before handoff, also run the repo-level checks that are relevant to touched files. If only native Swift files changed, explain why Flutter checks were not run.

Manual QA:

- iOS 17 simulator/device fallback
- Liquid-Glass-capable simulator/device
- Dynamic Type at largest sizes
- VoiceOver pass through Create -> Results -> Copy/Save/Edit
- Reduce Transparency
- Reduce Motion
- Free with messages left
- Free out of messages
- Usage loading/failure
- Premium active
- Keyboard visible on recipient/details fields

## Short Prompt For A Follow-Up Agent

```text
You are working in /private/tmp/prosepal-ios-native-worktree on branch ios-native-rewrite-prosepal-ios. Read prosepal-ios/NATIVE_UX_IMPLEMENTATION_HANDOFF.md first, then implement the native SwiftUI ProsePal redesign in small verified slices. Do not touch the production Flutter app except where shared backend/compliance plumbing is explicitly required. Keep provider/model names out of UI, make Premium monetization honest, use messages/versions terminology, preserve iOS 17 fallback, and verify accessibility/compliance gates before handoff.
```
