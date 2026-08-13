# Data and Privacy

This document is the canonical engineering map of data handled by the current
ProsePal iOS app and repository backend. It describes implementation facts and
known limits. It is not the public Privacy Policy and does not make legal-
compliance conclusions.

## Generation data flow

`RoutingMessageWritingService` owns both initial-draft and named-adjustment
routing. `MomentModel` owns the active request and preserves the user's current
Moment and previous draft when generation fails or is cancelled.

| Route | Processing | Content used |
|---|---|---|
| Private initial draft | `FoundationModelsPrivateDraftClient` uses Apple Foundation Models on the device | Person name, relationship, occasion, register description, tone, length, device locale, Moment detail, and approved matching Truth Beads and Voice Card |
| Direct careful initial draft | `GatewayCarefulMomentClient` sends a `CardRequest` over HTTPS to the ProsePal `generate-card` Edge Function | Person name, relationship, occasion, tone, length, device locale, Moment detail, register description, app/build/platform metadata, idempotency key, and authentication or guarded staging-development credentials |
| Private-to-careful fallback | An eligible private-lane technical failure starts a new gateway request | The same careful payload described above; relationship-vault records are not added to the gateway request |
| Careful-to-private fallback | An eligible direct-careful failure starts the on-device client | The private prompt content described above, including approved matching relationship memory |
| Named adjustment | Route follows the lane of the current bundle | The current draft text and adjustment name are added to either the private prompt or careful gateway payload; a private adjustment may fall back online, while an already-online adjustment stays online |
| Another/rewrite | Re-enters initial-draft routing for the current Moment | It does not send the current draft as adjustment context; the existing wording is retained as a recovery snapshot before successful replacement |

The native app does not contact the online model provider directly. For careful
work, the Edge Function validates and sanitizes the request, reserves rate/quota
capacity, and constructs a provider prompt containing the writing fields above.
It may send that prompt sequentially to the primary and configured fallback
models at the configured provider endpoint. The production provider binding
values and its binding terms are not present in the client or repository.

