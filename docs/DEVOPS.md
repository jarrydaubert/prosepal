# DevOps Runbook

This runbook covers the active native iOS ProsePal app in `prosepal-ios/`.

The previous Flutter production app is archived at tag
`flutter-prod-freeze-2026-06-25` and branch
`legacy/flutter-production-reference`. Flutter commands and production-reference
runbooks must not be reintroduced to `main` unless the user explicitly requests
an archive/hotfix investigation.

## Required Local Validation

For native app changes:

```bash
git diff --check
cd prosepal-ios
swift build
swift test --quiet
xcodebuild -project ProsePal.xcodeproj -target ProsePal -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

For Supabase Edge Function changes:

```bash
deno check supabase/functions/**/*.ts
```

For repo/workflow changes:

```bash
./scripts/release_preflight.sh native --no-env-file
```

## CI

Active CI on `main` and pull requests runs:

- commit attribution guard
- secret history guard
- native release preflight
- `swift build`
- `swift test --quiet`
- simulator build with `xcodebuild`
- Supabase Edge Function TypeScript validation with Deno
- CodeQL for GitHub Actions and TypeScript

The native iOS job is pinned to GitHub's documented `macos-26` hosted runner
label because `prosepal-ios/Package.swift` requires Swift tools 6.2+ and the
iOS 26 SDK. Do not change this back to `macos-latest` without proving the alias
resolves to an iOS 26-capable image; `macos-latest` has resolved to older Swift
6.1 images and cannot build the native package.

Flutter analyze/test/integration/golden workflows are intentionally removed from
active `main` because Flutter is archived, not the active app.

## Native Xcode Project

Tracked native project identity:

- production bundle ID: `com.prosepal.prosepal`
- production App Store Connect app: existing ProsePal listing
- production subscription products: existing `com.prosepal.pro.*` products

Staging/UAT is selected through the local-only Xcode scheme and staging
Supabase/StoreKit configuration. Do not create or commit a separate public
ProsePal app identity just to test staging.

Open the native app:

```bash
./scripts/run_ios.sh
```

Equivalent direct command:

```bash
open prosepal-ios/ProsePal.xcodeproj
```

Device testing should use a local-only Xcode scheme or Run environment values.
Do not commit `xcuserdata`, local schemes containing secrets, StoreKit receipts,
or evidence captures.

Important local Run environment variables:

- `PROSEPAL_GATEWAY_URL`
- `PROSEPAL_DEV_GATEWAY_SECRET` (staging only; never print or commit)
- `PROSEPAL_SUPABASE_URL`
- `PROSEPAL_SUPABASE_ANON_KEY`
- `PROSEPAL_PREMIUM_PRODUCT_IDS`
- `PROSEPAL_RECOMMENDED_PREMIUM_PRODUCT_ID`

See `prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md` for the detailed device
smoke matrix.

If the ignored local staging scheme is lost after worktree cleanup, restore it
from the operator's local backup:

```bash
./scripts/restore-local-staging-scheme.sh
```

The restore script verifies that the expected staging env keys are enabled, the
StoreKit staging config is referenced, and the restored scheme remains ignored
by Git. It must not print secret values.

Before debugging staging auth, generation, or StoreKit behavior from Xcode, run:

```bash
./scripts/verify-native-staging-plumbing.sh
```

The verifier checks the shared scheme is clean, the ignored local staging scheme
has the expected env keys enabled, the StoreKit config reference resolves, and
the local StoreKit file contains the expected native product IDs. It must not
print secret values.

## Supabase Environment Safety

Known project refs:

- staging: `llolwgqphwnhbiqewmcq`
- production: `mwoxtqxzunsjmbdqezif`

Rules:

- Never commit `supabase/.temp/` or `supabase/.branches/`.
- Never run `supabase db push --linked` from a production-linked checkout.
- Avoid remote DB mutations through linked projects; prefer explicit
  `STAGING_DB_URL` for staging.
- `STAGING_DB_URL` is a secret because it embeds DB credentials. It must come
  from the human operator's shell environment at runtime and must never be
  committed, printed, logged, or copied into docs.
- Function deploys to staging must use explicit
  `--project-ref llolwgqphwnhbiqewmcq`.
- Staging migrations require dry-run first.
- Untracking `supabase/.temp/` does not unlink existing local checkouts. Delete
  local `supabase/.temp`/`.branches` or relink deliberately before staging work.
- `supabase status` reports local-stack status and is not sufficient proof of
  the remote DB target.
- Agents prepare scripts/docs/diffs only. Deploys, secrets, migrations, and
  production/staging mutations remain human-gated unless the user explicitly
  authorizes a specific operation.

Guarded staging helper:

```bash
STAGING_DB_URL='postgresql://...' ./scripts/supabase-staging.sh db-push
```

Do not run this from automation by default. The script is intentionally
human-interactive and fail-closed.

## Staging Gateway Smoke

The native staging gateway endpoint is:

```text
https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/generate-card
```

Use:

```bash
./scripts/prosepal-staging-smoke.sh
```

The script expects the staging dev gateway secret to be available locally
without printing it. A healthy smoke returns HTTP 200, `lane_used=standard`,
`fallback_status=none`, and three generated messages.

If `nslookup llolwgqphwnhbiqewmcq.supabase.co` returns `NXDOMAIN` or device logs
show `NSURLErrorDomain Code=-1003`, check:

```bash
supabase projects list --output json
```

`prosepal-staging` must not be `INACTIVE`. Resume it in the Supabase dashboard
and wait for DNS before changing app code.

## App Store / Entitlement Work

Native monetization direction:

- StoreKit 2 in the app.
- App Store Server Notifications V2 and App Store Server API reconciliation on
  Supabase.
- Server entitlement is authoritative for future paid limits/extras.
- RevenueCat is not part of the native app.

Before native subscription behavior can be release-gated, staging must prove:

- Apple TEST notification verifies and writes an event row.
- TEST notifications do not grant entitlement.
- garbage/tampered `signedPayload` returns 400.
- signed-in sandbox purchase updates `user_entitlements`.
- expiry/refund flips entitlement off.
- reconciliation agrees with App Store Server API.

Track the remaining work in `docs/BACKLOG.md`.

## Release Hygiene

- Keep open work only in `docs/BACKLOG.md`.
- Keep release/readiness scope in `docs/NEXT_RELEASE_BRIEF.md`.
- Keep local evidence under ignored paths, such as `prosepal-ios/evidence/` or
  `/tmp/...`.
- Do not claim device, StoreKit, Supabase, or App Store behavior is verified
  without live evidence.
