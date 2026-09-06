# Backlog

Unresolved work only. Implemented behaviour belongs in the
[feature ledger](./reference/feature-status.jsonl); execution results belong in
private release evidence and Git history. Remove an item when its DoD is met.
Source presence is not proof of device behaviour or deployed configuration.

## Scope and decision rules

The [product north star](./product/overview.md) is a better personal message,
faster: person first, optional guidance, useful choices, human review, and no
loss of the writer's words. The [V1 contract](./product/v1-launch-contract.md)
retains three choices behind its private-device feasibility gate.

- V1 work must protect that loop, user data, privacy, payment integrity,
  accessibility, or a concrete release requirement. Each item names its value,
  current evidence and smallest acceptable outcome.
- Prefer removing an optional surface or misleading claim to adding a subsystem.
  Do not schedule cosmetic identifier renames, a monolith-deletion campaign,
  unused compatibility archaeology, generic provider adapters, or new platform
  integrations without a demonstrated problem. Preserve externally coupled
  identifiers and migration history; an existing App Store app is not a greenfield
  identity, even when the replacement client has no TestFlight users yet.
- Extract only the region materially touched by funded behaviour, following
  [SwiftUI ownership rules](./engineering/swiftui-architecture.md). Preserve the
  approved feature boundaries, previews, behavioural seams and shrink-only
  ratchets; file moves are not independent release gates. Delete misleading
  decoration instead of inventing state to justify it.
- Keep one owner each for generation, auth, entitlement, persistence and recovery.
  Change SwiftData models only through versioned schemas and explicit migrations.
- Keep private-first routing, current online permission, typed refusal and
  cancellation boundaries. No automatic send, provider-branded UI, custom crisis
  assessment, forced purchase login, or fabricated quota/progress.
- No secrets or user writing in tracked fixtures, diagnostics or release evidence.
  Use synthetic quality fixtures. New copy is localization-safe; touched colours
  are semantic and adaptive. Device and service evidence can proceed alongside
  local work; it never authorizes production mutations.

## V1 — Writing value and integrity

