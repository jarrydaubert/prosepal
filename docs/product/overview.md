# Product Overview

ProsePal is a native iOS app for writing thoughtful personal messages. It helps
someone move from “I need to say this properly” to a message they are ready to
send, without turning the experience into a chatbot or a document editor.

## Product promise

ProsePal helps a person:

1. start with who the message is for and their relationship;
2. name the moment and answer one helpful, optional question about what matters;
3. receive three meaningfully different ways to say it;
4. recognise and choose the one that sounds right;
5. revise without losing their own words; and
6. copy, share, send, or deliberately save the result.

The product should reduce blank-page anxiety while preserving the emotional
work that belongs to the user.

## Who it is for

The primary user is an adult who cares about sounding thoughtful but may be
short on time, unsure how to begin, or handling a difficult moment. High-fit
uses include birthdays, thanks, sympathy, apologies, congratulations, and
personal check-ins.

The initial market is English-language iPhone users, with the United States,
United Kingdom, Canada, Australia, New Zealand, and Ireland as natural launch
markets.

## Product principles

- Person-first, not document-first.
- The user’s words lead; AI edits and assists.
- A small set of genuinely different choices is useful; a wall of output is not.
- Everyday writing should stay private on device where available.
- Harder writing may use the careful gateway lane without becoming a paywall.
- Provider and model names are implementation details, never product language.
- Sign-in supports continuity and account controls; it does not block first
  value or purchase.
- Saved history and relationship memory are deliberate and user-approved.
- Reliability, privacy, accessibility, and honest error states outrank feature
  breadth.

## Product boundaries

ProsePal is for short personal messages. It is not:

- a generic AI chat application;
- a manuscript, scene, character, or project manager;
- a high-volume marketing-writing tool;
- a relationship score, streak, or guilt system; or
- a crisis-assessment or mental-health inference product.

Models and the gateway may refuse unsafe requests. The app presents those
refusals safely, but custom crisis classification is outside the product’s
native-v1 scope.

## Business model

The product offers useful first value without a mandatory account or immediate
paywall. StoreKit subscriptions support higher limits and future paid extras.
Purchase and careful writing remain separate concerns: a sensitive moment is
not made less safe because the user is not subscribed.

Retention should come from practical value: better writing, deliberate saved
messages, and user-controlled relationship context. Reminders or calendar
features are later options, not part of the core writing loop.

## Growth direction

Acquisition should begin with high-intent channels:

- App Store search;
- search content for “what should I write” questions; and
- low-overhead, reusable social or seasonal content.

Paid acquisition should follow proven product value and organic signal, not
precede them.

## Decision filter

Before expanding the product, ask:

- Does this help someone send a better personal message faster?
- Does it increase trust or repeat value without complicating the core loop?
- Can it be tested without weakening reliability, privacy, or release work?

If not, it does not belong in the near-term product.

## Related documentation

- [V1 launch contract](./v1-launch-contract.md)
- [Capabilities](./capabilities.md)
- [User journeys](./user-journeys.md)
- [Historical relationship-assistant vision](../history/product/relationship-assistant-vision.md)
