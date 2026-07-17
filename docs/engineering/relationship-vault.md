# Relationship Vault

The relationship vault is ProsePal’s local SwiftData store for user-approved
relationship memory and deliberately saved drafts. It is separate from active
draft recovery and from account/server state.

## Stored models

`RelationshipVaultSchemaV1` contains three models:

| Model | Content |
|---|---|
| `RelationshipTruthBeadRecord` | Person, approved fact, approval state, timestamps |
| `RelationshipVoiceCardRecord` | Person, user-written style summary, approval state, timestamps |
| `SavedMomentDraftRecord` | Person, relationship, occasion, register, tone, length, lane, true detail, draft, timestamps |

Text enters through the domain-owned caps in
[Generation contract reference](../reference/generation-contract.md). Stored
enum values fall back to safe native defaults if an older raw value becomes
unreadable.

## Person matching

Every record stores the display name and a normalized matching key. The key:

- trims outer whitespace;
- folds case and diacritics with the fixed `en_US_POSIX` locale; and
- remains internal to lookup and is omitted from export.

This is name matching, not identity resolution. Two different people with the
same normalized name are not distinguished by an account or contacts ID.

`RelationshipVaultMaintenance` repairs legacy records whose normalized key is
empty when the persistent container opens.

## Schema and migration

The current schema version is `1.0.0`. `RelationshipVaultMigrationPlan` is
already attached to persistent and in-memory containers and currently contains
no migration stages because only the first version exists.

Every future `@Model` change must add a new `VersionedSchema` and explicit
migration stage. Write-on-open key repair does not replace schema migration.

## Storage location

The persistent store is:

```text
Application Support/ProsePal/RelationshipVault/RelationshipVault.store
```

Both ProsePal directories are marked excluded from backup. If directory or
container creation fails, the factory returns an in-memory fallback and the app
reports storage as temporary instead of crashing or pretending persistence is
available.

## Draft recovery is separate

Active Moment recovery persists the current unsaved working state and snapshot
stack so relaunch does not lose ongoing work. It does not insert
`SavedMomentDraftRecord`. The saved library changes only after the user chooses
Save.

## Private drafting memory

`SwiftDataRelationshipMemoryProvider` creates a fresh model context for each
async lookup. It returns:

- approved Truth Beads matching the normalized person name, newest first; and
- at most one approved Voice Card, choosing the most recently updated.

Unapproved records and records for another normalized name do not enter the
private drafting prompt. Voice Cards are style guidance, not facts to copy.

## Export

`RelationshipVaultExporter` produces a versioned JSON snapshot containing:

- schema version and export timestamp;
- record counts;
- user-readable Truth Beads and Voice Cards; and
- saved draft fields needed to understand the Moment and message.

The export omits normalized person keys and local store paths. Dates use ISO
8601, keys are sorted, and file output is atomic. The default filename is
`prosepal-local-data-<timestamp>.json`.

## Deletion and persistence integrity

The full local-data eraser deletes all three model types and saves once. When an
ephemeral fallback was created after a persistent-store failure, it also removes
the inaccessible persistent-store directory before recreating the
backup-excluded folder.

Truth Bead, Voice Card, and saved-draft edit/delete flows report success only
after `ModelContext.save()` succeeds. Persistence failure rolls back to the last
saved value and leaves the affected detail visible with an honest error.

## Privacy boundary

- The vault is local and app-private.
- It is excluded from device backup by explicit resource values.
- It is not synchronized to Supabase or another cloud store.
- Relationship content is never allowed in operational diagnostics.
- Account switching does not silently reassign local records to another user.
- Export and erase are explicit user actions.

Stronger application-layer encryption is a triggered product decision before
cloud sync or materially more sensitive memory is introduced; current open work
is owned by the backlog.

## Verification

```bash
cd prosepal-ios
swift test --filter RelationshipVaultTests
```

The suite covers persistence, text caps, person matching, migration-plan wiring,
legacy-key repair, backup exclusion, ephemeral fallback, export shape, local
erasure, and approved-memory lookup.

## Source map

- `prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift`
- `prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift`
- `prosepal-ios/Tests/ProsePalAPITests/RelationshipVaultTests.swift`
- `prosepal-ios/Tests/ProsePalUITests/MomentModelTests.swift`

## Related documentation

- [Data and privacy](./data-and-privacy.md)
- [Capabilities](../product/capabilities.md)
- [Authentication and accounts](./auth-and-accounts.md)
