# Native UI Polish Report

Historical note:

This file is a local implementation/evidence report, not an active source of
truth. Open work belongs in `../docs/BACKLOG.md`; native product direction
belongs in `NATIVE_PRODUCT_NORTH_STAR.md`, `NATIVE_UX_DIRECTION.md`, and
`../docs/NEXT_RELEASE_BRIEF.md`.

Date: 2026-06-06
Branch: `ios-native-rewrite-prosepal-ios`

## Scope

Focused UI audit and P0/P1 polish pass across onboarding, create form, occasion browse, relationship picker, tone picker, generation mode selector, drafts/results actions, keyboard states, and bottom tab bar interactions.

This pass intentionally did not change production AI routing, add SDKs, add provider/model UI, or add template generation.

The 2026-06-06 follow-up continued Gate 2 from `REWRITE_PLAN.md`: improve Create -> Generate -> Results quality while preserving gateway-only generation.

## Before / After Notes

| Area | Before | After |
| --- | --- | --- |
| Onboarding | Welcome copy and the lower CTA could feel cramped on smaller/tall-safe-area layouts. | The single welcome screen scrolls, keeps the CTA in a bottom safe-area inset, and no longer depends on bitmap artwork. |
| Create keyboard state | Sticky Generate was hidden while typing, but scroll content had limited keyboard/CTA buffer. | Create content now reserves more bottom scroll space, keeps Write in the keyboard toolbar while typing, and keeps the sticky CTA above the tab bar when the keyboard is closed. |
| Create bottom action | The sticky Write action could feel visually heavy above the tab bar. | The bottom action keeps the same placement but uses tighter vertical padding so Create has more breathing room. |
| Keyboard toolbar | The keyboard toolbar used a longer Write Message label and could contribute to bar-button layout pressure on device. | The toolbar now keeps a short trailing Done / Write action set while the keyboard is open. |
| Create summary | The summary could read as a generic message without enough occasion/relationship context. | The summary now reads as a tone/length/occasion message for the named recipient or selected relationship. |
| Relationship picker | Visible relationship cards made Create feel busy as more Flutter taxonomy moved over. | Relationship is a compact selected row with the full taxonomy in a searchable grouped sheet. |
| Tone picker | Visible tone cards competed with the writing fields. | Tone is a compact selected row with every tone available in a searchable sheet. |
| Relationship/tone tap parity | Core Flutter options were present, but the screen paid for them with visual weight. | Relationship and tone remain one tap away while keeping Create calmer and more iOS-native. |
| Occasion browser | Rows displayed generation-oriented hints. | Rows now show short user-facing descriptions while keeping the full catalogue/search data underneath. |
| Home/Create duplication | Create had a selected occasion control plus repeated occasion discovery below it. | Create now has one selected occasion summary row; Most Used lives inside the searchable occasion sheet. |
| Spelling | Spelling appeared inside the generation form. | Spelling is now a Settings writing preference: Automatic, US English, or UK English. |
| Generation selector | Three cards were forced into the available width and could truncate awkwardly. | Generation modes are horizontal, compact cards with stable widths and Dynamic Type breathing room. |
| Generation language | UI exposed Auto as a generation option. | Create and Settings show Standard and Premium only. |
| Loading state | Native generation only changed the button to Writing. | A full-screen native writing overlay now shows the selected occasion, tone, and length without provider/model wording. |
| Results context | Results opened with generic explanatory copy. | Results now lead with a native context card and compact occasion/relationship/tone chips. |
| Results actions | Copy, Share, Edit, and Save were forced into a single row. | Draft actions use a stable two-row layout so buttons remain visible with Dynamic Type pressure. |
| Results hierarchy | Copy was visually equal to secondary actions, even though Flutter treated copy as the main success action. | Copy is now the primary action with an in-card Copied state; Share, Edit, and Save remain visible as secondary actions. |
| Results follow-up actions | Start Over lived at the end of the scroll and Regenerate lived in the toolbar. | Results now keep Adjust, Start new, and Regenerate in a bottom action bar with less horizontal crowding. |
| Launch/onboarding logo | Earlier native passes carried launch-logo/onboarding artwork assets forward. | Launch is plain navy, and the first-run welcome uses brand color, type, and SF Symbols without shipping unused logo/artwork assets. |
| Edit draft sheet | Actions lived inside the main sheet content and could be cramped with the keyboard. | Edit actions sit in a bottom safe-area bar with adaptive layout and sheet detents. |
| Paywall sheet | Medium-height presentation could crowd content. | Paywall content scrolls and supports medium/large detents. |
| Visible copy | Some copy exposed setup/roadmap wording such as contract/build language. | Settings and notices now use user-facing wording and avoid provider/model terminology. |
| SF Symbols | Four occasion symbols logged missing-system-symbol warnings on device. | Replaced with conservative iOS SF Symbols. |
| Device diagnostics | Xcode Console was mostly system noise and gateway outcomes were hard to correlate. | Added privacy-safe `OSLog` events for app flow and gateway requests under subsystem `com.prosepal.native`. |
| Staging gateway guard | Anonymous staging gateway access had no shared-secret header path. | Added optional `PROSEPAL_DEV_GATEWAY_SECRET` / `X-ProsePal-Dev-Gateway-Secret` support for staging-only anonymous gateway testing. |

