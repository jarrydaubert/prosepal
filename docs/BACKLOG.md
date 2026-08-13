# Backlog

This file contains unresolved work only. Completed behavior and verification
history belong in `docs/reference/feature-status.jsonl`, release evidence, and
git history. The adjacent CSV is a generated compatibility export, not an
editable source.

Every item uses `[ ]` until its definition of done is fully satisfied. Remove a
completed item instead of turning this file into a status log.

## Working Rules

- Reliability, security, auth, payments, and user-data integrity take priority.
- Do not change another SwiftData `@Model` without a new `VersionedSchema` and
  explicit migration stage.
- When touching `MomentExperienceView.swift`, extract the affected surface when
  the boundary is safe and replace source-string guards with behavioral or
  view-layer coverage where practical.
- The monolith line-count and source-string-test ceilings are shrink-only:
  lower both relevant baselines in the same commit as each extraction.
- New user-facing copy must use localization-safe APIs. New colors must be
  semantic and adaptive even while full localization and Dark Mode remain
  post-v1 work.
- Run Apple, Supabase, StoreKit sandbox, TestFlight, and physical-device setup in
  parallel with locally testable engineering work.
- Never put provider secrets, service-role keys, Apple private keys, development
  gateway secrets, tokens, receipts, or user message content in tracked build
  settings, fixtures, logs, or evidence.

## Native V1 — Engineering

- [ ] Complete lane-specific live writing-quality evidence for private and
  careful generation. DoD: separately approved live samples exercise the full
  representative rubric across both lanes without retaining user content or
  secrets; every candidate is scored individually and each three-option set is
  reviewed for meaningful variation rather than superficial paraphrases;
  preservation, invented personal facts, tone/length, everyday/careful writing
  mode, guilt or pressure, and provider/internal-language leakage all pass or
  have an explicit release-owner disposition. Every change expected to affect
  generated meaning or presentation reruns the deterministic baseline in
  `docs/quality/ai-output-quality.md` and, where required, the approved lane-
  specific review; persistence-only schema changes do not trigger an unrelated
  writing evaluation. Custom crisis classification and mental-health inference
  are out of scope.

- [ ] Define one measured end-to-end generation deadline across fallback
  attempts. DoD: the release owner first approves an initial user-visible
  ceiling and one total fallback budget; repeated device and staging measurements
  then confirm or explicitly revise that contract. Private-device measurements
  use the existing debug scheme, not a separate harness app, and compare the
  current single structured draft, complete one-session three-option generation,
  streamed time-to-first-useful-text, and complete streamed output across
  representative Brief, Standard, and Detailed fixtures. The same approved
  private-device runs score every completed synthetic output with the
  deterministic evaluator and retain the first live private-lane scorecard next
  to the timing evidence; the current single-draft control is scored per
  candidate, while complete three-option runs also receive a useful-choice set
  score. Fallback cannot extend the wait unintentionally; long waits receive
  honest progress copy; deterministic tests cover deadline propagation,
  cancellation, and late-result suppression.

  The current `GenerationTimeoutPolicy.total` value is a technical cancellation
  backstop that prevents unbounded work; it is not the release-owner-approved
  user-experience deadline or evidence that the current wait is acceptable.

