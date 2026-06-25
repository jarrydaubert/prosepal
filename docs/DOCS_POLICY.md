# Documentation Policy

This policy keeps project docs evergreen and actionable.

## Scope

- Applies to all docs in `docs/` and `prosepal-ios/*.md`.
- Exception: release records/postmortems/changelogs can be time-bound.
- Exception: `docs/BACKLOG.md` is the active build tracker and may use
  `[x]` / `[~]` / `[ ]` markers with evidence pointers.

## Rules

- Write docs as stable runbooks/specs, not status reports.
- Do not include test counts, pass rates, or timing claims.
- Do not include checkboxes, progress markers, or "last verified" dates outside
  the active backlog tracker.
- Do not include open issues, TODOs, or in-flight work in docs.
- Track all open work only in [BACKLOG.md](./BACKLOG.md).
- Keep examples minimal and implementation-agnostic where possible.
- Prefer "how to run" + "pass criteria" format over narrative.

## Required Structure For Operational Docs

- Purpose
- Prerequisites
- Commands/steps
- Pass criteria
- Failure handling/escalation path

## Ownership

- Any PR that adds TODO/status language to docs must move that content to backlog.
- Any PR that changes workflows must update `docs/DEVOPS.md` in the same PR.
