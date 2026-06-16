# ProsePal Native 2026 Technical Direction

Date: 2026-06-16

This is the active direction for the native iOS rebuild. ProsePal is now a
greenfield, craft-first iOS app. The goal is not Flutter parity, broad device
reach, or preserving the current grouped-form prototype. The goal is a small
surface built at the highest level the current Apple stack allows.

## Locked Product Direction

- Public name: ProsePal.
- Internal concept name: Near.
- Primary flow: person-first Moment Sheet.
- Occasion taxonomy: retained as product intelligence underneath the person
  flow.
- Current grouped Create/Saved/Settings UI: reference scaffolding only. Do not
  maintain it as a product fallback.
- App floor: iOS 26.
- AI lanes: Private draft and Take more care.
- User-facing UI must never expose provider or model names.
- No raw recipient names, personal details, prompts, generated text, tokens,
  provider payloads, or StoreKit receipts in logs.

## Architecture

```text
SwiftUI Moment Sheet
  -> MomentModel
  -> MessageWritingService
      -> PrivateDraftClient   FoundationModels on-device
      -> CarefulClient        ProsePal gateway / Apple cloud lane
      -> MockClient           tests and previews
```

The UI depends on `MessageWritingService`, not a provider SDK, model name, or
transport. Routing is based on emotional stakes, entitlement, model
availability, and connectivity.

## Apple-Native Stack

- Swift 6 and strict concurrency for new code.
- SwiftUI and `@Observable` view models for new code.
- SwiftData for the on-device relationship vault.
- StoreKit 2 only for subscriptions.
- Sign in with Apple for identity.
- Foundation Models for on-device private drafting.
- App Intents, WidgetKit, Control Center controls, and Share extension are
  first-class surfaces, not late add-ons.
- Liquid Glass belongs on the control/navigation layer. Content stays opaque,
  calm, and paper-like.

## First Implementation Slice

Build the wedge that proves the product:

```text
open
  -> who is this for?
  -> person
  -> moment
  -> one true thing
  -> draft already there
  -> warmer / shorter / more direct
  -> copy / share / send
```

Keep existing gateway, StoreKit, Sign in with Apple, catalogue, diagnostics,
and privacy posture. Replace the grouped-form UI as soon as the Moment Sheet
stands up.

## Current SDK Notes

Verified locally on Xcode 26.5 / iPhoneOS 26.5:

- `FoundationModels.framework` exists.
- `@Generable`, `@Guide`, `LanguageModelSession`, `SystemLanguageModel`,
  structured response generation, snapshot streaming, model availability, and
  tool calling are available.
- `SystemLanguageModel.Adapter` exists for adapter assets. A third-party
  provider protocol is not a v1 dependency.

Foundation Models availability must be checked at runtime. If the on-device
model is unavailable, the product should show an honest private-draft state or
route through the careful lane where appropriate. Do not fake local generation.