The gateway does not deliberately persist the incoming prompt or raw request
body. It stores a SHA-256 fingerprint of provider-affecting request fields and,
after success, the generated `CardResponse` for bounded replay. Exact server
retention is in [Server data](#server-data).

### Routing and failure rules

- Ordinary initial drafts try the private client first. Timeout, rate/busy,
  stale request-key, unavailable-runtime, malformed-response, and untyped
  failures may start the careful route. Offline, usage-limit, and content-block
  errors do not.
- Moments requiring careful treatment try the careful client first. Any typed
  generation error except a content block may try the private client; an
  untyped failure may also do so. Cancellation never starts another route.
- A private or mock adjustment has the same eligible private-to-careful
  fallback. An adjustment to a `standardDraft` or `careful` bundle calls the
  careful client only and does not fall back to private processing.
- The narrow local safety gate and either model's content refusal stop routing.
  A refusal is not converted into another provider attempt by the app.
- Per-lane timeouts run inside one total technical deadline. If all eligible
  routes fail, the app presents the final typed, provider-neutral error. The
  current Moment and any current draft or recovery snapshot remain available.

There is no separately persisted, explicit online-writing permission in the
current implementation. Establishing and enforcing that permission is owned by
backlog slice I-1.

## Local data

| Data and owner | Storage and retention | Export | Clearing and deletion |
|---|---|---|---|
| Active Moment, draft, and history — `MomentModel` | App memory. Person, relationship, occasion, style, Moment detail, current `MomentDraftBundle`, and up to 12 edit/rewrite snapshots live for the model lifetime. | Not included in local export unless the user separately saves the draft. | Meaning-bearing input changes clear generated output/history but retain the edited inputs. Start New Moment and confirmed account deletion clear all Moment state. Sign-out, local-vault deletion, and an indeterminate account deletion do not. |
| Relaunch recovery — `MomentDraftRecoveryState` and `MomentDraftRecoveryStore` | Versioned JSON in standard `UserDefaults` under `prosepal.native.activeDraftRecovery.v1`. It contains the active Moment, generated draft, model-returned notes and approved beads present in the bundle, and up to 12 snapshots. Recovery is written only when a bundle exists and has no time-based expiry. | Excluded. | Cleared when the bundle is invalidated, Start New Moment runs, recovery is unreadable/incompatible, or confirmed account deletion resets `MomentModel`. Sign-out, local-vault deletion, and indeterminate account deletion preserve it. |
| Truth Beads, Voice Cards, and saved drafts — `RelationshipVaultSchemaV1` | SwiftData at `Application Support/ProsePal/RelationshipVault/RelationshipVault.store`, with the containing directories excluded from backup. If persistent storage cannot open, the app uses an honestly reported in-memory fallback. Records remain until an explicit record edit/delete, full vault erasure, or confirmed account deletion succeeds. | `RelationshipVaultExporter` includes every stored Truth Bead, Voice Card, and saved draft, including approval flags, writing fields, identifiers, and timestamps. It omits normalized person keys and store paths. | Individual confirmed deletes save before reporting success. The current “Delete local data” action erases only these three SwiftData model types. Confirmed account deletion invokes the same vault eraser. Sign-out and indeterminate account deletion preserve them. |
| App Intent handoff — `MomentLaunchStore` | One encoded `MomentLaunchRequest` in standard `UserDefaults` under `prosepal.pendingMomentLaunch.v1`; it can contain person, occasion, shared text, source, and creation time. No time-based expiry is implemented. | Excluded. | Consume-once removal happens before decoding. Confirmed account deletion consumes any pending value. Sign-out, local-vault deletion, and indeterminate account deletion do not. |
| Share Extension handoff — `SharedMomentLaunchStore` | One sanitized text/URL payload and creation time in app-group `UserDefaults`; production and staging use separate keys. No time-based expiry is implemented. | Excluded. | Consumed once only for a share-extension launch. Confirmed account deletion consumes the running environment's pending value. Sign-out, local-vault deletion, and indeterminate account deletion do not. |
| Pending careful-request metadata — `CarefulRequestKeyStore` | Standard `UserDefaults` under `prosepal.native.pendingCarefulRequest.v1`; contains a random request key, SHA-256 request-identity value, and creation time, not raw writing. An existing value is eligible for reuse for 24 hours. There is no timer that physically removes it at 24 hours. | Excluded. | Cleared after successful initial careful generation or a replay-expired/idempotency-conflict response. A different or expired request replaces it on next use. Sign-out, local-vault deletion, and confirmed or indeterminate account deletion do not currently clear it. Named adjustments do not use this durable key. |
| Temporary export file — `MomentLocalDataExport` | A JSON copy of the vault export is written atomically under the OS temporary directory in `ProsePalLocalDataExports` only when a file transfer requests it. | This is the shareable export artifact. The export screen also holds the same JSON in memory and currently permits copying it. | The directory is removed before a new temporary file is written, when a new export is prepared, and best-effort when the export view disappears. The OS may also purge temporary files. Sign-out, the vault eraser, and account deletion do not independently remove it. |
| Auth session — `KeychainAuthSessionStore` and `AuthSessionController` | One Keychain generic-password item scoped to the app bundle's auth service and account `supabase-session`, accessible after first unlock on this device only. It contains access/refresh tokens, expiry, Supabase user ID/email when returned, and the opaque Apple credential user ID. | Excluded. | Cleared by successful local sign-out, terminal refresh rejection, invalid Apple credential handling, and confirmed or indeterminate account deletion. Local-vault deletion does not affect it. Transient network failure preserves a refreshable session. |
| StoreKit and account presentation state — StoreKit and `MomentAccountModel` | StoreKit owns transaction history. Product, entitlement, ownership, and Premium presentation state are held in memory by the app; ProsePal has no separate local transaction database. | Excluded. | Sign-out and account identity changes clear account-scoped Premium state, but they do not cancel or erase an App Store subscription or Apple's transaction history. Subscription management is a separate App Store action. |

The local export is therefore a vault export, not an export of every local or
server-side datum. Likewise, the current local-delete action is a vault eraser,
not account deletion and not a complete purge of UserDefaults, Keychain,
handoffs, active recovery, request metadata, diagnostics, or temporary files.

## Server data

| Data and owner | Purpose and account linkage | Implemented retention and account deletion |
|---|---|---|
| Supabase Auth | Supabase manages the auth user, provider identity, email when supplied, and server session state. The UUID links account-owned backend rows. | Retained while the auth account exists under Supabase's service behaviour. Confirmed `delete-user` ends by deleting the auth user. A pre-final failure leaves it for retry; a final indeterminate result does not establish whether deletion committed. |
| Apple revocation credential — `apple_credentials` and `exchange-apple-token` | Service-role-only Apple refresh token keyed by Supabase user UUID, used to revoke Sign in with Apple authorization during account deletion. The one-time authorization code is exchanged in memory and is not stored by the current function. | Replaced on a later successful exchange and otherwise retained while the account exists. Apple deletion requires revocation first; deleting `auth.users` cascades the credential row. Sign-out, local deletion, and subscription management do not remove it. |
| Gateway request ledger — `gateway_requests` | Service-role-only request UUID, account UUID or guarded `dev-anonymous` subject, idempotency key, request fingerprint, reservation token/status, lane/contract, attempt/failure, entitlement/month metadata, expiry times, and successful response payload containing generated text. | Replay is allowed for 24 hours. The hourly cleanup clears an expired payload on its next run. Terminal/abandoned rows are deleted when `updated_at` is more than seven days old; clearing a successful payload updates that timestamp, so its remaining metadata receives another seven-day cleanup window. Account-linked rows cascade when the auth user is deleted. |
| Usage/quota — `user_usage` | Total/monthly generation counts and month key linked by user UUID. Successful authenticated gateway finalization increments once. | No time-based deletion while the account exists. `delete-user` deletes the row before final auth deletion; the foreign key also cascades on confirmed auth deletion. |
| Rate attempts — `rate_limit_log` | Subject identifier (`user` UUID for current authenticated native requests or `dev-anonymous` for guarded staging), endpoint, and timestamp. Current native code does not send a device identifier. | Rows become cleanup-eligible after one hour and the hourly cron removes them on its next run. `delete-user` explicitly removes the user's rows; anonymous-development rows expire only through cleanup. |
| Server entitlement — `user_entitlements` | User UUID, active state, product/expiry, and current App Store notification or reconciliation metadata used for gateway policy. Current native App Store functions set the authoritative source; legacy-named nullable schema residue is not a current RevenueCat dependency. | Updated as authoritative events arrive; no separate history window is defined for the current row. `delete-user` removes it before final auth deletion and its foreign key also cascades. StoreKit subscription ownership at Apple remains separate. |
| App Store notification events — `app_store_notification_events` | Notification UUID/type/subtype, environment, product and transaction identifiers, optional UUID `appAccountToken`, signed/received/processed times. It stores selected verified metadata, not the signed payload or receipt. | No cleanup period is implemented. The table has no auth-user foreign key, and `delete-user` does not delete or anonymize its account token or transaction metadata. S-1 owns the retention and account-deletion policy. |
| App Store reconciliation events — `app_store_reconciliation_events` | Requested transaction/user, resolved user, App Store status/product/transaction metadata, optional UUID `appAccountToken`, outcome/error, and processing time. Raw signed responses and transaction bodies are not stored in this table. | No cleanup period is implemented. User UUID fields have no auth-user foreign key, and `delete-user` does not delete or anonymize these rows. S-1 owns the retention and account-deletion policy. |
| Operational diagnostics — native OSLog and Edge Function logs | Native code records event names, enum values, booleans, counts, status/error categories, latency, and truncated request IDs. Edge Functions record comparable request/operation metadata, redacted user/transaction identifiers, configured operator/model labels, and safe failure categories. | The app and repository define no independent log database, retention period, export, or per-account deletion mechanism. OS and hosted-service retention therefore remain outside these application data controls. Application logging code must not deliberately include raw writing, relationship facts, prompts, generated text, full request keys/fingerprints, tokens, receipts, signed payloads, provider responses, or secrets. |

The repository still contains legacy device-usage tables/RPCs and a
`send-feedback` Edge Function, but the current native app does not supply an
installation ID, call those device RPCs, or call `send-feedback`. They are not
current native data routes. Historical Firebase, Gemini-direct, RevenueCat, and
Flutter paths are also not part of the current app.

## User controls are separate

| Control | What it does | What it does not do |
|---|---|---|
| Sign out | Attempts Supabase logout, clears the Keychain session, and resets account-scoped Premium/UI state. | Does not erase local writing, recovery, handoffs, exports, pending request metadata, server usage/history, the account, or an App Store subscription. |
| Delete local data | Erases saved drafts, Truth Beads, and Voice Cards from the relationship vault after persistence succeeds. | Does not clear the active Moment/recovery, handoffs, Keychain, account, server rows, StoreKit subscription, pending careful metadata, diagnostics, or temporary exports. Its final name and whether its scope should expand are unresolved in I-2. |
| Delete account | Runs authenticated server revocation/cleanup and final auth-user deletion, then performs the confirmed or indeterminate local lifecycle below. | Is not subscription cancellation. It does not currently apply an App Store event retention/anonymization policy. |
| Export local data | Produces JSON for the three relationship-vault model types. | Does not export active/recovered work unless saved, handoffs, Keychain/auth, StoreKit, pending request metadata, logs, or server data. |
| Manage subscriptions | Opens Apple's subscription-management surface. | Does not sign out, erase local writing, delete the ProsePal account, or directly remove ProsePal server metadata. |

### Account-deletion outcomes

Before final auth deletion, `delete-user` authenticates the caller, requires and
revokes the Apple refresh token for an Apple account, deletes `user_usage`,
`user_entitlements`, and user rate-attempt rows, and removes the UUID from any
legacy device associations. Earlier cleanup may have completed even if a later
pre-final step fails. In that failure phase the app preserves its session and
local writing so the user can retry.

After confirmed auth deletion, database foreign keys remove the Apple credential
and account-linked gateway rows. The app clears the Keychain session and
account-scoped entitlement state, invokes the relationship-vault eraser, clears
the active Moment and recovery, consumes pending App Intent and Share Extension
handoffs, resets onboarding, and reports any vault-erasure failure honestly.
The pending careful-request value and any temporary export directory are not
part of that coordinated cleanup today.

If final auth deletion starts but the server result is indeterminate, the app
clears the Keychain session and account-scoped entitlement state and signs the
user out. It deliberately preserves the active Moment, recovery, relationship
vault, and pending handoffs. It does not claim whether remote deletion committed.

## Truth not established by implementation

These boundaries must remain decisions rather than being inferred from current
code or marketing copy. Their implementation work is tracked in the ordered
privacy programme in [BACKLOG.md](../BACKLOG.md):

- The repository does not establish the production provider binding or its
  binding retention, training, and data-use terms. Those facts are prerequisites
  for I-1, W-1, and release review.
- The current app has no explicit online-writing permission. I-1 owns the final
  wording, first-use presentation, versioned grant, and revocation behaviour.
- App Store notification and reconciliation event retention, deletion, or
  anonymization is undefined. S-1 owns the approved period and enforcement.
- App Store Connect's user-content classification remains an owner decision for
  the manifest/submission sequence.
- The local-vault control's final scope and precise name remain an I-2 owner
  decision; documentation must not call the current vault-only eraser “all
  data.”
- W-1 owns the canonical public contact, Standard-versus-custom EULA decision,
  final public policy/support/terms claims, and website analytics disclosure.

## Verification sources

- `prosepal-ios/Sources/ProsePalAPI/MessageWritingService.swift`:
  `RoutingMessageWritingService`; private, careful, fallback, and adjustment
  routing.
- `prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift`
  and `GatewayCarefulMomentClient.swift`: each lane's prompt/request boundary.
- `prosepal-ios/Sources/ProsePalUI/Features/Moment/MomentModel.swift` and
  `MomentDraftRecovery.swift`: active state, snapshots, recovery, and clearing.
- `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`:
  `RelationshipVaultSchemaV1`, `RelationshipVaultExporter`, and
  `RelationshipVaultLocalDataEraser`.
- `prosepal-ios/Sources/ProsePalDomain/MomentHandoff.swift`:
  `MomentLaunchStore` and `SharedMomentLaunchStore`.
- `prosepal-ios/Sources/ProsePalAPI/CarefulRequestKeyStore.swift`,
  `KeychainAuthSessionStore.swift`, and
  `prosepal-ios/Sources/ProsePalUI/Features/Settings/MomentLocalDataExport.swift`:
  durable request metadata, auth storage, and temporary export ownership.
- `prosepal-ios/Sources/ProsePalUI/MomentAccountModel.swift` and
  `MomentAppRootView.swift`: local account-control outcomes.
- `supabase/functions/generate-card/index.ts`, `delete-user/index.ts`,
  `exchange-apple-token/index.ts`, `app-store-notifications/index.ts`, and
  `app-store-reconcile-entitlement/index.ts`: server processing and controls.
- `supabase/migrations/20260712170634_gateway_request_ledger.sql`,
  `001_create_user_usage.sql`, `006_create_rate_limiting.sql`,
  `007_create_apple_credentials.sql`, `009_create_user_entitlements.sql`,
  `023_add_app_store_entitlement_metadata.sql`, and
  `024_add_app_store_reconciliation_events.sql`: server tables, linkage, and
  cleanup.
