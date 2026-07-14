# ProsePal Documentation

This is the canonical index for the native iOS product. Every active document
is reachable from this page and has one job. Open work belongs only in
[BACKLOG.md](./BACKLOG.md).

## Start here

| If you want to… | Read |
|---|---|
| Understand the app in plain English | [Native app guide](./guide/app-guide.html) |
| Know exactly what v1 launches with | [V1 launch contract](./product/v1-launch-contract.md) |
| See what the app can do | [Capabilities](./product/capabilities.md) |
| Understand the codebase | [Native architecture](./engineering/architecture.md) |
| Build the app for the first time | [Getting started](./operations/getting-started.md) |
| Work with staging | [Staging](./operations/staging.md) |
| Prepare a release | [Native release](./operations/release.md) |
| Find unresolved work | [Backlog](./BACKLOG.md) |

## Product

- [Product overview](./product/overview.md) — audience, promise, principles,
  business model, and boundaries.
- [V1 launch contract](./product/v1-launch-contract.md) — the narrow launch
  contract and non-goals.
- [Capabilities](./product/capabilities.md) — current native behaviour without
  roadmap claims.
- [User journeys](./product/user-journeys.md) — expected user-visible flows and
  integrity rules.

## Engineering

- [Native architecture](./engineering/architecture.md) — modules, state,
  dependencies, concurrency, and data boundaries.
- [SwiftUI architecture standard](./engineering/swiftui-architecture.md) —
  feature folders, state ownership, navigation, persistence, concurrency,
  previews, testing, and incremental extraction rules.
- [AI generation](./engineering/ai-generation.md) — private/careful routing,
  provider-neutral generation, validation, and fallback behaviour.
- [Gateway request ledger](./engineering/gateway-request-ledger.md) — atomic
  reservation, idempotency, quota, replay, charging, and retention.
- [Data and privacy](./engineering/data-and-privacy.md) — SwiftData, Keychain,
  recovery, logging, export, deletion, and sensitive data.
- [Relationship vault](./engineering/relationship-vault.md) — versioned local
  models, person matching, backup exclusion, export, erasure, and prompt memory.
- [Authentication and accounts](./engineering/auth-and-accounts.md) — Apple
  sign-in, Supabase session refresh, sign-out, and deletion.
- [Subscriptions and entitlement](./engineering/subscriptions.md) — StoreKit 2,
  transaction updates, server entitlement, and release proof.
- [System surfaces](./engineering/system-surfaces.md) — App Intent, Shortcuts,
  widget/control, Share Extension, and sanitized Moment handoff.

## Operations

- [Getting started](./operations/getting-started.md) — clean checkout to first
  successful native build.
- [Local development](./operations/local-development.md) — daily validation,
  CI, debugging, and failure handling.
- [Staging](./operations/staging.md) — internal target, secrets, guarded
  Supabase operations, device signing, and smoke proof.
- [Native release](./operations/release.md) — archive, TestFlight, acceptance,
  failure handling, and rollback.
- [Service ownership](./operations/service-ownership.md) — operational
  separation, identities, billing, secrets, and recovery ownership.

## Quality

- [Testing](./quality/testing.md) — deterministic test layers and commands.
- [AI output quality](./quality/ai-output-quality.md) — how to run and record a
  deterministic or approved live writing-quality review.
- [Writing quality rubric](./quality/writing-quality-rubric.md) — versioned
  scoring criteria, synthetic scenarios, and scorer rules.
- [Accessibility](./quality/accessibility.md) — native accessibility standard
  and release matrix.
- [Release evidence](./quality/release-evidence.md) — private evidence contract
  for non-local proof.

## Reference

- [Configuration](./reference/configuration.md) — public settings, local-only
  values, server secrets, and archive delivery.
- [Service endpoints](./reference/service-endpoints.md) — Edge Functions,
  database functions, and Apple boundaries.
- [Generation contract](./reference/generation-contract.md) — versioned request
  and response fields, input limits, identity, and HTTP mapping.
- [Feature status matrix](./reference/feature-status.csv) — detailed user-story
  implementation and evidence record.

## Project control

- [Backlog](./BACKLOG.md) — unresolved work only.
- [Documentation policy](./DOCS_POLICY.md) — ownership, evergreen rules, and
  validation.
- [Repository agent contract](../AGENTS.md) — canonical implementation and
  handoff rules.

## History

[History](./history/README.md) contains frozen Flutter references, earlier
architecture strategies, product explorations, App Review lessons, design
mockups, and release evidence. Historical documents explain past decisions; they
must not be used as current implementation instructions.

The web design-system source remains in [`design-system/`](../design-system/)
and agent skill manuals remain in `.agents/` and `.claude/`; neither is part of
the application documentation set.
