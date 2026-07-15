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

- [ ] Finish the extension-safe launch/input contract shared by the app, App
  Intents, Share Extension, widget/control, and production/staging routing.
  DoD: one canonical payload, app-group key, URL-routing policy, and text limit;
  production and staging targets compile against it; encode/decode,
  sanitization, and target-membership tests prevent drift.

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

- [ ] Decompose `MomentExperienceView.swift` incrementally while completing
  funded v1 work; do not run a separate big-bang rewrite. The remaining
  migration map is: move the memory library and details into
  `Features/RelationshipMemory/` with persistence/UI automation; move plan,
  privacy/export, authentication, and paywall
  destinations into `Features/Settings/` with release UI automation; move the
  composer, candidate choice, generation states, revision, voice/share, and
  pickers into cohesive feature files during the approved three-option and
  accessibility/core-flow work; then move `MomentModel` and the versioned draft
  recovery boundary into their owning workflow files. DoD: every
  region in the architecture map names a cohesive source file instead of the
  monolith; the original file is removed or has one reason to change; each
  extracted user-facing surface has a compiling `#Preview`; each moved region's
  source-string guard is deleted or replaced by behavioral/view coverage in the
  same commit; both shrink-only guardrail baselines are lowered; the architecture
  map is updated; when an extracted region's navigation chrome is touched,
  custom bars move to appropriate system toolbar placements while paper-like
  content surfaces retain their own visual treatment; this opportunistic chrome
  modernization never becomes a separate v1 release gate. Swift package tests
  and the complete app target build pass after every extraction.

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

- [ ] Prove the completed Apple account lifecycle and deletion flow in deployed
  environments. DoD: guarded staging deployment applies the service-role-only
  Apple-credential migration and matching `exchange-apple-token` / `delete-user`
  functions without touching production; sandbox/TestFlight evidence covers
  first and repeat sign-in, missing-code and server-failure presentation,
  refresh continuity, credential revocation notification/state handling, and
  sign-out without loss of unrelated local drafts; an Apple-backed deletion
  proves refresh-token revocation, validated server/auth cleanup, local cleanup,
  a pre-final failure that preserves authenticated retry, an unconfirmed final
  deletion that may complete after its response, and retry convergence when the
  account is still sign-in capable. Evidence is
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
  active architecture, app guide, feature-status, release, and operational
  documentation describe the app simply as ProsePal or the iOS app; frozen
  historical records remain clearly marked as historical. `AGENTS.md` and
  `CLAUDE.md` are already done: they no longer call the app a "rewrite" and now
  record that remaining "Native" names are historical residue.

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

- [ ] Reconcile App Store submission metadata and privacy evidence. DoD: built
  app and applicable extension bundles contain valid privacy manifests and
  required-reason declarations; App Privacy answers match actual collection;
  Terms, Privacy Policy, support, subscription disclosure, export, and deletion
  paths are reachable; the release owner verifies the user-facing claim that
  message text is never used to train models against the binding terms and data-
  use policy of every production gateway provider, then preserves private legal
  evidence or amends the copy; archive validation and submission preflight pass.

## Post-V1 / Triggered Work

- [ ] Consider a broader cosmetic rename of migration-era developer-facing
  symbols, targets, scripts, and filenames only when it provides measurable
  maintenance value. Examples: `ProsePalNativeApp`, the `ProsePalNative` package
  and `ProsePalNativePackageTests` target names, the `release_preflight.sh native`
  positional argument and its two CI call sites, "Native V1" backlog headings, and
  runbook filenames. Trigger: after v1 ships. This is aesthetics with no expiry
  date, unlike the persisted-identifier item, and it touches ~120 files. DoD: the
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
  Voice input was removed from v1 on 2026-07-14: it is not required to write a
  message, and it carried microphone/speech permissions, speech lifecycle risk,
  and physical-device release evidence that v1 does not need. Trigger: after v1,
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
  `SubscriptionStoreView` when the paywall region is extracted. Trigger: after
  v1, or earlier only if the current paywall cannot satisfy release evidence or
  App Review. DoD: branded system controls preserve the existing hero,
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
