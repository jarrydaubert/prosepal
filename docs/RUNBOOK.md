# Runbook

Commands run from the repository root unless stated. Read [AGENTS](../AGENTS.md)
for authorization boundaries and [CONFIGURATION](CONFIGURATION.md) for keys.
Source/scripts are exact execution truth; a local pass does not prove deployed state.

## Build

Requires macOS, Xcode with iOS 26 SDK, Swift 6.2+. Backend work also needs Deno,
Supabase CLI and Docker for local SQL tests. No live secrets are needed for package tests.

```bash
cd prosepal-ios
swift build
```

Open Xcode with `./scripts/run_ios.sh` from the root. If tools cannot parse the
package, check `xcode-select -p`, `swift --version`, `xcodebuild -version` before
changing requirements. Do not run the separate X-1 checkpoint by implication.

## Validation

Documentation, instructions and repository scripts:

```bash
git diff --check
./scripts/validate_docs.sh
./scripts/release_preflight.sh native --no-env-file
```

For changed shell scripts, also run `bash -n` on each; for script tests run
`python3 -m unittest discover -s scripts/tests -p 'test_*.py'` (preflight includes it).
CI and release workflows invoke the same preflight; no separate documentation ledger exists.

For iOS executable changes:

```bash
cd prosepal-ios
swift build
swift test
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

All commands must exit zero. The unsigned build includes embedded targets.
Run focused UI checks when presentation/wiring changes:
`./scripts/run_native_ui_tests.sh smoke`; release acceptance uses `full`.
These scripts run mock/synthetic scenarios, not live Apple/provider evidence.

For backend executable/migration changes (start the local stack first):

```bash
supabase start
deno check supabase/functions/**/*.ts
find supabase/functions -name '*.test.ts' -exec deno test --allow-env {} +
supabase test db
./scripts/test_gateway_ledger_concurrency.sh
supabase db lint --local --level warning
```

The concurrency harness uses separate local PostgreSQL sessions; the optional
`PROSEPAL_SUPABASE_DB_URL` is credential-bearing. Do not print it. Test changed
migration ordering on a fresh disposable local database with `supabase db reset --local`.
Never substitute a remote project for failed local SQL tests. G-2 owns SQL CI evidence.
Writing-output changes also use [WRITING EVALUATION](WRITING_EVALUATION.md).

## Staging and remote safety

| Environment | Bundle | Supabase project |
|---|---|---|
| Production/TestFlight | `com.prosepal.prosepal` | `mwoxtqxzunsjmbdqezif` |
| Internal staging | `com.prosepal.prosepal.staging` | `llolwgqphwnhbiqewmcq` |

The shared `ProsePal` and `ProsePal Staging` schemes contain no secrets. Real
staging Run values belong in the ignored `ProsePal Local Staging` user scheme.
Its backup is `~/.config/prosepal/xcode-schemes/ProsePal Local Staging.xcscheme`
with mode 600; `PROSEPAL_STAGING_SCHEME_BACKUP` can override the backup location.
Treat the entire scheme as credential-bearing: never attach it or dump its environment.

```bash
./scripts/restore-local-staging-scheme.sh
./scripts/verify-native-staging-plumbing.sh
```

These require an already configured private backup. Missing backup: duplicate
Staging as a local user scheme in Xcode, add CONFIGURATION's local Run keys,
select the StoreKit file, back it up outside Git, then restore/verify. Quit and
reopen Xcode after editing/restoring the scheme; it can cache old launch values.

Local StoreKit uses `prosepal-ios/App/ProsePalStaging.storekit`; Xcode's scheme
identifier is `../../App/ProsePalStaging.storekit`. If duplicate dropdown entries
appear, remove the reference and reselect in Xcode. Products are under
`subscriptionGroups[].subscriptions[]`. Staging has no App Store Connect products;
its local StoreKit configuration is required for those product tests.
Empty/wrong product results are setup failures; only an observed
`SKInternalErrorDomain` code `3` establishes the known runtime failure. Neither
that skip nor local `.storekit` success proves real products/server entitlement.

Staging device signing needs an explicit App ID/profile with Sign in with Apple;
a wildcard profile cannot carry that entitlement. Do not remove it to fix signing.
Staging Supabase Apple Client IDs must accept both production and staging bundle
audiences above; production must accept only approved production identities.
An `Unacceptable audience in id_token` means inspect that allow-list, not weaken
nonce/token validation. A successful Supabase exchange followed by failed Apple
revocation-material storage requires checking server `APPLE_*` secrets.

Remote mutation requires approval for the exact environment/operation. Once authorized:

```bash
./scripts/supabase-staging.sh deploy-functions generate-card
./scripts/supabase-staging.sh db-push
```

For db-push, the human operator supplies `STAGING_DB_URL` in their shell. The
helper rejects production link/URL state and requires dry-run/confirmation.
MUST NOT use `supabase db push --linked`, remote reset, or inferred targets.
`supabase status` describes the local stack, not remote mutation identity.

Approved staging smoke: `./scripts/prosepal-staging-smoke.sh`. It obtains the
local development secret without printing it; anonymous development needs both
`GATEWAY_DEV_ALLOW_ANONYMOUS=true` and the separate configured secret. Its current
response assertions reflect implementation, not approval of the future W-2/W-8 contract.
If running behaviour differs from source, download the deployed function to a
private temporary workdir using explicit `--project-ref llolwgqphwnhbiqewmcq`
and compare before any approved redeploy. `NXDOMAIN`/`Code=-1003`: check
`supabase projects list`, project activity and DNS before changing app code.

## Archive, TestFlight and submission

1. Resolve or explicitly disposition the candidate's mandatory BACKLOG gates.
   Select the intended archive target/public config; promotion requires approval.
2. Run relevant local gates, full simulator UI acceptance and direct StoreKit:
   `./scripts/run_storekit_release_gate.sh`. To retain its xcresult, supply a
   fresh private `PROSEPAL_STOREKIT_RESULT_BUNDLE` path; the default is temporary.
   The result gate requires all expected scenarios with zero failures/skips.
3. Supply public archive settings from CONFIGURATION. Run environment values do
   not enter archives. Inspect effective Release settings and the finished app;
   repository preflight is not proof of live configuration or product availability.
4. Archive the production identity in Xcode's `ProsePal` scheme, Release, generic
   iOS device. Equivalent CLI (approved public-only xcconfig and private output):

```bash
xcodebuild -project prosepal-ios/ProsePal.xcodeproj -scheme ProsePal -configuration Release -destination 'generic/platform=iOS' -xcconfig /private/path/public-release.xcconfig -archivePath /private/path/ProsePal.xcarchive archive
```

5. Inspect bundle identity, HTTPS gateway/Supabase values, public key, Premium
   product inventory/recommendation, target isolation, embedded privacy manifests
   and privacy report. Verify privileged/development secrets are absent. G-1's
   missing production Premium configuration is a blocker; do not infer coverage
   from the existing archive validation phase or a green repository preflight.
6. With explicit approval, upload through Organizer to the existing App Store
   Connect app; install via TestFlight and capture the evidence below. Submission,
   public release, production service/config changes and data mutations each
   require explicit approval for the exact action. The GitHub Release workflow
   creates a Git tag/release; it does not submit an app.

Keep candidate evidence private under `artifacts/release/<release-tag>/native-ios/`
(and `ai-output-quality/` for writing). Record command/user path, observed result,
environment, tool/runtime, pass/fail and release-owner disposition. Use synthetic
content only; no credentials, receipts, signed payloads or real writing. Do not
track evidence without owner approval. Simulator, local StoreKit, sandbox,
device and TestFlight proof are distinct.

Required proof: configuration/privacy archive inspection; auth/refresh/revocation,
sign-out and confirmed/indeterminate deletion; StoreKit products/purchase/restore,
updates/refund/revocation and server ownership/ordering; staging quota/idempotency,
replay/concurrency/cleanup; writing quality per lane; draft preservation/recovery,
copy/share/save/export; VoiceOver, Dynamic Type, contrast, keyboard/focus, Reduce
Motion/Transparency and supported widths; every included system surface.
Reconcile online permission/provenance, actual provider terms, retention/deletion,
public policy/support/EULA and App Store privacy/commercial metadata before promotion.
Never claim destination/send success from opening/cancelling the share chooser.

Stop promotion on a failed/blocked/skipped required gate; record the gap in
BACKLOG, fix and rerun the affected gate. Rollback is a deliberate candidate stop
or approved replacement release; Git's Flutter archive is context, not authority
to recreate its sources or mutate its services.

## App Review precedent

The previous production app was rejected for mandatory registration/sign-in
before subscription purchase and shipped a grey-screen release with missing
release-time configuration. Preserve these constraints as review evidence for
G-4/G-1 decisions; they do not settle the reopened purchase-identity design.
Use the archived Flutter Git reference for original context, and reassess any
changed purchase policy against current Apple requirements before implementation.

## Keepalive operations

`.github/workflows/supabase-keepalive.yml` calls only the public read-only
`keepalive()` RPC. Actions secrets: `SUPABASE_STAGING_URL`/`SUPABASE_STAGING_ANON_KEY`;
production equivalents are `SUPABASE_PRODUCTION_URL`/`SUPABASE_PRODUCTION_ANON_KEY`.
Never supply a service-role key. `KEEPALIVE_PRODUCTION_ENABLED=true` enables
production participation; otherwise production is neutrally skipped. Changing
production participation requires explicit approval.

Approved staging probe: `./scripts/keepalive-staging-smoke.sh`. For direct verification,
`scripts/verify_keepalive.sh` uses `PROSEPAL_KEEPALIVE_URL` and
`PROSEPAL_KEEPALIVE_ANON_KEY`. A pass is HTTP 200 with a server timestamp.
Missing secrets: configure the target environment; 401/403: check rotated public
key; 404: inspect migration application; DNS/timeout/5xx: check project activity.
Re-run the workflow after an approved fix and check both jobs and scheduled-run
history; missing runs are not success. Before launch, move live production to a
non-pausing paid plan and retire this temporary control; see BACKLOG.
