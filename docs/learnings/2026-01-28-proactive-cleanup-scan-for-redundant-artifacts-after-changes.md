---
date: 2026-01-28
tags: [refactoring, code-hygiene, technical-debt, testing, cleanup, codebase-maintenance]
workflow: [refactoring, code-simplification, test-driven-development]
consolidated-from:
  - 2026-01-27-remove-dead-code-in-same-commit-as-refactoring.md
  - 2026-01-27-proactive-identification-of-redundant-test-files-after-mocking-conversion.md
---

# Proactive Cleanup: Scan for Redundant Artifacts After Changes

## Problem Pattern

Not scanning for redundant artifacts after making changes:

1. **After refactoring** - Refactored `buildPrompts()` to use inline logic, but left `getCalendarInstructions()` and `getPrepGenerationPrompt()` exported but unused → required separate cleanup commits
2. **After test conversion** - Converted integration tests to unit tests with mocks, but didn't scan for manual test files → user had to ask "or check if we still need this?" about `todoist/test.js`

## Root Cause

Making changes without immediately checking for now-redundant artifacts. Not asking "what else became obsolete?"

## Core Principle: Change → Scan → Clean → Commit

After making changes that might obsolete other code:

1. **Make the primary change** (refactor, test conversion, etc.)
2. **Scan for redundant artifacts** (grep, find commands)
3. **Clean up in the SAME commit** (don't defer)
4. **Document what was removed** (commit message)

**Don't create separate "cleanup" commits** - that's a sign you should have checked earlier.

---

## Pattern 1: Dead Code After Refactoring

### Problem Example

Refactored `buildPrompts()` to compose inline instead of calling helpers:
- `getCalendarInstructions()` exported but never called
- `getPrepGenerationPrompt()` exported but never called
- Left in codebase, removed in separate commit later

### Solution: Grep for Dead Code Immediately

**Step 1: Identify Potentially Dead Code**

After these changes, check for orphans:
- Extracting inline logic → old helper function unused
- Changing data structure → old accessor methods unused
- Replacing library → old wrapper functions unused
- Consolidating APIs → old endpoints unused

**Step 2: Verify Function is Dead**

```bash
# Check for function calls (not just definition/export)
grep -rn "functionName(" packages/ --include="*.js" \
  | grep -v "function functionName" \
  | grep -v "export.*functionName" \
  | grep -v ".aws-sam" \
  | grep -v ".next"

# If no results → safe to remove
```

**Step 3: Remove in Same Commit**

```bash
# Remove function definition
# Remove from exports
git add .
git commit -m "refactor: [main change] + removed unused [functionName]"
```

**Example commit message:**

```
refactor: inline prompt composition logic

- buildPrompts() now composes prompts inline
- Removed getCalendarInstructions() (no longer used)
- Removed getPrepGenerationPrompt() (no longer used)
```

### Refactoring Triggers That Create Dead Code

- Inlining helper functions
- Replacing abstraction layers
- Consolidating duplicate logic
- Changing data access patterns
- Upgrading libraries (old wrappers)

### Red Flags

- Function is exported but `grep` finds no callers
- Function exists only for "convenience" but nothing uses it
- Comment says "legacy" or "deprecated"
- Test coverage shows function never executed

---

## Pattern 2: Redundant Test Files After Conversion

### Problem Example

User converted integration tests to unit tests with mocks (`stateManager.schedules.test.js`). Later had to explicitly ask about `todoist/test.js` manual test file.

AI should have proactively scanned for and flagged other manual/integration test files.

### Solution: Scan for Related Test Artifacts

**After converting tests to mocks, scan for:**

```bash
# Find manual test scripts
find packages -name "test-*.js" -not -path "*/__tests__/*" -not -path "*/.aws-sam/*"

# Find manual test files
find packages -name "test.js" -o -name "manual-test.js" | grep -v "__tests__"

# Look for integration test helpers
grep -r "integration" --include="*test*.js"

# Find demonstration scripts from initial implementation
find packages -name "*demo*.js" -o -name "*example*.js"
```

**Present findings to user:**

```markdown
I converted the integration tests to mocks. I also found these related test files:

- packages/lambda/src/scripts/test-processor-mocked.js (manual script)
- packages/lambda/src/functions/outputs/todoist/test.js (manual demo)
- packages/lambda/src/integration-test-helpers.js (integration helpers)

Should we review these for cleanup? Some might be:
- Redundant (now covered by mocked tests)
- Still useful (different test scenarios)
- Documentation (keep as examples)
```

### Test Conversion Triggers

When converting integration tests to unit tests with mocks, check for:
- Manual test scripts (node scripts/test-*.js)
- Integration test helpers
- Demonstration scripts from initial implementation
- Old manual test files (test.js, manual-test.js)
- Integration fixtures that are now unused

---

## Prevention Checklist

### After Refactoring

- [ ] Grep for all calls to functions you changed
- [ ] Check if any became orphans (exported but never called)
- [ ] Remove dead functions in same commit
- [ ] Update module.exports
- [ ] Run tests to ensure nothing broke
- [ ] Commit with clear message about removal

### After Test Conversion

- [ ] Find manual test scripts (`find packages -name "test-*.js"`)
- [ ] Find manual test files not in `__tests__/`
- [ ] Look for integration test helpers (`grep "integration"`)
- [ ] Present findings to user for review decision
- [ ] Document which files were kept and why

### General Pattern

After ANY significant change:
- [ ] Ask "What else might have become obsolete?"
- [ ] Run grep/find commands to scan for candidates
- [ ] Present findings (don't just delete without asking)
- [ ] Clean up in same commit if confirmed

## Cleanup Commands Reference

### Dead Code Detection

```bash
# Find all calls to a function
grep -rn "functionName(" packages/ --include="*.js" \
  | grep -v "function\|export\|.aws-sam\|.next"

# Search for unused exports
grep -rn "export.*functionName" packages/ --include="*.js"
grep -rn "functionName(" packages/ --include="*.js"
# Compare outputs - if second is empty, export is unused

# Find deprecated markers
grep -rn "@deprecated\|legacy\|obsolete" packages/ --include="*.js"
```

### Redundant Test File Detection

```bash
# Manual test scripts
find packages -type f -name "test-*.js" \
  -not -path "*/__tests__/*" \
  -not -path "*/.aws-sam/*" \
  -not -path "*/node_modules/*"

# Manual test files (not in test directories)
find packages -type f \( -name "test.js" -o -name "manual-test.js" \) \
  | grep -v "__tests__\|node_modules"

# Integration test markers
grep -rn "integration\|e2e\|manual" --include="*test*.js" packages/

# Demo/example files
find packages -type f \( -name "*demo*.js" -o -name "*example*.js" \)
```

### Module Export Analysis

```bash
# List all exports in a file
grep "module.exports\|export " file.js

# For each export, verify it's used
for func in $(grep "export.*function" file.js | awk '{print $3}'); do
  echo "Checking $func..."
  grep -rn "$func(" packages/ | grep -v "function $func\|export"
done
```

## Common Mistakes

❌ **"I'll clean it up later"**
- Never happens, accumulates debt

❌ **"Someone might use it"**
- If no one uses it now, remove it. Git history preserves it if needed.

❌ **"It's just one function"**
- Death by a thousand cuts. Many "just one" functions = cluttered codebase.

✅ **"Refactor = change + cleanup"**
- Both in one commit

## Success Criteria

**After refactoring:**
- ✅ Grep for old function names returns zero callers
- ✅ Module exports only actively-used functions
- ✅ No comments saying "deprecated" or "legacy"
- ✅ Tests verify all exported functions are covered
- ✅ API surface is minimal (principle of least exposure)

**After test conversion:**
- ✅ All redundant test files identified
- ✅ User made informed decision (keep/remove)
- ✅ Kept files documented with justification
- ✅ Removed files documented in commit message

## Examples from Sessions

### Example 1: Dead Code After Refactoring

**Bad:**
```
Refactored buildPrompts() to inline logic.

(Later, separate commit)
Removed unused getCalendarInstructions().
```

**Good:**
```bash
# Immediately after refactoring
grep -rn "getCalendarInstructions(" packages/ | grep -v "function\|export"
# Result: empty → function is dead

git add .
git commit -m "refactor: inline calendar instructions composition

buildPrompts() now appends output schema inline.
Removed getCalendarInstructions() (no longer used)."
```

### Example 2: Redundant Tests After Conversion

**Bad:**
```
Converted integration tests to mocks.

(User later asks: "or check if we still need this?")
```

**Good:**
```bash
# Immediately after conversion
find packages -name "test-*.js" -not -path "*/__tests__/*"

# Output:
# packages/lambda/src/scripts/test-processor-mocked.js
# packages/lambda/src/functions/outputs/todoist/test.js

# Present to user:
"I converted the integration tests to mocks. Found these manual test files:
- test-processor-mocked.js (mocked manual script)
- todoist/test.js (manual demo)

Should we review these for cleanup?"
```

## Related Patterns

- **Code hygiene:** Keep API surface minimal
- **Boy Scout Rule:** Leave code cleaner than you found it
- **Refactoring:** Always includes cleanup, not just restructuring
- **Technical debt:** Unused code is debt that accrues interest

## Related Skills

- `code-simplification` - Should include artifact cleanup
- `refactoring` - Should include dead code detection
- `test-driven-development` - Should scan for redundant tests after conversion

## Implementation Note

This learning consolidates two cleanup patterns:
1. **After refactoring:** Grep for dead code, remove in same commit
2. **After test conversion:** Scan for manual test files, present for review

Both stem from the same principle: **proactive cleanup prevents debt accumulation**. Changes that obsolete other code should trigger immediate scanning and cleanup, not deferred "TODO: cleanup" tasks.
