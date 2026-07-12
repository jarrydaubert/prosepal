# Native V1 Launch Contract

This document defines what the native ProsePal rewrite must be able to do at
launch. Unresolved implementation and release work belongs only in
[the backlog](../BACKLOG.md).

## Core loop

Native v1 is ready when this loop is reliable on a supported iPhone:

1. Open the app without a mandatory account or paywall.
2. Name the person, choose the moment, and add the words or detail that matter.
3. Produce one useful draft through the private lane where available or the
   careful gateway lane where appropriate.
4. Edit or adjust the draft without losing the user’s work.
5. Copy, share/send, or deliberately save the result.

## Supporting contract

V1 also includes:

- user-approved relationship memory through Truth Beads and one Voice Card;
- local saved drafts with clear edit, share, and deletion behaviour;
- Sign in with Apple, account deletion, and local-data export;
- StoreKit 2 purchase, restore, and deterministic entitlement convergence;
- privacy-safe diagnostics and truthful offline, timeout, refusal, and limit
  states;
- accessible core flows on supported iPhone sizes; and
- App Intent, widget/control, and Share Extension only when each embedded
  production target passes release qualification without weakening the app.

## Architecture boundary

- The native app lives in `prosepal-ios/`.
- SwiftUI depends on `MessageWritingService`, not a provider SDK.
- Private Draft is the everyday on-device lane where Foundation Models is
  available.
- Take More Care is the cloud/careful lane through the ProsePal gateway.
- Sensitive routing is a quality decision, not a subscription gate.
- StoreKit and server entitlement govern paid limits and extras.
- Provider and model names never appear in user-facing UI.

## Non-negotiables

- Never log raw recipient details, relationship memory, prompts, drafts,
  tokens, receipts, provider payloads, or secrets.
- Never silently overwrite or discard the user’s draft.
- Never require app sign-in before purchase.
- Never ship controls whose visible promise is not implemented.
- Never invent usage amounts, reset dates, retry state, or configuration state.
- Never put provider SDKs or provider-specific product language in the native
  client.
- Never turn the narrow defensive refusal path into a custom crisis-assessment
  programme for v1.

## Evolution rules

- Change a SwiftData model only through the versioned schema and an explicit
  migration stage.
- Extract a safely bounded surface when a product slice materially touches the
  main Moment view; avoid a big-bang rewrite.
- Introduce user-facing copy with localization-safe APIs.
- Introduce colours semantically so later appearance work does not deepen the
  hardcoded-colour debt.
- Keep timeouts and cancellation at the writing-service boundary, not in views.
- Run Apple, Supabase, StoreKit, TestFlight, and physical-device setup in
  parallel with local engineering work.

## Release gate

The implementation contract above is necessary but not sufficient. Launch also
requires the evidence in [Release](../operations/release.md) and
[Release evidence](../quality/release-evidence.md). The actionable list remains
[BACKLOG.md](../BACKLOG.md).

## Non-goals

- Android rewrite work.
- Flutter screen parity.
- A client-direct Firebase AI or provider-SDK path.
- RevenueCat in the native app.
- A forced first-run paywall.
- Template-generated messages as a native runtime fallback.
- Full Dark Mode, broad localization, or bespoke iPad product design as launch
  blockers unless the release scope is changed deliberately.
- Manuscripts, projects, characters, worldbuilding, or generic document tools.
