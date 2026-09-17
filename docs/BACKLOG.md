# Backlog

Unresolved work only. Implemented behaviour belongs in the
[feature ledger](./reference/feature-status.jsonl); execution results belong in
private release evidence and Git history. Remove an item when its DoD is met.
Source presence is not proof of device behaviour or deployed configuration.

## Scope and decision rules

The [product north star](./product/overview.md) is a better personal message,
faster: person first, optional guidance, useful choices, human review, and no
loss of the writer's words. The [V1 contract](./product/v1-launch-contract.md)
retains three choices behind its private-device feasibility gate. W-2 reopens
whether those choices earn their cost in either lane; a changed choice or
purchase/sign-in policy requires an explicit amendment to the owning product
contract before implementation, not an implicit exception here.

ProsePal should be a small, enjoyable, straightforward writing app: reliable,
honest about privacy and routing, and easy to maintain. It is not an AI
infrastructure science project, counselling product, crisis-intervention app,
or bespoke moderation/safety platform. Prefer deletion and simplification when
machinery does not earn its place. Keep cheap, justified input boundaries,
prompt/user-data separation, secret handling, provider/privacy controls,
quota/cost protection, graceful provider errors and truthful UI. These are
foundational protections, not a mandate to build a moderation engine.

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
  assessment, or fabricated quota/progress. Purchase identity is a G-4 decision;
  the current no-mandatory-login contract remains until deliberately amended.
- No secrets or user writing in tracked fixtures, diagnostics or release evidence.
  Use synthetic quality fixtures. New copy is localization-safe; touched colours
  are semantic and adaptive. Device and service evidence can proceed alongside
  local work; it never authorizes production mutations.

## Checkpoint sequencing and protected boundaries

The two independent audits establish the defects below, not approval of every
suggested repair. Source-confirmed findings and demonstrated scenarios are
distinguished from runtime measurements, deployed proof and unresolved design.
This documentation checkpoint authorizes no implementation.

| Work class | Owners and order |
|---|---|
| Demonstrated pre-release correctness | A-9 entitlement ordering; G-1 production Premium configuration (blocker); W-6 destructive launches; I-2 truthful generated-lane presentation; W-7 ephemeral save claims |
| Decisions before generation/purchase changes | W-8 online architecture and custom quality layer; W-9 crisis scope; W-2 measured candidate contract before W-3; G-4 purchase/sign-in behaviour |
| Evidence | G-2 local SQL CI then deployed proof; A-7 direct StoreKit execution; X-1 bounded compatibility/runtime checkpoint; W-2 prompt/wait measurements; Q-1 writing corpus |
| Cheap hardening | T-2 export-file protection; G-1 narrow effective-configuration gate |
| Future/developer experience | D-1 feature-status process; D-2 secret-history scope/performance; D-3 grouped dead machinery |

W-8 must assess current OpenRouter capabilities before repairing custom
fallback/filter/retry orchestration. W-9 settles crisis scope before preserving
or extending that subsystem. W-2/W-3 must not assume that three choices justify
extra generation; do not request four or five merely to make three survive.
Preserve X-1 as a separate checkpoint; do not start X-1, W-4, W-2 or W-3 as
part of this documentation work. Other existing release gates remain owned by
their items below.

Both audits found the current `AuthSessionController` refresh/cancellation
ordering, generation stale-result suppression, database ledger concurrency,
`RelationshipVaultLocalDataEraser` fallback deletion, development gateway-secret
handling, database privilege posture, basic prompt/user-material fencing and
client/server text-limit parity sound. Preserve these boundaries; missing
evidence or adjacent defects do not justify rewriting them. W-3 corrects online
directive provenance within the existing fencing architecture; G-2 adds SQL
proof without speculative ledger concurrency changes.

Explicit non-goals: broad `MomentExperienceView` refactoring, generic safety or
moderation engines, international crisis-support architecture, multi-provider
abstractions for their own sake, generic token-budget frameworks, broad
Xcode/iOS 27 modernisation, and repairing healthy auth/session/ledger code
merely because it was audited. Namespaced native and separately prefixed
Flutter preference keys do not establish a read-side collision; create no
migration/key-collision project. I-2 owns the actual legacy deletion residue.

## V1 — Writing value and integrity

