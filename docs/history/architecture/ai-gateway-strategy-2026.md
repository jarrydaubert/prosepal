# Historical: AI Gateway Strategy 2026

> Frozen context. This document preserves the pre-implementation gateway
> strategy, rollout stages, candidate tickets, and alternatives. Current
> behaviour is documented in
> [`docs/engineering/ai-generation.md`](../../engineering/ai-generation.md).

## Status

This document is an architecture strategy and decision framework.

As of the native-main transition, the previous Flutter production app is
archived at tag `flutter-prod-freeze-2026-06-25` and branch
`legacy/flutter-production-reference`. Historical references below to the
Flutter client-direct Firebase AI path describe the archived baseline, not the
active `main` implementation.

It is not:

* approval to build a production AI gateway
* approval to introduce new production AI providers
* approval to change production model routing
* approval to launch Standard or Premium generation
* approval to change pricing, limits, prompts, telemetry, privacy posture, or release scope
* approval to replace App Store production runtime without a separate release
  decision
* approval to scaffold a SwiftUI client
* approval to move provider keys, model selection, entitlement logic, or routing logic into the mobile app

Any production gateway work requires an Architecture Decision Record, backlog approval, eval evidence, privacy review, cost-budget owner, rollback plan, and release-gate approval.

Current release scope, gates, and open work remain owned by:

* [`docs/product/v1-launch-contract.md`](../../product/v1-launch-contract.md)
* [`docs/BACKLOG.md`](../../BACKLOG.md)

## Purpose

Define the target AI architecture direction for ProsePal without changing App
Store production runtime by accident.

The strategic direction is:

**ProsePal should depend on a message-writing capability, not on one provider, one SDK, or one model name.**

The product should be able to route generation through private, careful, cloud,
local, and fallback lanes without rewriting the client each time the AI market
changes.

## Product Direction

ProsePal should move toward a simple user-facing model:

```text
Free users
  -> Standard generation
  -> limited daily use
  -> low or controlled marginal cost

Subscribers
  -> Premium generation
  -> higher limits
  -> better model quality
  -> stronger fallback and priority behaviour
```

The app should not promise specific model names to users.

Good user-facing wording:

```text
Standard generation
Premium generation
Enhanced generation
Higher daily limits
Priority generation
```

Avoid user-facing wording such as:

```text
Gemma generation
Gemini generation
GPT generation
Claude generation
```

Provider and model names are implementation details. The product promise is quality, usefulness, and reliability.

## Archived Flutter AI Architecture

The archived Flutter production baseline used a client-direct path:

```text
Flutter app
  -> Firebase AI SDK
  -> Vertex AI backend
  -> configured Gemini model
```

Archived runtime facts:

* the Flutter app used the Firebase AI SDK
* the production default backend was Vertex AI
* an optional debug override can force the Google Developer API path
* Remote Config controls the configured primary and fallback model IDs
* model routing is limited to configured primary and fallback model slots
* the archived baseline remained client-direct unless a server-side gateway
  trigger was approved

Archived controls:

* primary and fallback model IDs are pinned stable IDs, not `latest` aliases
* Remote Config values are validated against `AiConfig.allowedModelIds`
* invalid or empty model selections fall back to repo-defined defaults
* the AI kill switch and App Check posture are part of the runtime operating model
* production telemetry should expose stable backend, model-slot, and error-bucket context without leaking provider URLs, raw payloads, or exact upstream resource paths

Related current docs:

* `docs/AI_SYSTEM.md`
* `docs/REMOTE_CONFIG.md`
* `docs/DEVOPS.md`
* `docs/NEXT_RELEASE_BRIEF.md`
* `docs/BACKLOG.md`

## Target Architecture

The target direction is a provider-agnostic AI Gateway and Model Router architecture:

```text
Client app
  -> ProsePal API
  -> request verification
  -> authentication and abuse controls
  -> entitlement and usage policy
  -> AI Gateway / Model Router
  -> provider adapters or approved platform generation
  -> private, careful, cloud, local, or fallback lane
```

In this target design, the client asks ProsePal for a message-writing capability. It does not ask a specific provider or model for a raw completion.

The native iOS 26 direction adds an on-device private drafting lane behind the
same product boundary. Everyday private drafts may be produced locally when the
device supports it. Careful, subscription-sensitive, abuse-sensitive, or
server-authoritative generation still routes through the ProsePal gateway.

The client should send structured intent, such as:

```text
Generate a birthday message for my dad, warm tone, short length, UK English, mention a quiet cup of tea.
```

The server decides how to satisfy that request.

## Architecture Tradeoff: Client-Direct To Server Gateway

