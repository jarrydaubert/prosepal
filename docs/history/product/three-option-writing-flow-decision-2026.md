# Frozen Decision Record: Guided Composer And Three-Option Writing Flow

> Frozen product decision context from July 2026. This file explains the
> reasoning; it is not implementation instruction. Current behaviour remains in
> the active product docs and unresolved delivery work remains in the backlog.

## Decision

Native v1 targets a guided compose-to-choice flow. Delivery remains gated on the
private on-device lane proving it can produce three useful options inside the
agreed end-to-end generation deadline.

The intended experience is:

```text
Name the person and confirm the relationship
  -> choose the occasion
  -> answer one tailored, skippable question
  -> optionally reveal up to two more questions
  -> keep or change compact Style defaults
  -> generate three equally weighted ways to say it
  -> choose the one that feels right
  -> edit, adjust, undo, copy, share, or save
```

This is now the explicit v1 launch target. Current-behaviour documentation must
continue to describe the implemented one-draft experience until the physical-
device gate and delivery work pass.

## Why

The previous Flutter product made comparison easy: a person could recognise the
message that felt right instead of first diagnosing how one draft should change.
The native rewrite protects edits and recovery much better, but its single-draft
result turns recognition into articulation.

The gateway already requires and returns three distinct messages. Its native
adapter currently selects `messages.first`, even though gateway order has no
best-candidate or ranking meaning. Keeping one primary message plus hidden
alternatives would preserve that accidental ordering and make comparison a
recovery action instead of the normal result.

## Compose Hierarchy

Keep meaning-bearing context visible:

- person;
- explicitly selected relationship;
- occasion;
- one relationship-by-occasion question; and
- the answer, when the user chooses to provide one.

Tone and length have safe defaults and should share one compact Style disclosure.
Relationship must not hide behind the current `closeFriend` default because an
unconfirmed relationship can materially distort the message.

The primary question replaces the generic blank “one true thing” field. It is
visible, inline, and skippable. A quiet “Help me personalise it further” action
may reveal no more than two additional inline questions. These questions never
become dialogs, separate screens, or prerequisites for generation once required
person/relationship/occasion context is valid.

Keep pre-generation Style because it protects scarce gateway usage from an
avoidable wrong-shape result. Post-selection adjustments complement Style; they
do not replace it.

## Register Fate

The target composer has no Quick / Your words / Take care selector. That control
is already absent from the current composer even though `MomentRegister` still
exists in domain state, recovery, prompt context, styling, routing, and one local
Pressure Check rule.

For new initial drafts, everyday-versus-careful treatment derives from occasion
policy and writing-service availability/fallback. The narrow defensive input
block remains a refusal boundary rather than a third writing mode. After the
user chooses a message, Take More Care remains an explicit refinement action.

Legacy register values must continue to decode so active recovery data is not
lost. They cannot remain hidden mutable intent for a new generation: regenerating
normalizes to the derived policy. The implementation records a before/after
occasion-to-lane parity matrix and enumerates any deliberate routing change.
Pre-result careful styling, prompt context, and Pressure Check rules move to the
same explicit occasion/lane policy instead of consulting an unreachable choice.

## Guidance Contract

Question selection combines a small occasion family with relationship context,
so a birthday for a parent does not read like a birthday for a manager. Families
cover celebration, gratitude, apology, sympathy, encouragement/check-in, and
professional moments, with a reviewed generic fallback for every supported
combination.

Each answer keeps a stable cue identifier and one explicit meaning:

- `personalDetail`: a memory, action, quality, or concrete fact to preserve;
- `messageGoal`: what the user wants the message to communicate; or
- `avoid`: wording or subject matter the generated messages must not introduce.

Positive and negative guidance must never be flattened into one ambiguous field.
Raw answers remain message content: they can reach the selected writing lane but
cannot enter operational logs or analytics. Existing recovery payloads must keep
decoding after the state model grows.

Tender prompts receive an editorial review. Sympathy questions may invite a
memory or quality but never probe the circumstances of a death. Apology prompts
encourage ownership without assigning blame, demanding reassurance, or creating
pressure. Questions are deterministic product copy, not generated dynamically.

## Result Hierarchy

Use calm human framing such as “Three ways to say it,” not variants, outputs,
A/B tests, or provider language. Give every option equal visual weight and a
clear choice action. Do not label one Best unless a future reviewed ranking
contract genuinely earns that claim.

After selection, reuse the native focused editing flow: direct edit, adjustments,
Pressure Check, undo, history, relaunch recovery, copy, share, send, and deliberate
save. Candidate choice must not weaken the existing no-loss draft guarantees.

## Feasibility Gate

The gateway path already generates three candidates in one charged request and
the request ledger replays the complete `CardResponse`. The unknown is private
on-device generation.

Before treating the target as delivered:

1. approve the measured end-to-end generation deadline;
2. prototype exactly three distinct structured candidates from one Foundation
   Models session;
3. measure representative Brief, Standard, and Detailed cases on a supported
   physical iPhone against the same end-to-end deadline used by routing;
4. evaluate every candidate for writing quality and the set for meaningful
   variation;
5. record the gate decision before production composer or result work begins;
6. prove candidate-set and selected-draft recovery, cancellation, fallback, and
   late-result behaviour; and
7. verify compact and accessibility-size selection flows without exposing which
   writing lane ran.

If private generation misses the deadline, do not ship different result models
for private and careful writing. Keep the current contract until a separate
decision chooses one universal fallback, with one primary plus disclosed
alternatives as the preferred fallback over returning to one draft only.

## Alternatives Rejected

### One draft plus “Other takes” as the default design

Rejected as the target because it presents an unranked first response as primary
and makes recognition available only after the user questions that response. It
remains the universal fallback if three-option private generation cannot meet the
latency bar and progressive presentation is not calm enough.

### One draft only

Rejected because it preserves the current recognition problem. Improving prose
quality alone does not give the user an easy point of comparison.

### Three options with all current composer controls expanded

Rejected because the output improvement would not address the form-like input
surface. The product should expose facts that change meaning and collapse style
preferences that have honest defaults.

## Documentation Activation Rule

The v1 launch contract and product promise now record the chosen target. After
the feasibility and release evidence pass, amend current-behaviour capabilities,
user journeys, HTML guide, feature matrix, AI-generation docs, recovery
documentation, and the release acceptance path together. Until then, those
documents continue to describe the implemented single-draft experience.