## Files Changed

Current Gate 2 follow-up:

- `prosepal-ios/Sources/ProsePalUI/ProsePalRootView.swift`
- `prosepal-ios/NATIVE_UI_POLISH_REPORT.md`

Earlier native UI/staging passes referenced by this report:

- `prosepal-ios/App/ProsePalNativeApp.swift`
- `prosepal-ios/App/LaunchScreen.storyboard`
- `prosepal-ios/Sources/ProsePalAPI/GatewayMessageWritingClient.swift`
- `prosepal-ios/Sources/ProsePalAPI/MessageWritingRouter.swift`
- `prosepal-ios/Sources/ProsePalDomain/CardModels.swift`
- `prosepal-ios/Sources/ProsePalUI/NativeDiagnosticsLogger.swift`
- `prosepal-ios/Sources/ProsePalUI/ProsePalRootView.swift`
- `prosepal-ios/Tests/ProsePalAPITests/MessageWritingClientTests.swift`
- `prosepal-ios/Tests/ProsePalUITests/UsagePolicyTests.swift`
- `prosepal-ios/README.md`
- `prosepal-ios/NATIVE_PRODUCT_NORTH_STAR.md`
- `prosepal-ios/NATIVE_UX_DIRECTION.md`
- `prosepal-ios/NATIVE_UI_POLISH_REPORT.md`
- `supabase/functions/generate-card/index.ts`
- `supabase/functions/generate-card/index.test.ts`
- `supabase/README.md`

Local evidence screenshots remain under `prosepal-ios/evidence/` and are not committed.

Do not commit Supabase `.temp` files, local Supabase link state, Xcode
`xcuserdata`, Xcode Run environment secrets, or local evidence screenshots.

## Gateway Safety Check

- `PROSEPAL_GATEWAY_URL` behavior is unchanged.
- `MessageWritingRouter` is used when `PROSEPAL_GATEWAY_URL` is set and routes
  Standard/Premium to the configured gateway client today.
- `GatewayMessageWritingClient` remains the gateway transport.
- `GatewayMessageWritingClient` sends `X-ProsePal-Dev-Gateway-Secret` only when
  `PROSEPAL_DEV_GATEWAY_SECRET` is configured in the Xcode environment or
  Info.plist.
- No template fallback was added.
- No provider/model names were added to user-facing SwiftUI copy.
- No raw prompt, card content, generated message text, provider payloads, API
  keys, or auth tokens are logged.
- Native diagnostics use `OSLog` subsystem `com.prosepal.native` with `flow` and
  `gateway` categories.
- Gateway operator logs include server-side model id for debugging, but the
  client response still omits provider/model fields.

## Evidence

Latest Gate 2 follow-up validation:

- `cd prosepal-ios && swift test` passed, 66 tests.
- `cd prosepal-ios && xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` passed.
- `git diff --check` passed.
- iPhone 17 Pro simulator smoke launch passed with bundle id `com.prosepal.prosepal.native`.
- Results screenshot was not captured in this pass because local simulator launch
  intentionally had no gateway URL configured, and the app has no client-side
  template fallback by design.

Earlier staging gateway validation retained by this report:

- `deno test supabase/functions/generate-card/index.test.ts` passed, 11 tests.

Screenshots captured:

- `prosepal-ios/build/screenshots/native-ui-polish-smoke.png`
- `prosepal-ios/build/screenshots/native-ui-polish-create-smoke.png`
- `prosepal-ios/build/screenshots/native-product-shape-onboarding.png`
- `prosepal-ios/build/screenshots/native-product-shape-create.png`
- `prosepal-ios/build/screenshots/native-router-picker-smoke.png`
- `prosepal-ios/evidence/gate2-create-results-smoke.png` (local only, not committed)
- `prosepal-ios/evidence/gate2-create-smoke.png` (local only, not committed)
- `prosepal-ios/evidence/gate2-create-results-quality-create-after.png` (local only, not committed)

## Manual Test Checklist

- First launch shows onboarding and the bottom CTA remains visible.
- Launch screen is a plain navy background with no logo.
- Skip onboarding routes to Create.
- Browse occasion opens a searchable sheet with grouped occasions.
- Select relationship from the searchable native relationship sheet.
- Select tone from the searchable native tone sheet.
- Change spelling from Settings and confirm it remains outside the Create tap budget.
- Type in recipient/include/avoid/context with keyboard open; active fields remain visible and Write is available in the keyboard toolbar.
- Close keyboard; sticky Write Message remains above the tab bar and does not clash with it.
- Write a Standard message through the staging gateway with `PROSEPAL_GATEWAY_URL` set.
- View Messages and confirm Copy, Share, Edit, and Save actions are visible.
- Edit a draft with the keyboard open and confirm Copy, Share, and Save remain reachable.