Moving from client-direct Firebase AI to a ProsePal gateway is a meaningful architectural tradeoff.

Client-direct generation is operationally simple:

```text
Client app
  -> Firebase AI / Vertex AI
```

A gateway adds:

* an extra network hop
* server compute on the interactive generation path
* gateway hosting cost
* gateway scaling responsibility
* server-side availability risk
* server-side authentication and abuse-control responsibility
* server-side privacy and logging obligations
* provider secret management
* contract compatibility for old app versions
* backpressure and concurrency decisions during provider slowness

The gateway buys:

* provider independence
* server-side model routing
* server-side entitlement enforcement
* server-side usage limits
* cost controls
* abuse controls
* provider fallback
* Standard and Premium product lanes
* centralised prompt and quality policy
* eval-driven model promotion
* fewer provider details in the client

This tradeoff must be accepted explicitly in the future ADR. The gateway is not free flexibility. It is a new production service on the interactive generation path.

## Stable Product Contract

The product API should expose a stable generation contract, such as:

```text
POST /generate-card
```

The request and response should be owned by ProsePal, not by any provider SDK.

Conceptual `CardRequest` fields:

* occasion
* recipient
* relationship
* tone
* length
* locale
* things to include
* things to avoid
* user-provided context
* requested generation tier when applicable
* client app version
* prompt contract version

Conceptual `CardResponse` fields:

* generated message
* optional variants
* generation tier used
* provider slot used, if safe to expose internally
* fallback status
* quality-check result
* prompt contract version
* output contract version
* retry eligibility
* user-safe error message when generation fails

The mobile app should rely on this stable ProsePal-owned contract. Provider payloads, provider SDK response shapes, upstream error messages, and model-specific quirks should stay behind the gateway.

## Contract And Versioning Compatibility

Mobile clients remain in the wild after new app releases. The gateway must not assume every user is on the latest client.

Rules:

* the gateway must know the client app version
* the gateway must know the supported request and response contract versions
* old app versions must continue receiving backward-compatible responses
* breaking response-contract changes require app release coordination
* gateway changes must not silently break previously shipped app versions
* any migration from client-direct generation to gateway generation must define which app versions are eligible for gateway routing
* old shipped app versions may need to remain on the archived Firebase AI path
  until they age out or are explicitly blocked

Example compatibility policy:

```text
Client version 1.x:
  supports client-direct Firebase AI path only unless explicitly enabled

Client version 2.x:
  supports gateway CardRequest/CardResponse v1

Gateway:
  may return v1-compatible fields until v1 clients are retired
```

## Generation Lanes

The target system should use explicit generation lanes.

### Standard Generation

Standard generation is the default free or low-cost lane.

Purpose:

* free users
* low-cost trial usage
* normal everyday messages
* low-risk generations
* early app engagement
* controlled marginal cost

Likely backing options:

* on-device private drafting where the native iOS device supports it
* approved platform cloud generation for devices without local capability
* a gateway-routed cloud model selected by server policy
* local or self-hosted generation only after explicit quality, privacy, and
  operations approval

Suggested product policy:

```text
Free users receive Standard generation with a small daily allowance.
```

A starting allowance could be:

```text
3 free generations per day
```

This number is product policy, not architecture law. It should be adjustable through server-side entitlement policy.

Standard generation must still be useful. It can be less polished than Premium, but it must not feel broken, spammy, or obviously low quality.

### Standard Generation Regression Risk

The archived Flutter baseline used the production Firebase AI / Vertex path for
free users.

If Standard generation later uses a cheaper or open model, existing free users may perceive a quality downgrade. This is a separate risk from whether Standard is good enough in isolation.

Before Standard/private generation replaces the App Store production experience,
it must be evaluated against the archived production baseline.

Gate:

```text
Standard/private generation must not meaningfully regress against the archived
free-user production experience.
```

This should be measured through the ProsePal eval harness, not by anecdotal impressions.

If Standard is cheaper but visibly worse, product options include:

* keep the archived production baseline available as rollback/eval reference
* make Standard available only to new anonymous users
* require sign-in for free generation
* reduce free usage rather than reduce quality
* keep Standard as fallback only
* improve Standard prompt/model before rollout

### Premium Generation

Premium generation is the subscriber lane.

Purpose:

* subscribers
* higher quality output
* harder occasions
* more nuanced relationship and tone handling
* higher daily or monthly limits
* priority generation
* stronger fallback behaviour

Likely backing options:

* frontier cloud model
* best current writing model available within cost budget
* model selected by the gateway based on quality, latency, reliability, and cost

Suggested product policy:

```text
Subscribers receive Premium generation with higher limits and better generation quality.
```