- [ ] Prove and deliver the approved choose-before-edit three-option writing
  flow without weakening private-first routing. DoD: the gateway client
  preserves all three distinct `CardResponse` messages instead of selecting an
  unranked first element, including exact request-ledger replay; one Foundation
  Models session produces and validates three distinct private options on a
  supported physical iPhone within the measured end-to-end deadline; both lanes
  expose one provider-neutral option-set contract without revealing routing.
  Execution order is mandatory: approve the end-to-end deadline, run a
  timeboxed private-device three-option spike, record the gate decision, and
  only then begin production domain, recovery, and UI work. The spike compares
  complete single-shot generation with `LanguageModelSession` streaming and
  prewarming, and may conclude that single-shot completion is already fast
  enough. Streaming must earn its state, recovery, accessibility, and lane-
  parity complexity; it is not a preselected implementation requirement.

  The composer presents person, explicitly confirmed relationship, and occasion
  before one skippable relationship-by-occasion question that replaces the
  generic blank-detail prompt. “Help me personalise it further” reveals no more
  than two additional inline questions; generation remains available when the
  questions are unanswered once the required person/relationship/occasion
  context is valid. Personal detail, message goal, and things to avoid remain
  structurally distinct, use stable cue identifiers, survive backward-compatible
  draft recovery, and reach both private and careful prompts without raw answer
  text entering diagnostics or analytics. The deterministic question bank is
  owned by a small set of occasion families with relationship-aware wording, a
  reviewed generic fallback, and editorial checks preventing sympathy/apology
  prompts from probing circumstances, assigning blame, or encouraging pressure.
  Tone and length retain honest defaults inside one compact Style disclosure;
  no hidden `closeFriend` default can be sent for an unconfirmed relationship.

  `MomentRegister` stops being user-controlled or hidden mutable compose input.
  New initial drafts derive everyday-versus-careful treatment from occasion
  policy and writing-service availability/fallback; the narrow defensive content
  block remains a separate refusal rule, not a routing mode. Legacy register
  recovery values decode safely, but regeneration normalizes them to the new
  derived policy. Prompt context, pre-result careful styling, and the local
  Pressure Check no longer depend on an unreachable register selection.
  A routing-parity matrix records every current occasion-to-initial-lane result
  before and after the migration, with every intentional change named and
  approved.

  Results say “Three ways to say it,” give all options equal visual weight with
  no invented best ranking, and require an explicit choice before the existing
  edit/adjust/copy/share/save flow. Post-choice rewriting stays optional and
  contextual: only the existing named adjustments remain available, and any new adjustment
  vocabulary must be supported by both lanes, the quality rubric, and occasion
  rules before appearing (for example, no “Funnier” promise on sympathy).
  Candidate sets and the chosen draft survive relaunch, changing any
  meaning-bearing input invalidates stale candidates, and choosing or switching
  an option never destroys recoverable wording.

  Each finalized candidate has a stable identifier and recovery stores the
  chosen candidate identifier rather than relying on array position. Only a
  complete, validated three-candidate set can become selectable or persistent;
  cancellation or Stop before completion discards incomplete fragments and
  returns to an honest retryable composer state. Recovery uses a versioned draft
  envelope that still decodes the current single chosen editable draft; it is
  distinct from SwiftData model versioning.

  If and only if the spike adopts streaming, the shared generation state owns
  idle, preparing, generating progress, awaiting three-way choice, and editing;
  deterministic scenarios cover complete success, cancellation before
  completion, meaning-bearing input mutation, retry with late-result suppression,
  background cancellation, total-budget expiry/fallback, and gateway completion.
  One private `LanguageModelSession` may live only for one composer epoch: any
  meaning-bearing change destroys it, prewarming is debounced, and backgrounding
  cancels it. The gateway may report truthful generic progress but must not fake
  streamed candidate text or expose a lane-divergent result screen.

  Deterministic domain/service/model tests cover cue selection, blank/partial
  answers, include-versus-avoid mapping, legacy recovery decoding, input limits,
  candidate variation, cancellation, and lane parity. Compact and
  accessibility-size UI automation proves the quick path, expanded guidance,
  Style disclosure, three-way choice, and edit handoff; VoiceOver review,
  writing-quality evaluation, and physical-device evidence pass. Current-
  behaviour docs and evidence change from one draft to three choices only when
  the private-lane gate and implementation pass. If the private prototype misses
  the agreed deadline, make an explicit universal fallback and v1-scope decision;
  never ship lane-divergent result UX.

- [ ] Make root navigation destinations distinct, discoverable, and accessible.
  DoD: each root destination has unique content and state restoration; Settings
  remains reachable; keyboard, VoiceOver, accessibility text sizes, and compact
  and regular widths retain a complete path; touched navigation views leave the
  monolith with behavioral coverage.

- [ ] Make critical asynchronous tests fail fast and prove rejected requests
  have no expensive side effects. DoD: auth refresh and Moment-model test
  synchronization has an explicit deadline instead of unbounded polling;
  bounded waits use deterministic synchronization or a shared fail-fast helper;
  auth and development-secret rejection tests configure a callable provider and
  explicitly assert that it receives zero requests; regressions fail rather than
  hanging the test run.

- [ ] Complete cross-cutting asynchronous feedback UI automation. DoD: a durable
  matrix covers generation, Sign in with Apple, product loading, purchase,
  restore, account deletion, sign-out, and every other user-triggered durable
  network action. Deterministic delayed success, failure, and indeterminate
  scenarios, where applicable, prove that each action acknowledges the tap
  immediately, exposes an honest accessible in-progress label or announcement,
  blocks accidental duplicate submission, preserves drafts and composer input,
  avoids an apparently frozen screen, and reaches a confirmed success, explicit
  failure with retry, pending/cancelled outcome, or honest indeterminate state.
  No scenario may expose invented percentage progress or claim completion
  before its injected boundary confirms the outcome. Assertions use stable
  actions and outcomes rather than exact copy, timing, view hierarchy, or the
  volatile composer and result-screen layout. Every unclear, inconsistent, or
  misleading waiting experience found by the matrix is reported as a named
  product finding with a dedicated follow-up slice rather than being hidden
  inside test work.

