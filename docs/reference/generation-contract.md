# Generation Contract Reference

This reference describes the versioned request and response boundary shared by
the native gateway client and `generate-card`. It covers wire shape and limits,
not product routing policy or provider configuration.

## Ownership

- Swift types: `prosepal-ios/Sources/ProsePalDomain/CardModels.swift`
- Shared native text limits: `prosepal-ios/Sources/ProsePalDomain/TextInputPolicy.swift`
- Native transport: `prosepal-ios/Sources/ProsePalAPI/GatewayMessageWritingClient.swift`
- Server parser: `supabase/functions/generate-card/index.ts`

Both prompt and output contract versions are currently `1`. The server rejects
unsupported versions, and the app rejects a successful response carrying
versions it cannot read.

## Request

`CardRequest` is encoded as snake-case JSON and sent with `POST`:

| Field | Type | Rule |
|---|---|---|
| `idempotency_key` | String | Required; 1–120 characters matching `[A-Za-z0-9._:-]` |
| `intent` | `CardIntent` | Required structured writing intent |
| `requested_lane` | Enum | `automatic`, `standard`, `premium`, or `local` |
| `client_context` | Object | App/build/platform metadata; excluded from request identity |
| `prompt_contract_version` | Integer | Must equal the server-supported version |
| `output_contract_version` | Integer | Must equal the server-supported version |

The same idempotency key is also sent in the `Idempotency-Key` header. The
server rejects a body/header mismatch before provider work.

## Card intent

| Field | Type | Server constraint |
|---|---|---|
| `occasion` | `Occasion` raw value | Must be a current native enum value |
| `relationship` | `Relationship` raw value | Must be a current native enum value |
| `tone` | `Tone` raw value | Must be a current native enum value |
| `length` | `MessageLength` raw value | `brief`, `standard`, or `detailed` |
| `spelling_preference` | String | `automatic`, `us`, or `uk`; native default is `automatic` |
| `locale_identifier` | String | Single-line normalization; capped at 40 graphemes |
| `recipient_name` | Optional string | Single-line normalization; capped at 80 graphemes |
| `things_to_include` | String array | At most 12 entries, each outer-trimmed and capped at 1,200 graphemes |
| `things_to_avoid` | String array | At most 12 entries, each outer-trimmed and capped at 1,200 graphemes |
| `user_context` | Optional string | Outer-trimmed and capped at 4,080 graphemes so the fixed adjustment wrapper can carry a full 4,000-grapheme draft |

The complete occasion, relationship, and tone vocabularies are owned by the
native enums in `CardModels.swift` and mirrored by the gateway parser. A change
to either side must update both contract suites; there is not yet one generated
cross-language enum source.

## Native text limits

These limits apply before native persistence or generation ingress:

| Content | Maximum characters |
|---|---:|
| Person name | 80 |
| Moment detail | 1,200 |
| Truth Bead | 500 |
| Voice Card | 500 |
| Draft text | 4,000 |
| Gateway `user_context` wire value | 4,080 |

Person names are collapsed to one line. Other native text inputs are trimmed at
their outer whitespace and capped without adding invented content. Native and
gateway limits count Unicode extended grapheme clusters, matching user-perceived
characters such as emoji, composed accents, and zero-width-joiner sequences. The
gateway preserves accepted wording and internal line structure in include,
avoid, and context fields. Ordinary instruction-looking language is not
filtered. Only provider prompt rendering neutralizes narrowly defined machine
control tokens with grapheme-count-preserving markers. User values are JSON
inside an explicitly delimited quoted-data region, with a system instruction
that they are not executable instructions. This rendering does not change the
accepted request, request identity, or include/avoid checks.
Private `PrivateDraftPromptPlan` likewise places quoted user values inside a
delimited data region, neutralizing delimiter collisions only when rendering.

The gateway adjustment mapping uses the existing `user_context` field. Its
4,080-character wire budget is the 4,000-character accepted draft bound plus 80
characters for the longest current register description, one newline, and the
fixed `Current message to reshape: ` label. Initial requests use only the short
register description.

## Request identity

The server hashes these provider-affecting fields with SHA-256:

