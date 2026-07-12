# Release Evidence

Release evidence proves the parts of ProsePal that deterministic local tests
cannot prove. Evidence is private release material, not evergreen documentation.

## Folder contract

Use one folder per release candidate:

```text
artifacts/release/<release-tag>/native-ios/
```

Recommended files:

- `01-version-build.md`
- `02-local-validation.md`
- `03-wired-device.md`
- `04-archive-configuration.md`
- `05-gateway-staging.md`
- `06-sign-in-with-apple.md`
- `07-storekit-and-entitlement.md`
- `08-account-deletion.md`
- `09-accessibility.md`
- `10-system-surfaces.md`
- `11-testflight.md`
- `12-secret-audit.md`
- `13-rollback.md`
- `signoff.md`

## Evidence rules

- Use synthetic message content only.
- Never store credentials, tokens, receipts, signed payloads, provider keys,
  private database URLs, or real personal messages.
- Record the exact target environment without copying secret values.
- Distinguish simulator, local StoreKit, wired device, sandbox, and TestFlight
  evidence; one cannot stand in for another.
- Include the command or user path, observed result, and pass/fail decision.
- Keep evidence outside evergreen docs and outside Git unless the repository
  owner explicitly approves a safe tracked artifact.

## Required proof areas

| Area | Proof |
|---|---|
| Archive | Correct bundle, public configuration present, privileged secrets absent |
| Gateway | Staging auth, quota, burst, idempotency, replay, retention, and safe errors |
| Apple identity | Sign-in, cancellation, refresh, sign-out, continuity, and deletion material |
| StoreKit | Products, purchase, cancellation/pending, restore, transaction updates, revocation/refund |
| Entitlement server | Notification verification and reconciliation to the correct user |
| Device UX | Core Moment loop, recovery, sharing, saving, deletion, Settings, and optional surfaces |
| Accessibility | VoiceOver, Dynamic Type, contrast, motion, transparency, keyboard, and width matrix |
| Privacy | No sensitive content or credentials in logs, bundle, evidence, or repository |
| Rollback | Candidate can be stopped or replaced without corrupting account or entitlement state |

## Sign-off

The release owner signs only after every required area is passed or explicitly
removed from the candidate scope. A failed gate becomes one backlog item with a
deterministic definition of done before the candidate is promoted.

See [Native Release](../operations/release.md) for the operational sequence.