- [ ] Give sign-out a complete local asynchronous feedback lifecycle. DoD:
  sign-out acknowledges the tap immediately, owns visible and accessible
  in-progress feedback, blocks duplicate taps, preserves unrelated drafts and
  composer input, reports failure with a retry path, and never claims completion
  before local and remote session clearing converges. Deterministic delayed
  success and failure UI scenarios prove each state without exact-copy or
  layout assertions.

- [ ] Keep purchase and restore outcomes visible inside the open paywall. DoD:
  purchase and restore expose action-specific accessible progress, prevent
  duplicate submission, preserve durable drafts and composer input, and keep
  confirmed success, failure, pending, cancelled, and indeterminate outcomes at
  the action surface instead of relying on a transient notice behind the sheet.
  Deterministic delayed UI scenarios cover every supported outcome without fake
  percentage progress or early completion. Keep this a focused feedback slice,
  not a paywall, composer, or result-screen redesign.

- [ ] Capture physical-device evidence for outgoing ShareLink and local-data
  file export. DoD: on a supported iPhone, active and saved drafts each present
  the system activity sheet with the reviewed text; cancelling records no send
  or destination; Copy places the exact visible text on the pasteboard; the
  local-data action presents a `.json` file with the generated filename and
  decodable expected contents; VoiceOver announces Copy and Share accurately;
  evidence is filed without exposing draft text or export contents.