Premium should justify paid access through:

* stronger tone fit
* better specificity
* better handling of sensitive occasions
* fewer generic outputs
* longer or more polished drafts where appropriate
* higher usage allowance
* more reliable fallback path

Premium should not be described to users as access to a named provider unless there is a deliberate product/legal reason to do so.

### Premium To Standard Fallback Policy

Premium fallback is a product policy, not only a technical flag.

If a subscriber’s Premium generation request falls back to Standard generation, the product must define:

* whether the user is told
* whether the request consumes a Premium allowance
* whether the user can retry later
* whether the user can request Premium again
* whether support messaging explains degraded generation
* whether telemetry records this as a degraded paid experience
* whether repeated Premium degradation triggers an alert or rollback

Internal telemetry should distinguish:

```text
premium_served
premium_degraded_to_standard
premium_degraded_to_template
premium_failed
```

The UI should not expose provider or model names, but it may need honest user-safe wording if the paid experience is degraded.

Example user-safe wording:

```text
We could not use enhanced generation this time. You can retry shortly.
```

No Premium fallback policy should be launched without product approval.

### Local Or Private Generation

Local or private generation is a future resilience and privacy lane.

Purpose:

* offline experiments
* privacy-sensitive generation
* local R&D
* quality comparison
* fallback exploration
* not being fully dependent on one hosted provider

Likely backing options:

* locally hosted open model
* device-adjacent model
* private server model

This lane may be lower quality initially. It should not be promoted to production unless it passes the ProsePal output-quality rubric.

### Emergency Template Generation

Emergency template generation is the last-resort lane.

This is server-side router policy only. It is not approval to add client-side
template generation or app-side fallback drafting to the native SwiftUI app.

Purpose:

* provider outage
* gateway outage
* exhausted provider quota
* user-safe degradation
* app still gives something useful rather than hard-failing

This lane should use deterministic templates and user input. It should be clearly limited, but not embarrassing.

Example user-facing wording:

```text
We could not generate a full draft right now, but here is a simple starting point.
```

Do not pretend template output is Premium generation.

## Authentication And Entitlement Source Of Truth

A server-side gateway must authenticate requests itself. It cannot rely on the old client-direct Firebase AI posture.

Before any production gateway rollout, the ADR must define:

* how the client authenticates to the ProsePal API
* whether Firebase Auth, Supabase Auth, Apple ID, anonymous identity, or another identity source is authoritative
* how App Check, device attestation, or equivalent abuse controls apply to the gateway
* how unauthenticated requests are handled
* how signed-in users are linked to usage counters
* how deleted accounts are handled
* how account transfer or restore is handled
* how the gateway rejects forged or stale tokens

Subscriber routing must also use a trusted entitlement source.

Before any Premium or careful lane exists, the ADR must define:

* how StoreKit 2 client state is used for immediate UX
* how App Store Server Notifications V2 and App Store Server API reconciliation
  feed the server entitlement store
* whether entitlement state is checked live, cached, or synced through
  webhooks/server notifications
* how stale entitlement state expires
* how refund, cancellation, grace period, billing retry, and restore are handled
* how the gateway prevents the client from simply claiming Premium status

Conceptual routing depends on trustworthy entitlement state:

```text
if trusted entitlement says subscriber:
  Premium eligible

if entitlement missing, expired, or unverifiable:
  Standard or blocked according to policy
```

The client may display subscription state, but the server must enforce Premium access.

## Gateway Request Verification

The gateway must verify that requests are legitimate before routing them to any model provider.

The ADR must define:

* authentication token source
* App Check or equivalent attestation verification
* entitlement verification
* rate-limit key derivation
* anonymous request policy
* replay protection where needed
* behaviour for missing, expired, forged, or unverifiable tokens

Model routing must not run until request authenticity and entitlement state have been checked.

If Firebase App Check remains part of the protection model, the gateway must verify App Check tokens manually or through a trusted server-side verification mechanism. The gateway must not assume the old Firebase AI client SDK protection applies automatically to the new ProsePal API.

## Entitlements And Usage Limits

The gateway should own usage and entitlement policy.

Conceptual routing:

```text
if user is subscriber:
  use Premium generation
  apply subscriber limit
  fallback according to Premium policy

if user is free:
  enforce free limit
  use Standard generation
  fallback according to Standard policy

if abuse or suspicious traffic is detected:
  deny, throttle, require sign-in, or disable generation
```

Starting policy idea:

```text
Anonymous or free user:
  3 Standard generations per day

Subscriber:
  higher daily or monthly Premium allowance
```

Exact limits should be configurable. Do not hardcode product economics deeply into the app.

Usage counters may include:

* user ID where signed in
* anonymous install ID where appropriate
* device or app instance ID
* IP or coarse abuse signal
* daily generation count
* monthly generation count
* regeneration count
* failed generation count
* provider error count

Abuse controls should be server-side. The client may display remaining allowance, but the server must enforce it.

## Anonymous Free-Tier Limitations

Anonymous free-tier enforcement is inherently weak.

Potential anonymous identifiers are imperfect:

* install IDs can reset on reinstall
* device IDs can be unavailable, reset, or privacy-sensitive
* IP addresses can be shared, mobile, VPN-routed, or rotated
* local counters can be tampered with
* App Check or attestation can reduce abuse but does not create a durable user identity

Therefore, a “3/day anonymous” limit should be treated as soft abuse reduction, not strong entitlement enforcement.

If robust free limits are required, product options include:

* require sign-in for free generation
* allow a very small anonymous trial, then require sign-in
* tie free generation to a verified account
* use App Check or attestation as an abuse signal, not as identity
* apply stricter rate limits to anonymous traffic
* disable anonymous free generation during abuse spikes

This is a product decision, not just a backend detail.

## Prompt Orchestration

Prompt orchestration should remain a ProsePal-owned layer. It is responsible for turning structured card intent into the canonical generation request.

This layer owns:

* system instruction
* user prompt construction
* tone rules
* safety rules
* UK English or US English requirements by surface or locale
* forbidden-topic handling
* sensitive-occasion handling
* output format
* retry instructions
* prompt versioning
* tier-specific prompt policy

Provider-specific prompt tweaks may exist behind adapters later, but the canonical product prompt should not be owned by a provider integration.

The prompt should express the product’s quality expectations, not the provider’s marketing language.

## Model Router

The AI Gateway / Model Router decides how to satisfy a card-generation request.

Routing inputs may include:

* trusted user identity
* trusted entitlement state
* requested generation lane
* daily or monthly usage limit
* request complexity
* occasion sensitivity
* provider health
* provider quota state
* latency budget
* cost budget
* fallback eligibility
* quality-check failure reason
* active release policy
* kill-switch state
* privacy or offline mode

The router should make these decisions on the server-side path only after the
gateway rollout trigger is approved. Archived Flutter routing stayed on the
client-direct Firebase AI primary/fallback behaviour.

Example routing policy:

```text
Free user:
  route to Standard generation
  enforce free daily limit
  fallback to template if Standard provider unavailable

Subscriber:
  route to Premium generation
  fallback according to paid-user fallback policy
  fallback to template only if all model lanes fail

Internal evaluation:
  route the same request through multiple providers
  compare against quality rubric
  do not expose experimental output to users unless explicitly enabled
```

## Router Scope Control

The first gateway should be deliberately small.

Initial responsibilities:

* validate `CardRequest`
* verify request authenticity
* check entitlement and usage policy
* select Standard, Premium, or fallback lane
* call one provider adapter
* run basic quality guardrails
* return `CardResponse`
* log redacted operational metadata

Do not build advanced routing, multi-provider arbitration, local-model orchestration, or complex fallback chains until the simpler router has evidence from non-production or controlled production use.

The router should be a traffic cop first, not an orchestration platform from day one.

## Ports And Adapters

The target design follows ports and adapters, also known as hexagonal architecture.

ProsePal defines the internal AI generation port. Providers are replaceable adapters behind that port.

Possible adapters:

* archived Firebase AI / Vertex AI adapter
* OpenRouter or model-aggregator adapter
* direct frontier-provider adapter
* local or self-hosted model adapter
* deterministic server-side template adapter for emergency fallback only
* mock or test adapter

Adapters hide provider-specific details such as:

* message formats
* content parts
* system instruction handling
* JSON mode
* tool calls
* safety settings
* temperature
* sampling controls
* max tokens
* error shapes
* retry semantics
* rate-limit semantics
* provider-specific response metadata

The app should not import provider SDKs for generation once the gateway path is approved and rolled out.

## Aggregator Adapter Risk

Model aggregators can be useful because they allow one integration to reach multiple model providers. They also add risk.

Aggregator adapters require extra review for:

* provider transparency
* data handling
* prompt and response retention
* logging behaviour
* latency variability
* model identity guarantees
* routing guarantees
* support and debuggability
* commercial terms
* regional data transfer
* privacy-policy impact
* App Store disclosure impact

Aggregator use should not hide the actual model or data processor from ProsePal operators.

No aggregator should become a production Standard or Premium path until its privacy, commercial, support, and reliability properties are reviewed.

## Quality Guardrails

Responses should be checked before they become user-visible.

Useful ProsePal guardrails include:

