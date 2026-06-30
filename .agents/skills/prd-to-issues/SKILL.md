---
name: prd-to-issues
description: "When the user wants to break down a product requirement, feature spec, or PRD into actionable issues. Also use when the user mentions 'break this down,' 'create issues,' 'task breakdown,' 'feature spec to tasks,' 'implementation plan,' or 'work breakdown.'"
metadata:
  version: "1.0"
  origin: mattpocock-adapted
---

# PRD to Issues

You are an expert at breaking down product requirements into well-structured, implementable issues. Your goal is to create a clear, ordered backlog that a developer can pick up and execute.

## Process

### 1. Understand the Requirement
- Read the full PRD/spec/feature description
- Identify the core user value
- List assumptions and open questions
- Note dependencies on existing systems

### 2. Decompose into Issues
Each issue should be:
- **Independently deliverable** — Can be merged without other issues
- **Testable** — Clear definition of done with test criteria
- **Small** — Completable in 1-3 hours of focused work
- **Ordered** — Dependencies flow top-to-bottom

### 3. Issue Template

```markdown
## Title: [Verb] [Thing] [Context]

### Description
[1-2 sentences: what and why]

### Acceptance Criteria
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
- [ ] Tests are added/updated for changed behavior

### Technical Notes
- [Key files to modify]
- [Patterns to follow]
- [Edge cases to handle]

### Dependencies
- Blocked by: #[issue] (if any)
```

### 4. Issue Categories
- **Setup/Infra** — New files, providers, dependencies
- **Core Logic** — Services, models, business rules
- **UI** — Screens, widgets, navigation
- **Integration** — API calls, auth, payments
- **Testing** — Unit, widget, integration tests
- **Polish** — Error handling, loading states, edge cases

## Output Format

Present the breakdown as an ordered list:

| # | Title | Category | Est. | Dependencies |
|---|-------|----------|------|-------------|
| 1 | Set up FooProvider | Setup | 30m | None |
| 2 | Implement FooService | Core Logic | 1h | #1 |
| 3 | Build FooScreen | UI | 2h | #2 |

Then provide the full issue body for each.

## Prosepal Context

### Issue Tracking
- **Platform:** GitHub Issues (not Linear, Jira, or other tools)
- **Backlog:** All open work tracked in `docs/BACKLOG.md` — new issues should reference or update this file
- **Labels:** Use P0 (launch blocker), P1 (important), P2 (lower priority)

### Architecture Patterns
- **State:** Riverpod 3.x providers — new features need providers in `lib/app/providers.dart` or feature-local
- **Navigation:** go_router — new screens need routes in `lib/app/router.dart`
- **Services:** Abstract + implementation pattern — `lib/core/services/`
- **Models:** Freezed for immutable models — run `dart run build_runner build --delete-conflicting-outputs` after changes

### Definition of Done (Every Issue)
- `flutter analyze` passes
- `flutter test` passes
- Tests are added/updated for changed behavior
- `docs/BACKLOG.md` updated if applicable

### Common Decomposition Patterns for Prosepal
- **New occasion type:** Model update → AI prompt update → UI selector update → tests
- **New AI feature:** ai_service.dart update → provider update → UI integration → tests
- **Payment change:** subscription_service.dart → paywall UI → entitlement checks → tests
