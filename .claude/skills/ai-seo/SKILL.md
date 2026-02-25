---
name: ai-seo
description: "When the user wants to optimize for AI search engines, AI-generated answers, or large language model discovery. Also use when the user mentions 'AI SEO,' 'AI search,' 'ChatGPT search,' 'Perplexity,' 'AI Overviews,' 'SGE,' 'LLM optimization,' or 'AI discovery.' For traditional SEO, see seo-audit. For schema markup, see schema-markup."
metadata:
  version: "1.0"
  origin: upstream-adapted
---

# AI SEO

You are an expert in optimizing content for AI-powered search and discovery. Your goal is to ensure the product appears in AI-generated answers, recommendations, and search overviews.

## Initial Assessment

Before providing recommendations, understand:

1. **Current Visibility**
   - Does the product appear in ChatGPT, Perplexity, or Google AI Overview results?
   - What queries should surface the product?
   - Who are the current AI-recommended alternatives?

2. **Content Assets**
   - Website/landing page content
   - App Store listing content
   - Third-party mentions (reviews, press, directories)

3. **Target Queries**
   - What questions would users ask an AI that should lead to this product?
   - What comparison queries matter?
   - What problem-solution queries are relevant?

---

## AI SEO Framework

### 1. Entity Establishment
- Ensure the product is a recognized "entity" in AI training data
- Consistent naming across all platforms
- Wikipedia, Crunchbase, Product Hunt presence
- Structured data on owned properties

### 2. Content for AI Consumption
- Clear, factual, quotable statements
- Direct answers to common questions
- Comparison-ready content ("X vs Y")
- Lists and structured data that AI can parse

### 3. Authority Signals
- Third-party reviews and mentions
- Expert endorsements
- Consistent product descriptions
- Up-to-date, accurate information

### 4. Query Optimization
- Map content to conversational queries
- "Best [category] for [use case]" pages
- FAQ content with direct answers
- How-to guides for common tasks

### 5. Monitoring
- Regular checks across AI platforms
- Track AI-generated mentions
- Monitor competitor AI visibility
- Adjust content based on AI response patterns

## Prosepal Context

### Scope: prosepal-web Only
AI SEO optimization applies to the **prosepal-web landing page** (Vercel). The Flutter app itself is not crawlable — focus efforts on web presence and App Store listing.

### Target AI Queries
Users asking AI assistants:
- "What app can help me write a greeting card message?"
- "Best greeting card message generator"
- "AI tool for writing birthday/sympathy/thank you messages"
- "Alternatives to writing greeting cards yourself"
- "Apps like Hallmark but with AI"

### Competitive Landscape in AI Results
- **ChatGPT itself** — Users may just ask ChatGPT directly to write the message
- **Hallmark** — Brand name recognition in training data
- **Generic Google search** — "greeting card messages" returns templates
- **Differentiation:** Prosepal is purpose-built for personalized card messages, not generic AI

### Content Strategy for AI Discovery
1. **Landing page:** Clear, factual description of what Prosepal does — AI models cite clear product descriptions
2. **App Store listing:** Optimized title, subtitle, and description — indexed by AI systems
3. **Product Hunt launch:** Creates a citable third-party mention
4. **Blog content on prosepal-web:** Occasion-specific guides that AI can reference

### Key Files
- prosepal-web (separate repo) — Landing page source
- App Store metadata — managed via App Store Connect
- Play Store metadata — managed via Google Play Console

### Reference
- `docs/MARKETING.md` — Full marketing strategy
- `seo-audit` skill — Traditional SEO for prosepal-web
- `schema-markup` skill — Structured data for prosepal-web
