# Capabilities

This is the compact catalogue of behaviour present in the ProsePal iOS app.
Detailed code and test evidence lives in
[feature-status.jsonl](../reference/feature-status.jsonl); unresolved work lives in
[BACKLOG.md](../BACKLOG.md).

## Moment writing

| Capability | Current behaviour |
|---|---|
| Root navigation | After welcome, Write, Drafts, and Settings tabs remain distinct and discoverable; app and extension handoffs return to Write. |
| Person-first entry | The user starts with who the message is for, then chooses relationship and occasion context. |
| One true thing | The user types the real sentence or detail the draft should preserve. Voice dictation is not part of v1. |
| Occasion-aware care | Ordinary moments default to private writing, while sympathy, pet sympathy, and apology automatically request the careful lane. |
| Tone | Heartfelt, Casual, Funny, Formal, Inspirational, Playful, Sarcastic, Nostalgic, and Poetic choices shape the voice. |
| Length | Brief, Standard, and Detailed choices set the intended message shape. |
| Locale | The app derives locale and spelling behaviour from the device rather than exposing a spelling picker. |
| Explicit generation | Drafting begins only after the user taps Write Draft. |
| Stop and cancellation | While writing, Stop cancels the active request; changing the Moment, leaving Write, or backgrounding also prevents obsolete work from replacing newer words. |
| Private Draft | Everyday moments use Foundation Models on device when available. |
| Careful lane | Harder moments use the ProsePal gateway automatically and keep provider details behind the service boundary. |
| Fallback | Retryable failures can move between eligible lanes while content blocks remain blocked. |

## Draft protection and results

| Capability | Current behaviour |
|---|---|
| Primary draft | One generated message is presented as the main writing surface. |
| Edit | The user can edit the active draft directly. |
| Another | Requests a fresh draft for the same Moment while preserving the current wording as a recoverable snapshot. |
| Adjust | Warmer, Shorter, and Direct are the supported named rewrite actions. |
| Undo and keep | Edits and rewrites create recoverable snapshots before replacing current text. |
| Relaunch recovery | The active draft and its snapshot history can be recovered after an app restart. |
| Copy | Copies the active message with visible confirmation. |
| Share/send | Uses the native share sheet; the destination remains the user’s choice. |
| Save | Adds a draft to the local saved list only after an explicit user action. |

## Relationship memory

| Capability | Current behaviour |
|---|---|
| Truth Beads | User-approved facts can be saved per person and included in future private drafting. |
| Voice Card | One user-written style example can guide future private drafting. |
| Local vault | SwiftData stores relationship memory and saved drafts in an app-private, backup-excluded location. |
| Honest saved-draft changes | Saved-draft edits report success only after SwiftData persists them; deletion requires confirmation and failed saves roll back without closing the detail. |
| Native sharing | Active and saved drafts expose one Copy action and one system Share action. ProsePal does not claim or force a destination and does not record a send when the chooser is cancelled. |
| Export | Settings can copy JSON or share a generated, named JSON file containing local relationship memory and saved drafts. |
| Memory delete | Truth Bead and Voice Card deletion requires confirmation, reports persistence failure, and rolls back after a failed save. |

## Identity and subscriptions

| Capability | Current behaviour |
|---|---|
| Anonymous first use | Welcome and first writing value do not require an account. |
| Sign in with Apple | Apple identity is exchanged through Supabase Auth; the one-time code is forwarded to the authenticated server boundary, only deletion revocation material is retained there, and the session plus opaque Apple credential ID is stored in Keychain. |
| Session refresh | Access-token refresh is single-flight, persists rotated tokens, and distinguishes terminal from transient failure. |
| Purchase | StoreKit 2 purchase does not require ProsePal sign-in first. |
| Restore | Restore is available from Paywall and Settings. |
| Transaction updates | Launch-time StoreKit updates converge verified purchases, renewals, approvals, sharing changes, and revocations. |
| Premium promise | Plan and Paywall describe higher writing limits, not unlimited use; exact counters remain hidden until approved structured server metadata reaches the UI. |
| Apple credential changes | The app checks stored Apple credential state and observes revocation, returning to signed out without erasing unrelated local writing. |
| Account deletion | The authenticated server boundary revokes Apple authorization before validated app/auth cleanup. Pre-final failures preserve signed-in retry; an unconfirmed final deletion signs out and clears account-scoped entitlement state while preserving device-local writing; confirmed and already-deleted results converge on success. Subscription cancellation remains separate. |

## Safety and honesty

| Capability | Current behaviour |
|---|---|
| Pressure Check | Local writing feedback flags obvious guilt or reassurance pressure without diagnosing the user. |
| Provider refusal | Model and gateway refusals become calm, provider-neutral errors. |
| Defensive block | A narrow existing explicit-input block stops drafting and presents support resources. It is not a general crisis classifier. |
| Offline recovery | The note remains local and the user receives a real Try Again action. |
| Waiting feedback | Generation, sign-in, subscription loading and actions, and account deletion expose indeterminate in-progress state, reject duplicate submission, and preserve current writing while their owning boundary responds. |
| Usage limits | The limit-reached screen shows the gateway’s user-safe policy message without inventing counters, reset dates, or an unlimited Premium promise; retry preserves the user’s note. |

## System surfaces

The project contains native App Intent, Shortcuts, widget/control, and Share
Extension targets. These are optional v1 entry points: each ships only after its
embedded production target passes release qualification. See
[System surfaces](../engineering/system-surfaces.md) for the current handoff
boundary and staging limitation.

## Platform and dependency boundary

- Native target: iOS 26 and later.
- UI: SwiftUI.
- Local models: Foundation Models.
- Storage: SwiftData and Keychain.
- Purchase: StoreKit 2.
- Backend: Supabase Auth, Edge Functions, and PostgreSQL policy.
- Third-party provider SDKs: none in the iOS app.
- Android and web product clients: outside the iOS app.