* non-empty output
* length fit
* requested tone fit
* requested relationship fit
* occasion fit
* no forbidden topics
* no invented personal facts
* no banned generic filler
* no overfamiliar or inappropriate language
* no accidental wrong locale
* UK English where requested
* appropriate handling for sensitive occasions
* useful output when user input is thin
* graceful clarification or generic fallback when needed

The first version can use deterministic checks where practical. Later versions can add model-assisted evaluation and regression evals, but only with explicit approval for any prompt, provider, model, or production-routing changes.

## Quality Evaluation Before Model Promotion

No model should become the Standard or Premium default just because it is cheap, free, new, or highly benchmarked.

Promotion should depend on ProsePal-specific evaluation.

Suggested eval set:

```text
50 to 100 representative ProsePal scenarios
```

Scenario dimensions:

* birthday
* sympathy
* apology
* thank you
* congratulations
* romantic
* friendship
* parent or family
* work colleague
* sensitive or emotionally awkward occasions
* short, medium, and longer outputs
* thin input
* highly specific input
* things to include
* things to avoid
* UK English and US English where relevant

Scoring dimensions:

* warmth
* specificity
* tone fit
* relationship fit
* occasion fit
* length fit
* usefulness
* non-cringe wording
* no invented facts
* no unsafe or inappropriate content
* locale fit
* editability by the user

Promotion rules should be explicit:

```text
Standard lane:
  must be good enough for free users
  must not damage trust
  must not meaningfully regress against the archived free-user production baseline

Premium lane:
  must outperform Standard on quality, nuance, and reliability
  must justify paid access

Fallback lane:
  must degrade gracefully and honestly
```

The eval suite should compare lanes, not only models.

Example comparison:

```text
Current production baseline
Standard candidate
Premium candidate
Template fallback
```

## Eval Ownership And Promotion Thresholds

Before any model or provider is promoted to Standard or Premium, the ADR must define:

* who owns the eval set
* who can approve model promotion
* who can approve prompt changes
* who can approve provider changes
* minimum score for Standard
* minimum Premium-vs-Standard uplift
* required sensitive-occasion quality threshold
* required regression threshold against archived production baseline
* whether evaluation is blind, human-reviewed, automated, or mixed
* how eval failures are triaged
* how new edge cases are added

The eval suite should contain:

* a stable golden set that changes rarely
* an expandable challenge set for new edge cases
* release comparison outputs
* regression notes for failed scenarios

No model promotion should happen from anecdotal testing alone.

## Hosting And Compute Model

A gateway puts ProsePal-owned server compute on the interactive generation path.

The ADR must choose a hosting and request model before any production rollout.

Options include:

* synchronous request and response
* streaming response
* asynchronous job with polling
* queued worker with callback or status endpoint

Stage 1 and Stage 2 may use synchronous request and response because they are non-production spikes.

Before Stage 4, the ADR must define:

* hosting platform
* expected concurrency
* timeout limits
* maximum provider-call duration
* retry behaviour
* whether streaming is supported
* whether async polling is required
* cost impact of long-lived requests
* backpressure behaviour during provider slowness
* behaviour when concurrency or budget limits are reached
* behaviour when the app is backgrounded during generation

The first production gateway should stay as simple as possible while still meeting latency, cost, and abuse-control requirements.

If provider calls regularly require long timeouts or chained fallbacks, the ADR should consider async job and polling rather than keeping mobile HTTP requests open indefinitely.

## SLOs, Latency, And Streaming

Generation is interactive. The gateway must define end-to-end latency expectations before controlled rollout.

Future ADR should define:

* Standard generation target latency
* Premium generation target latency
* fallback-chain maximum latency
* provider timeout per lane
* maximum retry count
* user-visible timeout behaviour
* whether generation streams tokens or returns one complete response
* whether streaming is required for the first gateway version
* how streaming works through the gateway if added later

Short greeting-card messages may not need streaming initially. If streaming is not supported, the UI should show clear progress and avoid appearing frozen.

Example conceptual targets:

```text
Standard generation:
  target under 8 seconds
  hard timeout under 15 seconds

Premium generation:
  target under 12 seconds
  hard timeout under 25 seconds

Fallback template:
  target under 2 seconds
```

These are placeholders. Final SLOs require measurement.

## Client UX During Generation

If the gateway does not stream tokens initially, the client must still make generation feel alive and controlled.

Before controlled rollout, define:

* loading state copy
* disabled duplicate-submit behaviour
* timeout behaviour
* retry behaviour
* whether retries consume allowance
* how fallback or degraded generation is communicated
* how the app behaves when backgrounded during generation
* how the app avoids duplicate expensive requests
* whether request cancellation is supported

