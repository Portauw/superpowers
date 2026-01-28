---
date: 2026-01-28
tags: [architecture, planning, brainstorming, mental-models, feature-interactions, scope-expansion]
workflow: [brainstorming, writing-plans]
consolidated-from:
  - 2026-01-27-clarify-mental-models-with-diagrams-before-architecture.md
  - 2026-01-27-map-feature-interactions-before-implementation.md
  - 2026-01-27-audit-artifacts-when-expanding-feature-scope.md
---

# Thorough Upfront Analysis: Mental Models, Interactions, Scope Impact

## Problem Pattern

Jumping to implementation without thorough upfront analysis:

1. **Missing mental model alignment** - Proposed architecture options based on my interpretation instead of understanding user's conceptual model first → multiple clarifications needed
2. **Unanalyzed feature interactions** - Added user context prompts without analyzing how they interact with existing schedule prompts → architectural bug requiring refactoring
3. **Unaudited scope expansion** - Expanded from "meeting preparation" to "any event preparation" but didn't rename artifacts → code review flagged `meeting_preparation_prompt` needing rename across 6 files

## Root Cause

Skipping upfront analysis and jumping directly to technical solutions. Not asking "how does this fit with what exists?" before implementing.

## Core Principle: Thorough Upfront Analysis

Before implementing ANY feature, perform three types of analysis:

1. **Mental Model Discovery** - Understand user's conceptual model BEFORE proposing solutions
2. **Feature Interaction Mapping** - Create matrix of all config combinations when features intersect
3. **Scope Impact Audit** - When expanding scope, grep for artifacts that need updating

---

## Pattern 1: Mental Model Discovery

### Problem Example

User had clear vision:
- System instructions = system.md + context + calendarInstructions
- First user message = schedule prompt

But I proposed options based on my interpretation, leading to:
- Multiple clarifying questions
- Back-and-forth to align understanding
- Implementation that initially mismatched user's intent

### Solution: Ask for Mental Model FIRST

**Step 1: Discovery Questions**

Before proposing any architecture, ask:

```markdown
Before I propose solutions, let me understand your mental model:

**For prompt/config architecture:**
- What's immutable vs configurable?
- What takes precedence when both are set?
- Do these compose or replace each other?
- Who can change each piece (user, admin, system)?

**For data flow:**
- Where does each piece come from?
- In what order are they processed?
- What happens if one is missing?

**For user expectations:**
- What should happen if user sets both X and Y?
- Should this be automatic or explicit?
- What's the default behavior?
```

**Step 2: Draw Diagram Showing User's Model**

```
System Prompt (to API):
┌─────────────────────────────────────┐
│ [system.md - base behavior]         │
│ [user context - domain knowledge]   │
│ [output schema - format rules]      │
└─────────────────────────────────────┘

User Messages (to API):
┌─────────────────────────────────────┐
│ Message 1: [schedule prompt - task]│
│ Message 2: [calendar instructions] │
│ Message 3: [events JSON]           │
└─────────────────────────────────────┘
```

**Step 3: Get Explicit Sign-Off**

"Does this match your vision? Any corrections?"

**Step 4: THEN Propose Implementation**

Only after conceptual alignment, propose technical solutions.

### When to Apply

**Red flags indicating model misalignment:**
- User asks "wait, where does X come from?"
- Multiple options proposed, none feel right to user
- User says "no, that's not what I meant"
- Back-and-forth clarifications
- Implementation gets rewritten after review

**Always apply when:**
- Designing architecture for new feature
- User describes vision using their own terminology
- Multiple valid interpretations exist
- Feature touches existing complex system

---

## Pattern 2: Feature Interaction Mapping

### Problem Example

Added user context prompts without analyzing interaction with existing schedule prompts:
- Schedule `systemPrompt` could override entire system prompt
- User context would be silently wiped out
- Architectural bug caught in code review

### Solution: Create Interaction Matrix

**Step 1: Identify Intersecting Configs**

When adding feature X that touches existing config Y:
- User prompts (new) + Schedule prompts (existing)
- Active hours (new) + Sync intervals (existing)
- Per-user settings (new) + Global defaults (existing)

**Step 2: Enumerate All Combinations**

Create matrix of all possible states:

```markdown
             | No Schedule Prompt | Schedule Prompt
-------------|-------------------|------------------
No Context   | ?                 | ?
User Context | ?                 | ?
```

**Step 3: Define Behavior for Each Cell**

For EACH combination, decide:
- What happens?
- What takes precedence?
- What's the user expectation?

**Don't guess** - explicitly define or ask user.

**Example filled in:**

```markdown
             | No Schedule Prompt       | Schedule Prompt
-------------|--------------------------|---------------------------
No Context   | Use system defaults      | Schedule defines task
User Context | Context + default task   | Context + schedule task (composed)

**Key:** User context is ALWAYS included (never overridden).
Schedule prompt defines the task instruction (user message, not system override).
```

**Step 4: Check for Conflicts**

Look for cells where behavior is unclear or conflicts with other cells:
- "X overrides Y" vs "Y overrides X" - which is correct?
- Does order matter?
- Are there circular dependencies?

**Step 5: Document in Architecture**

Add interaction matrix to design doc or CLAUDE.md:

```markdown
## Config Interaction: User Context + Schedule Prompts

| User Context | Schedule Prompt | Behavior |
|--------------|----------------|----------|
| None         | None           | Use system defaults |
| None         | Custom         | Schedule defines task |
| Custom       | None           | Context + default task |
| Custom       | Custom         | Context + schedule task (composed) |

**Key:** User context is ALWAYS included (never overridden).
```

### When to Apply

**Red flags indicating feature interaction:**
- Adding config that affects same component (prompts, schedules, filters)
- User-level config + Schedule-level config
- New feature has "priority" or "override" semantics
- Existing code has conditional logic based on config presence

**Examples requiring interaction matrices:**
- Adding user timezone + Schedule has timezone → which wins?
- Adding file upload limits + Existing size validation → which applies?
- Adding custom templates + Default templates → merge or replace?

---

## Pattern 3: Scope Expansion Audit

### Problem Example

Feature expanded from "meeting preparation" to "any event preparation", but:
- Field name `meeting_preparation_prompt` remained meeting-specific
- Required renaming across 6 files
- Schema descriptions still mentioned "meetings"
- Examples only showed meeting scenarios

### Solution: Audit ALL Artifacts

**When scope expands (specific → general), audit:**

### 1. Field Names
```bash
# Search for overly specific names
grep -rn "meeting_" packages/ --include="*.js"
grep -rn "client_" packages/ --include="*.js"
```

**Change:**
- `meeting_preparation_prompt` → `preparation_prompt`
- `client_meeting_notes` → `event_notes`
- `employee_schedule` → `user_schedule`

### 2. Schema Descriptions
```markdown
# Before (too specific)
Generate a JSON response where the `meeting_preparation_prompt` field
contains a prompt for another AI to prepare for the meeting.

# After (generic)
Generate a JSON response where the `preparation_prompt` field contains
instructions for preparing for the calendar event.
```

### 3. Documentation Examples
```markdown
# Before (only meeting examples)
Example: "1 on 1 with Jim", "Client meeting about project X"

# After (diverse examples)
Example: "1 on 1 with Jim", "Grocery shopping", "Gym workout", "Team meeting"
```

### 4. Code Comments
```javascript
// Before
/**
 * Generate meeting preparation content
 */

// After
/**
 * Generate event preparation content (works for meetings, errands, etc.)
 */
```

### 5. Test Cases
```javascript
// Before (only meeting scenarios)
it('should prepare for client meeting', ...)

// After (edge cases)
it('should prepare for client meeting', ...)
it('should prepare for shopping trip', ...)
it('should prepare for workout session', ...)
```

### 6. Variable Names
```javascript
// Before
const meetingsList = events.filter(...)

// After
const eventsList = events.filter(...)
```

### Scope Expansion Checklist

- [ ] **Field names** in schemas/types (grep for old term)
- [ ] **Schema descriptions** mentioning specific use case
- [ ] **Documentation examples** (too narrow?)
- [ ] **Code comments** referencing old scope
- [ ] **Test case names** (only old use case tested?)
- [ ] **Variable names** in implementation
- [ ] **Function names** (too specific?)
- [ ] **Error messages** mentioning old scope

### When to Apply

**Scope expansion scenarios:**
- Meeting-specific → Event-agnostic
- Client-specific → User-agnostic
- Single-tenant → Multi-tenant
- US-only → International
- Desktop → Cross-platform

**Red flags:**
- New feature supports broader use cases than naming suggests
- Documentation examples don't cover new use cases
- Field names contain domain-specific terms
- Tests only cover original narrow scope

---

## Prevention Checklist

Before implementing new features:

### Mental Model Discovery
- [ ] Ask user to describe their mental model
- [ ] Draw diagram showing "what goes where"
- [ ] Label each component (immutable? configurable? by whom?)
- [ ] Show data flow / composition order
- [ ] Get explicit "yes, that's exactly right" before coding

### Feature Interaction Mapping
- [ ] List all related existing configs
- [ ] Create interaction matrix (all combinations)
- [ ] Define behavior for each cell
- [ ] Check for conflicts/ambiguities
- [ ] Document in design doc
- [ ] Get user sign-off on interaction semantics

### Scope Expansion Audit
- [ ] Identify scope change ("meetings-only" → "event-agnostic")
- [ ] Grep for overly-specific terminology
- [ ] Update field names, schemas, examples, tests
- [ ] Create before/after checklist
- [ ] Assign as explicit task in plan

## Success Criteria

**Mental Model Alignment:**
- ✅ User says "yes, exactly right"
- ✅ No further clarifying questions
- ✅ Implementation matches expectations first try
- ✅ Code review has no "wait, this should be..." comments

**Feature Interactions:**
- ✅ All config combinations documented
- ✅ No "what happens if both are set?" questions
- ✅ No architectural bugs from unanalyzed interactions

**Scope Expansion:**
- ✅ Grep for old term returns no code references
- ✅ Schema descriptions are generic
- ✅ Examples cover full breadth of new scope
- ✅ Tests verify edge cases of broader scope

## Related Skills

- `brainstorming` - Should include these analysis phases
- `writing-plans` - Plans should document interaction matrices
- `code-review` - Check for scope mismatches and unaudited interactions

## Implementation Note

This learning consolidates three analysis types that should happen BEFORE implementation:
1. **Understand** user's mental model (don't assume)
2. **Map** feature interactions (don't implement in isolation)
3. **Audit** scope impact (don't leave old terminology)

All three prevent expensive rework by catching issues during planning instead of code review.
