# AI Generation

ProsePal exposes two product lanes through one provider-neutral writing service.
The UI asks for a draft; routing and transport details remain below that
boundary.

## Lanes

| Lane | Use | Implementation |
|---|---|---|
| Private Draft | Everyday writing where the device model is available | Apple Foundation Models on device |
| Careful | Automatic treatment for sensitive or higher-stakes occasions and eligible fallback | ProsePal `generate-card` gateway |

Careful routing is derived from occasion policy and is not a subscription gate.
Premium controls paid limits and future extras, not whether a hard moment
receives careful treatment. The lane is not a user-selected rewrite action.

## Routing

```text
MomentInput
  -> safety/refusal gate
  -> occasion/register routing decision
     -> ordinary initial draft: private first
     -> careful initial draft: gateway first
  -> eligible failure may start the other lane
  -> content block never falls through
```

For an ordinary initial draft, private timeout, busy/rate, stale request-key,
runtime-unavailable, malformed-response, and untyped failures may fall back to
the careful client. Offline, usage-limit, content-block, and cancellation
results do not. For an initial draft that requires careful treatment, any typed
generation error except a content block may fall back to the private client;
untyped failure may also fall back, while cancellation does not.

Named adjustment follows the current bundle's lane. A private or mock draft is
adjusted on device first and has the eligible private-to-careful fallback. A
`standardDraft` or `careful` bundle is adjusted through the gateway only. The
Another/rewrite action is a fresh initial draft for the current Moment rather
than an adjustment, so it re-enters initial routing and does not send the old
draft as rewrite context.

Timeouts, offline state, usage limits, rate limits, malformed responses, and
provider refusals map into `GenerationError`. Views receive stable product
errors rather than provider-specific exceptions. If routing ends in failure or
cancellation, `MomentModel` does not replace the current draft; the Moment and
recoverable wording remain available.

The implementation does not yet require a separate explicit online-writing
permission before direct careful work or private-to-careful fallback. That
boundary is owned by backlog slice I-1.

## Writing content boundary

Private generation uses person, relationship, occasion, style, locale, Moment
detail, and approved matching Truth Beads and Voice Card on the device. A
private adjustment also uses the current draft and adjustment name.

Careful generation sends the bounded `CardRequest` to the ProsePal gateway. Its
writing content is person name, relationship, occasion, tone, length, locale,
Moment detail, and the register description; an adjustment also sends the
current draft and adjustment name. Relationship-vault records are not included
in the gateway request. The request also carries app/build/platform and request-
identity metadata plus the applicable auth boundary.

After reservation, `generate-card` builds a structured prompt from those
writing fields. It may send the same prompt sequentially to configured primary
and fallback models at the configured provider endpoint. The production
provider binding and its retention, training, and data-use terms are not
established by repository source. The complete storage, retention, export, and
deletion map is [Data and privacy](./data-and-privacy.md).

## Generation lifecycle

`MomentModel` is the only UI-layer owner of generation tasks. Initial writing,
retry, rewrite, and named adjustments all enter one retained lifecycle.
The model cancels obsolete work when the user chooses Stop, resets, changes any
meaning-bearing input, dismisses the composer, backgrounds the app, or starts a
superseding request. A generation identity prevents a cancelled dependency from
overwriting a newer result even if that dependency returns late.

`RoutingMessageWritingService` owns the injected per-lane timeouts and one total
technical deadline. Cancellation is checked before and after each lane and
before every fallback, so cancelled work cannot silently start another route.
The Foundation Models client cooperates around memory lookup and model response;
the gateway client cooperates around request identity, transport, and response
handling.

## Gateway request lifecycle

```mermaid
sequenceDiagram
  participant App as iPhone app
  participant Auth as Auth session
  participant Edge as generate-card
  participant DB as Request ledger
  participant AI as Configured provider

  App->>Auth: Request usable access token
  Auth-->>App: Current or safely refreshed token
  App->>Edge: CardRequest + idempotency key
  Edge->>Edge: Authenticate, sanitize, validate
  Edge->>DB: Reserve request, burst and quota capacity
  alt completed duplicate
    DB-->>Edge: Replay cached safe response
    Edge-->>App: Same CardResponse, no provider call or charge
  else rejected or in flight
    DB-->>Edge: User-safe policy outcome
    Edge-->>App: Error, no provider call
  else reserved
    DB-->>Edge: Reservation token and usage summary
    Edge->>AI: Structured prompt, request signal + bounded provider budget
    AI-->>Edge: Structured candidates
    Edge->>Edge: Quality and leakage checks
    Edge->>DB: Finalize completed or failed
    Edge-->>App: CardResponse or user-safe error
  end
```

The provider call begins only after the database reservation succeeds. A failed
provider or quality attempt does not consume user usage. A successful finalize
consumes usage once. If the incoming request is cancelled after reservation,
the Edge Function aborts the active provider fetch, does not start another
fallback model, and finalizes the reservation as failed.

Gateway success carries three distinct candidates with equal contract status.
Array order is transport order, not a quality ranking or a declaration that the
first candidate is best.

Request identity, reservation leases, atomic quota decisions, replay, and
retention are specified in [Gateway request ledger](./gateway-request-ledger.md).

## Gateway validation

The Edge Function:

- verifies authenticated JWTs through Supabase Auth;
- permits anonymous development only when both the explicit development flag
  and configured development secret are present;
- caps and sanitizes every input field;
- enforces supported contract and lane versions;
- reserves burst and quota capacity atomically;
- uses a bounded provider request with configured fallbacks;
- propagates incoming request cancellation into the provider fetch and stops
  fallback attempts;
- requires three distinct structured messages;
- rejects generic filler, provider leakage, and sensitive-occasion failures;
- logs metadata only; and
- finalizes usage only after output passes quality checks.

## Contracts

`CardRequest` and `CardResponse` form the versioned provider-neutral wire
boundary. Field shapes, text limits, response validation, and HTTP mapping live
in [Generation contract reference](../reference/generation-contract.md).

## Verification

```bash
deno check supabase/functions/**/*.ts
deno test --allow-env supabase/functions/generate-card/index.test.ts
supabase test db
./scripts/test_gateway_ledger_concurrency.sh
```

See [Staging](../operations/staging.md) before any remote proof. The longer
pre-implementation strategy is preserved in
[AI Gateway Strategy 2026](../history/architecture/ai-gateway-strategy-2026.md).