- [ ] **W-2 — Decide candidate value, runtime context and the wait budget together.**
  Value: multiple choices must earn their latency, cost and complexity before
  ProsePal commits to them. Source: `GenerationTimeoutPolicy` and
  `FoundationModelsPrivateDraftClient` already implement one structured private
  draft with per-lane and total cancellation timers; those cooperative timers
  are not a measured user-visible deadline or a hard kill of an uncooperative
  child task.
  The Careful gateway's `parseProviderMessages`/`qualityCheck` contract requires
  three usable candidates with zero headroom: losing one to filtering fails the
  entire request, while `GatewayCarefulMomentClient` renders only the first.
  Neither relaxing to one nor requesting four or five is approved here.
  Decide whether V1 online writing offers one excellent response, three
  user-visible responses, or another deliberately measured contract, with W-8
  and Q-1 evidence. Amend the universal launch contract if the decision changes
  its three-choice promise; avoid accidental lane-dependent interactions.
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
  [PrivateDraftPromptPlan.init](../prosepal-ios/Sources/ProsePalAPI/FoundationModelsPrivateDraftClient.swift)
  includes all approved Truth Beads/relationship material without a measured
  count/context budget. Neither
  audit established the current runtime capacity; 4,096 tokens is not an
  accepted runtime fact. Use X-1 and current official Apple API documentation
  plus supported-device evidence to measure the actual context size and
  `tokenCount(for:)` or current equivalent, including schema, input and output.
  Budget/trim approved material intentionally and reserve output space for the
  chosen contract. Prove overflow/fallback remains truthful under I-2; private
  context overflow can route online while the UI still says “Private draft”.
  Keep the solution local to prompt construction, not a generic token framework.
  Evaluate prewarming only against current availability and measured benefit.
  A streaming variant must still validate the complete set before
  choice, persistence or sharing; do not build partial-output recovery.

- [ ] **W-3 — Deliver the smallest person-first writing loop after W-2.**
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

  Implement the deliberately approved W-2 contract after W-8, not an assumed
  candidate count. If three choices survive that decision, use one
  provider-neutral complete contract with stable IDs, explicit selection, equal
  visual weight and no invented ranking. Preserve gateway replay exactly; expose
  the approved choices rather than silently treating the first as a winner.
  Only supported named adjustments follow selection. Remove decorative variant
  dots or word-substitution tricks if they cannot truthfully explain a choice.
  Represent named adjustment and register guidance as typed app-owned metadata,
  not prose encoded inside free-form `things_to_include` or `user_context`.
  User-provided draft and context must remain clearly distinguishable as quoted
  user material. `MomentInput.gatewayIntent` in
  [GatewayCarefulMomentClient](../prosepal-ios/Sources/ProsePalAPI/GatewayCarefulMomentClient.swift)
  currently mixes this
  app guidance with user text; correct that provenance in the generation contract,
  not through phrase/prefix inference. The user-material fence can currently
  tell the model to ignore app-authored directives placed inside it. Keep this
  defect owned here rather than duplicating a gateway rewrite.
  Future `things_to_avoid` exclusions must define phrase/word semantics: gateway
  `qualityCheck` currently uses substring matching, so `age`, `art` and `ill`
  can reject `message`, `heart` and `still`. This field is not reachable from the
  shipped native client; test it with W-3's exclusions, not as a current blocker.
  Preserve chosen text and undo/history across option changes and relaunch with a
  versioned recovery envelope that reads existing single-draft state. Invalidate
  stale results on changed intent without silently destroying recoverable writing.
  Stop, backgrounding, supersession, timeout and late-result tests remain common
  to both lanes. Compact/large-text UI and VoiceOver prove choice-to-edit handoff.

  Another remains a fresh initial draft, not adjustment context. Contract
  changes must include Swift/gateway contract, enum and version parity and
  backward-compatible handling of the existing single-draft state; no separate
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

