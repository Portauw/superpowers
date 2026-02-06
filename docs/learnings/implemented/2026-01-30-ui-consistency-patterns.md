# UI Consistency Patterns Across Similar Elements

**Date:** 2026-01-30
**Category:** general-workflow
**Related Skills:** brainstorming, frontend-design

## Context

While implementing AI-driven event filtering, added "Event Filter" textarea field. Initial implementation lacked character limits (maxLength + counter) that were present in similar "AI Instructions" textarea field.

Required follow-up commit to add 5000 character limit with counter for consistency.

## Investigation

**Inconsistency found:**
- AI Instructions field: 5000 char limit with counter
- Event Filter field: No character limit, no counter
- Both fields: Same purpose (user input for AI), same component type (textarea)

**Why it was missed:**
- Implementation plan didn't specify consistency requirements
- No systematic check for similar UI elements during design
- Focused on functional requirements, not UX consistency

## Root Cause

No systematic audit for UI consistency patterns during design phase. When adding UI elements similar to existing ones, agents don't automatically check for:
- Form field validation patterns (char limits, format validation)
- Visual feedback consistency (character counters, error messages)
- Styling patterns (spacing, sizing, color scheme)
- Accessibility patterns (labels, ARIA attributes)
- Help text patterns (descriptions, examples)

## Solution

Enhanced `brainstorming` skill with "UI Consistency Audit" section:

### Pattern Detection Workflow
1. Identify existing similar elements
2. Document their patterns (e.g., "All textarea fields have 5000 char limit + counter")
3. Apply same patterns to new element
4. Verify in design review

### Checklist
- Form field validation (character limits, format, required fields)
- Visual feedback (counters, error messages, success states)
- Accessibility (labels, ARIA, keyboard navigation)
- Styling (spacing, sizing, colors)
- Help text (descriptions, examples, tooltips)

### Examples
- Textarea fields (AI Instructions, Event Filter, Custom Prompt)
- Date/time pickers (Schedule start time, Active hours)
- File upload fields (Drive file picker, local file upload)
- Toggle switches (Enable/disable features)

## Impact

- Catches UI consistency issues during design phase (before implementation)
- Prevents fragmented user experience from inconsistent patterns
- Reduces follow-up commits to fix missing validation/feedback
- Improves overall UX quality across features

## Tags

#ui-consistency #design-patterns #user-experience #form-validation
