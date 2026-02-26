---
description: Architecture planning and design session
argument-hint: [feature or problem]
---

# /plan - Architecture Planning

**CRITICAL INSTRUCTIONS - READ FIRST:**
- Do NOT use the EnterPlanMode tool
- Do NOT save anything to ~/.claude/plans/
- Do NOT create any files
- Output ALL plans directly in this conversation as markdown

Start a planning session for feature design or architectural decisions.

**Rules:**
- DO NOT write or modify code
- OUTPUT directly in the chat response
- DO explore the codebase to understand context
- DO design solutions with trade-offs
- DO specify files, patterns, and approaches
- LEAVE implementation to the builder session

## Usage
```
/plan user authentication
/plan offline support
/plan refactor payment flow
```

## Planning Mindset

When planning, consider:

### 1. Requirements Gathering
- What problem are we solving?
- Who is affected?
- What are the constraints?
- What's out of scope?

### 2. Technical Analysis
- What existing code/patterns apply?
- What services are involved?
- What are the dependencies?
- What could go wrong?

### 3. Design Options
Present 2-3 approaches with trade-offs:

| Option | Pros | Cons |
|--------|------|------|
| A: ... | ... | ... |
| B: ... | ... | ... |

### 4. Recommendation
- Which option and why
- Implementation phases
- Risk mitigation

### 5. Deliverables
- File changes needed
- New files to create
- Tests to write
- Docs to update

## Output Format

```markdown
## Planning: [Feature Name]

### Problem
[What we're solving]

### Constraints
- [Constraint 1]
- [Constraint 2]

### Options Considered
1. **Option A**: [Description]
   - ✅ Pro: ...
   - ❌ Con: ...

2. **Option B**: [Description]
   - ✅ Pro: ...
   - ❌ Con: ...

### Recommendation
[Option X] because [reasoning]

### Implementation Plan
1. [ ] Step 1
2. [ ] Step 2
3. [ ] Step 3

### Files Affected
- `lib/core/services/...`
- `lib/features/...`
```

## When to Use This

- Before starting a new feature
- When refactoring complex code
- When multiple approaches exist
- When changes affect multiple systems
