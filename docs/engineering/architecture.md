# Native Architecture

ProsePal is an iOS 26-first SwiftUI application with a Swift package supplying
domain, service, and UI modules. The app target composes concrete Apple and
Supabase clients at the root; feature views depend on provider-neutral
boundaries.

## System map

```text
ProsePal app target
  -> MomentAppRootView
     -> MomentModel
        -> MessageWritingService
           -> FoundationModelsPrivateDraftClient
           -> GatewayCarefulMomentClient
              -> GatewayMessageWritingClient
     -> MomentAccountModel
        -> AuthSessionController / SupabaseAuthClient
        -> StoreKitSubscriptionClient
        -> SupabaseAccountMaintenanceClient
     -> SwiftData relationship vault

Optional entry points
  -> App Intent / Shortcuts
  -> Widget and Control
  -> Share Extension
  -> sanitized Moment launch request
```

Their handoff and trust boundary is documented in
[System surfaces](./system-surfaces.md).

## Module responsibilities

| Module | Responsibility |
|---|---|
| `ProsePalDomain` | Stable product taxonomy, card contracts, text limits, Moment input, draft bundles, and pressure feedback. |
| `ProsePalAPI` | Generation routing, gateway transport, Foundation Models, auth/session control, StoreKit, runtime configuration, and vault services. |
| `ProsePalUI` | SwiftUI surfaces and observable app models; it does not know provider SDKs or privileged backend details. |
| `App` | Dependency composition, target configuration, entitlements, assets, and application lifecycle. |
| `supabase/functions` | Authenticated server boundaries for generation, account deletion, Apple-token exchange, feedback, and App Store events. |
| `supabase/migrations` | Database policy, quota, entitlement, request-ledger, privilege, and cleanup changes. |

## State ownership

`MomentModel` owns the active Moment, generation task, retry state, current
draft, and draft snapshots. Generation counters and task cancellation suppress
late results after the user changes the Moment or starts over.

`MomentAccountModel` owns sign-in presentation, current account state,
subscription products, entitlement convergence, transaction updates, and
account-maintenance actions.

SwiftData owns Truth Beads, Voice Cards, and deliberately saved drafts. Active
draft recovery is separate so relaunch recovery does not silently turn every
generation into saved history. See [Relationship vault](./relationship-vault.md)
for persistence, migration, export, and prompt-memory rules.

## Dependency rules

- SwiftUI calls `MessageWritingService`, never a provider SDK.
- Product code uses `SubscriptionClient`, `AuthClient`, and
  `AccountMaintenanceClient` protocols so tests can remain deterministic.
- Provider/model details stay behind the gateway or Foundation Models client.
- Privileged Supabase keys stay in Edge Functions and never enter an app
  bundle.
- Runtime failures become typed, user-safe domain errors before reaching views.

## Concurrency and cancellation

The native package uses Swift 6 concurrency. Actor-isolated session, request-key,
and model state serialize shared mutations. Generation timeouts race a transport
operation against an injected timeout policy; cancelling the winner’s task group
cancels the losing operation before any fallback begins.

## Data boundaries

```text
User-entered content
  -> active Moment memory
  -> Foundation Models on device, or sanitized gateway request
  -> optional explicit local save

Operational metadata
  -> privacy-safe OSLog / Edge logs
  -> no raw names, message text, tokens, receipts, or provider payloads
```

See [Data and privacy](./data-and-privacy.md) for retention and storage details.

## Evolution rules

- Add SwiftData model changes through `RelationshipVaultSchema` and
  `RelationshipVaultMigrationPlan`.
- Extract a touched SwiftUI surface when its boundary is safe; do not replace
  the main Moment view in one untestable refactor.
- Add behaviour behind an injectable boundary and deterministic tests.
- Keep optional system surfaces subordinate to the core app launch path.

## Source map

- `prosepal-ios/App/ProsePalNativeApp.swift`
- `prosepal-ios/Sources/ProsePalDomain/`
- `prosepal-ios/Sources/ProsePalAPI/`
- `prosepal-ios/Sources/ProsePalUI/`
- `supabase/functions/`
- `supabase/migrations/`

Historical design rationale remains in
[Native 2026 technical direction](../history/architecture/native-2026-technical-direction.md).
