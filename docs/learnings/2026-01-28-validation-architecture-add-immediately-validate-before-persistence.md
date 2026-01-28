---
date: 2026-01-28
tags: [validation, api, security, clean-architecture, state-consistency, infrastructure-constraints]
workflow: [code-review, api-design, architectural-refactoring]
consolidated-from:
  - 2026-01-27-validate-user-input-immediately-not-in-code-review.md
  - 2026-01-26-infrastructure-constraints-validation-before-persistence.md
---

# Validation Architecture: Add Immediately, Validate Before Persistence

## Problem Pattern

Two related validation failures:

1. **Missing validation during implementation** - Implemented API endpoint for user context without length/format validation, flagged as "Critical Issues" in code review requiring fix commit
2. **Wrong validation placement** - Almost moved "active hours interval compatibility" constraint from API to Lambda layer, which would have allowed invalid state in MongoDB

## Root Cause

1. Not adding validation during initial implementation (deferring to code review)
2. Not considering state consistency implications when deciding validation placement

## Core Principles

### Principle 1: Add Validation Immediately (Not in Code Review)

**For EVERY user input field, add validation during implementation, not after:**

```typescript
// PATCH /api/users/[userId]/config/prompts

// Length limits - prevent DoS, storage bloat
if (body.context.text && body.context.text.length > 50000) {
  return NextResponse.json(
    { error: 'Context text exceeds 50,000 character limit' },
    { status: 400 }
  );
}

// Format validation - prevent bad data, unnecessary API calls
if (driveFileId && !/^[a-zA-Z0-9_-]+$/.test(driveFileId)) {
  return NextResponse.json(
    { error: 'Invalid Drive file ID format' },
    { status: 400 }
  );
}
```

**Validation checklist for user input:**
- [ ] **Length limits** - Prevent DoS, storage bloat (text: 50k, file content: 100k)
- [ ] **Format validation** - Prevent bad data, unnecessary API calls (regex patterns)
- [ ] **Business rules** - Domain-specific constraints
- [ ] **Type checking** - Ensure correct types (string, number, boolean)

**Red flag:** If you write `body.fieldName` without first checking length/format/type, you're missing validation.

### Principle 2: Validate Before Persistence (State Consistency)

**The Critical Question:** "If validation fails AFTER the primary data store write, what state is left behind?"

**Example of wrong placement:**

```
❌ Bad Flow (State Corruption Risk):
Request → API (no validation) → MongoDB UPDATE ✅ → Lambda REJECTS ❌

Result: Invalid config stored in MongoDB, EventBridge schedule never created

Flow:
1. User submits invalid config (120-min interval + active hours)
2. API passes input validation (format checks only)
3. MongoDB accepts and persists the configuration
4. Lambda attempts to create EventBridge schedule
5. Lambda throws: 'Active hours not supported for intervals > 60 minutes'
6. MongoDB still contains invalid state
7. Every subsequent sync attempt fails silently
```

**Correct placement:**

```
✅ Good Flow (State Consistency):
Request → API VALIDATES → REJECTS ❌

Result: MongoDB never sees invalid state, user gets immediate feedback

Flow:
1. User submits invalid config (120-min interval + active hours)
2. API validates infrastructure constraint
3. API returns 400: 'Active hours not supported for intervals > 60 minutes'
4. MongoDB is never updated
5. User corrects config and resubmits
```

## Refined Validation Taxonomy

Where validation lives depends on **consistency requirements**, not **constraint origin**.

### Validation Types and Placement

| Validation Type | Layer | Timing | Example |
|----------------|-------|--------|---------|
| **Input Validation** | API | Immediately | Email format, required fields, type checks |
| **Infrastructure Constraints** | API (before persistence) | Before primary data store write | "intervals >60 can't use cron" (AWS limitation) |
| **Business Rules** | Service/Domain | Before domain operations | "Can't delete own account", uniqueness checks |
| **Client Validation** | NEVER (for internal data) | N/A | ❌ Re-validating already-validated data |

### The Critical Distinction

An **infrastructure constraint** (like AWS EventBridge limitations) may need to live in the **API layer** if:
- Its failure would corrupt the primary data store
- Downstream systems cannot self-heal
- Invalid state would persist indefinitely

This is **different** from a business rule, but has the **same placement requirement** due to consistency needs.

## Implementation Patterns

### Pattern 1: Input Validation (API Layer)

**During implementation planning, for each user input field ask:**

1. **What's the worst case input?**
   - Empty string? Null? Undefined?
   - Maximum length? (1MB text?)
   - Invalid format? (special characters in ID?)
   - Malicious input? (SQL injection, XSS, etc.)

