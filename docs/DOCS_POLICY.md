# Documentation Policy

This policy keeps ProsePal documentation accurate, discoverable, and clear
about the difference between current behaviour, open work, and history.

## Canonical locations

| Subject | Owner |
|---|---|
| Product promise and boundaries | `docs/product/` |
| Current technical design | `docs/engineering/` |
| Runnable workflows | `docs/operations/` |
| Quality standards and evidence contracts | `docs/quality/` |
| Exact settings, endpoints, and evidence matrix | `docs/reference/` |
| Open work | `docs/BACKLOG.md` |
| Frozen context and release records | `docs/history/` |
| Repository rules | `AGENTS.md` |

Each subject has one canonical owner. Other files link to it instead of copying
the same instructions.

## Evergreen rules

- Active docs describe current behaviour, stable policy, or a runnable process.
- Open work, “still needs”, proposed tickets, and unfinished status belong only
  in `BACKLOG.md`.
- Completed implementation history belongs in Git history or
  `reference/feature-status.jsonl`, not the backlog. Agents edit the JSONL and
  regenerate its CSV compatibility export; they never edit the CSV directly.
- Test counts, pass percentages, dated verification claims, and temporary
  worktree paths do not belong in active docs.
- Commands include prerequisites, pass criteria, and failure handling.
- Architecture diagrams match current source and label historical or optional
  components explicitly.
- User-facing and platform claims link to authoritative sources when the claim
  depends on external policy.
- Active documents are linked from `docs/README.md` and reachable within two
  clicks from the repository README.
- Package READMEs stay short and point to canonical docs rather than duplicating
  runbooks.
- Repo-local agent commands and skills are kept only when they encode a
  ProsePal-specific engineering workflow; generic marketing or framework packs
  belong outside this repository.

## Allowed time-bound material

- `docs/BACKLOG.md`: unresolved work with `[ ]` and a definition of done.
- `docs/reference/feature-status.jsonl`: canonical implementation and evidence
  ledger, including explicit verification dates and commits.
- `docs/reference/feature-status.csv`: generated human-readable compatibility
  export; never an editable source.
- `docs/history/releases/`: immutable release evidence and postmortems.
- Private `artifacts/release/`: candidate-specific evidence, normally untracked.

## Historical material

Historical files live under `docs/history/` and begin with, or inherit from
their folder, a clear frozen-context notice. They may contain dates, retired
technology, old identifiers, and superseded plans. Active docs may link to them
for rationale but must not rely on them for current commands.

## Documentation changes

- Read the complete source document before merging or removing it.
- Use `git mv` when a document still has a clear successor.
- Preserve valuable superseded strategy under `history/` before replacing it.
- Remove a redundant active file only after its unique content is incorporated
  or intentionally archived.
- Update inbound links in the same change.
- Workflow changes update the relevant file under `docs/operations/`.
- Configuration changes update `docs/reference/configuration.md`.
- Public behaviour changes update `docs/product/capabilities.md` and the feature
  status JSONL when evidence changes, followed by regenerating its CSV export.

## Document size and splitting

Split by reader job and component ownership, not by an arbitrary line count.

- Give a component its own engineering document when it owns a stable contract,
  state model, failure policy, tests, and operational boundary.
- Keep tutorials, task-oriented how-tos, factual references, and design
  explanations separate when combining them makes the reader switch jobs.
- Do not create a new file for a small subsection that has no independent owner
  or update trigger.
- Keep self-contained visual artifacts and frozen historical decision sequences
  intact even when large; add a short directory landing page instead.
- When splitting, leave a concise overview and reciprocal links so neither half
  becomes undiscoverable.

## Validation

Run:

```bash
python3 scripts/validate_feature_status.py
python3 scripts/export_feature_status_csv.py --check
./scripts/validate_docs.sh
./scripts/release_preflight.sh native --no-env-file
```

Documentation validation checks the canonical inventory, local links, forbidden
status language in active docs, references to retired canonical paths, and
repository paths used by active agent commands and skills. Feature-ledger
validation checks its schema, evidence paths, state vocabulary, deterministic
format, and generated-export parity.
