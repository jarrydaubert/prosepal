---
name: analytics-tracking
description: "When the user wants to implement, audit, or plan analytics tracking, event taxonomy, or crash reporting. Also use when the user mentions 'analytics,' 'tracking,' 'events,' 'Firebase Analytics,' 'Crashlytics,' 'crash reporting,' 'funnels,' 'user events,' or 'conversion tracking.' For A/B testing, see ab-test-setup."
metadata:
  version: "1.0"
  origin: upstream-adapted
---

# Analytics Tracking

You are an expert in mobile app analytics implementation. Your goal is to design and implement event tracking that provides actionable insights.

## Initial Assessment

Before providing recommendations, understand:

1. **Analytics Goals**
   - What business questions need answering?
   - What decisions will the data inform?
   - What's the current tracking state?

2. **Technical Stack**
   - Analytics platform(s) in use
   - Current event taxonomy
   - Data pipeline and destinations

3. **Privacy Requirements**
   - GDPR/CCPA compliance needs
   - User consent framework
   - Data retention policies

---

## Analytics Framework

### 1. Event Taxonomy Design
- **Naming convention:** `object_action` (e.g., `message_generated`, `paywall_viewed`)
- **Consistent properties:** Every event should include context (screen, source, timestamp)
- **Hierarchical:** Group related events with common prefixes
- **Documented:** Every event has a description and expected properties

### 2. Event Categories
- **Lifecycle:** app_open, app_background, session_start
- **Navigation:** screen_view, tab_switch, back_press
- **Core Actions:** The key user actions that define product usage
- **Conversion:** Funnel milestones (signup, purchase, upgrade)
- **Errors:** crash, api_error, validation_error

### 3. Funnel Tracking
- Define clear funnels with ordered steps
- Track drop-off between each step
- Include properties that explain context

### 4. User Properties
- Subscription status
- Account age
- Feature usage flags
- Platform / device info

### 5. Quality Assurance
- Debug mode for development
- Event validation rules
- Regular audit of tracking accuracy
- Remove deprecated events

## Prosepal Context

### Analytics Stack
- **Firebase Analytics** — Primary event tracking (console.firebase.google.com)
- **Firebase Crashlytics** — Crash and error reporting
- **No GTM/UTM** — Mobile app, not web; no tag manager or URL parameters
- **No third-party analytics** — Firebase is the single analytics platform

### Core Event Taxonomy

| Event | Properties | When |
|-------|-----------|------|
| `message_generated` | occasion, relationship, tone | User generates a message |
| `message_copied` | occasion, message_length | User copies generated message |
| `paywall_viewed` | source, trigger | User sees paywall |
| `purchase_completed` | plan, price, currency | Successful purchase |
| `purchase_restored` | plan | Subscription restored |
| `auth_completed` | provider (apple/google/email) | User signs in |
| `onboarding_completed` | steps_viewed | User finishes onboarding |
| `free_message_used` | occasion | User uses their one free message |

### What NOT to Track
- **PII** — No names, emails, or message content in analytics
- **Exact message text** — Never log AI-generated content to analytics
- **Financial details** — RevenueCat handles revenue; don't duplicate
- **Device identifiers** — Use Firebase's built-in anonymous IDs only

### Key Funnels
1. **Activation:** app_open → onboarding → first message generated
2. **Conversion:** paywall_viewed → purchase_started → purchase_completed
3. **Generation:** occasion_selected → relationship_selected → tone_selected → message_generated → message_copied

### Key Files
- Firebase Analytics calls should go through a centralized analytics service
- Crashlytics: automatic crash reporting + custom error logging
- `docs/NEXT_RELEASE_BRIEF.md` — Current analytics state

### Reference
- `ab-test-setup` skill — Firebase Remote Config for experiments
- `docs/MARKETING.md` — Marketing metrics and KPIs
