---
name: safe-refactoring
description: Use when deleting or renaming modules, files, functions, or moving code between files to ensure all references are found and updated
---

# Safe Refactoring

## Overview

Systematic approach to deletion and renaming operations that ensures no broken references remain.

**Core principle:** Search comprehensively BEFORE deleting, verify thoroughly AFTER deleting.

## Module Deletion Checklist

### Before Deletion

**1. Find ALL imports (not just obvious ones):**
```bash
# Search entire codebase for module name
grep -r "moduleName" . --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist

# Check different import styles
grep -r "require.*moduleName" .
grep -r "from.*moduleName" .
grep -r "import.*moduleName" .
```

**2. Check these locations specifically:**
- ✅ Main source code (src/, lib/)
- ✅ Test files (__tests__/, *.test.js, *.spec.js)
- ✅ Utility scripts (scripts/, tools/, bin/)
- ✅ Documentation examples (docs/, README.md, CLAUDE.md)
- ✅ Config files (package.json, tsconfig.json, jest.config.js)
- ✅ Monorepo packages (all packages/, not just current one)

**3. Identify export locations:**
```bash
# Find where module is exported
grep -r "export.*moduleName" .
grep -r "module.exports.*moduleName" .
```

### During Deletion

**4. Delete in order:**
1. Remove imports/usages first
2. Remove exports second
3. Delete file last

**Why:** Prevents intermediate broken states.

### After Deletion

**5. Verify no broken references:**
```bash
# Search for any remaining references
grep -r "moduleName" . --exclude-dir=node_modules --exclude-dir=.git

# Expected: Only docs/plans (historical) or changelog mentions
```

**6. Run tests:**
```bash
# Verify nothing breaks
npm test  # or appropriate test command
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| **Only check main source** | Check test scripts, utility scripts, docs |
| **Skip grep verification** | Always grep after deletion to catch missed references |
| **Delete file first** | Delete usages → exports → file (prevents broken intermediate state) |
| **Assume IDE refactor caught everything** | IDE doesn't know about string-based requires or dynamic imports |
| **Skip cross-package search in monorepos** | Search ALL packages, not just current one |

## File Renaming

Same checklist applies - search for old name, update all references, verify with grep.

**Prefer git mv for tracking:**
```bash
git mv old-name.js new-name.js
# Then update all imports
```

## Quick Reference

```bash
# Comprehensive search (before deletion)
grep -r "moduleName" . --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist

# Verify clean (after deletion)
grep -r "moduleName" . --exclude-dir=node_modules --exclude-dir=.git
# Should only show: docs/plans, CHANGELOG, git history

# Run tests
npm test  # or pnpm test, cargo test, go test, pytest
```

## Red Flags

- Skipping grep before deletion
- Not checking test/script directories
- Only searching current package in monorepo
- Assuming "it compiles" means it's safe
- Deleting file before removing all usages

**All of these mean: Stop and follow the checklist.**
