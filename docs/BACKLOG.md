# Backlog

This file contains unresolved work only. Completed behavior and verification
history belong in `docs/reference/feature-status.csv`, release evidence, and git
history.

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

- [ ] Establish a focused writing-quality evaluation for private and careful
  generation. DoD: deterministic representative fixtures and exemplar-tested
  scorers cover preservation of the user's words, invented personal facts,
  requested tone/length, derived everyday/careful writing mode, guilt or
  pressure, and provider/internal-language
  leakage; every candidate is scored individually and three-option sets are
  checked for meaningful variation rather than superficial paraphrases;
  separately approved live samples exercise both lanes without retaining user
  content or secrets. Custom crisis classification and mental-health inference
  are out of scope.

- [ ] Define one measured end-to-end generation deadline across fallback
  attempts. DoD: device and staging measurements determine a single ceiling or
  remaining-budget policy; private-device measurements compare the current
  single structured draft with one-session three-option generation across
  representative Brief, Standard, and Detailed fixtures; fallback cannot extend
  the wait unintentionally; long waits receive honest progress copy;
  deterministic tests cover deadline propagation, cancellation, and late-result
  suppression.

- [ ] Prove and deliver the approved choose-before-edit three-option writing
  flow without weakening private-first routing. DoD: the gateway client
  preserves all three distinct `CardResponse` messages instead of selecting an
  unranked first element, including exact request-ledger replay; one Foundation
  Models session produces and validates three distinct private options on a
  supported physical iPhone within the measured end-to-end deadline; both lanes
  expose one provider-neutral option-set contract without revealing routing.
  Execution order is mandatory: approve the end-to-end deadline, run a
  timeboxed private-device three-option spike, record the gate decision, and
  only then begin production domain, recovery, and UI work.

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
  block remains a separate refusal rule, not a routing mode. Explicit Take More
  Care remains available after a message is chosen. Legacy Quick/Your words/Take
  care recovery values decode safely, but regeneration normalizes them to the
  new derived policy. Prompt context, pre-result careful styling, and the local
  Pressure Check no longer depend on an unreachable register selection.
  A routing-parity matrix records every current occasion-to-initial-lane result
  before and after the migration, with every intentional change named and
  approved.

  Results say “Three ways to say it,” give all options equal visual weight with
  no invented best ranking, and require an explicit choice before the existing
  edit/adjust/copy/share/save flow. Post-choice refinement stays optional and
  contextual: existing adjustments remain available, and any new adjustment
  vocabulary must be supported by both lanes, the quality rubric, and occasion
  rules before appearing (for example, no “Funnier” promise on sympathy).
  Candidate sets and the chosen draft survive relaunch, changing any
  meaning-bearing input invalidates stale candidates, and choosing or switching
  an option never destroys recoverable wording.

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

- [ ] Add release-critical view/UI automation. DoD: blocking tests cover first
  run, auth entry, draft success, offline/error recovery, copy/share/save,
  purchase/restore presentation, destructive confirmation, Settings semantics,
  and one accessibility-size identifier-driven navigation path.

- [ ] Make critical asynchronous tests fail fast and prove rejected requests
  have no expensive side effects. DoD: auth refresh and Moment-model test
  synchronization has an explicit deadline instead of unbounded polling;
  bounded waits use deterministic synchronization or a shared fail-fast helper;
  auth and development-secret rejection tests configure a callable provider and
  explicitly assert that it receives zero requests; regressions fail rather than
  hanging the test run.

- [ ] Decompose `MomentExperienceView.swift` incrementally while completing
  funded v1 work; do not run a separate big-bang rewrite. Extraction order is:
  root navigation/welcome with navigation work; saved drafts and relationship
  memory with persistence/UI automation; settings, plans, privacy/export,
  authentication, and paywall with release UI automation; composer, candidate
  choice, generation states, revision, voice/share, and pickers with the
  approved three-option flow plus accessibility/core-flow work;
  then move `MomentModel` and draft recovery into their owning file. DoD: every
  region in the architecture map names a cohesive source file instead of the
  monolith; the original file is removed or has one reason to change; each
  extracted user-facing surface has a compiling `#Preview`; each moved region's
  source-string guard is deleted or replaced by behavioral/view coverage in the
  same commit; both shrink-only guardrail baselines are lowered; the architecture
  map is updated; Swift package tests and the complete app target build pass
  after every extraction.

- [ ] Complete core-flow accessibility and visual hardening. DoD: release flows
  pass VoiceOver, Dynamic Type, hit-target, contrast, keyboard/focus, Reduce
  Motion, and Reduce Transparency checks on supported iPhone sizes; regular-width
  layouts remain usable; no fixed-size or light-only styling is added while
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
  provider work; parallel requests at the last free allowance produce exactly
  one provider call and one charge; provider/quality failure is reclaimable;
  database linter/advisors and scheduled-cleanup history are clean or explicitly
  accepted; no probe touches production.

