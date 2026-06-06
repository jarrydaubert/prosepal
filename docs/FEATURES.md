# Feature And Parity Inventory

## Purpose

List ProsePal capabilities that the native iOS rewrite must preserve, improve,
or deliberately defer before it can replace the Flutter production app.

Open implementation work belongs in `docs/BACKLOG.md`.

## Core Writing Experience

| Capability | Native Direction |
|------------|------------------|
| Occasion catalogue | Preserve full catalogue coverage from Flutter. Present through native searchable/grouped selection rather than a busy cloned grid. |
| Relationship taxonomy | Preserve Flutter relationship options. Present through compact native selection or searchable sheet. |
| Tone taxonomy | Preserve Flutter tone options. Keep labels user-facing and avoid prompt/provider language. |
| Length | Preserve Brief, Standard, and Detailed behavior. |
| Recipient | Capture naturally as “who this is for” without making the app feel like a document editor. |
| Include details | Capture optional personal details to shape drafts. |
| Avoid details | Capture anything the user wants left out. |
| Extra context | Support sensitive or awkward context without logging raw text. |
| Spelling/locale | Keep Automatic, US English, and UK English as a writing preference. |
| Generated options | Return three drafts per successful generation where the gateway contract allows it. |

## Results

| Capability | Native Direction |
|------------|------------------|
| Copy | Primary result action. Show clear confirmation. |
| Share | Visible secondary action through native sharing. |
| Edit | Allow user to adjust a draft before copying/saving. |
| Save | Save useful drafts locally first; cloud sync depends on later auth/backend decisions. |
| Regenerate | Product-lane aware. Free/Premium boundaries come from gateway/entitlement policy. |
| Start over | Return to Create without stale keyboard focus or stale form state surprises. |

## Account And Identity

| Capability | Native Direction |
|------------|------------------|
| Anonymous first use | Preserve. Users should experience Standard value before forced auth. |
| Sign in with Apple | First-class native identity path. |
| Google sign-in | Deferred unless existing-account continuity requires it. |
| Account deletion | Required before production replacement if account state exists. |
| Data export | Required before production replacement if user data is stored beyond local-only drafts. |
| Biometric lock | Parity requirement before production replacement if retained. Only available after sign-in. |

## Subscription And Entitlement

| Capability | Native Direction |
|------------|------------------|
| Free/Standard lane | Gateway-backed during native staging; future local lane requires separate spike. |
| Premium lane | Gateway-authorized cloud/frontier generation. |
| Paywall | Contextual sheet from Premium/limit/settings boundaries, not forced immediately after welcome. |
| Purchase | Must not require app sign-in before purchase. |
| Restore | Available from Paywall and Settings. |
| Entitlement continuity | Decide deliberately between RevenueCat continuity and StoreKit 2 direct handling. |
| Usage limits | Gateway/server state is authoritative on production-capable paths. |

## Saved, History, And Reminders

| Capability | Native Direction |
|------------|------------------|
| Saved messages | Native list/detail with copy, share, edit, delete. |
| Generated history | Either implement as a filter/section inside Saved or explicitly defer from replacement scope. |
| Calendar/reminders | Keep as replacement-scope parity consideration. Do not force a primary tab until mature. |
| Notifications | Request only at the moment a reminder-style feature needs them. Gateway generation itself does not require notification permission. |

## Settings And Support

| Capability | Native Direction |
|------------|------------------|
| Writing preferences | Spelling, default tone, default generation mode where useful. |
| Subscription management | Subscription, restore, legal terms, and entitlement state. |
| Privacy controls | Only show analytics/crash controls if those systems exist. |
| Feedback/support | User-controlled support path; no raw card content in diagnostics unless explicitly approved. |
| Legal | Terms and Privacy Policy accessible from Settings and paywall. |
| About | Version/build and safe runtime metadata. |

## Infrastructure

| Capability | Native Direction |
|------------|------------------|
| Generation runtime | ProsePal gateway contract. No native provider SDKs. |
| Provider routing | Server-side only. |
| Provider/model copy | Never user-facing. |
| Logging | Privacy-safe OSLog locally; no raw content or secrets. |
| Analytics/crash | Not carried forward by default. Requires product/privacy/ops rationale. |
| Supabase | Useful for staging gateway, auth, functions, and backend policy where it earns its keep. |
| RevenueCat | Useful only if entitlement continuity justifies it. |
| Firebase Remote Config | Flutter production reference only; not a native default. |

## Platform Scope

| Platform | Direction |
|----------|-----------|
| iOS | Active native rewrite target. |
| Android | Deferred/frozen for native rewrite. Flutter Android remains production-reference only. |
| Web | Separate marketing/product surface, outside this native app scope. |

## Verification Reference

Use:

- `docs/BACKLOG.md` for active DoD.
- `docs/DEVOPS.md` for runnable validation.
- `prosepal-ios/NATIVE_PRODUCT_NORTH_STAR.md` for native UX/product shape.
- `prosepal-ios/REWRITE_PLAN.md` for scenario-level native delivery gates.
