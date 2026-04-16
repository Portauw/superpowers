---
name: code-simplification
description: Use after completing feature implementation when code works but could be cleaner - optional quality step before code review that dispatches code-simplifier agent to refine recently modified files
---

# Code Simplification

**Optional quality step** - refine working code before review.

**Requires:** `code-simplifier` plugin (fail gracefully if not installed)

## When to Use

- After implementation complete, tests passing
- Before code review or verification
- When diff is substantial (5+ files or 100+ lines changed)
- User says "clean this up" or "simplify"

**Skip if:**
- Trivial changes (1-2 files, < 50 lines)
- User wants to ship immediately
- Code is legacy/untested (risky to refactor)

## Workflow

```
1. CHECK: Is code-simplifier plugin available?
   └─ NO → Inform user, suggest manual review, EXIT
   └─ YES → Continue

2. DETECT SCOPE: What files changed?
   └─ Run: git diff --name-only origin/main (or base branch)
   └─ Count files and estimate lines changed

3. EVALUATE: Is simplification worthwhile?
   └─ < 3 files, < 50 lines → Skip, too trivial
   └─ >= 5 files OR >= 100 lines → Recommend
   └─ Between → Offer as option

4. DISPATCH: Launch code-simplifier agent
   └─ Use Task tool with subagent_type="code-simplifier:code-simplifier"
   └─ Prompt: Focus on recently modified files from git diff

5. VERIFY: Check results
   └─ Run tests to confirm functionality preserved
   └─ Review changes before accepting
```

## Checking Plugin Availability

**Before dispatching code-simplifier, verify the plugin is installed:**

```
IF dispatching code-simplifier agent fails with:
   - "Unknown subagent type"
   - "code-simplifier not found"
   - Similar error

THEN gracefully inform user:
   "The code-simplifier plugin is not installed. You can:
   1. Install it via: /plugin install <plugin-name>
   2. Skip this step and proceed to verification
   3. Manually review code for simplification opportunities"

DO NOT fail silently or retry repeatedly.
```

## Scope Detection

```bash
# Files changed from base branch
git diff --name-only origin/main

# Lines changed (rough estimate)
git diff --stat origin/main | tail -1
```

**Auto-recommend when:**
- 5+ files modified
- 100+ lines changed
- Complex logic visible in diff (nested conditionals, long functions)

**Offer as option when:**
- 3-4 files modified
- 50-100 lines changed

**Skip when:**
- 1-2 files modified
- < 50 lines changed
- User explicitly declines

## What Gets Simplified

The code-simplifier agent focuses on:
- Long functions → smaller, focused functions
- Nested conditionals → early returns, guard clauses
- Duplicate code → extracted helpers
- Unclear names → descriptive names
- Inconsistent patterns → unified approach

**Preserves:** All functionality, tests, behavior

## Post-Implementation Quality Loop

When user requests a full quality pass (e.g., "simplify, review, fix, loop"), follow this sequence:

```
1. /simplify     → reduce complexity, remove verbosity
2. /review       → find correctness, security, and logic issues → fix them
3. Dead code     → remove unused exports, bloat tests, unreachable branches
4. Simplify loop → repeat simplify+fix for N iterations (default: 2)
```

**Iteration guidance:**
- **2 iterations** for routine features — iteration 1 catches real issues, iteration 2 confirms clean
- **3 iterations** for security-sensitive code (auth, credential handling, network, process spawning)
- **Stop early** when an iteration finds no meaningful changes — don't force it
- Diminishing returns are steep: iteration 1 is high-value, iteration 2 moderate, iteration 3 rarely finds new issues

**Why this order matters:**
- Simplifying first reduces surface area for the reviewer
- Review on cleaner code produces genuine logic/security findings, not style complaints
- Dead code audit after review catches test bloat introduced during fix cycles

**Subagent dispatch:** Each step can be dispatched as a separate subagent. Pass the full file list and "make no changes unless they improve the code" instruction to prevent churn.

## Integration Points

**After these skills, suggest code-simplification:**
- `executing-plans` (if substantial changes)
- `subagent-driven-development` (if substantial changes)

**After code-simplification, continue to:**
- `requesting-code-review` (if review desired)
- `verification-before-completion` (if skipping review)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Simplify before tests pass | Fix tests first, then simplify |
| Simplify legacy code | Too risky without tests, skip |
| Force simplification on trivial changes | Skip if < 50 lines |
| Retry failing plugin repeatedly | Fail gracefully after first error |
| Simplify without re-running tests | Always verify after changes |
