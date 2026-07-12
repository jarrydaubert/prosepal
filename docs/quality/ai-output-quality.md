# How to Evaluate AI Output Quality

Use this procedure to review generated-message quality without mixing provider
experiments, prompt changes, or real user content into ordinary test runs. The
canonical criteria and synthetic cases live in
[Writing quality rubric](./writing-quality-rubric.md).

## Prerequisites

- Choose the private or careful lane being evaluated.
- Use only the synthetic scenarios in the rubric or another reviewed synthetic
  fixture.
- Choose an evidence folder following [Release evidence](./release-evidence.md).
- Obtain explicit repository-owner approval before a live or staging provider
  call, paid quota use, or retained generated sample.

Local contract, parser, scorer, and fixture work does not require a provider
call. It must remain deterministic and content-safe.

## 1. Record the evaluation identity

At the top of the evidence, record:

- rubric version;
- scenario IDs;
- lane under review;
- deterministic fixture, on-device model, or approved gateway path;
- app/gateway contract version;
- backend/model slot when applicable; and
- reviewer name or stable local reviewer label.

Record an exact model identifier only in a trusted private release location.
Do not place provider URLs, credentials, private billing data, or tokens in the
evidence.

## 2. Run deterministic checks first

Run the ordinary native and gateway gates before judging prose:

```bash
cd prosepal-ios
swift test
cd ..
deno test --allow-env supabase/functions/generate-card/index.test.ts
```

Deterministic writing-quality coverage should check:

- preservation of supplied words and facts;
- invented personal facts;
- requested register, tone, and length;
- guilt, coercion, or reassurance pressure;
- generic filler and greeting-card mush;
- provider or internal implementation language;
- schema validity and distinct non-empty options; and
- scorer abstention when a criterion does not apply.

Scorers for subjective properties are advisory until exemplar tests show that
their pass, concern, fail, and not-applicable decisions match reviewed examples.
Automation never replaces human review of warmth, humour, grief, apology, or
non-cringe wording.

## 3. Generate or select samples

For deterministic development, use synthetic committed fixtures and fake model
clients. For approved live review, follow [Staging](../operations/staging.md)
and run only the named scenario subset against the approved lane.

Capture:

- the exact synthetic input;
- the generated options or primary draft;
- the route/lane, without exposing provider details publicly; and
- any user-safe refusal or failure instead of replacing it with a fabricated
  draft.

Never capture a real personal message, recipient name, relationship-memory
record, token, or secret.

## 4. Score each sample

Apply every criterion in the rubric. Use `Not applicable` with a short reason
instead of forcing a pass when a criterion cannot be judged.

Any `Fail` for invented facts, preservation of the user’s meaning, coercive
pressure, sensitive-occasion appropriateness, or provider/internal leakage
blocks the sample set. Other failures require triage against the intended
release bar rather than being averaged away.

Record concerns as concrete text behaviour. “Feels off” is not actionable;
“adds an invented shared holiday memory” is.

## 5. Compare both writing lanes

When a release changes shared prompts, contracts, routing, or output handling,
review representative private and careful samples separately. Do not feed a
careful-lane fixture through the private client and call the result careful-lane
evidence.

Live suites remain independently gated:

- private/on-device suite: supported physical device and model availability;
- careful/gateway suite: approved staging configuration and provider quota.

## 6. Store evidence

Use:

```text
artifacts/release/<release-tag>/ai-output-quality/
```

Suggested files:

- `01-evaluation-identity.md`
- `02-scenario-results.md`
- `03-automated-checks.md`
- `04-reviewed-samples.md`
- `05-failures-and-remediation.md`
- `06-final-decision.md`

The `artifacts/` path is release evidence, not evergreen documentation. Keep it
outside Git unless the repository owner explicitly approves a redacted tracked
artifact.

## 7. Make the decision

A pass requires:

- deterministic contract and scorer checks passing;
- every required scenario reviewed;
- no blocking rubric failure;
- concerns either fixed or explicitly accepted by the release owner; and
- retained evidence containing no real user content or secrets.

Prompt, model, routing, generation-parameter, Supabase, or production-setting
changes are separate implementation work. Re-run the affected deterministic and
human evaluation after any such change.

## Approval boundary

Explicit approval must name the environment, lane/backend path, scenario subset,
evidence destination, quota/cost permission, and whether generated text may be
retained. Approval to evaluate does not authorize a prompt, model, deployment,
or production configuration change.