- [ ] Complete the ordered privacy-truth and data-control programme before
  extracting Privacy & Data. The remaining slices below are independently
  reviewable and execute in order: I-1, W-1, S-1, I-2, A-2, M-1, then R-1.
  I-1, W-1, S-1, and I-2 are prerequisites for A-2. All mandatory release
  gates must close before release; they are not all prerequisites for beginning
  A-2.

  Mandatory release gates:

  - verify the production providers' binding retention, training, and data-use
    terms
  - implement and test online-writing permission
  - correct the public Privacy Policy, support, and terms surfaces
  - correct technical data-flow, retention, export, and deletion claims
  - implement the approved App Store event retention and deletion policy
  - reconcile privacy manifests and App Store Connect declarations
  - capture privacy-safe release evidence for the resulting build and public
    surfaces

  Open product-owner decisions:

  - online-writing permission wording and first-use presentation
  - whether local deletion expands or keeps the precise name “Delete Saved
    Writing Data”
  - the canonical public contact
  - Standard EULA or a custom EULA
  - App Store Connect user-content classification
  - whether customer-visible quota and three-option claims are supportable
  - the App Store event retention period
  - the exact Vercel analytics disclosure

  Ordered slices:

  - I-1 — require explicit, revocable online-writing permission.
    - Ownership: the `MessageWritingService` routing boundary in `ProsePalAPI`
      enforces permission immediately before online work; app composition owns
      one versioned permission store; `ProsePalUI` owns only provider-neutral
      permission presentation.
    - DoD: direct careful generation, automatic fallback, and adjustments all
      require a current explicit grant. Denial, withdrawal, or a stale policy
      version causes zero gateway calls and leaves a truthful local path or
      actionable unavailable state. Permission can be reviewed and revoked
      without signing out or deleting local writing.
    - Dependencies: the canonical technical data map, verified production-
      provider terms, and approved permission wording and first-use
      presentation.
    - Non-goals: provider names or SDKs in the UI, quota or paywall changes,
      account-behavior changes, or a privacy view model, coordinator, router,
      manager, or service locator.
    - Evidence: service-spy tests for direct, fallback, adjustment, withdrawal,
      and policy-version cases; UI automation for first use and revocation; and
      privacy-safe staging evidence that a rejected route sends no request.

  - W-1 — make the public privacy, support, and terms surfaces match the
    product.
    - Ownership: the corresponding public routes in `prosepal-web` own customer
      policy and support copy; the iOS app links to those canonical surfaces.
    - DoD: publish accurate routes, processors, retention, deletion, export,
      contact, EULA, analytics, and current-product language. Remove stale
      Google, Gemini, RevenueCat, Firebase, device, and analytics-toggle claims,
      plus unsupported training, quota, or three-option claims.
    - Dependencies: the canonical technical data map, verified provider terms,
      and owner decisions for contact, EULA, Vercel analytics, quotas, and
      three-option wording.
    - Non-goals: a website redesign, iOS runtime changes, or duplicating the
      full policy inside the app.
    - Evidence: web validation, live-route review, link checks from the app, and
      a cross-surface claim comparison.

  - S-1 — enforce an App Store event retention and deletion policy.
    - Ownership: Supabase migrations and functions own App Store notification
      and reconciliation event tables, cleanup, and account-linked deletion or
      anonymization.
    - DoD: implement the approved retention period, scheduled cleanup, and the
      selected deletion or anonymization behavior; ensure account deletion and
      routine cleanup honor the same policy; never log event payloads, receipts,
      secrets, or user content.
    - Dependencies: the canonical technical data map and the owner-approved App
      Store event retention period.
    - Non-goals: production-data mutation in the implementation pull request,
      gateway quota redesign, or unrelated schema cleanup.
    - Evidence: migration, function, and pgTAP coverage; guarded staging cleanup
      and deletion proof; and privacy-safe logs.

  - I-2 — make in-app privacy controls and claims truthful before extraction.
    - Ownership: existing local persistence and erasure owners perform data
      changes; `MomentAccountModel` retains account deletion; `ProsePalUI` owns
      only presentation and confirmation.
    - DoD: implement the selected local-deletion scope and matching name. The
      action either deletes all locally named writing stores or precisely says
      that it deletes saved writing only. Preserve the separate account-deletion
      contract, remove unsupported status or training claims, and report partial
      or failed deletion honestly.
    - Dependencies: the canonical technical data map, I-1, W-1, and the owner
      decision on local-deletion scope and naming.
    - Non-goals: deleting authentication or subscription state, changing
      account deletion, creating a second persistence owner, or performing the
      A-2 file move.
    - Evidence: behavioral deletion and failure tests, UI automation and
      VoiceOver review, and regression proof that local deletion does not change
      account, session, or subscription state.

  - A-2 — simplify and extract Privacy & Data after its truth and controls are
    settled.
    - Ownership: `Features/Privacy/MomentPrivacyDataView.swift`,
      `Features/Privacy/MomentLocalDataExportView.swift`, and
      `Features/Privacy/MomentLocalDataExport.swift` own presentation and the
      export contract; existing exporters, erasers, and `MomentAccountModel`
      retain their current data ownership.
    - DoD: use a standard `Form` and navigation, a permission `Toggle`,
      `ShareLink`, public-policy `Link` actions, and destructive confirmation.
      Remove custom top chrome and status cards plus JSON preview, Copy, and
      Refresh affordances. Add representative compiling previews, preserve
      stable accessibility identifiers where behavior is unchanged, and update
      architecture ownership and shrink-only ratchets with the move.
    - Dependencies: the canonical technical data map, I-1, W-1, S-1, and I-2.
    - Non-goals: routing, persistence, account, or provider changes; provider
      names in the UI; or a new view model, coordinator, router, manager, or
      service locator.
    - Evidence: previews, behavioral and view tests, app build and UI
      automation, and physical-device file-export evidence.

  - M-1 — reconcile executable privacy manifests with the settled behavior.
    - Ownership: the app and Share Extension privacy manifests and their target
      embedding own required-reason and collected-data declarations.
    - DoD: re-audit every executable and embedded SDK; declare only APIs and data
      uses present in the final behavior; keep each manifest embedded in the
      correct target; remove unsupported permission declarations.
    - Dependencies: the canonical technical data map, I-1 through A-2, and the
      App Store Connect user-content classification decision.
    - Non-goals: capability or entitlement changes, App Store Connect mutation,
      provider changes, or unrelated manifest cleanup.
    - Evidence: manifest source tests, the archived app privacy report, archive
      validation, and release preflight.

  - R-1 — reconcile App Store submission metadata and capture release evidence.
    - Ownership: the release owner owns App Store Connect declarations and
      private evidence; release documents own the runnable verification
      process.
    - DoD: make App Store Connect answers match the release build, provider
      terms, and public policy; verify reachable Privacy Policy, support, and
      terms routes; capture production-provider review, online-permission,
      export, deletion, manifest, physical-device, and TestFlight evidence; and
      close unresolved privacy review gates before submission.
    - Dependencies: every preceding slice, all open owner decisions, and a
      release-candidate build.
    - Non-goals: merging, deploying, submitting, mutating production
      configuration or data, or storing private legal evidence in the
      repository without explicit approval.
    - Evidence: privacy-safe App Store Connect capture, archived privacy report,
      live-route checks, device and TestFlight proof, hosted checks, and
      release-owner sign-off.

