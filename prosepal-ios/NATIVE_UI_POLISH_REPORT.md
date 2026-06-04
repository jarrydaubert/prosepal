# Native UI Polish Report

Date: 2026-06-04
Branch: `ios-native-rewrite-prosepal-ios`

## Scope

Focused UI audit and P0/P1 polish pass across onboarding, create form, occasion browse, relationship picker, tone picker, generation mode selector, drafts/results actions, keyboard states, and bottom tab bar interactions.

This pass intentionally did not change production AI routing, add SDKs, add provider/model UI, or add template generation.

## Before / After Notes

| Area | Before | After |
| --- | --- | --- |
| Onboarding | Artwork and copy could crowd the lower CTA on smaller/tall-safe-area layouts. | Onboarding pages now scroll and artwork has a max height so the CTA remains reachable. |
| Create keyboard state | Sticky Generate was hidden while typing, but scroll content had limited keyboard/CTA buffer. | Create content now reserves more bottom scroll space, keeps Write in the keyboard toolbar while typing, and keeps the sticky CTA above the tab bar when the keyboard is closed. |
| Relationship picker | Visible relationship cards made Create feel busy as more Flutter taxonomy moved over. | Relationship is a compact selected row with the full taxonomy in a searchable grouped sheet. |
| Tone picker | Visible tone cards competed with the writing fields. | Tone is a compact selected row with every tone available in a searchable sheet. |
| Relationship/tone tap parity | Core Flutter options were present, but the screen paid for them with visual weight. | Relationship and tone remain one tap away while keeping Create calmer and more iOS-native. |
| Occasion browser | Rows displayed generation-oriented hints. | Rows now show short user-facing descriptions while keeping the full catalogue/search data underneath. |
| Home/Create duplication | Create had a selected occasion control plus a featured occasion chip strip. | Create now has one selected occasion summary and one Browse path; Most Used lives in the searchable sheet. |
| Spelling | Spelling appeared inside the generation form. | Spelling is now a Settings writing preference: Automatic, US English, or UK English. |
| Generation selector | Three cards were forced into the available width and could truncate awkwardly. | Generation modes are horizontal, compact cards with stable widths and Dynamic Type breathing room. |
| Generation language | UI exposed Auto as a generation option. | Create and Settings show Standard and Premium only. |
| Loading state | Native generation only changed the button to Writing. | A full-screen native writing overlay now mirrors Flutter's waiting-state reassurance without provider/model wording. |
| Results actions | Copy, Share, Edit, and Save were forced into a single row. | Draft actions adapt between one-row and stacked layouts so buttons remain visible. |
| Results language | Results used Drafts as the primary title. | Results now use Messages/Options language to match the broader card/text/note use case. |
| Launch/onboarding logo | The launch storyboard and onboarding used logo treatment. | Launch is plain navy, and onboarding uses artwork without placing the logo on screen. |
| Edit draft sheet | Actions lived inside the main sheet content and could be cramped with the keyboard. | Edit actions sit in a bottom safe-area bar with adaptive layout and sheet detents. |
| Paywall sheet | Medium-height presentation could crowd content. | Paywall content scrolls and supports medium/large detents. |
| Visible copy | Some copy exposed setup/roadmap wording such as contract/build language. | Settings and notices now use user-facing wording and avoid provider/model terminology. |
| SF Symbols | Four occasion symbols logged missing-system-symbol warnings on device. | Replaced with conservative iOS SF Symbols. |
| Device diagnostics | Xcode Console was mostly system noise and gateway outcomes were hard to correlate. | Added privacy-safe `OSLog` events for app flow and gateway requests under subsystem `com.prosepal.native`. |
| Staging gateway guard | Anonymous staging gateway access had no shared-secret header path. | Added optional `PROSEPAL_DEV_GATEWAY_SECRET` / `X-ProsePal-Dev-Gateway-Secret` support for staging-only anonymous gateway testing. |

## Files Changed

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

Pre-existing local changes still present and not part of this UI pass:

- `prosepal-ios/ProsePal.xcodeproj/project.pbxproj`
- `prosepal-ios/ProsePal.xcodeproj/xcshareddata/xcschemes/ProsePal.xcscheme`
- `prosepal-ios/ProsePal.xcodeproj/xcuserdata/`
- `supabase/.temp/*`
- `supabase/README.md`

Do not commit Supabase `.temp` files or local Supabase link state.

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

Validation run:

- `cd prosepal-ios && swift test` passed, 17 tests.
- `deno test supabase/functions/generate-card/index.test.ts` passed, 11 tests.
- `cd prosepal-ios && xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` passed.
- iPhone 17 Pro simulator smoke launch passed with bundle id `com.prosepal.prosepal.native`.

Screenshots captured:

- `prosepal-ios/build/screenshots/native-ui-polish-smoke.png`
- `prosepal-ios/build/screenshots/native-ui-polish-create-smoke.png`
- `prosepal-ios/build/screenshots/native-product-shape-onboarding.png`
- `prosepal-ios/build/screenshots/native-product-shape-create.png`
- `prosepal-ios/build/screenshots/native-router-picker-smoke.png`

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
