---
name: product-marketing-context
description: "When the user needs product positioning, messaging framework, value propositions, or brand context for marketing materials. Also use when the user mentions 'positioning,' 'messaging framework,' 'value prop,' 'brand story,' 'product marketing,' 'ideal customer profile,' or 'competitive positioning.' For writing specific copy, see copywriting."
metadata:
  version: "1.0"
  origin: upstream-adapted
---

# Product Marketing Context

You are an expert product marketer. Your goal is to define and communicate the product's positioning, messaging, and value proposition clearly and consistently.

## Framework

### 1. Product Definition
- What is it? (One sentence)
- Who is it for? (Specific persona)
- What problem does it solve? (Pain point)
- How is it different? (Differentiation)

### 2. Messaging Hierarchy
- **Tagline:** 5-8 words, memorable
- **Value proposition:** 1 sentence, specific benefit
- **Positioning statement:** For [audience] who [need], [product] is [category] that [benefit]. Unlike [alternative], [product] [differentiator].
- **Elevator pitch:** 30 seconds, covers problem → solution → proof

### 3. Key Messages
- 3-5 core messages that support the positioning
- Each with supporting proof points
- Consistent across all channels

### 4. Competitive Positioning
- Category definition (where do you play?)
- Competitive alternatives (what do people use today?)
- Differentiation matrix (why pick you?)

### 5. Customer Evidence
- Testimonials, reviews, ratings
- Usage statistics
- Before/after stories

## Prosepal Context

### Product Definition
- **What:** AI-powered greeting card message assistant
- **Who:** Anyone buying a greeting card who struggles with what to write
- **Problem:** The "blank card moment" — you've bought the perfect card but can't find the right words
- **How it's different:** Purpose-built for greeting cards (not generic AI), personalized to your relationship and occasion

### Tagline
**"The right words, right now."**

### Value Proposition
Prosepal generates personalized greeting card messages in seconds, so you can give a card that sounds like you — not a greeting card factory.

### Positioning Statement
For gift-givers who struggle to write heartfelt card messages, Prosepal is a mobile app that uses AI to generate personalized messages for any occasion. Unlike ChatGPT or generic AI tools, Prosepal is purpose-built for greeting cards with prompts optimized for warmth, occasion-appropriateness, and personal voice.

### Competitive Alternatives
| Alternative | Weakness Prosepal Exploits |
|------------|---------------------------|
| ChatGPT / generic AI | Not optimized for cards; requires prompt engineering; output feels generic |
| Google "birthday messages" | Copy-paste templates; everyone gets the same message; no personalization |
| Hallmark pre-printed | Expensive; limited; not personalized |
| Writing it yourself | Takes time; writer's block; anxiety about getting it right |

### Key Messages
1. **Effortless personalization** — Tell us the occasion and relationship, get a message that sounds like you wrote it
2. **Every occasion covered** — Birthday, sympathy, congratulations, thank you, and dozens more
3. **Try before you buy** — Your first message is free, no account required
4. **Private and personal** — Your messages aren't stored or used to train AI

### Target Personas (from docs/MARKETING.md)
- **Primary:** 25-45, buys 5+ cards/year, time-poor, wants thoughtful messages without the stress
- **Secondary:** 18-25, new to card-giving, needs help with tone and formality
- **Tertiary:** 45+, frequent card sender, values quality and personal touch

### Brand Voice
| Yes | No |
|-----|-----|
| Warm, helpful, slightly playful | Corporate, cold, preachy |
| "You've got this" | "Leverage our platform" |
| Self-aware, relatable humor | Cheesy, forced humor |
| "Cards are hard" empathy | "You're doing it wrong" |

### Pricing Context
- **Free:** 1 message (lifetime) — no account needed
- **Paid:** Weekly / monthly / yearly subscriptions via Apple & Google
- **Fair use:** ~500 messages/month (generous limit, not a hard wall)
- Apple and Google take 15-30% commission

### Key Files
- `docs/MARKETING.md` — Full marketing strategy
- `docs/NEXT_RELEASE_BRIEF.md` — Current product scope and features
- `lib/core/services/ai_service.dart` — How AI generation works
- `lib/core/services/subscription_service.dart` — Pricing/entitlements

### Reference
- `copywriting` skill — For writing specific marketing copy
- `launch-strategy` skill — For product launch planning
- `competitor-alternatives` skill — For competitive content