The UI must prevent repeated tapping from creating duplicate provider calls.

If generation takes several seconds, the app should provide visible state changes or clear progress messaging rather than appearing frozen.

## Observability And Cost Controls

The gateway should preserve operator signal without exposing sensitive user content or provider internals.

### Native V1 Request Ledger

The native gateway reserves capacity before provider work through a
service-role-only PostgreSQL request ledger. The request lifecycle is:

```text
authenticate and validate
  -> derive server request fingerprint
  -> reserve burst and quota capacity
     -> replay / reject without provider work
     -> or call the provider once
  -> finalize the reservation
     -> completed: consume usage once and retain replay payload for 24 hours
     -> failed: release reservation without consuming usage
```

The ledger uses `(subject, idempotency_key)` uniqueness, a request fingerprint
to reject key reuse with changed provider input, and a per-attempt reservation
token so late results cannot complete a reclaimed request. Failed and reclaimed
attempts receive separate rows in the existing sliding-window rate-limit log.

The app persists the pending idempotency key for an initial draft for the same
24-hour recovery window. A retry with unchanged draft input can recover a
completed response after a connection loss or app relaunch. Expired or
conflicting keys are cleared, but the app never starts a replacement paid
request without another user action.

Generated response payloads are sensitive user content. They are never logged,
are inaccessible to client roles, and are cleared hourly after 24 hours by the
database cleanup job. Terminal and abandoned request metadata is removed after
seven days; an active reservation is never deleted.

Useful fields:

* generation lane used
* provider class or slot used
* model class or slot used
* latency
* estimated cost
* failure bucket
* fallback reason
* prompt version
* output contract version
* quality-check failures
* usage-limit state
* regeneration count
* user rating where the product explicitly collects one
* subscriber or free tier classification without exposing billing details
* provider quota status

These signals should support:

* provider switching
* fallback tuning
* quality evaluation
* cost budgets
* abuse detection
* release rollback decisions
* deciding whether Standard is good enough
* deciding whether Premium still justifies subscription value

Do not log raw user messages unless explicitly approved with privacy review. Prefer redacted, sampled, or structured diagnostic fields.

## Cost Envelope

Before any production gateway rollout, the ADR must define:

* maximum cost per Standard generation
* maximum cost per Premium generation
* monthly AI budget cap
* budget owner
* alert thresholds
* automatic degradation behaviour when budget or quota is at risk
* maximum retries per lane
* whether failed generations count toward cost budget
* whether subscriber usage caps are daily, monthly, or rolling
* emergency kill-switch conditions

Example policy questions:

```text
If Premium costs spike:
  do we switch Premium provider?
  do we lower max retries?
  do we temporarily route to Standard?
  do we pause generation?
  do we notify users?

If Standard free usage spikes:
  do we require sign-in?
  do we lower free daily limit?
  do we switch provider?
  do we disable anonymous generation?
```

Premium must not mean “whatever the expensive model costs today.”

## Security And Privacy Model

A gateway changes the privacy posture because user text flows through ProsePal-controlled infrastructure before provider routing.

Before production gateway rollout, define:

* authentication model
* anonymous identity policy
* App Check, device attestation, or equivalent server enforcement
* API abuse controls
* rate-limit keys
* prompt and content retention policy
* provider data-retention settings
* provider data processor list
* PII minimisation rules
* secrets management
* audit logs for model/provider config changes
* redaction rules for telemetry
* access controls for logs
* incident response path for provider or gateway leak
* privacy-policy update requirements
* App Store disclosure update requirements

Greeting-card inputs can contain soft PII:

* names
* family relationships
* grief or sympathy details
* health hints
* apologies
* romantic relationships
* workplace context
* personal events

The architecture must treat generation content as sensitive by default.

## Provider And Model Config

Provider and model selection should be configuration-driven.

Example conceptual config:

```yaml
lanes:
  standard:
    provider: open_model_provider
    model: current-standard-model
    daily_free_limit: 3
    timeout_ms: 12000
    max_retries: 1

  premium:
    provider: frontier_provider
    model: current-premium-model
    timeout_ms: 20000
    max_retries: 2

  template:
    provider: local_template
    model: none
```

This is conceptual only. The final implementation may use Remote Config, server environment variables, database config, or another controlled configuration path.

Rules:

* do not use `latest` aliases for production
* pin stable model IDs where possible
* make lane names stable even when provider models change
* keep provider secrets server-side
* never put provider API keys in the client
* keep kill switches and rollback paths explicit
* audit model/provider config changes
* require approval for production lane changes

## Operational Rollback Ladder

Gateway rollout should have multiple rollback levels.

