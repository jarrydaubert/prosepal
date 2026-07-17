# Native V1 Launch Contract

This document defines what the native ProsePal rewrite must be able to do at
launch. Unresolved implementation and release work belongs only in
[the backlog](../BACKLOG.md).

## Core loop

Native v1 is ready when this loop is reliable on a supported iPhone:

1. Open the app without a mandatory account or paywall.
2. Name the person, explicitly confirm the relationship, and choose the moment.
3. Answer one tailored, skippable question about what matters, with no more than
   two optional follow-up questions, then keep or change the compact Style
   defaults.
4. Produce three meaningfully different ways to say it through the private lane
   where available or the careful gateway lane where appropriate.
5. Choose one message before entering focused editing.
6. Edit or adjust the chosen message without losing any recoverable wording.
7. Copy, share/send, or deliberately save the result.

The tailored questions are an aid, not an intake gate. Personal detail, message
goal, and things to avoid remain distinct so the writing service cannot mistake
an exclusion for something to include. The interface never presents one of the
three messages as “best” unless a future ranking contract genuinely earns that
claim.

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
- Careful writing is an automatic cloud lane through the ProsePal gateway.
- Legacy writing-register values are not a visible compose step. New initial
  drafts derive everyday-versus-careful treatment from occasion policy and
  writing-service availability; legacy values are recovery input, not hidden
  user intent.
- After a message is chosen, only the supported named adjustments in
  `MomentAdjustment` may request a rewrite.
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
- Never log raw answers to tailored questions or use them as analytics payloads.
- Never require the optional guidance questions before writing can begin.
- Never ship different result interactions for the private and careful lanes.
- Never let an unreachable legacy register silently change a new draft’s route,
  prompt, Pressure Check, or visual treatment.

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

The three-option contract has one explicit feasibility gate: a supported
physical iPhone must produce three useful private options in one Foundation
Models session within the approved end-to-end generation deadline. Missing that
gate requires a deliberate universal fallback and v1-scope amendment; it does
not permit lane-dependent result screens or an unmeasured launch exception.
The deadline is approved first, the private-device spike runs second, and
production composer/result work starts only after that recorded decision.

## Non-goals

- Android rewrite work.
- Flutter screen parity.
- A client-direct Firebase AI or provider-SDK path.
- RevenueCat in the native app.
- A forced first-run paywall.
- Three mandatory dialog screens or an unskippable personalisation interview.
- Template-generated messages as a native runtime fallback.
- Full Dark Mode, broad localization, or bespoke iPad product design as launch
  blockers unless the release scope is changed deliberately.
- Manuscripts, projects, characters, worldbuilding, or generic document tools.
