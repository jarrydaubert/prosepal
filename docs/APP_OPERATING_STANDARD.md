# App Operating Standard

## Purpose

Define the default operating model for building multiple apps under one legal
owner while keeping each app operationally separate.

This standard is about clean boundaries, low cross-app contamination, and
maintainable admin practices. It is not a legal-separation document.

## Operating Model

Operate as one legal owner and many operationally separate apps.

Each app should be built as its own independent unit with its own:
- domain
- admin identity
- support surface
- backend/projects
- web stack
- secrets
- billing trail
- documentation

## Core Rule

Each app should continue functioning if the other apps disappear.

One app should not depend on another for:
- DNS
- hosting
- cloud project
- backend
- analytics
- support mailboxes
- secrets
- web repo
- legal pages
- vendor logins

## Identity Standard

Primary owner where possible:
- `admin@appdomain.com`

Personal identity should be used only for:
- recovery
- break-glass admin
- emergency access

Personal identity should not be the default for:
- public support
- day-to-day service login
- production project ownership
- public-facing app contact

## Per-App Minimum Setup

For every app, create:
- `admin@appdomain.com`
- `support@appdomain.com`
- `billing@appdomain.com`

Optional later:
- `legal@appdomain.com`
- `security@appdomain.com`

Use role-based public identities rather than person-based mailboxes.

## What Must Be Separate Per App

Separate these per app where practical:
- domain
- DNS/Cloudflare control
- Google identity used for setup
- Firebase / Google Cloud project
- Supabase org/project
- RevenueCat project
- email delivery vendor account or project
- analytics property
- search tooling / Search Console
- web hosting/deploy project
- mobile repo
- web repo
- CI/CD secrets
- deployment tokens
- support/contact details
- operational documentation

## What Can Stay Centralized

These may remain centralized when duplication is wasteful:
- legal identity
- bookkeeping/accounting
- personal recovery identity
- 1Password account
- Apple Developer account
- Google Play developer account

If store accounts stay centralized, app-facing metadata must still stay
app-specific:
- support email
- privacy URL
- terms URL
- marketing site
- contact details
- internal ownership records

## Google / Firebase Standard

Each app gets its own production cloud boundary.

Do not share across apps:
- auth
- database
- storage
- analytics
- crash reporting
- OAuth clients
- API keys
- quotas
- billing visibility

One app, one production cloud boundary.

## Backend / SaaS Standard

Use separate accounts, orgs, or projects per app whenever it materially
improves:
- quota separation
- billing clarity
- blast-radius control
- admin clarity

Not every vendor needs a brand-new login, but every app should have a clean,
documented boundary inside that vendor.

## DNS / Cloudflare Standard

Early-stage acceptable:
- central DNS ownership if it is clearly documented and transferable

Cleaner long-term:
- app-specific DNS account/control

Rule:
- do not leave domain custody ambiguous
- centralize intentionally or separate intentionally
- document who owns the zone, renewals, and transfer path

## Repo Standard

Prefer separate repos per app:
- `app-mobile`
- `app-web`

Keep separate:
- env vars
- branding
- store metadata
- legal copy
- deploy config
- analytics tags
- secrets
- docs

Shared internal libraries are acceptable only if they are truly reusable and do
not create operational coupling.

Do not share production infrastructure just to save setup time.

## Billing Standard

Per app, classify every vendor as one of:
- legitimate free tier per separate product/project
- one-time trial only
- restricted by provider terms
- paid once usage or reliability requires it

Do not assume a new email always means a permitted new free trial.

## Secrets Standard

Store credentials in 1Password.

Per app, track:
- registrar
- DNS
- admin identity
- cloud project IDs
- backend org/project IDs
- app store IDs
- analytics properties
- deploy tokens
- API keys
- recovery codes
- 2FA method
- renewal dates
- billing owner
- emergency recovery path

Hard rules:
- never reuse cross-app secrets
- rotate secrets when ownership changes

## Documentation Standard

Each app needs a private operating record containing:
- domain and registrar
- DNS owner
- admin identity
- repos
- store IDs
- cloud/backend project IDs
- vendor account IDs
- billing owner
- support email
- privacy/terms/support URLs
- deploy process
- recovery process
- what is centralized vs app-specific

This can live in:
- a private admin repo
- a private `OPERATIONS.md`
- secure internal docs
- 1Password secure notes

For public repos, record only high-level operational facts. Do not commit:
- raw certificate fingerprints
- secret values or token-like identifiers
- recovery codes or recovery email paths
- detailed service-account inventories
- private support-routing rules or personal phone numbers

## When This Standard Applies

Use this standard by default for every new app unless there is a clear reason to
centralize a specific service.

If a service is centralized, document:
- why it is centralized
- who owns it
- which apps depend on it
- how recovery works

## Standard Operating Principle

One legal owner can operate many apps.
Each app should run inside its own operational boundary.
Personal identity is backup only.
Shared paid developer accounts are acceptable when duplication is wasteful.
Everything else should be separated per app where practical.
