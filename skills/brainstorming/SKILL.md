---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## Thorough Upfront Analysis (Before Implementation)

Before jumping to solutions, perform three types of analysis:

### 1. Mental Model Discovery

**Don't assume - ask for the user's conceptual model FIRST:**

**Discovery Questions:**
```
Before I propose solutions, let me understand your mental model:

For prompt/config architecture:
- What's immutable vs configurable?
- What takes precedence when both are set?
- Do these compose or replace each other?
- Who can change each piece (user, admin, system)?

For data flow:
- Where does each piece come from?
- In what order are they processed?
- What happens if one is missing?

For user expectations:
- What should happen if user sets both X and Y?
- Should this be automatic or explicit?
- What's the default behavior?
```

**Then draw a diagram showing user's model:**
```
System Prompt:
┌─────────────────────────────────────┐
│ [component A - source/role]         │
│ [component B - source/role]         │
│ [component C - source/role]         │
└─────────────────────────────────────┘

Data Flow:
Component A → Component B → Component C
```

**Get explicit sign-off:** "Does this match your vision? Any corrections?"

**THEN propose implementation** - only after conceptual alignment.

### 2. Feature Interaction Mapping

**When adding feature X that touches existing config Y, create interaction matrix:**

**Step 1: Identify intersecting configs**
- User prompts (new) + Schedule prompts (existing)
- Active hours (new) + Sync intervals (existing)
- Per-user settings (new) + Global defaults (existing)

**Step 2: Enumerate all combinations**
```
             | No Existing Feature | Existing Feature Enabled
-------------|---------------------|-------------------------
New Off      | ?                   | ?
New On       | ?                   | ?
```

**Step 3: Define behavior for EACH cell**
- What happens?
- What takes precedence?
- What's the user expectation?

**Example filled in:**
```
             | No Schedule Prompt       | Schedule Prompt
-------------|--------------------------|---------------------------
No Context   | Use system defaults      | Schedule defines task
User Context | Context + default task   | Context + schedule (composed)

Key: User context is ALWAYS included (never overridden)
```

**Step 4: Document in design**

### 3. Scope Expansion Audit

**When scope expands (specific → general), audit ALL artifacts:**

**Checklist:**
- [ ] **Field names:** `grep -rn "meeting_" packages/` → rename to generic
- [ ] **Schema descriptions:** "for the meeting" → "for the event"
- [ ] **Documentation examples:** Add non-meeting examples
- [ ] **Code comments:** Update to reflect broader scope
- [ ] **Test cases:** Cover edge cases of broader scope
- [ ] **Variable names:** meetingsList → eventsList

**Examples of scope expansion:**
- Meeting-specific → Event-agnostic
- Client-specific → User-agnostic
- Single-tenant → Multi-tenant
- US-only → International

**Red flags:**
- New feature supports broader use cases than naming suggests
- Documentation examples don't cover new use cases
- Field names contain domain-specific terms
- Tests only cover original narrow scope

### 4. UI Consistency Audit

**When adding UI elements similar to existing ones, audit for consistency:**

**Checklist:**
- [ ] **Form field validation:** Character limits, format validation, required fields
- [ ] **Visual feedback:** Character counters, error messages, success states
- [ ] **Accessibility:** Labels, ARIA attributes, keyboard navigation
- [ ] **Styling:** Spacing, sizing, color scheme matches similar fields
- [ ] **Help text:** Descriptions, examples, tooltips

**Examples of similar UI elements:**
- Textarea fields (AI Instructions, Event Filter, Custom Prompt)
- Date/time pickers (Schedule start time, Active hours)
- File upload fields (Drive file picker, local file upload)
- Toggle switches (Enable/disable features)

**Pattern detection:**
1. Identify existing similar elements
2. Document their patterns (e.g., "All textarea fields have 5000 char limit + counter")
3. Apply same patterns to new element
4. Verify in design review

**Red flags:**
- New textarea lacks character limit when others have it
- New form field missing validation that others have
- Inconsistent styling or spacing
- Missing help text when similar fields explain usage

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git

**Implementation (if continuing):**
- Ask: "Ready to create the implementation plan?"
- Use superpowers:writing-plans to create detailed implementation plan

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Libraries should pull their weight** - Do look for library options but they should pull their weight, lets avoid heavy libraries for very simple solutions but also lets not re-invent the wheel. Example would be to convert markdown format to plain text. Look for very lightweight libraries that can perform this. Always offer the option of library when applicable. The decision needs be made by the user.
