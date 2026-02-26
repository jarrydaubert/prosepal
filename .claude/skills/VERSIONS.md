# Skills Version Tracking

Canonical source for upstream skill provenance and inclusion policy.

## Upstream Reference

- Repository: https://github.com/coreyhaines31/marketingskills
- Version tag: `v1.2.0`
- Commit: `ea8df8290a515a85b1b59f3374d9a225962bb340`

## Freshness Check (2026-02-26)

- `main` head at check time: `0c24410a0b757b557c385aaaa218048a40405069`
- Upstream skill directories on `main`: unchanged (29 total)
- `SKILL.md` diff from `v1.2.0...main`: none
- Result: `v1.2.0` skill content is current for this repo at check time

## Upstream Skills Included (27/29)

These upstream skills are present locally and adapted with `## Prosepal Context`.

`ab-test-setup`, `ad-creative`, `ai-seo`, `analytics-tracking`, `churn-prevention`, `competitor-alternatives`, `content-strategy`, `copy-editing`, `copywriting`, `email-sequence`, `form-cro`, `launch-strategy`, `marketing-ideas`, `marketing-psychology`, `onboarding-cro`, `page-cro`, `paid-ads`, `paywall-upgrade-cro`, `popup-cro`, `pricing-strategy`, `product-marketing-context`, `programmatic-seo`, `referral-program`, `schema-markup`, `seo-audit`, `signup-flow-cro`, `social-content`.

## Upstream Skills Excluded (NA)

These are intentionally not installed for this project.

- `cold-email` (B2B outbound focus; not aligned to Prosepal app priorities)
- `free-tool-strategy` (web-SaaS acquisition model; not aligned to current product model)

## Non-Upstream Skills Kept

- `tdd` (adapted from `mattpocock/skills`)
- `prd-to-issues` (adapted from `mattpocock/skills`)
- `accessibility` (Prosepal-specific Flutter accessibility skill)

## Optimization Policy

- Keep upstream methodology intact where possible.
- Put project-specific behavior in `## Prosepal Context`.
- Keep references aligned to active docs:
  - `docs/DEVOPS.md`
  - `docs/BACKLOG.md`
  - `docs/NEXT_RELEASE_BRIEF.md`
- Remove references to disabled slash commands.
