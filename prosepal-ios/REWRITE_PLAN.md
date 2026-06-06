# Native iOS Delivery Plan

## Purpose

Provide the compact delivery path for the SwiftUI rewrite in `prosepal-ios/`.

Use this file for sequence and scenario policy. Use:

- `../docs/BACKLOG.md` for open work and Definition of Done.
- `../docs/NEXT_RELEASE_BRIEF.md` for the shareable readiness brief.
- `NATIVE_PRODUCT_NORTH_STAR.md` for product/UX direction.
- `ARCHITECTURE.md` for native AI architecture.
- `../docs/architecture/AI_GATEWAY_STRATEGY.md` for long-term gateway strategy.

## Direction

The native app is:

- iOS-first;
- SwiftUI-first;
- gateway-first;
- dependency-light;
- behaviorally faithful to Flutter where that behavior is valuable;
- visually and structurally native, not a Flutter screen clone.

Flutter remains production/reference until a signed production replacement
decision is made.

## Non-Negotiables

- Native generation goes through a ProsePal-owned message-writing contract.
- Do not add Firebase AI, Vertex AI, provider SDKs, or model names to the
  native client.
- Do not add client-side template generation fallback.
- Do not log raw recipient names, user details, prompt text, generated drafts,
  tokens, receipts, provider payloads, provider keys, or secrets.
- Do not force sign-in before purchase.
- Do not commit local Xcode schemes, Supabase `.temp`, local evidence,
  screenshots, receipts, secrets, or model binaries.

## Delivery Sequence

| Step | Backlog Gate | Outcome |
|------|--------------|---------|
| 1 | `N-IOS-01` | Core Create and Results flow is keyboard-safe, gateway-backed, and visually native. |
| 2 | `N-IOS-02` | Staging gateway is repeatable, guarded, documented, and privacy-safe. |
| 3 | `N-IOS-03` | Sign in with Apple works on device and provides gateway bearer tokens. |
| 4 | `N-IOS-04` | Usage and entitlement state come from gateway/server policy on production-capable paths. |
| 5 | `N-IOS-05` | Paywall, purchase, restore, product loading, and entitlement confirmation are real. |
| 6 | `N-IOS-06` | Auth/purchase/restore/account-switch edge cases are deterministic. |
| 7 | `N-IOS-07` | Settings, support, privacy, legal, and account flows are mature and honest. |
| 8 | `N-IOS-08` | Saved/history local behavior is intentionally defined and implemented. |
| 9 | `N-IOS-09` | Flutter user migration and App Store continuity are designed and tested. |
| 10 | `N-IOS-10` | Native CI/TestFlight gates and evidence path are promoted appropriately. |
| 11 | `N-IOS-11` | Native diagnostics and logging are privacy-safe and useful. |
| 12 | `N-IOS-12` | Local Standard generation is evaluated separately from the current gateway path. |

## Product Flow

```text
Launch
  -> first-run welcome
  -> Create
  -> gateway generation
  -> Drafts
  -> copy / share / edit / save

Tabs
  Create
  Saved
  Settings
```

Calendar/reminders remain a parity consideration before replacement, but should
not become a primary tab until they are mature.

## Auth And Purchase Scenario Oracle

| Scenario | Expected Native Behavior |
|----------|--------------------------|
| First launch, signed out | Welcome leads to Create; no forced auth or paywall. |
| Returning launch, signed out | Create is available; Standard generation follows gateway policy. |
| Premium selected | Paywall opens with product/loading/error/restore/legal states and Standard fallback. |
| Purchase while signed out | Allowed. After purchase, sign-in can be offered for continuity. |
| Purchase while signed in | Purchase result reconciles with account and entitlement state. |
| Purchase cancelled | No Premium granted; paywall remains usable. |
| Purchase pending | Pending state is shown; Premium is not granted until entitlement is active. |
| Product loading fails | User-safe unavailable state with retry/close/Standard path. |
| Restore from paywall | Restore is available without mandatory app sign-in; successful restore refreshes entitlement. |
| Restore from Settings | Same restore path with progress and honest result state. |
| Sign in cancellation/failure | App is not stuck; no fake signed-in state appears. |
| Sign out | Session, stale entitlement UI, biometric lock, and account-scoped diagnostics clear. |
| Account switch | New user does not inherit previous user's entitlement, usage, telemetry, or pending state. |
| Premium generation request | Gateway authorizes entitlement; local Premium UI alone is insufficient. |
| Delete account | Signed-out users see sign-in gate; signed-in users see explicit destructive warning and subscription-management reminder. |
| Biometric lock | Only available after sign-in; prompt is single-flight/debounced. |
| Privacy toggles | Shown only for systems that actually exist. |

## Evidence That Matters

Native replacement confidence depends on evidence for the legs that cannot be
fully proven with unit tests:

- physical iPhone first-run and Create flow;
- keyboard-open Compose behavior;
- staging gateway generation;
- Sign in with Apple;
- purchase, cancel, pending, restore, and entitlement convergence;
- settings/support/legal/account flows;
- TestFlight install and smoke;
- secret audit and rollback plan.

## End State

The native app is eligible to replace Flutter production only when:

- Create and Results are better on iPhone than the Flutter flow;
- auth, entitlement, usage, purchase, restore, support, legal, and settings are
  real;
- gateway policy is server-authoritative and privacy-safe;
- existing user continuity has a tested migration path;
- physical-device and TestFlight evidence pass;
- App Review lessons from Flutter are explicitly preserved;
- rollback to the current Flutter production baseline remains available until
  native is approved.