- [ ] **W-6 — Preserve unsaved work through recovery and incoming handoffs.**
  Value: relaunch or a shortcut must not erase the user's only wording.
  Source: `MomentModel.persistDraftRecovery` requires an existing bundle;
  pre-generation input has no recovery envelope. `applyLaunchRequest` and
  `resetDraftForMomentChange` clear bundle/history/recovery; the root applies an
  incoming handoff directly. Input invalidation and preservation are different
  responsibilities.
  Confirmed pre-release defect: `applyLaunchRequest` unconditionally resets even
  when no meaning-bearing input changes, bypassing `meaningBearingInputDidChange`.
  It can erase the current draft, undo history and recovery envelope, including
  immediately after cold-launch restoration. `StartMomentIntent.perform` writes
  a pending request that the warm-running root does not promptly consume; it can
  unexpectedly apply at a later cold launch.
  DoD: first fix unchanged-launch destruction and warm consumption narrowly in
  [MomentModel](../prosepal-ios/Sources/ProsePalUI/Features/Moment/MomentModel.swift),
  [MomentAppRootView](../prosepal-ios/Sources/ProsePalUI/MomentAppRootView.swift)
  and the existing launch store; prove same-value/empty handoffs preserve draft,
  history and recovery, cold restoration survives and a warm intent applies once
  without delayed cold replay. Do not invent a handoff subsystem.
  Separately, versioned recovery can preserve meaningful composer input before
  a first result; changing intent prevents old-result acceptance without losing a
  recoverable prior draft; an incoming handoff with existing work requires an
  explicit replace/discard decision or preserves that work first. Keep this in
  `MomentModel` and the existing stores, not a second draft system. Test relaunch,
  declined replacement, accepted replacement, Stop, background, legacy envelopes
  and account reset. Explicit New Moment/discard and confirmed account deletion
  still clear recovery. No automatic resume or saved-library insertion.

- [ ] **W-7 — Make save outcomes durable and roll back failed insertions.**
  Value: “Saved” must mean durable data; “Could not save” must not leave a pending
  duplicate or approved memory that a later save silently commits.
  Source: `MomentSheetView.save`,
  `addTruthBead` and `addVoiceCard` insert before saving and catch without rollback;
  extracted saved-writing/memory edit/delete seams already handle rollback.
  Confirmed pre-release defect:
  [RelationshipVaultContainerFactory.makePersistentOrEphemeral](../prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift)
  can fall back after persistent-container/maintenance failure; in-memory
  `save()` still succeeds and `MomentSheetView.save` says “Saved”, although the
  data disappears on termination. The on-disk store may remain recoverable.
  DoD: do not claim durable persistence in ephemeral fallback. Expose the
  existing storage mode through a clear minimal degraded state and honest save
  outcome; preserve the recoverable disk store instead of silently replacing it.
  Test injected persistent/maintenance failure and ephemeral save presentation,
  without an elaborate recovery UI or a persistence-layer replacement.
  Reuse the existing persistence pattern for insertion failures,
  preserve input, and prove retry creates one record and unrelated subsequent
  saves do not commit the rejected insertion. No schema or persistence-layer
  replacement. Keep account/local erase failures visible under I-2.

- [ ] **Q-1 — Finish lane-specific live writing-quality acceptance.**
  Value: useful, faithful writing is the product, not an implementation detail.
  DoD: separately approved synthetic private and careful samples satisfy the
  [quality rubric](./quality/writing-quality-rubric.md) for preserved facts,
  no invented personal details, tone/length, sensitive occasions, pressure and
  internal-language leakage. Score each candidate and, if multiple choices are
  approved, meaningful set variation; reuse W-2's private evidence where
  applicable. Failures receive explicit
  release-owner disposition. Re-evaluate meaning-affecting changes; do not rerun
  live writing for unrelated persistence-only work. No user-content retention or
  mental-health inference or expansion of a bespoke safety system. W-9 owns
  whether the existing crisis branch should remain at all.
  Include a ProsePal short-form writing corpus for W-8: everyday names and
  phrases, assistant/meta leakage, sympathy/bereavement/grief and difficult
  emotional messages. Measure false refusals/rejections, naturalness and the
  actual selected candidate contract rather than generic intelligence scores.

- [ ] **W-8 — Reassess the online path and simplify custom quality machinery.**
  Value: one proven simple online-generation path should beat home-grown
  provider orchestration. Confirmed defect in
  [generate-card](../supabase/functions/generate-card/index.ts):
  `internalTermPattern`, `genericFillerPattern`, `sensitiveClichePattern` and
  `qualityCheck` reject legitimate writing while obvious assistant/meta leakage
  can pass. Demonstrated false positives include role model, model railway,
  model student, care provider, Gemini as a zodiac/name, Claude as a recipient,
  ordinary vertex usage, “Wishing you all the best” and common greeting-card
  clichés/prose. `callOpenAICompatibleProviderWithFallbacks` can repeat the same
  deterministically rejected request across models, adding latency and cost.
  The future work is to simplify and re-evaluate the custom quality/guardrail
  layer, not add more regexes or schedule a moderation framework.

  DoD: before repairing that architecture, verify current official OpenRouter
  routing, provider failover, model fallback, Auto Router and privacy/ZDR
  capabilities and constraints. Compare one curated model with OpenRouter
  provider routing/failover; one curated primary with a very small native
  OpenRouter model-fallback list; current Auto Router as an evaluation candidate;
  and direct provider integration if OpenRouter no longer adds enough value.
  Use Q-1's ProsePal writing corpus to compare writing quality, naturalness,
  emotional appropriateness, consistency, latency, cost, privacy/ZDR availability,
  provider reliability, false refusal rate, operational complexity and code
  complexity. Verify actual provider/model terms and available controls rather
  than infer them from endpoint compatibility or provider safety claims.
  Explicitly identify custom filters, fallback and retry machinery made
  redundant by current provider/model safety and OpenRouter capabilities.
  Record the smallest justified path and retained protections in the owning
  generation decision/contract. Coordinate W-2 candidate count and W-4 typed
  cancellation/refusal, preserving quota, privacy permission and prompt fencing.
  Research is not permission to implement or deploy a replacement.

