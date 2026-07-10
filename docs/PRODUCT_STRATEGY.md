# Product Strategy

## Purpose

Capture Prosepal's high-level product, growth, and experimentation direction in one place.

This document is directional, not a release checklist or backlog. Open implementation work belongs in `docs/BACKLOG.md`.

## Product Positioning

ProsePal is a native iOS app for thoughtful personal messages. It helps someone
show up for the people who matter: remember the moment, say what is true, and
get the message sent.

Core promise:

- Start person-first, not document-first.
- Turn a person, moment, relationship, and one true thing into a useful draft
  without making the user prompt-engineer.
- Treat AI as an editor and co-writer that improves the user's own words, not a
  chatbot that takes over the emotional work.
- Reduce blank-page anxiety, especially for difficult moments like sympathy,
  apology, gratitude, and milestones.
- Keep sensitive writing private by default and never expose provider/model
  names to users.

Differentiation:

- More emotionally aware than a generic AI text box.
- More native and immediate than a form-based card-message generator.
- More personal than static examples because relationship memory and voice can
  live on device.
- More privacy-aligned than client-direct provider SDKs because generation
  routes through a ProsePal-owned service boundary.

## Product Baseline

The active native baseline is the person-first Moment Sheet in `prosepal-ios/`.
The previous Flutter app is archived at tag `flutter-prod-freeze-2026-06-25`
and branch `legacy/flutter-production-reference` for lessons, service behavior,
App Review history, and functional inventory. Flutter screens are not the
native interaction or visual spec.

Near-term native work should strengthen:

- Moment Sheet clarity and speed to first useful draft
- private draft and take-more-care routing through `MessageWritingService`
- relationship vault, Truth Beads, and Voice Card control
- careful-mode writing, Pressure Check, and honest model-refusal/error states
- StoreKit 2, Sign in with Apple, account deletion, and entitlement determinism
- accessibility, Liquid Glass control surfaces, and privacy-safe diagnostics

Avoid reintroducing:

- a giant occasion grid as the primary experience
- grouped-form parity as a maintained fallback
- Firebase AI / Vertex AI / provider SDK generation in the native client
- RevenueCat as a native dependency
- user-facing provider/model names
- manuscript, scene, character, project-library, or document-manager bloat

## Audience And Markets

Primary user:
- Busy adults who buy cards, care about sounding thoughtful, and want help expressing themselves quickly.

High-fit segments:
- Last-minute card writers
- People handling emotionally difficult messages
- Users who are not naturally confident writers
- Users for whom English is not their first language

Priority markets:
- United States
- United Kingdom
- Canada
- Australia
- New Zealand
- Ireland

The UK remains strategically important because card-buying behavior is especially strong there.

## Growth Strategy

Primary acquisition approach:
- App Store optimization
- search-driven web content
- lightweight, sustainable social distribution

Preferred channel mix:
- ASO for high-intent mobile discovery
- SEO for "what do I write in a card" searches
- Pinterest for evergreen distribution of occasion-based content
- selective short-form social content only if it is low-overhead and reusable

Paid acquisition should remain staged and disciplined:
- start with the highest-intent channels first
- use paid only after the product and organic signals justify it
- avoid broad multi-channel spend before one channel is working

## Monetization And Retention

Monetization model:
- free first-use experience
- Pro subscription for frequent use and premium value

Retention should come from practical reasons to return, not from novelty alone.

Most promising retention directions:
- occasion reminders
- lightweight calendar support
- seasonal and event-based re-entry points
- clear history and reuse value

## Product Direction

Prioritize improvements that strengthen the native Moment product:

- faster path from person -> moment -> one true thing -> draft
- better local relationship memory where the user stays in control
- Standard/private drafting for everyday moments
- take-more-care escalation for sensitive or higher-stakes messages
- contextual AI refinement actions such as warmer, firmer, shorter, less
  defensive, more professional, keep my voice, explain how this might land, and
  say no clearly
- clearer saved/local privacy semantics
- sharper onboarding that gets users to first value quickly
- spelling/locale preferences where they improve trust

Deprioritize or avoid:
- broad feature expansion that weakens the message-writing core
- creative-writing, manuscript, or document-project workflows
- automatic memory inference before user-approved memory is solid
- notifications/reminders before timing semantics are safe and useful
- custom crisis classification or mental-health assessment in native v1
- heavy B2B work before consumer value is proven
- Flutter parity work that does not serve the native Moment shape

## Experiments And Ideas

Ideas are acceptable when they are small, low-risk, and clearly subordinate to the core product.

Good fits:
- seasonal content and release-note polish
- hidden delight features
- lightweight brand moments
- narrow audience experiments that do not complicate core flows

Example of a possible non-core experiment:
- a hidden Pro-only haiku feature as an optional delight, not a roadmap pillar

Any experiment must not:
- compromise reliability
- create auth/payment ambiguity
- introduce privacy or moderation risk without clear controls
- become release-critical without explicit approval

## Brand And Messaging

Brand voice should stay:
- warm
- helpful
- lightly playful
- clear rather than clever

Messaging should emphasize:
- relief from blank-message stress
- speed without sounding robotic
- thoughtfulness, privacy, and personal tone

## Decision Rules

Use these filters before expanding scope:
- Does this help users show up for someone with a better message faster?
- Does it strengthen trust, retention, or monetization without complicating the core flow?
- Can it be validated cheaply before deep investment?
- Is it more valuable than reliability and release hardening work already in backlog?

If the answer is no, keep it out of the near-term product scope.