- [ ] Decompose `MomentExperienceView.swift` incrementally while completing
  funded v1 work; do not run a separate big-bang rewrite. The target structure
  below is approved and binding: implementation slices execute it rather than
  redesigning it.

  Target files, all under `prosepal-ios/Sources/ProsePalUI/`:

  - `Features/Moment/MomentSheetView.swift`
  - `Features/Moment/MomentComposerView.swift`
  - `Features/Moment/MomentDraftResultView.swift`
  - `Features/Moment/MomentDraftReviseView.swift`
  - `Features/Moment/MomentDraftBlockedStates.swift`
  - `Features/Moment/MomentDraftHistorySheet.swift`
  - `Features/Moment/MomentPickerSheets.swift`
  - `Features/RelationshipMemory/RelationshipMemoryVaultView.swift`
  - `Features/RelationshipMemory/RelationshipMemoryDetailView.swift`
  - `Features/RelationshipMemory/RelationshipMemoryPersistence.swift`
  - `Features/RelationshipMemory/RelationshipMemoryComposerSection.swift`
  - `Features/Privacy/MomentPrivacyDataView.swift`
  - `Features/Privacy/MomentLocalDataExportView.swift`
  - `Features/Privacy/MomentLocalDataExport.swift`, moved from
    `Features/Settings/`
  - `MomentDraftUnavailableNotice.swift`, which gains the unavailable-notice
    factory

  Implementation order. Each A-slice except A-2 is a safe standalone
  extraction and independent of the other decomposition slices. A-2 follows
  the privacy-programme prerequisites above. Each B-slice moves only while the
  funded work it names is already changing that surface:

  - A-1: move the relationship-memory vault, both detail editors with their
    file-private chrome, and the persistence seam into
    `Features/RelationshipMemory/`; delete the unreachable `MomentSelectionRow`
    and `MomentCompactSelectionRow`; replace the moved half of the memory
    source-string guard with behavioural confirmation and rollback coverage.
  - A-2: after I-1, W-1, S-1, and I-2, simplify and move privacy
    presentation, export presentation, and the export contract into
    `Features/Privacy/` as defined by the privacy programme above.
  - A-3: extract `MomentDraftHistorySheet` with a preview and timeline contract
    coverage.
  - A-4: extract both pickers into `MomentPickerSheets.swift` with previews and
    direct filter tests.
  - A-5: move the unavailable-notice policy into
    `MomentDraftUnavailableNotice.swift` with complete branch tests.
  - B-1: move the composer, the composer memory section, and
    `MomentComposerField` during the approved three-option work.
  - B-2: move the result and revise surfaces during the same three-option work;
    resolve the decorative variant dots; leave adjustment chips unselected
    unless real selection state is introduced; explicitly preserve or remove the
    revision word-substitution heuristic.
  - B-3: move the offline, generation-error, and quota states during
    accessibility hardening; replace the quota source-string guard with
    behavioural coverage and a repository-wide invariant.
  - Final: move the residual coordinator to
    `Features/Moment/MomentSheetView.swift`; delete `MomentExperienceView.swift`
    and both path-specific ratchets.

  `MomentSheetView` ends as the Write-tab presentation coordinator: region
  selection, cross-region presentation coordination, focus and scroll handling,
  and the least-common-ancestor Copy, Save, and toast actions. It owns no
  region-internal rendering. `MomentAccountModel` remains one observable owner
  for v1, and the authentication and account-deletion presentation that Settings
  already owns stays there.

  DoD: each extracted user-facing surface has a compiling `#Preview`; behaviour
  and accessibility identifiers stay unchanged unless an approved product slice
  changes them explicitly; each moved region's source-string guard is replaced
  by behavioural, rendering, or direct contract coverage rather than repointed
  at the new path; no extraction adds a coordinator, router, manager, service
  locator, or a second owner for state that already has one; both shrink-only
  guardrail baselines are lowered to their exact new values in the same pull
  request as the extraction they describe; the architecture region map names a
  cohesive owning file for every moved region; when an extracted region's
  navigation chrome is touched, custom bars move to appropriate system toolbar
  placements while paper-like content surfaces retain their own visual
  treatment, and this opportunistic chrome modernization never becomes a
  separate v1 release gate. Swift package tests and the complete app target
  build pass after every extraction.

- [ ] Complete core-flow accessibility and visual hardening. DoD: release flows
  pass VoiceOver, Dynamic Type, hit-target, contrast, keyboard/focus, Reduce
  Motion, and Reduce Transparency checks on supported iPhone sizes; regular-width
  layouts remain usable; first-run and composer device logs contain no invalid
  frame-dimension warnings; no fixed-size or light-only styling is added while
  touched surfaces are extracted.

## Native V1 — Production Configuration And Gateway