- [ ] **W-9 — Decide whether a crisis/helpline subsystem belongs in ProsePal.**
  Value: keep ordinary emotional writing support without making a small writing
  app responsible for crisis intervention. Confirmed source: `MomentSafetySignal`
  and `indicatesCrisisSupportNeed` in
  [MomentModels](../prosepal-ios/Sources/ProsePalDomain/MomentModels.swift), and
  `MomentSheetView.crisisSupportSection` in
  [MomentExperienceView](../prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift)
  still implement special crisis handling and hard-coded regional phone numbers.
  DoD: determine whether this subsystem is needed at all; product direction
  strongly favours removal unless an explicit requirement justifies retention.
  Inventory crisis detection, helpline UI, distress/self-harm handling, tests,
  documentation, prompts, analytics and backlog references for that decision
  and any later narrow removal. Do not assume internationalising helplines is
  the answer. Sympathy, bereavement, grief and difficult emotional messages
  remain valid writing use cases; preserve ordinary provider refusal handling
  and cheap foundational protections without a custom crisis platform.

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
  Confirmed pre-release defect: `MomentSheetView.draftSection` in
  [MomentExperienceView](../prosepal-ios/Sources/ProsePalUI/MomentExperienceView.swift)
  can label gateway-produced `.standardDraft` output “Private draft 🔒”. The
  actual generation lane is persisted but is not consistently used for
  provenance. This is a false privacy claim, not copy polish.
  DoD: simply and truthfully communicate on-device/private, online/Careful and
  fallback provenance using actual generation-lane state, including saved and
  recovered results and online adjustments. Test gateway `.standardDraft`,
  private success and private-context-overflow fallback with no private lock
  claim on online output. Explain current-draft transfer and memory-derived
  wording accurately; preserve prospective revocation semantics unless a
  separate demonstrated need justifies stronger cancellation.
  Prefer the precise “Delete Saved Writing
  Data” name over expanding a vault-only eraser into account/auth destruction;
  confirm the owner decision and list inclusions/exclusions before deletion.
  Report partial failure, including session-store clear failure after account
  deletion rather than implying all local credentials were erased. Explicitly
  settle recovery/handoffs, request-key metadata and export-file treatment for
  each deletion action using the [data map](./engineering/data-and-privacy.md).
  Explicitly treat legacy pre-native local state written by the previous App
  Store client under the same bundle identity: deletion must erase it or
  accurately document its exclusion. Migration of legacy content is not required.
  The concrete audit finding is old Supabase user identifiers retained in legacy
  preferences after upgrade/account deletion; inventory and settle erasure of
  those keys. Native key namespacing and Flutter preference prefixes make the
  feared read-side collision effectively irrelevant. Keep this deletion-scoped;
  do not reopen `RelationshipVaultLocalDataEraser`'s sound fallback behaviour.
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
  S-1 retention, approved candidate-count wording and approved allowance copy.
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
  Confirmed pre-release blocker from effective Release build-setting evidence:
  production `ProsePal` has no Premium product IDs, while Staging does. Current
  release/config checks can accept a production archive with a non-functional
  paywall. The audit established effective settings, not just pbxproj text.
  DoD: reproducible per-environment public configuration reaches the intended
  archive; a release check rejects missing values, insecure URLs, cross-target
  contamination and privileged/development secrets. Inspect a real archive with
  public values present and secrets absent. Preserve existing bundle/App Store
  identity. Use it for the auth, gateway and deletion release proof, not another
  configuration abstraction or cosmetic key migration.
  Verify effective Release settings and the built archive, including
  `PROSEPAL_PREMIUM_PRODUCT_IDS` and the recommended product, against the
  approved StoreKit inventory. Add a narrow gate that fails missing/malformed
  production Premium configuration; Staging values must not satisfy it.

