# Video Creation with Launchpad

> Programmatic video creation for App Store previews, social media, and launch announcements.

## Overview

[Launchpad](https://github.com/trycua/launchpad) is an open-source toolkit for creating product videos using React instead of traditional video editors. Built on [Remotion](https://remotion.dev/), it lets you write videos as code - version-controlled, reusable, and AI-assisted.

## Why Consider This

| Traditional Approach | Code-Based Approach |
|---------------------|---------------------|
| Edit in Final Cut/Premiere | Write React components |
| Manual timeline adjustments | Programmatic animations |
| Hard to maintain consistency | Reusable templates |
| Re-export for every change | `pnpm render` |
| No version control | Git-friendly |

## Potential Uses for Prosepal

### 1. App Store Preview Videos
- **iOS requires:** 15-30 second previews showing app functionality
- **Benefit:** Update screenshots/flows without re-editing entire video
- **Template idea:** Phone frame + screen recording + text overlays

### 2. Social Media Clips
- TikTok/Reels showing "how to write the perfect birthday message"
- Consistent branding across all clips
- Quick iteration on messaging/copy

### 3. Launch Announcements
- New feature announcements
- Version update videos
- "What's New" content

### 4. Blog/Website Embeds
- Demo videos for landing page
- Tutorial walkthroughs
- Testimonial/review compilations

## Tech Stack

```
Remotion       - React-based video framework
Next.js        - Preview/development server
TailwindCSS    - Styling
Claude Code    - AI-assisted scene creation
```

## Getting Started

```bash
# Clone the repo
git clone https://github.com/trycua/launchpad.git
cd launchpad

# Install dependencies
pnpm install

# Create a new video project
pnpm create-video
# Enter: prosepal-appstore

# Open Remotion Studio (live preview)
pnpm remotion

# Render final video
pnpm render
```

## Project Structure

```
launchpad/
├── packages/
│   ├── shared/         # Reusable components
│   │   ├── FadeIn
│   │   ├── SlideUp
│   │   ├── TextReveal
│   │   └── Terminal
│   └── assets/         # Brand assets
│       ├── colors
│       ├── fonts
│       └── sounds
├── videos/
│   ├── _template/      # Base template
│   ├── cuabench/       # Example project
│   └── prosepal-*/     # Our video projects
└── docs/
```

## Prosepal Brand Integration

When setting up, configure brand assets:

```typescript
// packages/assets/src/colors.ts
export const prosepal = {
  primary: '#7C5DCA',      // M3 Purple
  primaryLight: '#E8E0F5',
  background: '#FAFAFA',
  gold: '#FBBF24',         // Pro badge only
  text: '#1F1F1F',
};

// packages/assets/src/fonts.ts
export const fonts = {
  display: 'Playfair Display',
  body: 'Inter',
};
```

## Example: App Store Preview Scene

```tsx
// videos/prosepal-appstore/src/scenes/HeroScene.tsx
import { AbsoluteFill, useCurrentFrame, interpolate } from 'remotion';
import { FadeIn, TextReveal } from '@launchpad/shared';
import { prosepal } from '@launchpad/assets';

export const HeroScene: React.FC = () => {
  const frame = useCurrentFrame();
  
  return (
    <AbsoluteFill style={{ backgroundColor: prosepal.background }}>
      <FadeIn>
        <TextReveal 
          text="The right words, right now"
          style={{ color: prosepal.primary }}
        />
      </FadeIn>
      
      {/* Phone mockup with screen recording */}
      <PhoneMockup 
        video="src/assets/demo-recording.mp4"
        enterFrame={30}
      />
    </AbsoluteFill>
  );
};
```

## AI-Assisted Workflow

Install Remotion skills for Claude Code:

```bash
npx skills add remotion-dev/skills
```

Then describe scenes naturally:

> "Create an intro scene with the Prosepal logo fading in, 
> then word-by-word reveal of 'The right words, right now' 
> in purple on white background"

## Rendering Options

```bash
# Local render (MP4)
pnpm render

# Specific composition
pnpm --filter @launchpad/prosepal-appstore render

# Different formats
npx remotion render src/index.ts Main out.mp4 --codec=h264
npx remotion render src/index.ts Main out.webm --codec=vp8
npx remotion render src/index.ts Main out.gif

# App Store specs (iOS)
# 1080x1920 (9:16) for iPhone
# 1200x1600 (3:4) for iPad
```

## Video Specs Reference

### App Store Preview (iOS)
| Device | Resolution | Duration |
|--------|------------|----------|
| iPhone 6.7" | 1290x2796 | 15-30s |
| iPhone 6.5" | 1242x2688 | 15-30s |
| iPad Pro 12.9" | 2048x2732 | 15-30s |

### Social Media
| Platform | Resolution | Duration |
|----------|------------|----------|
| TikTok/Reels | 1080x1920 | 15-60s |
| YouTube Shorts | 1080x1920 | <60s |
| Twitter/X | 1280x720 | <140s |
| LinkedIn | 1920x1080 | <10min |

## Recommended Workflow

1. **Plan scenes** - Storyboard key moments
2. **Record app footage** - Screen record on device/simulator
3. **Create components** - Build reusable scene templates
4. **Compose video** - Arrange scenes in sequence
5. **Add polish** - Transitions, text, sound effects
6. **Render & review** - Export, watch, iterate
7. **Export variants** - Different aspect ratios/lengths

## Cost

- **Launchpad:** Free (MIT license)
- **Remotion:** Free for personal/open-source, $15/month for commercial
- **Rendering:** Local = free, cloud = pay-per-render

## When to Use

**Good fit:**
- Multiple videos with consistent branding
- Frequent updates/iterations
- Team collaboration on video content
- Version control requirements

**Maybe not:**
- One-off simple video
- Complex motion graphics (After Effects better)
- Live action footage editing

## Resources

- [Launchpad GitHub](https://github.com/trycua/launchpad)
- [Remotion Docs](https://remotion.dev/docs)
- [Remotion Skills](https://github.com/remotion-dev/skills)
- [App Store Preview Guidelines](https://developer.apple.com/app-store/app-previews/)

---

## Future Ideas

- [ ] Create `prosepal-appstore` video project
- [ ] Build reusable phone mockup component
- [ ] Create social media templates (TikTok, Reels)
- [ ] Add Prosepal brand assets to shared package
- [ ] Create "How to write a birthday message" tutorial video