- [ ] Complete and prove the production-safe remote-service configuration
  channel. DoD:
  build-configuration-driven `Info.plist` values provide
  `PROSEPAL_GATEWAY_URL`, `PROSEPAL_SUPABASE_URL`, and the Supabase
  publishable/legacy anon key to archived TestFlight/App Store builds; production
  and staging values are reproducible and bound to the intended target; archive
  validation rejects missing configuration, insecure URLs, target/environment
  cross-contamination, and embedded development gateway secrets or privileged
  keys; an archive inspection proves the intended public values are present and
  secrets are absent. This is a prerequisite for live auth, careful generation,
  and account deletion proof.

- [ ] Verify gateway reservation and cost controls in staging. DoD: the guarded
  staging migration dry-run and apply succeed; authenticated and explicitly
  authorized development requests reserve burst and quota capacity before
  provider work; the legacy pre-provider `check_and_increment_usage` path is no
  longer the deployed charging boundary; parallel requests at the last free
  allowance produce exactly
  one provider call and one charge; provider/quality failure is reclaimable;
  repeated healthy smoke requests return a validated three-message response
  rather than timing out or failing the output-quality gate; attempt-level
  staging evidence distinguishes provider timeouts, upstream/provider errors,
  and output-quality rejection before model or timeout policy is changed;
  database linter/advisors and scheduled-cleanup history are clean or explicitly
  accepted; no probe touches production.

- [ ] Verify gateway idempotency and replay in staging. DoD: concurrent
  duplicates produce one provider call; a completed duplicate replays the same
  safe response and usage result without another charge; an abandoned lease
  becomes reclaimable; expired cached output requires a fresh client key;
  cross-user keys remain isolated; logs and evidence contain neither full keys
  nor message text.

- [ ] Extend durable gateway request identity beyond initial careful drafts.
  DoD: named Adjust actions reuse a persisted request key after transport
  ambiguity, change keys when provider-affecting input changes, clear keys after
  success or an explicit expiry/conflict response, and have relaunch/retry tests;
  a user's first gateway-backed request cannot be charged twice merely because
  its response was lost.

- [ ] Apply and verify the guarded Supabase native hardening in staging. DoD:
  migrations remove client access to usage/rate-limit tables and SECURITY
  DEFINER RPCs; only intended Edge Function/service-role paths remain; database
  advisors/linter are clean or explicitly accepted; auth, rate, quota,
  entitlement, and deletion smoke tests pass without touching production.

## Native V1 — Auth, Payments, And Account Integrity

- [ ] Prove the Apple account lifecycle and deletion flow in production-like
  environments. DoD: a fresh physical-device run re-proves the coordinated
  clean-state reset —
  confirmed deletion emits the `account_deletion_*` outcome events, returns
  the app to onboarding, unmounts the previous Write/Settings surfaces, and a
  fresh sign-in (and relaunch) shows no saved drafts, relationship memory,
  generated message, composer input, or recovered draft from the deleted
  account, while an indeterminate outcome preserves local data without
  claiming success — plus sandbox/TestFlight coverage of repeat sign-in,
  missing-code and server-failure presentation, refresh continuity, credential
  revocation notification/state handling, and sign-out without loss of
  unrelated local drafts on the production bundle. Evidence is
  privacy-safe and includes no codes, tokens, client secrets, private keys, or
  unredacted credential-bearing artifacts.

- [ ] Complete StoreKit and server-entitlement release proof. DoD: configured
  local StoreKit testing returns all three configured products from an
  Xcode-launched paywall; an app-hosted StoreKit Test suite directly exercises
  `StoreKitSubscriptionClient` with verified, unverified, unrelated, and retired
  product transactions, purchase cancellation/pending/approval, renewal, grace,
  billing retry, expiry, refund/revocation, Family Sharing when enabled,
  update-stream termination, and finish only after entitlement convergence;
  transient read failure remains distinguishable from inactive entitlement.
  The direct-suite release wrapper proves the expected scenario count with zero
  failures and zero skips; its harness skips only for an actually caught
  `NSError` matching `SKInternalErrorDomain` code `3`, while an empty, missing,
  extra, or wrong product result fails setup without an inferred diagnosis.
  The known Xcode/iOS runtime failure is rechecked on a fixed runtime and is not
  accepted as a pass. Configured
  production product IDs return products; purchase and user-triggered restore
  work without a forced app login; App Store Server notifications and
  reconciliation update staging entitlement; account switching cannot carry
  Premium incorrectly; evidence is captured from sandbox/TestFlight.

- [ ] Verify `appAccountToken` ownership mapping. DoD: only a valid signed-in
  Supabase UUID is sent; anonymous purchase and later sign-in have an explicit
  convergence policy; server reconciliation never grants one user's transaction
  to another; unit and sandbox evidence cover missing and mismatched tokens.