- [ ] **G-2 — Prove gateway policy, replay and database privileges once in staging.**
  Value: no duplicate cost, last-slot race, exposed usage mutation or indefinite
  retention. Source: `reserve_card_request`, `finalize_card_request`,
  `cleanup_gateway_requests` and `handleGenerateCard` implement these boundaries;
  source/tests do not establish deployed state.
  Confirmed evidence gap: pgTAP/database suites exist under `supabase/tests` but
  are not automated; TypeScript Edge Function tests stub RPC behaviour and do
  not prove real SQL quota/ledger/idempotency semantics.
  DoD: first add a deterministic local-Supabase/pgTAP CI gate using `supabase test db`
  and the existing separate-session concurrency proof where relevant. Fail on
  SQL/privilege/ledger regressions without live services or masked retries.
  Preserve the audited sound ledger concurrency and privilege design; missing
  tests are not evidence for changing it. Then guarded staging migration
  dry-run/apply and advisors/privilege checks; reject
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
  Confirmed design gap: a purchase without the server identity needed for online
  entitlement does not automatically associate after later sign-in. Compare
  requiring sign-in before purchase where server entitlement is required with
  reconciliation only if anonymous-purchase-first UX genuinely warrants it.
  Settle signed-out purchase, subsequent sign-in and account-switch behaviour
  explicitly with A-7; update the current no-required-purchase-login product
  contract if chosen. Do not assume a complex reconciliation system or silently
  promise server access from local StoreKit entitlement alone.
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
  Evidence gap: the direct release suite/gate is manual and prior execution was
  blocked by StoreKit test execution behaviour. X-1 must retry it before any
  StoreKit redesign; a skipped or blocked run is not passing evidence.
  DoD: execute the existing direct suite on a working supported stable runtime
  through `run_storekit_release_gate.sh`, with every expected scenario and zero
  failures/skips. Empty/wrong product results are failures, not an inferred Apple
  bug; do not assume a newer runtime fixes the observed issue without a rerun.
  Sandbox/TestFlight proves configured products, purchase and explicit restore
  under the deliberately approved G-4 identity policy (currently without
  mandatory login), pending/cancelled/renewal/refund/revocation, transaction
  delivery/convergence and server notifications/reconciliation. Family Sharing
  is conditional on actually enabling it. Include valid/missing/mismatched
  `appAccountToken`, purchase/sign-in order (anonymous purchase then sign-in if
  retained by G-4), and account switching in the same evidence matrix; no separate
  duplicate ownership gate or new purchase UI.
  G-4 owns the purchase-before-sign-in design decision; A-9 owns the demonstrated
  server event-ordering defect. Do not mistake this evidence gate for either fix.
  Include an update-install over the previous App Store client under the same
  bundle identity, proving entitlement/restore behaviour and honest signed-out
  presentation.

- [ ] **A-9 — Make App Store server entitlement ordering transaction-aware.**
  Value: a paying subscriber must not lose online Pro quota to a stale event.
  Confirmed pre-release correctness defect in
  [app-store-notifications.handleAppStoreNotification](../supabase/functions/app-store-notifications/index.ts):
  entitlement upsert is effectively last-writer-wins on `user_id`, without
  comparison to existing state. `app_store_signed_date` is stored but not an
  ordering guard; duplicate UUID event-ledger insertion does not prevent
  entitlement reapplication. Multiple independently demonstrated replay/order
  scenarios let stale revocation overwrite newer active entitlement state;
  server quota can then reduce a subscriber to the lifetime free allowance.
  The key is too coarse to safely reason about multiple transaction histories.
  DoD: decide and implement atomic ordering/idempotency semantics that account
  for original transaction identity, duplicate notification UUID, missing and
  equal signed dates, ordering semantics, resubscription and replacement
  transactions. Comparing `signed_date` alone is not an accepted final design.
  Deterministic notification and real SQL tests prove replay, out-of-order
  active/revoked transitions and independent/replacement histories cannot
  regress effective entitlement or quota; coordinate reconciliation semantics
  and A-7 evidence without altering the healthy quota ledger concurrency.

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

## Bounded compatibility and runtime evidence checkpoint