- [ ] Verify gateway idempotency and replay in staging. DoD: concurrent
  duplicates produce one provider call; a completed duplicate replays the same
  safe response and usage result without another charge; an abandoned lease
  becomes reclaimable; expired cached output requires a fresh client key;
  cross-user keys remain isolated; logs and evidence contain neither full keys
  nor message text.

- [ ] Extend durable gateway request identity beyond initial careful drafts.
  DoD: Adjust and Take More Care reuse a persisted request key after transport
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

- [ ] Connect native Sign in with Apple to Apple authorization-code exchange.
  DoD: the native authorization result forwards the one-time authorization code
  only to an authenticated, tested server boundary; `exchange-apple-token`
  validates configuration and caller identity, uses bounded requests, checks
  token and database responses, stores only required revocation material, and
  never logs codes or tokens.

- [ ] Prove Apple-compliant account deletion end to end. DoD: a sandbox/TestFlight
  Apple sign-in stores revocation material; deletion authenticates the caller,
  revokes Apple authorization with an explicit failure policy, deletes app and
  auth data, clears local state, and produces privacy-safe evidence. Add focused
  tests for exchange, revocation failure, missing credentials, partial cleanup,
  and retry behavior.

- [ ] Complete StoreKit and server-entitlement release proof. DoD: configured
  production product IDs return products; purchase and restore work without a
  forced app login; transaction updates converge after renewal, approval,
  Family Sharing change, and revocation/refund; App Store Server notifications
  and reconciliation update staging entitlement; account switching cannot carry
  Premium incorrectly; evidence is captured from sandbox/TestFlight.

- [ ] Verify `appAccountToken` ownership mapping. DoD: only a valid signed-in
  Supabase UUID is sent; anonymous purchase and later sign-in have an explicit
  convergence policy; server reconciliation never grants one user's transaction
  to another; unit and sandbox evidence cover missing and mismatched tokens.

- [ ] Set explicit bounded timeouts for Supabase auth and account-maintenance
  requests. DoD: sign-in, refresh, logout, token exchange, and deletion cannot
  wait on `URLSession.shared` defaults indefinitely; cancellation and timeout
  map to honest errors; gateway token acquisition remains within the overall
  generation deadline.

## Native V1 — Release Evidence

- [ ] Run the complete physical-device/TestFlight acceptance loop. DoD: first
  run → person/relationship/moment/detail → private or careful candidate set →
  choose a message → adjust without losing work → copy/share/send/save passes on
  a supported iPhone; voice input succeeds where on-device speech is available;
  offline and refusal states are honest; release-candidate evidence contains no
  user content or secrets. Until the three-option feasibility gate passes, use
  the current one-draft loop rather than claiming candidate-choice proof.

- [ ] Qualify optional system surfaces. DoD: App Intent/Shortcuts, widget,
  Control Center/Action Button, and Share Extension are launched from their real
  system surfaces in production-like builds and hand off correctly. Remove any
  optional embedded target from v1 if it cannot pass without destabilizing the
  core writing loop.

- [ ] Reconcile App Store submission metadata and privacy evidence. DoD: built
  app and applicable extension bundles contain valid privacy manifests and
  required-reason declarations; App Privacy answers match actual collection;
  Terms, Privacy Policy, support, subscription disclosure, export, and deletion
  paths are reachable; archive validation and submission preflight pass.

## Post-V1 / Triggered Work

- [ ] Add generated or cross-language parity coverage before changing the
  native generation vocabulary. DoD: Occasion, Relationship, Tone,
  MessageLength, lane, and contract-version values have one generated source or
  a test that compares the Swift and gateway sets; adding a native value cannot
  reach production while the gateway would reject it.

- [ ] Define handling for verified StoreKit transactions from retired or
  temporarily unconfigured product IDs before changing the stable launch set.

- [ ] Add quantified quota UI only when the server contract supplies structured
  limit, remaining-use, and reset metadata backed by an approved product policy.

- [ ] Move the careful lane to the approved Apple-native/PCC path when that API
  is available and its privacy, reliability, and cost behavior are proven.

- [ ] Decide whether relationship-vault data needs stronger at-rest encryption
  beyond current platform storage, backup exclusion, deletion, and export
  controls before adding cloud sync or more sensitive memory.

- [ ] Complete full Dark Mode, String Catalog localization, broader iPad window
  adaptation, Switch Control, and non-critical visual/motion/haptic polish.

- [ ] Evaluate system Writing Tools integration only if it improves the focused
  message workflow without bypassing draft protection or exposing private text.

- [ ] Add a provider-protocol escape hatch only when a second approved runtime
  requires it; keep provider details behind `MessageWritingService`.

- [ ] Reconsider app-owned crisis classification only as a separate future
  product decision. Do not build multilingual detection, three-tier assessment,
  or mental-health inference for native v1. Any expansion requires specialist
  safety review and evidence that model/gateway refusal handling is insufficient.