- [ ] Set explicit bounded timeouts for Supabase auth and account-maintenance
  requests. DoD: sign-in, refresh, logout, token exchange, and deletion cannot
  wait on `URLSession.shared` defaults indefinitely; cancellation and timeout
  map to honest outcomes; deletion distinguishes guaranteed pre-final failure
  from indeterminate final deletion and never promises that a dispatched remote
  delete did not commit; gateway token acquisition remains within the overall
  generation deadline.

## Native V1 — Pre-Release Identity And Migration Residue

- [ ] Freeze persistent client identifiers before TestFlight. Audit every
  persisted or cross-process identifier created during the Flutter-to-Swift
  transition: UserDefaults, app-group storage, Keychain, `SceneStorage`, draft
  recovery, onboarding, App Intent, widget, Control, and Share Extension handoff
  keys. Rename obsolete migration-era keys now where appropriate, including the
  current `prosepal.native.*` keys, while there is no external installed user
  base; this is the last point at which a rename is free rather than a permanent
  compatibility shim. DoD: every retained or renamed identifier has a documented
  owner and purpose; clean install, onboarding, active-draft recovery, relaunch,
  deep-link, and Share Extension handoff tests pass; no silent reset or data loss
  occurs across the supported development upgrade path; identifiers are declared
  frozen once TestFlight distribution begins.

- [ ] Remove migration terminology from user-facing and actively maintained
  product surfaces. The SwiftUI app is the only current ProsePal implementation;
  "Native" must not imply a second live app or appear as unexplained product
  vocabulary. DoD: user-facing copy such as the "Native iOS" row value in
  `MomentSettingsComponents.swift` is replaced with clear product language;
  remaining `Native*` uses are explicit developer-facing compatibility names or
  Apple-platform capability descriptions; frozen historical records remain
  clearly marked as historical.

- [ ] Audit and retire obsolete pre-release compatibility and configuration
  residue. Inspect legacy draft values, removed feature flags and vocabulary,
  analytics events, unused permissions and entitlements, extension targets, URL
  routes, configuration variables, StoreKit identifiers, Supabase functions/RPCs,
  and migration-era scripts. DoD: unused pre-release compatibility code is
  removed where no shipped data depends on it; the removed voice-dictation and
  manual Take More Care pathways cannot reappear through recovery, analytics, or
  configuration; unused Apple capabilities and permission declarations are absent
  from built executables; externally coupled identifiers such as bundle IDs, app
  groups, Sign in with Apple IDs, StoreKit product IDs, and deployed database
  migrations are retained unless a complete validated migration is justified;
  reproducible database migration history remains intact.

## Native V1 — Release Evidence

- [ ] Run the complete physical-device/TestFlight acceptance loop. DoD: first
  run → person/relationship/moment/detail → private or careful candidate set →
  choose a message → adjust without losing work → copy/share/send/save passes on
  a supported iPhone;
  offline and refusal states are honest; release-candidate evidence contains no
  user content or secrets. Until the three-option feasibility gate passes, use
  the current one-draft loop rather than claiming candidate-choice proof.

- [ ] Qualify optional system surfaces. DoD: App Intent/Shortcuts, widget,
  Control Center/Action Button, and Share Extension are launched from their real
  system surfaces in production-like builds and hand off correctly; the app
  exposes exactly one `AppShortcutsProvider`, and extracted shortcut metadata
  contains the intended phrases and target identity. Remove any optional
  embedded target from v1 if it cannot pass without destabilizing the core
  writing loop.

## Post-V1 / Triggered Work

- [ ] Consider a broader cosmetic rename of migration-era developer-facing
  symbols, targets, scripts, and filenames only when it provides measurable
  maintenance value. Examples: `ProsePalNativeApp`, the `ProsePalNative` package
  and `ProsePalNativePackageTests` target names, the `release_preflight.sh native`
  positional argument and its two CI call sites, "Native V1" backlog headings, and
  runbook filenames. Trigger: after v1 ships. This is aesthetics with no expiry
  date, unlike the persisted-identifier item. DoD: the
  cleanup is intentionally scoped, preserves useful git history where practical,
  updates every build/CI reference, and is not allowed to delay v1 merely for
  naming aesthetics.

- [ ] Add generated or cross-language parity coverage before changing the
  native generation vocabulary. DoD: Occasion, Relationship, Tone,
  MessageLength, lane, and contract-version values have one generated source or
  a test that compares the Swift and gateway sets; adding a native value cannot
  reach production while the gateway would reject it.