- [ ] **X-1 — Run the Xcode 27 / iOS 27 compatibility checkpoint separately.**
  Value: replace toolchain/runtime assumptions with evidence without broad
  modernisation. DoD: establish active Xcode, Swift and SDK versions and release
  channel; run existing relevant validation under Xcode 27 and record failures
  without upgrading scope by default. Retry A-7's direct StoreKit release gate,
  preserving blocked/skipped outcomes honestly. Query actual Foundation Models
  runtime context size and use `tokenCount(for:)` or current equivalent for
  representative synthetic ProsePal prompts, schema, approved memory and output
  headroom. Verify API availability/constraints against current official Apple
  documentation; correct stale fixed-context assumptions in owning documents.
  Evaluate current writing behaviour with Q-1's corpus and pass the evidence to
  W-2. This is compatibility/evidence work, not broad Xcode/iOS 27 adoption,
  PCC integration, StoreKit redesign or W-2/W-3 implementation. Do not run it
  during the documentation checkpoint.

## Future — developer experience and proportionate repository machinery

- [ ] **D-1 — Reassess feature-status claim accuracy and maintenance cost.**
  Value: useful evidence without noisy bureaucracy for a small app. Audit
  evidence: 58 of 63 records referenced tracked evidence files changed since
  their verification point, but file changes do not automatically invalidate a
  claim. The second audit found both still-correct records and at least one
  genuinely incorrect claim. Source:
  [feature-status.jsonl](./reference/feature-status.jsonl) and
  `scripts/validate_feature_status.py`.
  DoD: inspect claims semantically, correct confirmed inaccuracies and decide
  whether this level of ledger machinery remains proportionate. If retained,
  prefer PR-scoped contributor attention or another low-noise process over a
  global “file changed therefore stale” failure. Preserve canonical JSONL/export
  parity; do not refresh verification stamps without behavioural evidence.
  This process review is not a pre-release product blocker.

- [ ] **D-2 — Reduce secret-history guard cost and tighten scan exclusions.**
  Value: fast ordinary PR feedback with meaningful security coverage. Confirmed
  audit evidence: full fetched-history scanning cost roughly one minute at
  about 1,264 revisions; CI fetches full history where the guard runs.
  [security_history_guard.sh](../scripts/security_history_guard.sh) excludes
  all Markdown/docs from secret-pattern scanning and retains a dead `test/**`
  exclusion. DoD: evaluate PR-range scanning for ordinary PRs with occasional,
  scheduled or release full-history assurance; tighten exclusions so docs are
  not a blanket secret-pattern blind spot. Preserve fail-closed behaviour,
  sensitive-output suppression and meaningful guard tests. This is developer
  experience/security hardening, not an immediate product blocker; coordinate
  the stale exclusion with D-3 rather than duplicate its cleanup.

- [ ] **D-3 — Delete clearly dead or redundant repository machinery together.**
  Value: less maintenance without a broad cleanup campaign. Inventory:
  unreachable second failed-`qualityCheck` branch after the provider loop has
  already accepted quality; obsolete Flutter-era `scripts/build_release.local.sh`;
  stale `test/**` history-guard exclusion (D-2 owns scan policy); and clearly
  obsolete RevenueCat-era paths referenced by dead scripts.
  DoD: verify reachability/callers, delete only proven dead machinery, update
  owning references and validate the remaining runnable paths. W-8 owns quality
  architecture decisions; do not use cleanup to pre-empt those decisions,
  recreate Flutter, erase migration history or rename healthy Native symbols.
  Do not perform cleanup in the documentation checkpoint.

## Cheap hardening and triggered work — no speculative expansion

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

- [ ] **T-2 — Protect temporary exports now; gate broader vault encryption on need.**
  Cheap hardening independent of sync: confirmed plaintext temporary exports in
  [RelationshipVaultExporter.writeExportFile](../prosepal-ios/Sources/ProsePalAPI/RelationshipVault.swift)
  are atomically written without explicit complete file protection and can
  survive termination until a later cleanup opportunity. DoD for this narrow
  fix: apply explicit complete protection, bound cleanup lifetime and test file
  attributes/cleanup while preserving sharing and I-2 deletion scope. Do not
  build a recovery or encryption framework.
  Broader trigger: approved cloud sync or materially more sensitive memory.
  DoD: a focused threat/data-lifecycle review decides whether application
  encryption is needed beyond current app-private storage and backup exclusion;
  no speculative cloud or key-management implementation before that product decision.

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
