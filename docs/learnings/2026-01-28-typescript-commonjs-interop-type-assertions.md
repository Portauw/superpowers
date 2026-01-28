---
date: 2026-01-28
type: repeated-error
source: ai-detected
confidence: high
category: general-workflow
tags: [typescript, commonjs, type-assertions, javascript-interop]
project: calendar-prep-mvp
---

# TypeScript/CommonJS interop requires explicit type assertions for nested properties

## What Happened

Encountered 2 TypeScript compilation errors in the same API route file when calling JavaScript CommonJS modules from TypeScript:
1. `Property 'name' does not exist on type 'Object'` when accessing `schedule.name` after `createSchedule()` call
2. `Expected 1 arguments, but got 2` when calling `authorizeUserAccess(userId, { adminOnly: false })`

Both errors occurred in `packages/admin-ui/app/api/operations/triggers/schedule/[scheduleId]/route.ts` when calling functions from `packages/shared/src/services/stateManager.js`.

## AI Assumption

Assumed TypeScript could:
1. Infer return object structure from JavaScript CommonJS `module.exports`
2. Function signatures included option objects based on naming patterns

## Reality

- TypeScript cannot infer nested property types from dynamic JavaScript exports even when the module returns a well-defined object structure
- JavaScript modules must be checked for actual function signatures - don't assume option objects exist based on conventions

## Lesson

**Before calling JavaScript CommonJS modules from TypeScript:**
1. Verify the actual function signature in the JS module (parameter count, types)
2. Use explicit type assertions when accessing nested properties on return values:
   ```typescript
   const result = await jsFunction(params) as { expectedProperty: string };
   ```

**Prevention checklist:**
- Read the JS module implementation before calling from TS
- Count parameters in function definition
- Check what the function actually returns (object shape)
- Add type assertion immediately after calling JS function if accessing nested properties

## Context

**Codebase pattern:** Calendar Prep MVP uses:
- CommonJS JavaScript modules in `packages/shared/src/` (services, clients)
- TypeScript in `packages/admin-ui/app/api/` (Next.js API routes)
- Frequent calls from TS routes → JS shared modules

**Error locations:**
- `packages/admin-ui/app/api/operations/triggers/schedule/[scheduleId]/route.ts`
- Calling: `stateManager.createSchedule()`, `stateManager.authorizeUserAccess()`

**Fixes applied:**
```typescript
// Fix 1: Type assertion for nested property access
const schedule = await createSchedule(scheduleData) as { scheduleId: string };

// Fix 2: Removed extra parameter (function only accepts 1 param)
await authorizeUserAccess(userId); // Not authorizeUserAccess(userId, options)
```

## Suggested Action

**For general-workflow learnings:** This pattern applies broadly to any project mixing TypeScript and JavaScript CommonJS modules. Consider:

1. **Adding to TypeScript best practices skill** (if one exists)
2. **Creating a TS/JS interop checklist** for code-review skill
3. **Adding to verification-before-completion** - TypeScript build should catch these before deployment

**Example prevention pattern:**
```markdown
## TypeScript/JavaScript Interop Checklist

When calling JavaScript CommonJS modules from TypeScript:

- [ ] Read JS module implementation to verify function signature
- [ ] Count parameters (don't assume option objects exist)
- [ ] Check return value structure
- [ ] Add type assertion if accessing nested properties: `as { prop: type }`
- [ ] Run TypeScript build locally before committing
```

This could be added to brainstorming, writing-plans, or code-review skills where TS/JS interop is common.
