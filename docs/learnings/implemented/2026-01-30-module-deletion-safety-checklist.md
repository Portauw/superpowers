# Module Deletion Safety Checklist

**Date:** 2026-01-30
**Category:** general-workflow
**Related Skills:** safe-refactoring

## Context

While implementing AI-driven event filtering, removed `eventFilter.js` module. Initial deletion missed a reference in `test-modules.js` (utility script), causing a broken import.

Required follow-up commit to remove the missed reference.

## Investigation

**What was missed:**
- Test utility scripts (test-modules.js)
- Focus was on main source and test files
- Utility scripts in scripts/ directory not checked

**Why it was missed:**
- No systematic search performed before deletion
- Relied on "obvious" imports only
- Didn't check all locations (scripts, docs, configs)

**Similar past issues:**
- Cross-package imports in monorepos
- Documentation examples with outdated imports
- Config files referencing deleted modules

## Root Cause

No systematic checklist for module deletion. Agents rely on intuition about where imports might be, missing non-obvious locations like:
- Utility scripts (scripts/, tools/, bin/)
- Test scaffolding (test-modules.js, test helpers)
- Documentation examples
- Config files (package.json, tsconfig paths)
- Monorepo cross-package imports

## Solution

Created new `safe-refactoring` skill with comprehensive Module Deletion Checklist:

### Before Deletion
1. Search entire codebase for module name (all import styles)
2. Check specific locations:
   - Main source code (src/, lib/)
   - Test files (__tests__/, *.test.js, *.spec.js)
   - **Utility scripts** (scripts/, tools/, bin/)
   - **Documentation examples** (docs/, README.md, CLAUDE.md)
   - **Config files** (package.json, tsconfig.json)
   - **Monorepo packages** (all packages/, not just current)

### During Deletion
3. Delete in order: usages → exports → file

### After Deletion
4. Verify no broken references with grep
5. Run tests to confirm nothing breaks

## Verification

Tested skill with realistic scenario: deleting eventFilter.js. Skill guidance successfully identified all locations including test-modules.js that was originally missed.

## Impact

- Prevents broken references from incomplete deletion
- Systematic approach catches non-obvious import locations
- Reduces follow-up commits to fix missed references
- Applies to renaming operations (same search pattern)

## Tags

#refactoring #code-safety #module-deletion #systematic-workflow
