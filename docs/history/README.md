# Historical Documentation

Everything below this directory is frozen context, not current implementation
instruction. It is retained because old architecture, App Review experience,
service ownership, design explorations, and release evidence still explain why
the native product has its present boundaries.

## Contents

- [architecture](./architecture/) — superseded native and gateway strategies.
- [product](./product/) — longer-range product explorations preserved outside
  the v1 contract.
- [flutter](./flutter/README.md) — archived Flutter production architecture,
  services, security, and configuration.
- [app-review-lessons.md](./app-review-lessons.md) — lessons translated from
  the previous production release.
- [design-explorations](./design-explorations/) — non-current layout mockups.
- [releases](./releases/) — immutable evidence from earlier release work.

## Rules

- Do not execute commands here against current production without a current
  operations runbook and explicit authorization.
- Do not copy retired provider, Firebase, RevenueCat, or Flutter architecture
  into the native app.
- Do not edit release evidence to make an old result look current.
- When historical material becomes relevant again, verify it against current
  source and move the resulting decision into active documentation.