- [ ] **W-2 — Decide private three-choice feasibility and the wait budget together.**
  Value: three useful alternatives must earn their latency before a larger UI
  is built. Source: `GenerationTimeoutPolicy` and
  `FoundationModelsPrivateDraftClient` already implement one structured private
  draft with per-lane and total cancellation timers; those cooperative timers
  are not a measured user-visible deadline or a hard kill of an uncooperative
  child task.
  DoD: approve the end-to-end ceiling first; use the existing debug app on a
  supported iPhone to compare the current single draft with one-session complete
  three-option output for Brief, Standard and Detailed. Score every synthetic
  candidate and the set for meaningful variation using
  [the existing evaluator](./quality/ai-output-quality.md). Measure full completion
  and fallback, not just first text. Try streaming or prewarming only if that
  baseline misses the ceiling; neither is a deliverable by default. Retain the
  device scorecard and timing evidence once, for this and the release-quality
  gate. A miss requires a deliberate universal scope amendment before composer
  implementation, not online-first routing or different result interactions.
  Apple documents a [4,096-token on-device session window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
  including schema, input and output. Bound approved-memory context in the spike;
  three outputs cannot simply inherit the single draft's token budget.
  [Prewarming](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/prewarm(promptprefix:))
  is available on iOS 26, needs useful lead time, and does not guarantee immediate
  asset loading. A streaming variant must still validate the complete set before
  choice, persistence or sharing; do not build partial-output recovery.

- [ ] **W-3 — Deliver the smallest person-first, choose-before-edit loop after W-2.**
  Value: reduce blank-page anxiety without replacing it with an interview.
  Source: `MomentModel`, `MomentInput`, `MomentSheetView` and
  `GatewayCarefulMomentClient` currently expose one draft; the gateway adapter
  takes `response.messages.first` from an unranked three-candidate response.
  DoD: explicitly confirm person/relationship/occasion; one skippable tailored
  question with a small occasion-family bank and relationship-aware wording;
  safe fallback question; compact Style defaults. Do not build a large question
  engine. Additional questions are optional, at most two, and must improve
  writing in evaluation before inclusion. Separate detail, goal and exclusions;
  no probing grief circumstances or blame. No hidden close-friend default or
  legacy register may determine new intent. Derive routing from occasion policy,
  safely decode legacy recovery, and test intentional routing changes explicitly.

  Use one provider-neutral complete three-candidate contract with stable IDs,
  explicit selection, equal visual weight and no invented ranking. Preserve
  gateway replay exactly; expose all candidates, not the first as a winner.
  Only supported named adjustments follow selection. Remove decorative variant
  dots or word-substitution tricks if they cannot truthfully explain a choice.
  Preserve chosen text and undo/history across option changes and relaunch with a
  versioned recovery envelope that reads existing single-draft state. Invalidate
  stale results on changed intent without silently destroying recoverable writing.
  Stop, backgrounding, supersession, timeout and late-result tests remain common
  to both lanes. Compact/large-text UI and VoiceOver prove choice-to-edit handoff.

  Another remains a fresh initial draft, not adjustment context. Contract
  changes must include Swift/gateway enum and version parity; no separate
  code-generation project is required.

- [ ] **W-4 — Close cancellation and explicit-refusal classification gaps.**
  Value: stopping or refusing a request must not trigger another paid attempt.
  Source: `GatewayMessageWritingClient` has no HTTP 499 case; its default maps
  that status to fallback-eligible `unexpectedResponse`. Normal URLSession
  cancellation maps correctly, so actual 499 exposure is narrow.
  `extractOpenAICompatibleContent` and the provider loop also do not classify
  explicit provider refusal metadata; a missing-content refusal can become a
  technical failure and advance to another model.
  DoD: received 499 stays cancellation through transport and routing; recognized
  refusals from the configured provider stay typed blocks through the model loop,
  HTTP boundary and lane routing. Missing/unrecognized payloads remain technical
  failures; do not infer refusal by scanning natural-language text or build a
  general moderation system. Deterministic tests prove no subsequent provider or
  lane call and no result acceptance after cancellation/refusal. Reconcile the
  HTTP/reference docs in the same fix. Preserve the distinction between a local
  abort request and confirmed server no-charge finalization.

- [ ] **W-5 — Reject unusable output and repair input/body handling.**
  Value: a successful Write must yield usable wording rather than a blank or
  formatting residue. Source: `PrivateDraftContent.bundle` trims message text
  without a nonempty check; gateway `parseProviderMessages` collapses newlines
  before the newline-dependent `stripGreetingAndSignoff` rule.
  DoD: empty/whitespace-only private output is a typed failure that cannot replace
  existing wording or become a successful candidate; strip recognized sign-offs
  before losing the line structure, without deleting legitimate message content.
  Add focused tests and rerun the deterministic quality baseline. Keep the
  existing targeted quality rules; do not clone a broad regex moderation engine
  into the private lane or promise semantic grounding from format validation.

  Fix the live prompt asymmetry: Moment detail accepts 1,200 characters, but
  `gatewayIntent` puts it in one `thingsToInclude` item capped at 160 by
  `parseRequest`; adjustment `userContext` accepts 4,000 natively but the server
  caps it at 1,200. Choose one honest bound per field and preserve accepted
  meaning in both lanes, including exclusions and existing rewrite text. Add
  tests with meaningful content beyond the old cutoffs; do not silently truncate
  the only personal detail. Contract/version parity remains owned by W-3.

- [ ] **W-6 — Preserve unsaved work through recovery and incoming handoffs.**
  Value: relaunch or a shortcut must not erase the user's only wording.
  Source: `MomentModel.persistDraftRecovery` requires an existing bundle;
  pre-generation input has no recovery envelope. `applyLaunchRequest` and
  `resetDraftForMomentChange` clear bundle/history/recovery; the root applies an
  incoming handoff directly. Input invalidation and preservation are different
  responsibilities.
  DoD: versioned recovery can preserve meaningful composer input before a first
  result; changing intent prevents old-result acceptance without losing a
  recoverable prior draft; an incoming handoff with existing work requires an
  explicit replace/discard decision or preserves that work first. Keep this in
  `MomentModel` and the existing stores, not a second draft system. Test relaunch,
  declined replacement, accepted replacement, Stop, background, legacy envelopes
  and account reset. Explicit New Moment/discard and confirmed account deletion
  still clear recovery. No automatic resume or saved-library insertion.

- [ ] **W-7 — Roll back failed composer insertions.**
  Value: “Could not save” must not leave a pending duplicate or approved memory
  that a later save silently commits. Source: `MomentSheetView.save`,
  `addTruthBead` and `addVoiceCard` insert before saving and catch without rollback;
  extracted saved-writing/memory edit/delete seams already handle rollback.
  DoD: reuse the existing persistence pattern for those insertion failures,
  preserve input, and prove retry creates one record and unrelated subsequent
  saves do not commit the rejected insertion. No schema or persistence-layer
  replacement. Keep account/local erase failures visible under I-2.

- [ ] **Q-1 — Finish lane-specific live writing-quality acceptance.**
  Value: useful, faithful writing is the product, not an implementation detail.
  DoD: separately approved synthetic private and careful samples satisfy the
  [quality rubric](./quality/writing-quality-rubric.md) for preserved facts,
  no invented personal details, tone/length, sensitive occasions, pressure and
  internal-language leakage. Score each candidate and meaningful set variation;
  reuse W-2's private evidence where applicable. Failures receive explicit
  release-owner disposition. Re-evaluate meaning-affecting changes; do not rerun
  live writing for unrelated persistence-only work. No user-content retention or
  expansion of the narrow crisis substring rule into mental-health inference.

## V1 — Trust, account and release gates

- [ ] **I-2 — Make in-app privacy claims and deletion scope exact.**
  Value: consent and erasure must describe what actually happens.
  Source: `OnlineWritingPermissionAlert`, `OnlineWritingPrivacyControl`,
  `MomentPrivacyDataView`, `RelationshipVaultLocalDataEraser` and
  `MomentAccountModel`. Current-policy permission is already implemented; do not
  rebuild it. The alert says Relationship Memory stays on device, but a private
  draft can contain memory-derived facts and an online adjustment sends that
  draft. Revocation gates future online operations; it does not recall sent text
  or cancel an already-started operation.
  DoD: explain current-draft transfer and memory-derived wording accurately;
  preserve prospective revocation semantics unless a separate demonstrated need
  justifies stronger cancellation. Prefer the precise “Delete Saved Writing
  Data” name over expanding a vault-only eraser into account/auth destruction;
  confirm the owner decision and list inclusions/exclusions before deletion.
  Report partial failure, including session-store clear failure after account
  deletion rather than implying all local credentials were erased. Explicitly
  settle recovery/handoffs, request-key metadata and export-file treatment for
  each deletion action using the [data map](./engineering/data-and-privacy.md).
  Explicitly treat legacy pre-native local state written by the previous App
  Store client under the same bundle identity: deletion must erase it or
  accurately document its exclusion. Migration of legacy content is not required.
  Preserve separate sign-out, local deletion, account deletion and subscription
  management. Test unchanged account/subscription state after local erasure.
  Review disclosure against Apple's [5.1.2 data-sharing rule](https://developer.apple.com/app-store/review/guidelines/#data-use-and-sharing)
  and W-1's verified destinations/terms; no unsupported training claims.

- [ ] **W-1 — Reconcile public policy, support and commercial claims.**
  Value: the linked promises must match the launch build and actual processors.
  Ownership: the separate public website repository and release owner; this repo
  owns the app's links and technical data map, not the website implementation.
  DoD: verify live routes and source in that repository, then correct stale
  processor/device/analytics claims only where found. Confirm actual production
  provider binding, retention/training/data-use terms, public contact, Standard
  or custom EULA and any Vercel analytics disclosure. Match export/deletion and
  S-1 retention, supported three-choice wording and approved allowance copy.
  No assumed OpenRouter deployment or provider terms from generic compatibility.
  Reconcile with I-2 before release. A website redesign is out of scope.
  Apple requires [accurate privacy disclosures](https://developer.apple.com/app-store/app-privacy-details/)
  including relevant partners; repository source is not evidence of their terms.

- [ ] **S-1 — Enforce App Store event retention and account-deletion treatment.**
  Value: remove account-linked purchase metadata when its approved purpose ends.
  Source: notification/reconciliation event tables in migrations `023` and `024`
  have no implemented retention cleanup or auth-user cascade;
  `delete-user` does not delete/anonymize those events.
  DoD: owner approves the minimum justified period and deletion/anonymization
  rule; implement both scheduled cleanup and deletion consistently, preserving
  required transaction integrity. Migration/function/pgTAP tests and guarded
  staging proof pass without raw receipts, signed payloads or secrets in logs.
  This is not permission to mutate production data during implementation.

- [ ] **M-1 / R-1 — Close privacy manifest and submission evidence.**
  Value: submission declarations must describe the actual executable and data
  flow. DoD: audit every embedded executable/SDK, validate required-reason API
  declarations and archive embedding, settle user-content classification and
  reconcile App Store Connect with W-1, S-1 and I-2. Capture archive privacy
  report, reachable policy/support/terms links, online-consent, export and
  deletion evidence. Use Apple's [per-executable required-reason guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
  Manifests already exist; do not recreate them. File extraction is not a
  prerequisite. Final metadata follows settled data behaviour; independent source
  checks need not wait for an artificial serial privacy programme. Release
  mutations/submission still require explicit authorization.

- [ ] **G-1 — Validate the archived service configuration, then prove live services.**
  Value: the distributed app must reach the intended services without privileged
  or development credentials. Source: `App/Info.plist` already has build-setting
  substitutions; `NativeRuntimeConfig` validates URLs/public-key shape, while
  checked-in target values are blank. Runtime parsing is not archive validation.
  DoD: reproducible per-environment public configuration reaches the intended
  archive; a release check rejects missing values, insecure URLs, cross-target
  contamination and privileged/development secrets. Inspect a real archive with
  public values present and secrets absent. Preserve existing bundle/App Store
  identity. Use it for the auth, gateway and deletion release proof, not another
  configuration abstraction or cosmetic key migration.

- [ ] **G-2 — Prove gateway policy, replay and database privileges once in staging.**
  Value: no duplicate cost, last-slot race, exposed usage mutation or indefinite
  retention. Source: `reserve_card_request`, `finalize_card_request`,
  `cleanup_gateway_requests` and `handleGenerateCard` implement these boundaries;
  source/tests do not establish deployed state.
  DoD: guarded migration dry-run/apply and advisors/privilege checks; reject
  direct client table/SECURITY DEFINER access; concurrent last-slot and duplicate
  requests yield one provider call/charge; replay matches payload/usage; reclaim,
  fresh-key expiry, cross-user isolation, failure and scheduled cleanup pass.
  Healthy approved synthetic requests pass quality; classify timeout, provider
  and quality failures before changing models or budgets. Verify the deployed
  path uses reservation/finalization rather than legacy pre-call charging.
  Explicitly exercise success with failed finalization and cancellation during
  completion: do not claim guaranteed no-charge cancellation or replay when the
  RPC outcome is unconfirmed. Preserve privacy-safe evidence and touch no production.

- [ ] **G-3 — Extend retry identity to named online adjustments.**
  Value: losing a response must not charge the same logical adjustment twice.
  Source: `GatewayCarefulMomentClient.adjust` generates a fresh UUID; only
  initial drafts use durable `CarefulRequestKeyStore` reuse.
  DoD: persist/reuse identity for an unchanged ambiguous adjustment, replace on
  provider-affecting changes, clear on success/fresh-key errors, and prove retry
  and relaunch replay. Include current text and adjustment in identity; retain
  server subject isolation and coordinate deletion with I-2. No general job queue.

- [ ] **G-4 — Approve launch allowance and first-value availability.**
  Value: pricing and sign-in must not defeat the first useful message.
  Source: the ledger allows one lifetime free authenticated request or 500/month
  entitled; gateway auth requires sign-in outside guarded development mode;
  Foundation Models availability is device/runtime-dependent. Paid local access
  and server capability are separate. These are implemented constraints, not
  approved commercial promises.
  DoD: accept/change the launch allowance and explicitly prove first value for a
  signed-out user with private writing available and unavailable. Choose an
  honest supported-device/availability policy or the smallest viable account
  flow; do not silently add anonymous production generation or assume an online
  fallback works signed out. Align Plan/Paywall/store/public copy and limit states.
  Numerical quota UI is not required: retain truthful unquantified higher limits
  unless counts demonstrably help; then supply success and exhaustion metadata
  end to end. Do not promise unlimited usage or gate careful treatment on Premium.

- [ ] **A-6 — Prove Apple account lifecycle and coordinated deletion on device.**
  Value: users must be able to leave without stale identity or lost unrelated
  writing. Source: native auth clients already set explicit 15s timeouts and
  account maintenance 20s; Apple exchange/revocation and indeterminate deletion
  are implemented. Do not add a duplicate timeout/lifecycle project.
  DoD: production-identity sandbox/TestFlight evidence covers first/repeat sign-in,
  missing code/server failure, refresh, credential revocation, sign-out, confirmed
  deletion→onboarding→fresh sign-in/relaunch, and indeterminate deletion preserving
  local writing without claiming success. Verify partial local failure honestly.
  No codes, tokens or private keys in evidence. Follow Apple's
  [account-deletion/token-revocation guidance](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple).

- [ ] **A-7 — Finish StoreKit and server-ownership evidence.**
  Value: money must buy the right account's access, and uncertainty must not
  invent or silently revoke it. Source: `StoreKitSubscriptionClient`,
  `MomentAccountModel` and the app-hosted `SKTestSession` suite already implement
  tri-state entitlement, deferred finish and ownership checks.
  DoD: execute the existing direct suite on a working supported stable runtime
  through `run_storekit_release_gate.sh`, with every expected scenario and zero
  failures/skips. Empty/wrong product results are failures, not an inferred Apple
  bug; do not assume a newer runtime fixes the observed issue without a rerun.
  Sandbox/TestFlight proves configured products, purchase and explicit restore
  without mandatory login, pending/cancelled/renewal/refund/revocation, transaction
  delivery/convergence and server notifications/reconciliation. Family Sharing
  is conditional on actually enabling it. Include valid/missing/mismatched
  `appAccountToken`, anonymous purchase then sign-in, and account switching in the
  same evidence matrix; no separate duplicate ownership gate or new purchase UI.
  Include an update-install over the previous App Store client under the same
  bundle identity, proving entitlement/restore behaviour and honest signed-out
  presentation.

- [ ] **A-8 — Close the remaining sign-out and paywall feedback gaps.**
  Value: a tap needs an honest outcome at the surface where it occurred.
  Source: sign-out has no owned busy state and ignores remote logout failure;
  paywall purchase/restore already show progress but do not render the shared
  account notice while the sheet remains open. Delayed automation already covers
  other generation/auth/product/restore/deletion paths.
  DoD: sign-out blocks duplicate actions and immediately exposes accessible busy
  state, with honest local-clear failure/retry. Local sign-out must not depend on
  a reachable logout server; distinguish local success from unconfirmed remote
  invalidation instead of waiting for impossible offline convergence. Paywall
  purchase/restore outcomes remain visible there, including pending, cancelled,
  failure and uncertainty, without a redesign or duplicate state owner. Extend
  existing delayed scenarios for these gaps and mutual action exclusion; preserve
  composer/drafts. Do not rebuild a matrix for every hypothetical network action.

- [ ] **Q-2 — Remove the remaining unbounded auth-test wait and prove auth rejection is cheap.**
  Value: a security regression must fail deterministically rather than hang CI
  or invoke a provider. Source: `AuthSessionTests` waits for refresh count using
  an unbounded `Task.yield` loop; `MomentModelTests.expectEventually` is already
  bounded. Gateway missing-auth and incorrect-dev-secret tests do not configure
  and assert a zero-call provider, unlike the missing-secret-configuration test.
  DoD: use an existing bounded synchronization pattern and assert zero provider
  calls for those rejection branches with a callable injected provider. No new
  generic test framework, flaky tag convention or broad timeout inflation.

- [ ] **Q-3 — Execute one core device, accessibility and sharing acceptance loop.**
  Value: implemented controls must be usable on the supported iPhone.
  DoD: first run→person/context→write→choose (only after W-2/W-3)→edit/adjust→
  Copy/Share/Save/recover passes, with offline/refusal/limit/failure states and
  preserved work. Until implemented, use the current single-draft loop honestly.
  Active and saved ShareLink pass with reviewed text, no send/destination claim
  on cancellation; Copy is exact; export produces the named decodable JSON file.
  VoiceOver, Dynamic Type, contrast, hit targets, keyboard/focus, Reduce Motion/
  Transparency, supported sizes and usable regular widths pass with no invalid
  frame warnings. Keep Write/Drafts/Settings discoverable; they already have
  distinct content, so no tab redesign or navigation-restoration project is a
  gate. Remove misleading “Native iOS” product copy in the touched Settings
  surface, not through repository-wide renaming. Use privacy-safe evidence.

- [ ] **Q-4 — Qualify or remove optional system surfaces.**
  Value: shortcuts can reduce effort only if they preserve review and existing work.
  Source: App Intent, widget/control and Share Extension already share sanitized
  `MomentHandoff`; package and app still define `AppShortcutsProvider` conformers.
  DoD: one intended provider in extracted app metadata; real production-like
  Shortcuts/widget/Control/Share Extension cold/warm launches hand off once to
  the correct environment and respect W-6 draft protection. No generation or
  auto-send in an extension. Remove an unqualified optional embedded surface
  from V1 rather than letting it delay the core loop. No typed-entity or Messages-
  domain expansion as a prerequisite.

## Triggered work — not V1 gates

- [ ] **T-1 — Re-evaluate PCC only when eligible and useful.**
  Trigger: stable adoption toolchain plus confirmed developer eligibility and
  managed entitlement, followed by evidence it improves this short-message job.
  Apple's [PCC API](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute)
  is real and requires iOS 27, Apple Intelligence-compatible device/region,
  network and daily quota handling; it is not an iOS 26 replacement or relief for
  devices ineligible for Apple Intelligence. Apple's [eligibility rules](https://developer.apple.com/private-cloud-compute/)
  require Small Business Program membership, download eligibility and entitlement
  approval; the quota/iCloud+ path is distinct from ProsePal Premium. Check the
  [release channel](https://developer.apple.com/news/releases/), not API presence,
  before changing the deployment/toolchain policy. DoD: a timeboxed service-boundary
  experiment proves quality, latency, refusal/cancellation, quota, consent and
  result parity; compare total operational complexity. Keep the existing gateway
  unless replacement earns a separate decision, including loss of PCC eligibility.
  No pre-emptive provider abstraction or commitment to migration.

- [ ] **T-2 — Strengthen vault protection before greater sensitivity or sync.**
  Trigger: approved cloud sync or materially more sensitive memory. DoD: a focused
  threat/data-lifecycle review decides whether application encryption is needed
  beyond current app-private storage and backup exclusion; no speculative cloud
  or key-management implementation before that product decision.

- [ ] **T-3 — Expand platform presentation only against user evidence.**
  Trigger: a supported market, accessibility or maintenance need unmet by the
  current product. DoD: scope the specific appearance/localization/iPad problem;
  use system controls and String Catalogs where they remove manual behaviour.
  `SubscriptionStoreView` or Writing Tools must preserve account-token delivery,
  entitlement, review, pressure checks and recovery before replacing current UI.
  Deeper navigation restoration and saved-library prominence need actual use
  evidence. Voice input first evaluates the system keyboard's existing affordance;
  no app-owned speech assets/permissions pipeline without demonstrated need.
  Do not turn this into a bundle of mandatory post-launch features.