Possible rollback options:

1. disable Premium lane
2. disable a specific Premium provider
3. disable Standard provider and use alternate Standard provider
4. disable anonymous free generation
5. disable gateway routing for new app versions
6. return eligible app versions to the archived client-direct Firebase AI path where supported
7. disable model generation and use template fallback
8. disable generation entirely with user-safe messaging

Rollback should not depend on a mobile app release.

Rollback controls should be server-side wherever possible.

Each rollback level should define:

* trigger condition
* owner
* user impact
* telemetry expectation
* support message
* restoration path

## Stage Decision Gates

This strategy should be implemented in stages only after explicit approval.

### Stage 0: Document And Decide

Purpose:

* agree product language
* agree Standard and Premium lane definitions
* agree that model names are implementation details
* agree how archived client-direct behavior is used as an eval baseline

Entry criteria:

* strategy document reviewed
* archived production runtime documented
* no production routing change in scope

Exit criteria:

* strategy document approved as direction only
* proposed backlog items identified
* ADR trigger criteria agreed

Production guardrail:

* no gateway code required
* no provider keys required
* no production runtime changes

### Stage 1: Non-Production Router Spike

Purpose:

* build a server-side generation interface in staging or local development
* prove adapter boundaries
* avoid changing production runtime

Entry criteria:

* ADR or spike ticket approved
* provider keys available only in non-production, if needed
* mock adapter planned first; server-side template fallback only if explicitly
  approved
* no production config values changed
* no production model routing changed

Exit criteria:

* gateway accepts conceptual `CardRequest`
* gateway returns conceptual `CardResponse`
* mock adapter passes contract tests
* server-side fallback adapter passes contract tests if explicitly in scope
* at least one experimental model adapter can be tested outside production
* no production user traffic uses the gateway

Production guardrail:

* App Store production runtime is not changed by strategy work alone
* provider/model config is unchanged unless a separate release decision approves
  it

### Stage 2: Eval Harness

Purpose:

* compare Standard, Premium, archived production, and fallback candidates
* score message quality using ProsePal-specific criteria

Entry criteria:

* scenario format defined
* baseline production outputs available or reproducible
* rubric drafted
* eval owner named

Exit criteria:

* 50 to 100 scenario eval set exists
* golden set identified
* challenge set identified
* Standard threshold drafted
* Premium uplift threshold drafted
* sensitive-occasion threshold drafted
* archived production baseline captured

Production guardrail:

* eval output does not reach users unless explicitly approved
* no model promotion from eval spike alone

### Stage 3: Usage And Entitlement Policy

Purpose:

* define free and subscriber limits
* connect generation lanes to entitlement
* prevent abuse

Entry criteria:

* authentication source proposed
* entitlement source proposed
* anonymous free-tier policy proposed
* cost envelope drafted
* privacy model drafted

Exit criteria:

* free limit policy defined
* subscriber allowance policy defined
* StoreKit 2 and App Store server entitlement source selected
* anonymous-abuse limitations accepted
* server-side enforcement design drafted
* budget owner identified

Production guardrail:

* no paid-user routing change without entitlement verification
* no anonymous free limit launch without abuse review

### Stage 4: Controlled Gateway Rollout

Purpose:

* route a small controlled slice through the gateway
* preserve rollback to archived Firebase AI path where supported

Entry criteria:

* ADR approved
* privacy review complete
* cost envelope approved
* fallback policy approved
* rollback ladder implemented
* telemetry redaction approved
* eval thresholds met
* SLO targets defined
* hosting and compute model selected
* request verification approach selected

Exit criteria:

* staging rollout criteria met
* internal tester rollout criteria met
* no unacceptable latency regression
* no unacceptable quality regression
* no privacy or telemetry violations
* no concurrency or timeout issue under expected load
* rollback tested

Production guardrail:

* rollout flag required
* immediate server-side rollback required
* no broad production rollout from first gateway deployment

### Stage 5: Production Lane Promotion

Purpose:

* make Standard and Premium generation real product capabilities

Entry criteria:

* controlled rollout criteria met
* Standard does not meaningfully regress against archived free-user baseline
* Premium demonstrates measurable uplift over Standard
* entitlement enforcement verified
* paid fallback semantics approved
* support copy approved
* App Store/privacy disclosures updated where needed

Exit criteria:

* Standard lane active for approved user segment
* Premium lane active for approved subscriber segment
* budget alerts active
* provider health alerts active
* degradation telemetry active
* rollback ladder remains available

Production guardrail:

* lane promotion can be reversed server-side
* model/provider promotion requires eval evidence

## Relationship To Client Strategy

This document is client-agnostic.

It supports:

