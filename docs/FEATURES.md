# Native Capability Inventory

## Purpose

List ProsePal capabilities that matter to the native iOS direction.

Open implementation work belongs in `docs/BACKLOG.md`.

## Core Writing Experience

| Capability | Native Direction |
|------------|------------------|
| Person-first entry | Lead with who this is for, not a document type or giant occasion grid. |
| Occasion catalogue | Keep catalogue coverage as product intelligence underneath the moment model. |
| Relationship taxonomy | Capture the relationship naturally and reuse existing relationship vocabulary where useful. |
| Tone/register | Support everyday, medium, and hard moments without provider/prompt language. |
| Length | Let the draft be shaped shorter, warmer, more direct, or more detailed without turning the flow into a form. |
| One true thing | Capture the sentence or detail the user actually wants to say. |
| Avoid details | Capture anything the user wants left out. |
| Extra context | Support sensitive or awkward context without logging raw text. |
| Spelling/locale | Keep Automatic, US English, and UK English as a writing preference. |
| Draft output | Make one useful draft feel primary; alternatives can exist when the lane returns them. |

## Results

| Capability | Native Direction |
|------------|------------------|
| Copy | Primary result action. Show clear confirmation. |
| Share | Visible secondary action through native sharing. |
| Edit | Allow user to adjust a draft before copying/saving. |
| Save | Save only when the user chooses to save; do not create surprise visible history. |
| Adjust | Warmer, shorter, more direct, and take-more-care actions stay close to the draft. |
| Start over | Return to the Moment Sheet without stale keyboard focus or stale state surprises. |

## Account And Identity

| Capability | Native Direction |
|------------|------------------|
| Anonymous first use | Preserve. Users should experience Standard value before forced auth. |
| Sign in with Apple | First-class native identity path. |
| Google sign-in | Not part of the native default. |
| Account deletion | Required once account state exists. |
| Data export | Required once account or non-local user data exists. |
| Biometric lock | Optional privacy feature. Only available after sign-in if retained. |

## Subscription And Entitlement

| Capability | Native Direction |
|------------|------------------|
| Private draft lane | Everyday draft produced locally where device capability allows, with honest unavailable/degraded states. |
| Take more care lane | Gateway or approved cloud/careful generation for harder moments. This is a safety/quality route, not a paywall gate. |
| Paywall | Contextual sheet from Premium/limit/settings boundaries, not forced immediately after welcome. |
| Purchase | Must not require app sign-in before purchase. |
| Restore | Available from Paywall and Settings. |
| Entitlement source | StoreKit 2 in app; App Store server notifications/API and gateway state are authoritative for future Premium limits/extras and any paid cloud capability. |
| Usage limits | Server state is authoritative for cloud/careful generation. |

## Saved, History, And Reminders

| Capability | Native Direction |
|------------|------------------|
| Saved messages | Native list/detail with copy, share, edit, and delete for user-saved drafts. |
| Generated history | Do not expose automatic history until privacy, deletion, and sync semantics are settled. |
| Relationship vault | SwiftData-backed Truth Beads and Voice Card, user-approved and editable. |
| Calendar/reminders | Later enrichment only; never silent inference or guilt nudging. |
| Notifications | Request only at the moment a reminder-style feature needs them. Generation itself does not require notification permission. |

## Settings And Support

| Capability | Native Direction |
|------------|------------------|
| Writing preferences | Spelling and voice preferences where useful. |
| Subscription management | Subscription, restore, legal terms, and entitlement state. |
| Privacy controls | Only show analytics/crash controls if those systems exist. |
| Feedback/support | User-controlled support path; no raw card content in diagnostics unless explicitly approved. |
| Legal | Terms and Privacy Policy accessible from Settings and paywall. |
| About | Version/build and safe runtime metadata. |

## Infrastructure

| Capability | Native Direction |
|------------|------------------|
| Generation runtime | `MessageWritingService` with private, careful, and mock clients. No third-party provider SDKs. |
| Provider routing | Hidden behind the service/gateway boundary. |
| Provider/model copy | Never user-facing. |
| Logging | Privacy-safe OSLog locally; no raw content or secrets. |
| Analytics/crash | Not carried forward by default. Requires product/privacy/ops rationale. |
| Supabase | Useful for staging gateway, auth, functions, and backend policy where it earns its keep. |
| RevenueCat | Flutter production reference only; not a native default. |
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
- `prosepal-ios/NATIVE_2026_TECHNICAL_DIRECTION.md` for native UX/product
  direction.
- `prosepal-ios/NATIVE_DEVICE_DEBUG_RUNBOOK.md` for local staging and device
  proof.
