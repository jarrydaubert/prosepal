# Backlog

Only open work items live here.

Active product direction:

- `prosepal-ios/` is the active native iOS rewrite path.
- The existing Flutter app remains the current production/reference
  implementation until a signed replacement decision is made.
- Flutter production maintenance work should be added here only when it is
  required to protect the live app.

## Rules

- No status updates, progress notes, or completed work.
- No placeholder rows for work that is not part of the active native direction.
- Every item must include a clear, testable Definition of Done.
- If an item changes runtime behavior, its Definition of Done must name the
  regression protection: automated coverage at the right layer, or an explicit
  replacement evidence path with a named bug target and oracle.
- When an item is complete, remove it from this file in the same change set.

## Global Definition Of Done

Every backlog item is complete only when all conditions below are true:

1. Outcome is delivered exactly as written.
2. Regression protection is added or explicitly justified.
3. Relevant deterministic validation passes.
4. Evidence is attached through logs, screenshots, CI run IDs, release
   artifacts, or a named manual evidence path.
5. The completed item is removed from this file.

## Active Priority Order

1. `N-IOS-01` Core Create and Results quality
2. `N-IOS-02` Staging gateway reliability and operator runbook
3. `N-IOS-03` Sign in with Apple identity path
4. `N-IOS-04` Server-authoritative usage and entitlement state
5. `N-IOS-05` Native paywall, purchase, and restore
6. `N-IOS-06` Auth, purchase, restore, and account-switch edge cases
7. `N-IOS-07` Settings, support, privacy, and legal parity
8. `N-IOS-08` Saved, history, and local data model
9. `N-IOS-09` Existing Flutter user migration and App Store continuity
10. `N-IOS-10` Native TestFlight and CI promotion gates
11. `N-IOS-11` Native privacy, logging, and diagnostics hardening
12. `N-IOS-12` Local Standard generation spike

## Native iOS Release Gates