* archived Flutter app
* active SwiftUI iOS client
* possible web client
* possible Android client later

The target client should call a ProsePal-owned generation contract rather than embedding model/provider logic.

For the active SwiftUI rewrite, the required direction is:

```text
SwiftUI app
  -> ProsePal API / AI Gateway
```

not:

```text
SwiftUI app
  -> Firebase AI / Vertex AI directly
```

This does not reintroduce Flutter production routing to active `main`. Native
iOS work remains gateway-first/careful-lane aware; App Store production
replacement remains a separate release decision.

## Relationship To Existing Backlog

This strategy document provides architecture context for native and future AI
work. Open implementation work lives in `docs/BACKLOG.md`.

Relevant backlog relationships:

* `N-IOS-02`: staging gateway reliability and operator runbook.
* `N-IOS-03`: native auth token path into gateway requests.
* `N-IOS-04`: server-authoritative usage and entitlement state.
* `N-IOS-11`: native privacy, logging, and diagnostics hardening.
* `N-IOS-12`: future local Standard generation spike.

## Candidate Backlog Items

These are proposed candidate tickets, not approved work.

```text
AI-GW-ADR-01:
  Draft gateway trigger ADR

AI-GW-SPIKE-01:
  Define CardRequest/CardResponse contract

AI-GW-SPIKE-02:
  Build mock adapter and any approved server-side fallback adapter in non-production

AI-GW-SPIKE-03:
  Build one experimental Standard adapter in non-production

AI-EVAL-01:
  Create 75-scenario ProsePal eval set

AI-EVAL-02:
  Define Standard/Premium promotion thresholds

AI-EVAL-03:
  Capture archived production baseline outputs

AI-OPS-01:
  Define AI cost budget, alerts, owner, and degradation policy

AI-OPS-02:
  Define gateway hosting, concurrency, timeout, and backpressure model

AI-PRIV-01:
  Define gateway telemetry redaction and retention policy

AI-PRIV-02:
  Review provider and aggregator data-processing implications

AI-ENT-01:
  Define authentication and entitlement source of truth

AI-ENT-02:
  Define anonymous free-tier policy and abuse limitations

AI-REQ-01:
  Define gateway request verification and App Check or attestation approach

AI-UX-01:
  Define fallback and degraded-generation copy

AI-UX-02:
  Define paid-user fallback disclosure and retry policy

AI-UX-03:
  Define non-streaming generation loading and retry UX

AI-SLO-01:
  Define Standard, Premium, and fallback latency targets

AI-ROLLBACK-01:
  Define and test gateway rollback ladder

AI-CONTRACT-01:
  Define mobile contract versioning and old-app compatibility policy
```

## Future ADR Trigger

Create an Architecture Decision Record only when ProsePal is deciding whether to actually build and roll out the server-side gateway.

The ADR should cover:

* trigger criteria, such as abuse threshold, provider-failover need, model policy requirement, cost-control need, quality-evaluation need, or monetisation trigger
* server-hop tradeoff and operational cost
* gateway hosting and compute model
* concurrency and long-lived request behaviour
* Standard and Premium lane definitions
* free-user allowance
* subscriber allowance
* authentication source of truth
* entitlement source of truth
* gateway request verification and App Check or attestation policy
* approved provider set
* approved model classes
* provider data-processing review
* production rollout plan
* staging or non-production spike path
* parity tests against the archived client-direct path
* backward compatibility for old app versions
* failure and rollback behaviour
* telemetry and redaction contract
* cost-budget owner and alert path
* model evaluation threshold before promotion
* latency and SLO targets
* streaming, synchronous request, or async polling decision
* App Store and privacy implications
* support messaging for degraded generation

Until those criteria are met and approved, App Store production replacement must
not be promoted by accident. The archived client-direct path remains an eval and
rollback reference.

## Why This Matters

A provider-agnostic AI layer reduces hard dependency on one model provider. The product depends on the message-writing capability rather than one provider SDK or one model ID.

This matters because:

* model IDs and provider APIs can be deprecated or changed
* free tiers can disappear or change limits
* production reliability improves when fallback paths are explicit
* provider switching becomes an operational decision instead of a mobile app rewrite
* quality evals can compare prompts, providers, and model classes against the same product contract
* cost controls can route simple work to cheaper paths while preserving quality for paying users
* diagnostics can explain behaviour using stable ProsePal concepts instead of provider-specific payloads
* subscribers can justify the cost of Premium generation
* free users can still try the app without giving the product an uncapped AI bill

The gateway direction is valuable, but it is not free. It adds a new production service, a new privacy surface, and a new operational responsibility. That tradeoff must be made deliberately.