- [ ] Approve the launch gateway-allowance policy and add quantified quota UI
  only if it earns its place. DoD: the release owner explicitly accepts or
  changes the repository’s one-lifetime-free and 500-per-month-entitled policy;
  the server supplies structured limit, remaining-use, and reset metadata on
  both success and quota-exhaustion paths; the native domain retains it; Plan,
  Paywall, limit state, StoreKit metadata, and App Store copy remain consistent;
  private on-device work, failed work, and idempotent replay are not presented
  as charged; no client invents a count, meter, reset date, or unlimited claim.

- [ ] Prototype an Apple-native Private Cloud Compute careful lane after the
  iOS 27 SDK and entitlement path stabilize. The API-discovery trigger has
  occurred, but adoption remains blocked on a provider-neutral
  `MessageWritingService` prototype proving privacy, refusal behaviour, latency,
  availability, cost, and universal result-contract parity; this is an
  experiment, not a migration commitment.

- [ ] Decide whether relationship-vault data needs stronger at-rest encryption
  beyond current platform storage, backup exclusion, deletion, and export
  controls before adding cloud sync or more sensitive memory.

- [ ] Complete full Dark Mode, String Catalog localization, broader iPad window
  adaptation, Switch Control, and non-critical visual/motion/haptic polish.

- [ ] Evaluate system Writing Tools integration only if it improves the focused
  editor without bypassing Pressure Check, undo/history, recovery, or private-
  text boundaries. DoD: a small `.writingToolsBehavior(.limited)` experiment
  proves the system UI cannot evade those protections before any product-scope
  decision.

- [ ] Reconsider voice dictation as an independently owned post-v1 feature.
  Voice input is not part of v1: it is not required to write a message, and it
  would add microphone/speech permissions, speech lifecycle risk, and physical-
  device release evidence that v1 does not need. Trigger: after v1,
  and only if people actually ask to speak the moment detail. DoD: the feature is
  reintroduced behind its own transcriber protocol boundary in its own file, not
  in the Moment monolith; it is built on stable Apple speech APIs (`SpeechAnalyzer`
  with `SpeechTranscriber` and an explicit `DictationTranscriber` fallback), never
  beta-only live-capture helpers; a person-initiated Stop is a graceful finish that
  preserves the final spoken words and is distinct from cancellation; locale
  selection, managed asset installation, unsupported devices/languages,
  permissions, offline behaviour, and supported-device evidence all pass; the
  microphone and speech usage descriptions return only in the same change that
  ships a reachable control that needs them.

- [ ] Evaluate replacing custom subscription purchase controls with
  `SubscriptionStoreView` inside `Features/Paywall/`. Trigger: after v1, or
  earlier only if the current paywall cannot satisfy release evidence or App
  Review. DoD: branded system controls preserve the existing hero,
  entitlement listener, restore path, and `appAccountToken` boundary; localized
  products, policies, purchase, restore, cancellation, accessibility, and
  sandbox/TestFlight convergence pass before replacement.

- [ ] Research a lane-neutral result-screen trust layer after the core
  three-option experience ships. DoD: user testing and legal/privacy review
  decide whether “AI-assisted — review before sending” and a disclosure of the
  user-selected inputs improve understanding; wording never names providers,
  exposes routing, implies gateway work occurred on-device, or displays raw
  personal context unexpectedly; accessibility and both-lane accuracy pass.

- [ ] Modernize optional App Intents only after their v1 system-surface evidence
  is complete. DoD: availability-gated typed entities, current Messages-domain
  schema support, and direct widget/control intent buttons preserve foreground
  review, sanitized handoff, and the rule that ProsePal never auto-sends an AI-
  authored message.

- [ ] Review Drafts-tab prominence after launch using privacy-safe usage
  evidence. If the saved-drafts destination is materially quiet, test moving the
  library below the writing surface without harming discoverability, state
  restoration, accessibility, or saved-work recovery; do not change root
  navigation from intuition alone.

- [ ] Reorder burst enforcement before quota lookup inside
  `reserve_card_request` if observed abuse traffic shows quota-exhausted callers
  are creating avoidable database load. DoD: idempotency and subject isolation
  still run first; burst-denied requests cannot reach quota or provider work;
  quota, replay, reclaim, concurrency, and staging tests pass with unchanged
  legitimate-user charging semantics.

- [ ] Add a provider-protocol escape hatch only when a second approved runtime
  requires it; keep provider details behind `MessageWritingService`.

- [ ] Reconsider app-owned crisis classification only as a separate future
  product decision. Do not build multilingual detection, three-tier assessment,
  or mental-health inference for native v1. Any expansion requires specialist
  safety review and evidence that model/gateway refusal handling is insufficient.
