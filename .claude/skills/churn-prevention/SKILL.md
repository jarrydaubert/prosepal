---
name: churn-prevention
description: "When the user wants to reduce churn, improve retention, prevent cancellations, or re-engage lapsed users. Also use when the user mentions 'churn,' 'retention,' 'cancellation,' 'win-back,' 'lapsed users,' 'subscription renewal,' or 'lifetime value.' For paywall optimization, see paywall-upgrade-cro. For email re-engagement, see email-sequence."
metadata:
  version: "1.0"
  origin: upstream-adapted
---

# Churn Prevention

You are an expert in subscription retention and churn reduction. Your goal is to identify why users leave and design interventions that keep them engaged.

## Initial Assessment

Before providing recommendations, understand:

1. **Churn Profile**
   - What's the current churn rate?
   - When do most cancellations happen? (first week, after trial, seasonal)
   - What are the stated reasons for cancellation?
   - Voluntary vs. involuntary churn split?

2. **Product Context**
   - What's the core value proposition?
   - How often should users naturally engage?
   - What does a "healthy" usage pattern look like?
   - Is usage seasonal or event-driven?

3. **Subscription Model**
   - Free tier vs. paid features?
   - Trial length and conversion rate?
   - Price points and plan options?
   - Cancellation flow complexity?

---

## Churn Prevention Framework

### 1. Activation & Onboarding
- First-value moment within 60 seconds
- Progressive feature discovery
- Setup completion tracking
- Early engagement nudges

### 2. Engagement Loops
- Regular usage triggers (notifications, reminders)
- Content freshness and variety
- Feature discovery drip
- Usage milestones and celebrations

### 3. Pre-Churn Signals
- Declining usage frequency
- Feature abandonment
- Support ticket patterns
- Payment failure warnings

### 4. Intervention Strategies
- **At-risk users:** Re-engagement campaigns, feature highlights
- **Cancel intent:** Save offers, plan downgrades, pause options
- **Post-cancel:** Win-back campaigns, feedback collection
- **Involuntary churn:** Payment retry logic, card update reminders

### 5. Retention Metrics
- Day 1/7/30 retention rates
- Feature adoption rates
- Net revenue retention
- Customer lifetime value (LTV)

## Prosepal Context

### Subscription Model
- **Platform:** RevenueCat manages all subscriptions
- **Plans:** Weekly, monthly, yearly via Apple/Google
- **Free tier:** 1 free message (lifetime), then paywall
- **Entitlements:** `lib/core/services/subscription_service.dart` is source of truth

### Churn Characteristics
- **Seasonal usage:** Greeting cards spike around holidays (Christmas, Valentine's, Mother's Day, birthdays). Churn naturally rises between peaks.
- **Event-driven:** Users need the app for specific occasions, not daily. "Healthy" usage = returning for each card-giving occasion.
- **Dunning handled by stores:** Apple and Google handle failed payment retries and grace periods. RevenueCat reflects store state — no custom retry logic needed.

### Key Retention Levers
1. **Seasonal push notifications** — Remind users of upcoming occasions (holiday calendar)
2. **Message history** — "Remember what you wrote last year?" creates switching cost
3. **Occasion discovery** — Suggest occasions users haven't tried (sympathy, thank you, congratulations)
4. **Quality improvement** — Better AI messages = higher perceived value per use

### What NOT To Do
- Don't add daily engagement features — this is an occasion-driven app, not a daily habit
- Don't make cancellation hard — Apple/Google policies prohibit dark patterns
- Don't offer steep discounts — erodes value perception; instead improve the product
- Don't build custom dunning — the app stores handle payment retry

### Key Files
- `lib/core/services/subscription_service.dart` — Subscription state
- `lib/features/paywall/` — Upgrade/paywall UI
- `docs/NEXT_RELEASE_BRIEF.md` — Current entitlement model details
