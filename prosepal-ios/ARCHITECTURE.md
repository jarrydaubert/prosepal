# Native iOS AI Architecture

This note captures the agreed long-term native AI direction. No LiteRT-LM
dependency is currently added, no Gemma model files are downloaded or committed,
and the current staging gateway behavior is unchanged.

## Boundary

`prosepal-ios/` is a native client rewrite area, not a provider-routing system.
The app depends on `MessageWritingClient`, which is a ProsePal-owned generation
port.

```text
SwiftUI View
  -> ViewModel
  -> MessageWritingClient / MessageWritingRouter
  -> CardRequest
  -> CardResponse
```

The app should depend on the generic message-writing port, with implementations
such as:

- `LocalMessageWritingClient`
- `GatewayMessageWritingClient`
- `MockMessageWritingClient`

The UI and product copy must not know whether a message was produced by Gemma,
OpenRouter, Claude, GPT, or any other provider/model ID.

## Target Architecture

```text
SwiftUI app
  -> ProsePalAppModel
  -> MessageWritingRouter
      -> Standard lane
          -> GatewayMessageWritingClient today
          -> LocalMessageWritingClient later
          -> LiteRT-LM runtime in app
          -> downloaded on-device model in Application Support
      -> Premium lane
          -> GatewayMessageWritingClient
          -> Supabase gateway
          -> auth / abuse controls / entitlements / usage policy
          -> model router
          -> cloud provider adapters
      -> Mock lane
          -> MockMessageWritingClient for tests and previews
```

## Product Lanes

Standard and Premium are product lanes, not model names.

Target routing:

- Standard today: gateway-backed generation while the local model work is not
  implemented.
- Standard target: local on-device drafts.
- Premium: cloud/frontier drafts through the Supabase gateway.

Product story:

- Standard gives private local drafts, offline use after model download, and no
  per-generation API cost.
- Premium gives more polished cloud drafts through the gateway, with stronger
  routing and entitlement policy behind the server boundary.

The UI may describe:

- Standard generation
- Premium generation
- enhanced generation
- higher limits
- retry shortly

The UI must not name model providers or model IDs.

## Local Model Direction

Preferred first local model spike:

- Gemma 4 E2B via LiteRT-LM.

Later evaluation:

- Gemma 4 E4B may be evaluated as a higher-quality local option if device
  performance, memory, thermal behavior, and download size are acceptable.

Not iPhone-first:

- 12B-class models are macOS/desktop experiment territory, not the initial
  iPhone Standard generation target.

The LiteRT-LM runtime/dependency may eventually live in the app binary. The
Gemma model binaries should not be bundled in the initial app binary.

## Model Storage And Download

Downloaded model files should live in app-private Application Support, for
example:

```text
Application Support/
  ProsePal/
    Models/
      standard/
        <model-version>/
          model files
          manifest.json
```

Storage rules:

- Download the Standard model on demand, not during initial install.
- Mark the model directory as excluded from iCloud/device backup with
  `isExcludedFromBackup`.
- Keep a versioned model manifest.
- Validate checksums before activating a downloaded model.
- Support interrupted download recovery.
- Handle low-storage errors with clear user-safe copy.
- Support model deletion from Settings or storage management.
- Keep the active model version separate from partially downloaded versions.
- Never commit model binaries to the repository.

Current native foundation:

- `LocalModelStore` defines the app-private Application Support directory
  shape for future Standard model files.
- It can create versioned model directories, mark them as excluded from backup,
  write/read a manifest, track the active version, list installed versions, and
  delete versions.
- It does not download model files, validate real checksums, run LiteRT-LM, or
  change current gateway behavior.

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

## Privacy And Logging

Allowed client-side telemetry fields:

- generation lane requested
- generation lane used
- fallback status
- retry eligibility
- contract versions
- timeout bucket
- error bucket
- app version
- local model availability state
- local model version ID
- local download progress bucket
- local download checksum result
- local storage error bucket

Disallowed telemetry fields without explicit privacy approval:

- raw card text
- raw personal details
- provider payloads
- provider URLs
- provider model IDs
- tokens or secrets
- raw local model prompts
- raw generated message text

Local Standard generation should not send card content to the gateway. Premium
generation sends structured intent to the Supabase gateway under the approved
privacy, logging, auth, entitlement, and abuse-control policy.

## Known Risks

- On-device quality may not match the current cloud-generated experience.
- E2B may be fast enough but not nuanced enough for sensitive occasions.
- E4B may improve quality but exceed acceptable memory, thermal, latency, or
  download-size limits on target iPhones.
- LiteRT-LM integration may add binary size, build complexity, and App Store
  review/privacy questions.
- Model downloads require storage management, resume support, integrity checks,
  and careful user messaging.
- Offline generation needs clear degraded-state UX when the model is missing,
  deleted, corrupt, or mid-download.
- Product copy must keep Standard/Premium language stable even as underlying
  implementations change.

## Gemma 4 E2B Spike Checklist

- Confirm LiteRT-LM licensing, distribution, and App Store compatibility.
- Measure app binary impact of adding the runtime without model weights.
- Define model manifest fields: model id, version, size, checksum, minimum app
  version, release channel, and download URL.
- Prototype on-device download into Application Support.
- Set `isExcludedFromBackup` on the model directory and verify it sticks.
- Validate checksum before activating the model.
- Test interrupted download resume and corrupt partial cleanup.
- Test low-storage behavior before and during download.
- Measure cold start, warm start, first-token latency, total generation latency,
  memory, battery, and thermal behavior on real devices.
- Compare E2B output quality against staging gateway outputs for core occasions.
- Test sensitive occasions such as sympathy, apology, encouragement, and pet
  loss with human review.
- Define user-safe offline/missing-model/deleted-model states.
- Confirm diagnostics log only metadata and never raw prompt/output text.
- Decide whether E4B deserves a second local-quality spike.
- Keep 12B experiments out of the iPhone-first implementation plan.