| ID | Item | Definition of Done |
|----|------|--------------------|
| `N-IOS-01` | Core Create and Results quality | The native Create flow preserves Flutter's product inputs without adding extra taps: occasion, relationship, tone, length, spelling preference, recipient, include, avoid, and context all map into `CardIntent`. Occasion selection has one obvious path, not duplicated selectors. The keyboard never hides the active field or write action on a physical iPhone. Generation shows a calm waiting state. Results show three drafts with Copy as the primary action and Share, Edit, Save, Start Over, and Regenerate/Premium actions still reachable. No provider/model names appear in UI. DoD requires Swift tests for request construction and state transitions, simulator build, physical iPhone smoke evidence for keyboard and results actions, and staging gateway generation evidence. |
| `N-IOS-02` | Staging gateway reliability and operator runbook | The staging Supabase project supports repeatable Standard generation for native testing without touching production. The runbook documents the staging project ref, function URL, required secret names only, Xcode env var names, smoke-test commands, expected 401/200 result shapes, and failure triage buckets. Gateway smokes prove a valid secret-authenticated request returns three drafts, invalid/no secret fails closed, provider/model fields are not exposed to the client, and logs do not contain raw prompt/card/generated content. DoD requires `./scripts/prosepal-staging-smoke.sh`, Edge Function tests where relevant, and a no-secrets git-status check. |
| `N-IOS-03` | Sign in with Apple identity path | Native Sign in with Apple works on a physical iPhone through the staging Supabase Auth configuration. Signed-out users can still use allowed Standard generation. Signed-in state persists across relaunch, clears on sign out, and cannot be faked by placeholder UI. `GatewayMessageWritingClient` receives bearer tokens through a token provider without logging token values. DoD requires unit tests for signed-out, signed-in, relaunch, sign-out, and cancelled/failed auth paths; wired iPhone evidence for sign in and sign out; and gateway evidence showing authenticated request handling without token or content exposure. |
| `N-IOS-04` | Server-authoritative usage and entitlement state | Native usage and Premium access are rendered from gateway/server state on production-capable paths. Local placeholder allowance cannot block or grant production behavior. Gateway response handling covers usage allowed, free limit reached, Premium required, rate limited, timeout, content blocked, degraded route, service unavailable, and unexpected response. Premium generation is not unlocked by local UI state alone. DoD requires contract tests for the relevant response shapes, staging curl evidence for success and failure classes, Swift tests for UI state mapping, and physical iPhone evidence for free-limit and retry/paywall states. |
| `N-IOS-05` | Native paywall, purchase, and restore | The native paywall presents Premium value, product loading, purchase, restore, legal links, and a Standard fallback without forcing account creation before purchase. Purchase and restore use the chosen entitlement strategy deliberately: RevenueCat for continuity or StoreKit 2 direct with a documented ADR. Product IDs align with App Store Connect and any entitlement backend. Premium UI only updates after an active entitlement is confirmed by the selected source, and gateway Premium still depends on server authorization. DoD requires StoreKit or RevenueCat sandbox evidence, physical iPhone purchase/cancel/restore evidence, Swift tests for product-load and purchase result states, and App Review copy/legal verification. |
| `N-IOS-06` | Auth, purchase, restore, and account-switch edge cases | Native auth and subscription flows cover cancellation, failure, duplicate taps, pending purchase, expired entitlement, anonymous purchase followed by sign in, restore from paywall, restore from Settings, sign out, account switch, stale entitlement cache, and delete-account gating. A new user must never inherit usage, entitlement, telemetry, saved account state, or pending sync state from a previous user. DoD requires deterministic tests for each edge case, physical iPhone evidence for Apple/auth/store legs that cannot be proven in unit tests, and no secrets or user content in logs. |
| `N-IOS-07` | Settings, support, privacy, and legal parity | Settings covers Account, Subscription, Restore, Writing preferences, Privacy, Support, Legal, and About in a grouped native iOS layout. Rows are hidden or disabled honestly when backing functionality is not implemented. Support/feedback uses a user-controlled path and does not include raw card content unless explicitly approved by the user. Delete account and data export either work through staging/authenticated backend paths or are not presented as available. DoD requires Swift tests for settings state, wired iPhone screenshots for settings/account/paywall/support/legal, and a privacy review of any diagnostic payload. |
| `N-IOS-08` | Saved, history, and local data model | The native app defines whether `Saved` contains only user-curated messages, generated history, or both through a filter. Local saved-message behavior supports list, search/filter where chosen, detail, copy, share, edit, delete, and metadata display. Generated history is either implemented or explicitly excluded from the native replacement scope with product approval. DoD requires unit/UI tests for saved-message persistence and edit/delete behavior, physical iPhone evidence for list/detail actions, and a migration note for any retained Flutter history behavior. |
| `N-IOS-09` | Existing Flutter user migration and App Store continuity | Before native replacement, the app identity strategy is approved: Apple Developer Team, bundle ID, App Store listing, subscription product IDs, entitlement ID, and rollback path. If the native app ships over the existing bundle ID, migration handles or safely ignores Flutter storage formats for onboarding, spelling, analytics/crash preferences, paywall cooldown, anonymous entitlement identity, history, saved reminders, usage cache, and biometric preference. DoD requires a migration design, tests for every imported format, failure-safe behavior for unreadable legacy data, TestFlight evidence, and rollback instructions. |
| `N-IOS-10` | Native TestFlight and CI promotion gates | Native Swift tests and simulator builds are promoted from companion/R&D checks to the correct blocking level before native TestFlight or release-candidate work. The native release evidence path captures version/build, Swift tests, simulator build, physical iPhone smoke, gateway config summary with no secrets, auth evidence, purchase/restore evidence, App Store Connect review, TestFlight sanity, secret audit, rollback plan, and owner sign-off. DoD requires `.github/workflows/ci.yml` or equivalent workflow updates, `docs/DEVOPS.md` updates, and a dry-run evidence bundle. |
| `N-IOS-11` | Native privacy, logging, and diagnostics hardening | Native diagnostics provide enough signal to debug tethered-device generation, auth, purchase, restore, settings, and gateway legs without logging raw recipient names, include/avoid/context fields, prompt text, generated drafts, tokens, receipts, provider payloads, provider keys, or provider/model IDs in client-visible logs. Any analytics/crash SDK decision requires an ADR and privacy rationale before adding a dependency. DoD requires OSLog/event schema review, redaction tests where applicable, device-console evidence, and updated diagnostics docs. |
| `N-IOS-12` | Local Standard generation spike | Evaluate local Standard generation separately from the current gateway path. The first spike target is Gemma 4 E2B via LiteRT-LM; E4B can be evaluated later if quality/device tradeoffs justify it. Model binaries must not be bundled in the initial app binary and must download on demand into app-private Application Support with backup exclusion, versioning, checksum validation, interrupted-download recovery, low-storage handling, and deletion support. DoD requires licensing/App Store review, real-device performance and quality evidence, storage/download tests, privacy-safe diagnostics, and no change to current gateway behavior until explicitly approved. |

## Flutter Production Reference

The Flutter app remains live production/reference. Add Flutter work here only
when needed for a production hotfix, production security issue, live service
ownership requirement, or migration evidence needed by the native replacement.
