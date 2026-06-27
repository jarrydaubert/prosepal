# ProsePal Native 2026 Technical Direction

Date: 2026-06-16

This is the active direction for the native iOS rebuild. ProsePal is now a
greenfield, craft-first iOS app. The goal is not Flutter parity, broad device
reach, or preserving the current grouped-form prototype. The goal is a small
surface built at the highest level the current Apple stack allows.

Open work belongs in `../docs/BACKLOG.md`. This document defines direction; it
is not a progress tracker.

## Product Doctrine

ProsePal is a premium Moment-writing workspace. It is AI-assisted, not AI-led.

The product job is:

```text
I need to say this properly.
```

It is not:

```text
I need to manage a writing project.
```

ProsePal should feel like a calm, trustworthy native writing surface for
personal moments. It should not become a manuscript manager, project library,
scene/character/worldbuilding tool, Scrivener-lite, or generic AI chat box.

## Locked Product Direction

- Public name: ProsePal.
- Internal concept name: Near.
- Production app identity: reuse the existing ProsePal App Store Connect app,
  bundle ID `com.prosepal.prosepal`, and subscription product IDs. Staging is
  UAT through local scheme/runtime configuration and staging services, not a
  second public App Store app.
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
- Never silently overwrite or risk the user's draft.
- The user's words lead; AI helps refine, shorten, soften, clarify, or check
  how a message may land.

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
- No RevenueCat, Firebase AI, Vertex AI, Sentry, analytics SDK, or provider SDK
  should be added by default. A dependency needs a specific product, privacy,
  and operations reason.

## Native Quality Bar

- Use standard Apple navigation, sheets, search, controls, haptics, text
  selection, sharing, and accessibility affordances where they fit.
- Keep Liquid Glass restrained to navigation and control surfaces. Writing
  content should remain opaque, calm, and readable.
- Treat Dynamic Type, VoiceOver, Reduce Motion, Increase Contrast, keyboard,
  iPad layout, and safe-area behavior as core product requirements.
- Protect user text through autosave, snapshots, explicit accept/reject, undo,
  and clear error states.
- Prefer contextual writing actions over a giant prompt box: warmer, firmer,
  shorter, less defensive, more professional, keep my voice, explain how this
  might land, remove passive aggression, say no clearly, and take more care.

References:

- Adopting Liquid Glass: https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass
- Accessibility: https://developer.apple.com/accessibility/

## First Implementation Slice

Build the wedge that proves the product:

```text
open
  -> who is this for?
  -> person
  -> moment
  -> one true thing
  -> Write draft
  -> warmer / shorter / more direct
  -> copy / share / send
```

Keep existing gateway, StoreKit, Sign in with Apple, catalogue, diagnostics,
and privacy posture. Replace the grouped-form UI as soon as the Moment Sheet
stands up.

## Preserve From The Current Branch

The branch already contains useful foundations that should survive the Moment
Sheet rebuild:

- provider-agnostic domain catalogue for occasions, relationships, tone, length,
  and spelling preferences;
- gateway request/response contracts and privacy-safe gateway client behavior;
- StoreKit 2 subscription boundary;
- Sign in with Apple and Supabase Auth REST boundary;
- local keychain session storage;
- privacy-safe OSLog diagnostics;
- local saved-message primitives where they fit the new product shape;
- StoreKit staging config and tethered-device runbook.

Do not preserve the grouped-form Create UI as a second product path. Once the
Moment Sheet is functional, remove the legacy scaffolding instead of maintaining
two experiences.

## Product And Safety Principles

- The user should never have to prompt-engineer.
- The app should ask for the person first, then the moment, then what is true.
- Everyday moments can be helped by a fast private draft.
- Hard moments should generate less and preserve more of the user's own words.
- The first paywall should follow a meaningful writing result or a clear paid
  limit/extras boundary, not first launch.
- Sign-in should support continuity, restore confidence, support, export, and
  deletion. It should not block first value.
- Premium copy should say `Take more care`, not imply a specific provider or
  guaranteed emotional perfection.
- Saved history must be deliberate and user-approved. Do not create a surprise
  visible history surface before privacy, deletion, and sync semantics are
  settled.
- Grief, crisis, and relationship repair flows must avoid guilt mechanics,
  streaks, scores, or pressure nudges.

## Current SDK Notes

Live development baseline:

- Xcode 26.6, build 17F113.
- Swift 6.3.3.
- Xcode 26.6 is the production development baseline for this native branch.
- Xcode 27 / iOS 27 beta work belongs in an explicit exploration branch until
  the APIs and App Store submission requirements are production-ready.

References:

- Xcode App Store listing: https://apps.apple.com/us/app/xcode/id497799835?mt=12
- Apple developer releases: https://developer.apple.com/news/releases/

Verified locally on the Xcode 26.x toolchain:

- `FoundationModels.framework` exists.
- `@Generable`, `@Guide`, `LanguageModelSession`, `SystemLanguageModel`,
  structured response generation, snapshot streaming, model availability, and
  tool calling are available.
- `SystemLanguageModel.Adapter` exists for adapter assets. A third-party
  provider protocol is not a v1 dependency.

Foundation Models availability must be checked at runtime. If the on-device
model is unavailable, the product should show an honest private-draft state or
route through the careful lane where appropriate. Do not fake local generation.

## Backend And Entitlement Direction

- The native client uses StoreKit 2 for product loading, purchase, restore, and
  local transaction state.
- The server/gateway remains authoritative for entitlement-sensitive cloud or
  careful generation.
- App Store Server Notifications V2 and App Store Server API reconciliation are
  the intended first-party entitlement path.
- Purchase must not require app sign-in first.
- Account deletion must be available in app once account creation is available.

References:

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Auto-renewable subscriptions: https://developer.apple.com/app-store/subscriptions/

## Out Of Scope For The Native v1

- Flutter screen parity as a design requirement.
- Android work.
- RevenueCat.
- Client-direct Firebase AI or Vertex AI.
- Third-party model providers in the native client.
- Image generation.
- CloudKit sync.
- Manuscripts, scene lists, characters, worldbuilding, goals, export-heavy
  writer workflows, or document-manager architecture.
- Automatic silent memory inference from Contacts or Calendar.
- Physical card ordering, social features, or gamified relationship mechanics.