- `intent`;
- `requested_lane`;
- `prompt_contract_version`; and
- `output_contract_version`.

`client_context` is excluded. Updating the app version or build number must not
turn the same pending generation into an idempotency conflict. Identity uses
preserved accepted text, before provider-only control-token rendering.

## Response

`CardResponse` uses snake-case JSON:

| Field | Type | Meaning |
|---|---|---|
| `messages` | `[GeneratedMessage]` | Structured generated options; gateway success contains three distinct, non-empty messages |
| `lane_used` | `GenerationLane` | Server lane that produced the response |
| `fallback_status` | `FallbackStatus` | `none`, `degradedToStandard`, or `failed` |
| `quality_check` | Optional object | Pass flag and optional user-safe note |
| `usage` | Optional object | Structured `remaining`, `limit`, and `resets_at` values when supplied by policy |
| `retry_eligibility` | Enum | `eligible`, `ineligible`, or `waitBeforeRetry` |
| `user_safe_error` | Optional object | Stable code and display-safe message |
| `prompt_contract_version` | Integer | Version used for prompt construction |
| `output_contract_version` | Integer | Version of the response contract |

The native client requires readable contract versions and at least one message.
`ProsePalTextInput.generatedDraft` is the shared validator for private output,
gateway draft ingress, and gateway response validation. After outer trimming,
each generated draft must be non-empty, contain at least one Unicode letter or
number, and contain no more than 4,000 extended grapheme clusters. Exactly 4,000
succeeds; 4,001, punctuation-only, whitespace-only, and emoji-only output fail.
`Ok.` and `1` are usable. Unusable generated output throws the typed
`GenerationError.unexpectedResponse`; it is never truncated into validity.
Existing user-edit caps and lane fallback/online-permission policy are unchanged.

The gateway drops unusable provider candidates before formatting normalization
and validates them again afterward. Fewer than three usable candidates follows
the existing quality-failure/provider-fallback path. `normalizedMessageContent`
provides one letters/numbers/whitespace-normalized definition for candidate
textual content and duplicate fingerprints. Avoid checks compare preserved
accepted phrases with case and whitespace normalization only.
`messages` order has no ranking semantics; every gateway candidate is subject to
the same response quality gate.

The gateway evaluates recognized trailing sign-offs while provider line
structure is still available, then normalizes remaining whitespace. An exact
recognized whole-option closing is removed and therefore rejected as unusable.
A terminal closing block is removed from a message body only when a blank line
separates the two, which provides formatting evidence beyond capitalization and
line position. The closing block may contain an exact recognized sign-off, a
same-line signature, or a signature on the immediately following line; supported
signatures contain up to four capitalized name-like tokens joined by `&` or
lowercase `and`. A closing-like block separated by only one line break is
discarded as an ambiguous candidate rather than being rewritten into a shorter
message. Other questionable closing prose that does not match the narrow closing
shape is retained. These structural rules do not classify arbitrary prose or
invent additional closing variants.

## HTTP and error mapping

| Status | Native result |
|---|---|
| `2xx` | Decode and validate `CardResponse` |
| `401` | Auth/configuration-safe error |
| `402`, `403` | Usage or entitlement limit |
| `408` | Gateway timeout |
| `409` | In-flight, replay-expired, or idempotency-conflict handling |
| `422` | Content blocked |
| `425`, `429` | Rate limited |
| `499` | Server reports caller cancellation; native transport currently has no explicit case and maps a received response to `unexpectedResponse` |
| `5xx` | Service unavailable |

Normal client-initiated transport cancellation stays cancellation, usually through
`URLError.cancelled`. A received HTTP 499 is a narrower, different path: the
native default status branch makes it fallback-eligible where routing permits.
Server cancellation attempts failed finalization; an unconfirmed RPC outcome
is not proof of no charge.

Connectivity failures map to offline, and provider details never become part of
the public response type.

## Related documentation

- [AI generation](../engineering/ai-generation.md)
- [Gateway request ledger](../engineering/gateway-request-ledger.md)
- [Configuration](./configuration.md)
- [Testing](../quality/testing.md)