2. **Add validation as explicit task step:**
   ```markdown
   Task: Implement PATCH /api/users/[userId]/config/prompts

   Step 1: Add validation
     - Text length: max 50k chars
     - Drive file ID: alphanumeric + dash/underscore only
     - Required fields: userId

   Step 2: Implement feature logic
     - Fetch Drive file if provided
     - Update MongoDB
   ```

3. **Validate at the boundary:** API routes are the system boundary - validate there, not in services

### Pattern 2: Infrastructure Constraint Validation (Before Persistence)

**Before moving validation, draw the complete data flow:**

```
1. Draw complete flow including ALL persistence points
2. Identify "point of no return" (primary data store write)
3. Ask: "If validation fails AFTER this point, what state is left behind?"
   - Clean state → Current location acceptable
   - Corrupted state → Validate earlier
4. Read existing tests for timing expectations (look for "BEFORE" in test names)
```

**Example code with correct placement:**

```typescript
// route.ts (API layer)
function validateActiveHoursInterval(schedule: {
  intervalMinutes?: number;
  activeHours?: { enabled?: boolean };
}): ValidationResult {
  const errors: string[] = [];

  // IMPORTANT: Must validate BEFORE MongoDB update to prevent inconsistent state
  if (schedule.activeHours?.enabled && schedule.intervalMinutes > 60) {
    errors.push(
      'Active hours are not supported for intervals > 60 minutes. ' +
      'Please use 5, 15, 30, or 60 minute intervals.'
    );
  }

  return buildValidationResult(errors);
}

// In PUT handler, BEFORE MongoDB update:
const intervalValidation = validateActiveHoursInterval({ intervalMinutes, activeHours });
if (!intervalValidation.valid) {
  return NextResponse.json(
    { error: intervalValidation.errors?.[0] },
    { status: 400 }
  );
}

// Only after validation passes:
await updateUserConfig(userId, updates);
```

**Test documenting timing requirement:**

```typescript
test('returns 400 for active hours with interval > 60min BEFORE MongoDB update', async () => {
  // ...
  // CRITICAL: Verify MongoDB was never updated
  expect(updateUserConfig).not.toHaveBeenCalled();
});
```

## Code Review Checklist for Validation Placement

Before moving or implementing validation:

- [ ] Does this validation move leave any invalid state in persistence?
- [ ] Are downstream systems best-effort or critical path?
- [ ] Is the primary data store the source of truth?
- [ ] What happens to user experience if validation fails at the new location?
- [ ] Are there tests encoding timing requirements?

## Understanding "Trust Internal Data"

**Correct interpretation:**
- API validates → Service trusts it → Client trusts it
- No re-validation of already-validated data flowing through the system

**Incorrect interpretation:**
- ❌ "Skip validation and let downstream catch it"
- ❌ "Move all validation to domain layer for architectural purity"
- ❌ "Persist first, validate later"

**The boundary:**
"Trust Internal Data" means don't re-validate. It does NOT mean skip validation and risk persisting bad state.

## Risk if Missed

**Missing validation during implementation:**
- Caught in code review (extra commit, review round)
- Potential production issue if not caught
- User confusion (bad data accepted)

**Wrong validation placement:**
- **Silent data corruption** - Invalid configurations saved that will never work
- **Repeated failures** - Every operation attempt fails at runtime
- **User confusion** - UI shows success but nothing happens
- **Poor observability** - Errors only visible in infrastructure logs
- **Manual cleanup required** - Database fixes needed to restore consistency

## Prevention

**During implementation:**

1. **Add validation as first step in API routes**
   - Before feature logic
   - At the system boundary
   - Return 400 with clear error messages

2. **For infrastructure constraints, validate before persistence**
   - Draw complete data flow
   - Identify point of no return
   - Place validation before that point

3. **Document validation decisions**
   - Why this placement?
   - What's the consistency requirement?
   - Add comments explaining timing

## Success Criteria

- ✅ All user input has validation (length, format, type)
- ✅ Validation happens during implementation, not discovered in review
- ✅ Infrastructure constraints validated before persistence
- ✅ No invalid state can persist in primary data store
- ✅ Tests verify validation timing (especially for state consistency)

## Related Concepts

- Clean Architecture validation layering
- State consistency in distributed systems
- Best-effort vs critical-path operations
- Source of truth in system design
- Infrastructure constraints vs business rules
- Fail fast principle

## Implementation Note

This learning consolidates two validation patterns:
1. **Timing:** Add validation during implementation, not after (prevents review cycles)
2. **Placement:** Validate before persistence if downstream failure would corrupt state (prevents data corruption)

Both stem from the same root: **validation is architecture**, not afterthought. Plan it upfront.
