# Frozen Decision Record: Three-Option Writing Flow

> Frozen product decision context from July 2026. This file explains the
> reasoning; it is not implementation instruction. Current behaviour remains in
> the active product docs and unresolved delivery work remains in the backlog.

## Decision

ProsePal should move from presenting one arbitrary generated draft to a
choose-before-edit flow when the private on-device lane proves it can produce
three useful options inside the agreed end-to-end generation deadline.

The intended experience is:

```text
Compose simply
  -> generate three equally weighted ways to say it
  -> choose the one that feels right
  -> edit, adjust, undo, copy, share, or save
```

The current one-draft launch contract remains authoritative until that physical-
device feasibility gate passes.

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
- occasion; and
- one optional personal detail or true thing.

Tone and length have safe defaults and should share one compact Style disclosure.
Relationship must not hide behind the current `closeFriend` default because an
unconfirmed relationship can materially distort the message.

The personal detail remains visible rather than sitting behind an add button. It
is optional so a simple birthday or thank-you message is still quick, but the UI
should explain that this is what makes the result personal.

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

Before changing the active product contract:

1. prototype exactly three distinct structured candidates from one Foundation
   Models session;
2. measure representative Brief, Standard, and Detailed cases on a supported
   physical iPhone against the same end-to-end deadline used by routing;
3. evaluate every candidate for writing quality and the set for meaningful
   variation;
4. prove candidate-set and selected-draft recovery, cancellation, fallback, and
   late-result behaviour; and
5. verify compact and accessibility-size selection flows without exposing which
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

After the feasibility and release evidence pass, amend the v1 launch contract,
product overview, capabilities, user journeys, HTML guide, feature matrix, AI
generation docs, recovery documentation, and release acceptance path together.
Until then, those active documents continue to describe the implemented
single-draft experience.
