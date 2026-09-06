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
| `locale_identifier` | String | Sanitized to 40 characters |
| `recipient_name` | Optional string | Sanitized to 80 characters |
| `things_to_include` | String array | At most 12 entries, each sanitized to 160 characters by the gateway |
| `things_to_avoid` | String array | At most 12 entries, each sanitized to 160 characters by the gateway |
| `user_context` | Optional string | Sanitized to 1,200 characters |

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
| Draft text or internal user context | 4,000 |

Person names are collapsed to one line. Other native text inputs are trimmed at
their outer whitespace and capped without adding invented content.

## Request identity

The server hashes these provider-affecting fields with SHA-256:

- `intent`;
- `requested_lane`;
- `prompt_contract_version`; and
- `output_contract_version`.

`client_context` is excluded. Updating the app version or build number must not
turn the same pending generation into an idempotency conflict.

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

The native client requires readable contract versions, at least one message,
and no blank message text before returning success to the writing service.
`messages` order has no ranking semantics; every gateway candidate is subject to
the same response quality gate.

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
