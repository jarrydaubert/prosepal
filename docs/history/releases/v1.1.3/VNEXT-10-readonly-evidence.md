# VNEXT-10 Read-Only Evidence Record

This release record references the local evidence discovery bundle for
`VNEXT-10` AI cost/abuse controls. It does not close `VNEXT-10`; the backlog
item remains open until the approval-gated live evidence below is captured.

## Evidence References

Local evidence folder:

```bash
artifacts/release/v1.1.3/VNEXT-10/
```

Captured artifacts:

- `01-repo-only-ai-cost-abuse-audit.log`
- `02-coverage-and-live-evidence-gap-analysis.md`
- `03-proposed-kill-switch-drill.md`
- `04-live-remote-config-active.json`
- `04-live-remote-config-summary.json`
- `04-live-remote-config-versions.txt`
- `05-live-ai-cost-abuse-audit-sanitized.log`
- `06-app-check-enforcement-readonly-attempt.md`
- `07-budget-alerts-assessment.md`
- `07-budget-alerts-sanitized-summary.json`
- `08-readonly-closure-assessment.md`

Read-only findings:

- Repo-only AI cost/abuse audit passed.
- Active Remote Config matches expected AI controls and pinned model defaults.
- Full live AI cost/abuse audit passed for visible read-only checks.
- Budget thresholds exist, but exact human notification and delivery proof are
  not fully evidenced from CLI output.
- Firebase App Check API is enabled, but current credentials could not read
  Firebase AI/App Check enforcement posture through the attempted API endpoint.

Closure assessment:

- `VNEXT-10` is not closable from read-only evidence alone.
- Remaining proof is blocked on App Check enforcement visibility, budget alert
  notification/delivery evidence, and an approved AI kill-switch drill or
  equivalent runtime-disable proof.

## Repo Owner Approval Checklist

### 1. App Check Enforcement Evidence Needed

Provide read-only evidence for the production Firebase AI path showing App Check
enforcement posture.

Acceptable evidence:

- Firebase Console screenshot/export for App Check service enforcement covering
  Firebase AI Logic / production app traffic, with private identifiers redacted.
- Read-only API output from a principal with Firebase App Check service viewing
  permission.

Pass/fail oracle:

- Pass: evidence shows Firebase AI requests are protected by App Check
  enforcement for production traffic.
- Fail: evidence only proves the App Check API is enabled, or cannot distinguish
  API enablement from enforcement.

Approval needed:

- Grant or use read-only access equivalent to viewing Firebase App Check service
  posture, such as permissions including `firebaseappcheck.services.list`.

### 2. Budget Alert Notification/Delivery Evidence Needed

Provide read-only evidence that the active budget alerts reach a
human-monitored destination.

Current read-only evidence:

- One budget exists.
- Currency is GBP.
- Thresholds are present at 50%, 90%, and 100%.
- A notifications rule exists.

Acceptable additional evidence:

- Sanitized billing-budget console screenshot/export showing the alert
  destination.
- Sanitized API export proving the intended notification path.
- Provider-supported test alert, replay, dry-run, or equivalent delivery proof.

Pass/fail oracle:

- Pass: warning and critical thresholds have a named human-monitored first
  response path, and delivery is evidenced rather than assumed.
- Fail: budget exists but alert delivery relies on undocumented default
  recipients, or no delivery proof is available.

Approval needed:

- Read-only billing-budget and notification-channel visibility.
- If current alert routing is insufficient, a separate approval is required
  before editing budget alerts or notification channels.

### 3. Kill-Switch Drill Approval Request

Purpose:

- Prove `ai_enabled=false` disables generation through production Remote Config
  and that restoring the prior template recovers normal generation.

Backup command:

```bash
firebase remoteconfig:get -P prosepal-1a24b --output json \
  > artifacts/release/v1.1.3/VNEXT-10/07-remote-config-before.json
```

Prepare disabled template:

```bash
jq '.parameters.ai_enabled.defaultValue.value = "false"' \
  artifacts/release/v1.1.3/VNEXT-10/07-remote-config-before.json \
  > artifacts/release/v1.1.3/VNEXT-10/07-remote-config-ai-disabled.json
```

Publish disabled template:

```bash
firebase remoteconfig:update \
  artifacts/release/v1.1.3/VNEXT-10/07-remote-config-ai-disabled.json \
  -P prosepal-1a24b
```

Verify disabled readback:

```bash
firebase remoteconfig:get -P prosepal-1a24b --output json \
  > artifacts/release/v1.1.3/VNEXT-10/07-remote-config-disabled-readback.json
```

Restore command:

```bash
firebase remoteconfig:update \
  artifacts/release/v1.1.3/VNEXT-10/07-remote-config-before.json \
  -P prosepal-1a24b
```

Verify restored readback:

```bash
firebase remoteconfig:get -P prosepal-1a24b --output json \
  > artifacts/release/v1.1.3/VNEXT-10/07-remote-config-restored-readback.json
```

Pass/fail oracle:

- Pass: disabled readback shows only `ai_enabled=false`; the app blocks
  generation before contacting Firebase AI, shows the temporary-unavailable
  path, logs/classifies the path as the AI kill switch, consumes no usage, and
  normal generation recovers after restore.
- Fail: any unexpected Remote Config key changes, app cannot fetch config,
  unrelated paywall/premium/auth behavior changes, usage is consumed while AI is
  disabled, or generation does not recover after restore.

Approval needed:

- Explicit repo-owner approval before any `firebase remoteconfig:update`
  command.
- Explicit confirmation of test window and rollback owner before the drill.
