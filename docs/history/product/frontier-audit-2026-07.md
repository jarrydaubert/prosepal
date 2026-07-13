# Frozen Decision Record: Apple-First Frontier Audit

> Frozen product and engineering decision context from July 2026. This file
> preserves why work was accepted or deferred; it is not an implementation plan.
> Every unresolved action lives in `docs/BACKLOG.md`.

## Scope Decision

The audit began as a review of how current Apple frameworks could improve the
guided three-option writing flow. It expanded to Foundation Models streaming and
prewarming, speech recognition, StoreKit presentation, system navigation chrome,
App Intents, Writing Tools, and Private Cloud Compute.

The selected scope is deliberately narrower: native v1 owns the core writing
loop. Platform replacements and frontier experiments are retained in the backlog
without becoming launch commitments. Temporary Claude plan files and chat
threads are not sources of truth.

```text
V1 writing loop
  -> remove duplicate model tooling
  -> establish the minimum quality baseline
  -> approve one end-to-end deadline
  -> measure three-option generation on a physical iPhone
  -> choose single-shot or streaming from evidence
  -> deliver one universal choose-before-edit experience

Independent platform opportunities
  -> backlog as post-v1 or evidence-triggered work
  -> adopt only behind existing protocols and release gates
```

## Decisions Retained

### Relationship memory remains prompt context

The private writing client already injects approved relationship memory into a
deterministic prompt and also exposes the same information through a Foundation
Models tool. The prompt is sufficient for this fixed, already-known context.
Remove the redundant tool before recording latency or quality baselines so the
measurement does not straddle two model configurations.

### Streaming must earn its complexity

`LanguageModelSession` supports prewarming and streamed partial generated
content. Availability alone does not prove that streaming improves this app.
The physical-device spike compares complete single-shot generation, streamed
time to first useful text, and complete streamed output. It may select
single-shot generation when that already meets the approved deadline.

If streaming is selected, incomplete fragments never become persistent or
selectable messages. The gateway cannot pretend to stream candidate text it has
not received. Both writing lanes still converge on one complete three-option
result contract.

### Quality precedes output-affecting change

A minimum deterministic fixture runner and baseline must exist before changing
prompts, model-facing schemas, tool configuration, generation runtime, or
adjustment vocabulary for the three-option work. The broader corpus and approved
lane-specific review remain release evidence. This gate does not apply to an
unrelated persistence-only schema change.

### Apple platform swaps remain independent

`SpeechAnalyzer` and its transcriber/asset model are credible successors to the
current speech internals, and `SubscriptionStoreView` can provide localized
StoreKit merchandising and policy controls. Neither replacement is required to
prove the v1 writing loop. Each remains behind the app's existing protocol or
entitlement boundary and is triggered after v1 unless current release evidence
shows the existing surface is inadequate.

System toolbar adoption can happen when navigation chrome is already being
extracted from the SwiftUI monolith. It is opportunistic cleanup, not a separate
visual rewrite or release gate.

### Trust language requires its own proof

A quiet AI-assistance label or explanation of the inputs used may improve user
understanding, but a single data-path claim can become false when private and
gateway processing differ. The trust layer therefore remains post-v1 research,
must stay provider- and lane-neutral, and needs accessibility plus legal/privacy
review.

The existing claim that message text is never used to train models is different:
it is already user-facing. Its accuracy against every production gateway
provider's binding terms is a v1 release-evidence requirement.

### Frontier APIs are prototypes, not migrations

Apple has announced `PrivateCloudComputeLanguageModel` for the iOS 27 generation
of the Foundation Models framework. That satisfies the discovery trigger, not
the adoption trigger. A later provider-neutral prototype must still prove
privacy, refusal behaviour, latency, availability, cost, and result parity.

Writing Tools and newer App Intents receive similarly bounded experiments after
the focused editor and existing system surfaces have passed their v1 evidence.
ProsePal continues to require foreground review and never auto-sends an AI-
authored message.

## Work Placement

Only removal of the redundant relationship-memory tool joins the near-term v1
engineering sequence. Streaming stays conditional inside the existing deadline
and three-option items. Legal verification of existing training copy joins App
Store evidence.

Speech, StoreKit presentation replacement, result-screen trust explanations,
App Intents modernization, Drafts-tab prominence, Writing Tools, and Private
Cloud Compute remain post-v1 or explicitly triggered backlog work. Burst-before-
quota reordering remains an abuse-evidence-triggered database hardening item.

## Authoritative Sources Consulted

- [LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)
  documents session reuse, `prewarm(promptPrefix:)`, and streamed responses.
- [Expanding generation with tool calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling)
  documents the Foundation Models tool boundary.
- [iOS and iPadOS 27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes)
  record current beta constraints and known issues that require rechecking before
  adoption.
- [SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer),
  [AssetInventory](https://developer.apple.com/documentation/speech/assetinventory),
  and [Apple's WWDC25 SpeechAnalyzer session](https://developer.apple.com/videos/play/wwdc2025/277/)
  document live transcription, managed assets, and fallback considerations.
- [SubscriptionStoreView](https://developer.apple.com/documentation/storekit/subscriptionstoreview)
  documents localized subscription merchandising, purchase controls, and policy
  destinations.
- [What's new in the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/241/)
  and [Build with the new Apple Foundation Model on Private Cloud Compute](https://developer.apple.com/videos/play/wwdc2026/319/)
  introduce the iOS 27 Private Cloud Compute model path.

## Relationship To Other Decisions

The guided composer, register fate, three-option result contract, and physical-
device feasibility gate remain owned by
[the three-option writing-flow decision](./three-option-writing-flow-decision-2026.md).
Current product behaviour remains in active product documentation. The backlog
is the only source for unfinished delivery work.
