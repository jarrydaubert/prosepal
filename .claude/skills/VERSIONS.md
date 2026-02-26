# Skills — Version Tracking

Tracks where each skill came from and how to maintain it.

## Upstream: coreyhaines31/marketingskills (21 skills)

These skills are adapted from the upstream marketing skills repository. Keep the upstream methodology intact; customization goes in the `## Prosepal Context` section appended to each file.

| Skill | Status |
|-------|--------|
| ab-test-setup | ✅ + Prosepal Context |
| competitor-alternatives | ✅ + Prosepal Context |
| copy-editing | ✅ + Prosepal Context |
| copywriting | ✅ + Prosepal Context |
| email-sequence | ✅ + Prosepal Context |
| form-cro | ✅ + Prosepal Context |
| launch-strategy | ✅ + Prosepal Context |
| marketing-ideas | ✅ + Prosepal Context |
| marketing-psychology | ✅ + Prosepal Context |
| onboarding-cro | ✅ + Prosepal Context |
| page-cro | ✅ + Prosepal Context |
| paid-ads | ✅ + Prosepal Context |
| paywall-upgrade-cro | ✅ + Prosepal Context |
| popup-cro | ✅ + Prosepal Context |
| pricing-strategy | ✅ + Prosepal Context |
| programmatic-seo | ✅ + Prosepal Context |
| referral-program | ✅ + Prosepal Context |
| schema-markup | ✅ + Prosepal Context |
| seo-audit | ✅ + Prosepal Context |
| signup-flow-cro | ✅ + Prosepal Context |
| social-content | ✅ + Prosepal Context |

## Upstream + Heavy Adaptation (4 skills)

New skills created from upstream templates with significant Prosepal-specific content.

| Skill | Based On | Adaptation |
|-------|----------|------------|
| churn-prevention | Upstream template | RevenueCat subscriptions, mobile app retention |
| content-strategy | Upstream template | B2C mobile app content pillars, ASO focus |
| ad-creative | Upstream template | Apple Search Ads, warm emotional tone |
| product-marketing-context | Upstream template | Prosepal positioning, B2C mobile |

## External-Adapted (2 skills)

Adapted from mattpocock/skills for Flutter/Dart workflow.

| Skill | Source | Adaptation |
|-------|--------|------------|
| tdd | mattpocock/skills | flutter test, ProviderContainer, integration_test/ |
| prd-to-issues | mattpocock/skills | GitHub Issues (not Linear), flutter commands |

## Prosepal-Only (2 skills)

Written specifically for Prosepal with no upstream equivalent.

| Skill | Purpose |
|-------|---------|
| accessibility | Flutter Semantics, VoiceOver/TalkBack, 48dp touch targets |
| analytics-tracking | Firebase Analytics + Crashlytics, mobile event taxonomy |
| ai-seo | prosepal-web SEO, App Store listing optimization |

## Deliberately Excluded

Skills from upstream that don't apply to Prosepal:

| Skill | Reason |
|-------|--------|
| engineering | Next.js/web stack — Prosepal is Flutter |
| cold-email | B2B outbound — Prosepal is B2C mobile |
| free-tool-strategy | Web SaaS model — Prosepal is native mobile app |

## Editing Rules

1. **Upstream skills:** Do NOT modify the upstream methodology sections. Add Prosepal-specific guidance only in the `## Prosepal Context` section at the bottom of each file.
2. **New skills:** Full creative control, but follow the same YAML frontmatter format.
3. **All skills:** Must have YAML frontmatter (name, description) and a `## Prosepal Context` section.
