# Native iOS Architecture

## Boundary

`prosepal-ios/` is a native client rewrite area, not a provider-routing system.
The app depends on `MessageWritingClient`, which is a ProsePal-owned generation
port.

```text
SwiftUI View
  -> ViewModel
  -> MessageWritingClient
  -> CardRequest
  -> CardResponse
```

The gateway decides whether a request is served by Standard, Premium, local,
template, or future provider-backed lanes.

## Product Lanes

Standard and Premium are product lanes, not model names. The UI may describe:

- Standard generation
- Premium generation
- enhanced generation
- higher limits
- retry shortly

The UI must not name model providers or model IDs.

## Error Handling

The client handles user-safe failure categories:

- offline
- timed out
- rate limited
- usage limit reached
- content blocked
- service unavailable
- degraded generation
- unexpected response

Provider errors are mapped behind the gateway boundary. The app can display a
safe message and retry affordance, but it must not surface upstream resource
paths or model/provider names.

## Observability

Allowed client-side telemetry fields:

- generation lane requested
- generation lane used
- fallback status
- retry eligibility
- contract versions
- timeout bucket
- error bucket
- app version

Disallowed telemetry fields without explicit privacy approval:

- raw card text
- raw personal details
- provider payloads
- provider URLs
- provider model IDs
- tokens or secrets

