# Backlog

This file contains unresolved work only. Completed behavior and verification
history belong in `docs/FEATURE_STATUS.csv`, release evidence, and git history.

Every item uses `[ ]` until its definition of done is fully satisfied. Remove a
completed item instead of turning this file into a status log.

## Working Rules

- Reliability, security, auth, payments, and user-data integrity take priority.
- Do not change another SwiftData `@Model` without a new `VersionedSchema` and
  explicit migration stage.
- When touching `MomentExperienceView.swift`, extract the affected surface when
  the boundary is safe and replace source-string guards with behavioral or
  view-layer coverage where practical.
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
  requested length/register, guilt or pressure, and provider/internal-language
  leakage; separately approved live samples exercise both lanes without
  retaining user content or secrets. Custom crisis classification and
  mental-health inference are out of scope.

- [ ] Define one measured end-to-end generation deadline across fallback
  attempts. DoD: device and staging measurements determine a single ceiling or
  remaining-budget policy; fallback cannot extend the wait unintentionally;
  long waits receive honest progress copy; deterministic tests cover deadline
  propagation, cancellation, and late-result suppression.

- [ ] Make root navigation destinations distinct, discoverable, and accessible.
  DoD: each root destination has unique content and state restoration; Settings
  remains reachable; keyboard, VoiceOver, accessibility text sizes, and compact
  and regular widths retain a complete path; touched navigation views leave the
  monolith with behavioral coverage.

- [ ] Add release-critical view/UI automation. DoD: blocking tests cover first
  run, auth entry, draft success, offline/error recovery, copy/share/save,
  purchase/restore presentation, destructive confirmation, Settings semantics,
  and one accessibility-size identifier-driven navigation path.

- [ ] Complete core-flow accessibility and visual hardening. DoD: release flows
  pass VoiceOver, Dynamic Type, hit-target, contrast, keyboard/focus, Reduce
  Motion, and Reduce Transparency checks on supported iPhone sizes; regular-width
  layouts remain usable; no fixed-size or light-only styling is added while
  touched surfaces are extracted.

## Native V1 — Production Configuration And Gateway

- [ ] Add a production-safe remote-service configuration channel. DoD:
  build-configuration-driven `Info.plist` values provide
  `PROSEPAL_GATEWAY_URL`, `PROSEPAL_SUPABASE_URL`, and the Supabase
  publishable/legacy anon key to archived TestFlight/App Store builds; production
  and staging values are distinct; release builds reject missing configuration;
  no development gateway secret or privileged key is embedded. This is a
  prerequisite for live auth, careful generation, and account deletion proof.

- [ ] Restrict remote runtime URLs to secure production transport. DoD:
  `NativeRuntimeConfig` accepts HTTPS for production/staging services, permits
  HTTP only for explicit debug loopback/local development where required, and
  has tests for rejected insecure and malformed URLs.

- [ ] Add atomic pre-provider abuse and cost control to `generate-card`. DoD:
  authenticated and explicitly authorized development requests reserve burst and
  quota capacity before provider work; exhausted users cannot incur provider
  cost; concurrent requests cannot oversubscribe limits; provider/quality failure
  releases or refunds the reservation; success finalizes it; database functions
  are service-role-only, concurrency-safe, and covered by migration/function and
  Edge Function tests.

- [ ] Implement real gateway idempotency. DoD: user plus idempotency key has a
  unique server-side record; in-flight duplicates do not start another provider
  call; completed duplicates replay the same safe response and usage result;
  failed attempts follow an explicit retry policy; keys and cached responses
  expire; tests cover lost responses, concurrent duplicates, and cross-user key
  isolation without logging full keys or message text.

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
  run → person/moment/detail → private or careful draft → adjust without losing
  work → copy/share/send/save passes on a supported iPhone; voice input succeeds
  where on-device speech is available; offline and refusal states are honest;
  release-candidate evidence contains no user content or secrets.

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
