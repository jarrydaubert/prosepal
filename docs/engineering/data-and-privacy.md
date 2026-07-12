# Data and Privacy

ProsePal handles personal writing. Its architecture minimizes where that writing
travels, makes persistence deliberate, and keeps operational telemetry free of
message content and credentials.

## Data classification

| Data | Storage or transport | Rule |
|---|---|---|
| Active Moment and draft | App memory plus explicit relaunch-recovery store | Never operationally logged |
| Truth Beads and Voice Card | Local SwiftData relationship vault | User-approved, editable, exportable, deletable |
| Saved drafts | Local SwiftData vault | Created only after explicit Save |
| Auth session | Device-bound Keychain item | Tokens never logged or placed in UserDefaults |
| Pending careful request key | UserDefaults, maximum 24 hours | Contains a UUID and non-content hash, not message text |
| Gateway request | HTTPS to ProsePal Edge Function | Sanitized, bounded, authenticated where configured |
| Gateway replay response | Service-role-only PostgreSQL ledger, maximum 24 hours | Sensitive generated content, never in ordinary logs |
| Subscription transaction | StoreKit and server entitlement records | Receipts and signed payloads never logged |

## Local relationship vault

The vault uses a versioned SwiftData schema containing Truth Beads, Voice Cards,
and saved drafts. Its persistent store lives in an app-private Application
Support directory and is excluded from backup. If the persistent container
cannot open, the app can use an explicitly reported ephemeral container rather
than crash.

`RelationshipVaultMigrationPlan` owns schema evolution. Maintenance can repair
legacy normalized person keys without treating write-on-read repair as a schema
migration.

## Draft recovery versus saved history

Active-draft recovery protects work after edits, rewrites, cancellation, or app
relaunch. It is not the saved-message library. A generated draft appears in the
saved list only after the user chooses Save.

## Logging

Native diagnostics may include:

- event and action names;
- writing lane;
- error category;
- character or item counts;
- request-ID prefix;
- status code; and
- latency.

Native and server logs must not include recipient names, relationship facts,
prompt text, generated text, full request keys, tokens, receipts, provider
payloads, API keys, or development secrets.

## Gateway retention

The request ledger retains a completed `CardResponse` for up to 24 hours so a
lost response can be replayed without another provider call or charge. Terminal
and abandoned metadata is retained for seven days; rate-attempt rows are retained
for one hour. Scheduled cleanup enforces those limits.

## Export and deletion

The local export contains user-readable Truth Beads, Voice Cards, and saved
drafts. It omits internal person keys and store paths.

Confirmed local deletion persists before reporting success. A failed save rolls
back the model context and tells the user the item remains saved. Account
deletion invokes an authenticated server boundary, then clears local account and
vault state. Partial local cleanup is reported honestly rather than hidden.

## Secrets and configuration

- Public gateway and Supabase URLs may be embedded in the app bundle.
- The Supabase publishable/legacy anon key may be embedded; it is not a service
  role credential.
- Provider keys, service-role keys, Apple private keys, and the development
  gateway secret stay server-side or local-only.
- Archive validation rejects missing public remote configuration, insecure
  URLs, and embedded development gateway secrets.

## Security operations

Production and staging mutations remain human-gated. Use the explicit staging
project reference and guarded database helper described in
[Staging](../operations/staging.md). Public vulnerability reporting is defined
in the repository [security policy](../../SECURITY.md).
