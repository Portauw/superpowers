---
date: 2026-01-28
tags:
  - typescript
  - build-verification
  - ci-cd
  - deployment
workflow:
  - finishing-a-development-branch
  - verification-before-completion
---

# Always run local build before pushing TypeScript changes to catch type errors pre-CI

## Problem

After fixing multi-schedule bugs and pushing to master, AWS Amplify build failed with TypeScript errors:
- Missing uuid type definitions (ESM browser build without types)
- Wrong parameter count for `authorizeUserAccess(userId, { adminOnly: false })` - function only takes 1 param
- Missing type assertion for `createSchedule()` return value

Required 3 additional fix commits to resolve build errors that could have been caught locally.

## Solution

Run `pnpm build` locally in the admin-ui package before pushing:

```bash
cd packages/admin-ui
pnpm build
```

This runs TypeScript compilation and catches:
- Type errors
- Missing type definitions
- Parameter count mismatches
- Return type issues

Only push after seeing `✓ Compiled successfully`.

**In this session:**
- Local build revealed all 3 TypeScript errors
- Fixed them before final push
- Amplify build succeeded on first try after verification

## Prevention

**Update finishing-a-development-branch skill:**

Add mandatory build verification step before Step 2 (Verify Tests):

```
Step 1.5: Verify Build (TypeScript projects only)

For TypeScript/Next.js projects, run build:
  cd packages/admin-ui && pnpm build

If build fails:
  - Fix TypeScript errors
  - Commit fixes
  - Re-run build
  - Only proceed when build succeeds

If build passes:
  ✓ TypeScript compilation successful
  Continue to Step 2
```

**Key principle:** Local verification catches 90% of CI/CD failures before they waste deployment time.
