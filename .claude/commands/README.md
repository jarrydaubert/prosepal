# Custom Commands

> Slash commands for Project Nexus. Invoke with `/command-name` in Claude Code.

## Available Commands

| Command | Expert Role | Purpose | Writes Code? |
|---------|-------------|---------|--------------|
| `/plan [feature]` | Architect | Design and planning sessions | No - advises |
| `/audit [target]` | Architecture Reviewer | Deep code/system analysis | No - advises |
| `/security [scope]` | Security Architect | Vulnerability review, OWASP checklist | No - advises |
| `/test [scope]` | Test Engineer | Coverage gaps, write/review tests | **Yes - writes tests** |
| `/debug [issue]` | Debugger | Systematic issue investigation | **Yes - fixes bugs** |
| `/pr [base]` | Release Engineer | Generate pull request | No - generates PR |
| `/pre-launch [app]` | Release Manager | Store submission readiness | No - checklist |
| `/new-app [name]` | Project Scaffolder | Create app from blueprint | **Yes - scaffolds** |
| `/marketing [task]` | Growth Marketer | Content generation, ASO, analytics | No - generates content |
| `/web [task]` | Web Developer | Landing pages, SEO, performance | **Yes - writes HTML/CSS** |

**Analysis roles** (`/plan`, `/audit`, `/security`) advise only. Take their recommendations to a **builder session** for implementation.

**Marketing role** (`/marketing`) generates content for external channels (TikTok, Pinterest, blog, ads). See `docs/MARKETING.md` Section 13 for the full AI execution playbook.

## Usage Examples

```bash
# Deep audit of auth system
/audit auth

# Security review of entire app
/security

# Find untested code paths
/test coverage

# Write tests for a service
/test usage_service

# Verify ready for App Store
/pre-launch prosepal

# Start a new app
/new-app captionpal

# Generate week's TikTok scripts
/marketing tiktok

# Write SEO blog post
/marketing blog sympathy card

# Analyze App Store metrics
/marketing analyze

# Full landing page audit
/web audit

# Add new section to landing page
/web section testimonials

# Fix mobile layout issues
/web responsive
```

## How Commands Work

1. **One-shot, not persistent** - Command applies to that request only
2. **Conversation continues context** - Follow-ups stay in that frame
3. **CLAUDE.md always applies** - Base persona is always active

## Adding New Commands

Create a new `.md` file in this folder:

```markdown
# /command-name - Short Description

What this command does.

## Usage
/command-name [args]

## Checklist or Instructions
- [ ] Item 1
- [ ] Item 2
```

The filename (minus `.md`) becomes the command name.

## Multi-Session Workflow

Run parallel Claude Code sessions like a dev team. Each session = one role.

### Recommended Setup (7 Sessions)

```
Tab 1: /plan        → Architect (design, decisions)
Tab 2: [implement]  → Builder (write code)
Tab 3: /test        → Test Engineer (coverage, quality)
Tab 4: /security    → Security (vulnerabilities)
Tab 5: /debug       → Debugger (issues as they arise)
Tab 6: /marketing   → Growth (content, ASO, analytics)
Tab 7: /web         → Web Developer (landing pages, SEO)
```

### Session Naming

Use `/rename` to label sessions:
```
/rename auth-feature
/rename payment-refactor
/rename security-audit
```

### Workflow Patterns

**Feature Development:**
1. Tab 1: `/plan user-auth` → Design the approach
2. Tab 2: Implement based on plan
3. Tab 3: `/test auth_service` → Write tests
4. Tab 4: `/security auth` → Check for vulnerabilities
5. Tab 2: `/pr` → Create pull request

**Bug Investigation:**
1. Tab 5: `/debug payment stuck` → Investigate
2. Tab 2: Implement fix
3. Tab 3: `/test` → Add regression test
4. Tab 2: `/pr` → Ship it

**Code Review:**
1. Tab 1: `/audit payments` → Deep review
2. Tab 4: `/security payments` → Security review
3. Tab 3: `/test coverage` → Check test gaps

**Weekly Marketing:**
1. Tab 6: `/marketing tiktok` → Generate week's video scripts
2. Tab 6: `/marketing pinterest` → Generate pin concepts
3. Tab 6: `/marketing analyze` → Review last week's metrics

**Launch Prep:**
1. Tab 5: `/pre-launch prosepal` → Store readiness check
2. Tab 6: `/marketing launch` → Product Hunt assets
3. Tab 6: `/marketing twitter` → Launch announcement thread

**Landing Page Update:**
1. Tab 7: `/web audit` → Full page review
2. Tab 7: `/web section pricing` → Add new section
3. Tab 7: `/web seo` → Optimize for search
4. Tab 6: `/marketing` → Generate copy for new section

### Tips

- Start each session with the relevant command to set context
- Use `/continue` to resume named sessions later
- All sessions share the same CLAUDE.md context
- Each session maintains its own conversation history

## Command Ideas (Not Yet Created)

| Command | Purpose | Inspiration |
|---------|---------|-------------|
| `/perf` | Performance analysis, profiling | - |
| `/a11y` | Accessibility audit | - |
| `/docs` | Documentation review/generation | - |
| `/refactor [target]` | Guided refactoring | - |
| `/changelog` | Generate release notes from commits | awesome-claude-skills |
| `/iterate` | ship-learn-next style feedback loops | awesome-claude-skills |
| `/competitors` | Deep competitive analysis | awesome-claude-skills |
