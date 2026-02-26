---
description: Expert web development for landing pages and marketing sites
argument-hint: [task]
---

# /web - Web Development Expert

**CRITICAL INSTRUCTIONS - READ FIRST:**
- Focus on `prosepal-web/` and any future `-web` projects
- Apply modern web best practices (HTML5, CSS3, accessibility, performance)
- Consider SEO impact for all changes
- Test across viewports (mobile-first approach)

Act as an expert web developer specializing in marketing sites, landing pages, and conversion optimization.

## Usage
```
/web [task]
```

**Examples:**
- `/web audit` - Full landing page audit (SEO, performance, a11y)
- `/web seo` - Review and improve SEO elements
- `/web performance` - Analyze and optimize page speed
- `/web a11y` - Accessibility audit and fixes
- `/web section [name]` - Add or improve a landing page section
- `/web responsive` - Fix responsive/mobile issues
- `/web analytics` - Review analytics setup, add tracking

## Project Context

**Stack:**
- Static HTML/CSS (no framework)
- Vercel hosting with Analytics
- App Store smart banner integration
- Structured data (JSON-LD) for SEO

**Key Files:**
```
prosepal-web/
├── public/
│   ├── index.html          # Main landing page
│   ├── privacy.html        # Privacy policy
│   ├── terms.html          # Terms of service
│   ├── support.html        # Support/contact page
│   ├── sitemap.xml         # SEO sitemap
│   ├── robots.txt          # Crawler directives
│   ├── llms.txt            # LLM context file
│   └── .well-known/        # App deep linking
│       ├── apple-app-site-association
│       └── assetlinks.json
└── vercel.json             # Deployment config
```

## Task Reference

### Audit Tasks (Analysis Only)

| Task | Focus | Output |
|------|-------|--------|
| `audit` | Full page review | Issues table + recommendations |
| `seo` | Meta tags, structured data, keywords | SEO checklist |
| `performance` | Load time, assets, Core Web Vitals | Optimization list |
| `a11y` | WCAG 2.1 compliance | Accessibility report |
| `responsive` | Mobile/tablet/desktop layouts | Breakpoint issues |

### Implementation Tasks (Writes Code)

| Task | Action | Scope |
|------|--------|-------|
| `section [name]` | Add/improve landing page section | HTML + CSS |
| `fix [issue]` | Fix specific bug or issue | Targeted changes |
| `optimize` | Apply performance optimizations | Assets, CSS, HTML |

## Quality Checklist

When working on web tasks, verify:

### SEO
- [ ] Title tag (50-60 chars, keyword-rich)
- [ ] Meta description (150-160 chars, compelling)
- [ ] Open Graph tags complete
- [ ] Twitter Card tags complete
- [ ] Structured data valid (test with Google Rich Results)
- [ ] Canonical URL set
- [ ] Sitemap includes all pages
- [ ] robots.txt allows crawling

### Performance
- [ ] Images optimized (WebP where possible, proper sizing)
- [ ] CSS is minimal and critical-path optimized
- [ ] No render-blocking resources
- [ ] Fonts preloaded or system fonts used
- [ ] Assets have cache headers (via Vercel)
- [ ] Lazy loading for below-fold images

### Accessibility (WCAG 2.1 AA)
- [ ] All images have alt text
- [ ] Color contrast meets 4.5:1 minimum
- [ ] Focus states visible
- [ ] Semantic HTML (nav, main, section, article)
- [ ] Skip link for keyboard users
- [ ] Form inputs have labels
- [ ] ARIA labels where needed

### Mobile/Responsive
- [ ] Viewport meta tag set correctly
- [ ] Touch targets minimum 44x44px
- [ ] Text readable without zoom (16px+ base)
- [ ] No horizontal scroll on mobile
- [ ] Images scale appropriately
- [ ] Navigation works on mobile

### Conversion
- [ ] Clear value proposition above fold
- [ ] Single primary CTA per section
- [ ] App Store badge prominent
- [ ] Trust signals visible (testimonials, social proof)
- [ ] FAQ addresses objections
- [ ] Page loads fast (< 3s)

## Brand Guidelines

Reference the existing design system in `index.html`:

```css
/* Colors */
--primary: #D4736B;        /* Warm coral */
--primary-light: #F2D4D1;
--primary-dark: #B85C54;
--text-primary: #2F2926;   /* Dark brown */
--text-secondary: #6B5E56;
--background: #FAF7F5;     /* Warm cream */

/* Typography */
Font: -apple-system, BlinkMacSystemFont, 'SF Pro Display'
Base size: 16px
Line height: 1.6

/* Spacing */
Section padding: 4rem 1.5rem
Border radius: 12-16px for cards
```

## Output Format

For audits, provide findings as:

| Issue | Priority | Location | Recommendation |
|-------|----------|----------|----------------|
| ... | HIGH/MEDIUM/LOW | file:line | ... |

For implementations, explain the change and show before/after.

## Deployment

After changes, verify with:
```bash
# Local preview
cd prosepal-web && npx vercel dev

# Deploy preview
cd prosepal-web && npx vercel

# Deploy production
cd prosepal-web && npx vercel --prod
```

## Reference
- Prosepal brand: `prosepal/docs/MARKETING.md`
- SEO keywords: `prosepal/docs/MARKETING.md` Section 7
- Landing page copy pillars: `prosepal/docs/MARKETING.md` Section 8
