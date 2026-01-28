---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch superpowers:code-reviewer subagent to catch issues before they cascade.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## Before Requesting Review

**Self-Review Checklist:** Run these checks BEFORE requesting external review to catch common issues:

### 1. Code Simplification (Optional)

**Consider:** Use `superpowers:code-simplification` first if substantial changes (5+ files or 100+ lines). Cleaner code = faster, more focused review.

### 2. Proactive Cleanup

**After refactoring, scan for dead code:**

```bash
# Check if refactored functions are still called
grep -rn "functionName(" packages/ --include="*.js" \
  | grep -v "function functionName" \
  | grep -v "export.*functionName" \
  | grep -v ".aws-sam" \
  | grep -v ".next"

# If output is empty → function is dead → remove it
```

**After converting tests to mocks, scan for redundant test files:**

```bash
# Find manual test scripts
find packages -name "test-*.js" -not -path "*/__tests__/*" -not -path "*/.aws-sam/*"

# Find manual test files
find packages -name "test.js" -o -name "manual-test.js" | grep -v "__tests__"

# Look for integration test helpers
grep -r "integration" --include="*test*.js" packages/
```

**If found, present to user:** "I found these related test files: [list]. Should we review these for cleanup?"

**Pattern:** Remove dead code/redundant files in the SAME commit as the refactoring, not separate cleanup commits.

### 3. Validation Architecture Check

**For API endpoints with user input, verify validation is present:**

**Input Validation Checklist:**
- [ ] Length limits (text: 50k chars, file content: 100k chars)
- [ ] Format validation (regex patterns for IDs, emails, etc.)
- [ ] Type checking (string, number, boolean)
- [ ] Required fields validation

**Validation Placement Check:**

If validation failure would corrupt persistent state, validate BEFORE persistence:

```typescript
// ✅ Good: Validate BEFORE MongoDB update
const validation = validateInput(data);
if (!validation.valid) {
  return NextResponse.json({ error: validation.errors[0] }, { status: 400 });
}
await updateDatabase(data);

// ❌ Bad: MongoDB updated, then Lambda rejects
await updateDatabase(data);  // ✅ Saved
await lambda.invoke(data);   // ❌ Throws error
// Result: Invalid state in MongoDB
```

**Questions to ask:**
- Does this API accept user input?
- Is validation present for all input fields?
- If validation fails downstream, would MongoDB contain invalid state?
- If yes → move validation BEFORE persistence

### 4. Red Flags

**If you find any of these, fix BEFORE requesting review:**
- ❌ Functions exported but never called (grep finds no callers)
- ❌ Manual test files after converting to mocks (test-*.js, test.js)
- ❌ API endpoint with no input validation (length, format, type)
- ❌ Validation happens AFTER MongoDB write (corruption risk)
- ❌ Comments saying "TODO: cleanup" or "deprecated"

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code-reviewer subagent:**

Use Task tool with superpowers:code-reviewer type, fill template at `code-reviewer.md`

**Placeholders:**
- `{WHAT_WAS_IMPLEMENTED}` - What you just built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{DESCRIPTION}` - Brief summary

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch superpowers:code-reviewer subagent]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**
- Review after each batch (3 tasks)
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: requesting-code-review/code-reviewer.md
