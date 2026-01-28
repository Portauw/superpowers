---
date: 2026-01-28
tags: [verification, evidence, testing, build-verification, infrastructure]
workflow: [verification-before-completion, finishing-a-development-branch, systematic-debugging]
consolidated-from:
  - 2026-01-19-worktree-verification-and-test-infrastructure.md
  - 2026-01-23-running-actual-aws-cli-commands-to-verify-infrastructure-state.md
  - 2026-01-28-always-run-local-build-before-pushing-typescript-changes-to-catch-type-errors-pre-ci.md
---

# Evidence Before Assertions: Always Verify with Concrete Commands

## Problem Pattern

Declaring success based on assumptions rather than concrete evidence:

1. **Assuming agent worked in worktree** - Checked only worktree location, declared "implementation failed", but files were actually in main directory
2. **Trusting deployment messages** - Could have relied on "SAM deploy succeeded" instead of verifying Lambda actually works
3. **Pushing without local build** - Pushed TypeScript changes without running `pnpm build`, CI failed with type errors requiring 3 fix commits

## Root Cause

Making assertions ("implementation complete", "deployed successfully", "ready to push") based on indirect evidence or assumptions instead of running actual verification commands.

## Core Principle: Evidence Before Assertions

**Never declare success based on:**
- ❌ Assumptions ("agent should have worked in worktree")
- ❌ Indirect evidence ("SAM deployment succeeded" → Lambda must work)
- ❌ Intention ("I wrote the fix" → tests must pass)
- ❌ Documentation ("design says it should work")

**Always verify with:**
- ✅ Actual commands that show real state
- ✅ Command output as concrete proof
- ✅ Checks in ALL relevant locations
- ✅ Tests that actually run, not theoretical coverage

## Verification Patterns by Category

### 1. File System / Worktree Verification

**Problem:** Assumed agent worked in expected location.

**Solution:** Check BOTH locations when using worktrees:

```bash
# After agent completes work
git status --short
git branch --show-current

# Check worktree location
ls /path/to/.worktrees/feature-name/target/directory/

# Check main directory
ls /path/to/main-project/target/directory/

# Report what you found
if [ worktree has files ]; then
  echo "✅ Implementation in worktree (expected)"
elif [ main has files ]; then
  echo "⚠️  Implementation in main directory (unexpected but present)"
else
  echo "❌ No implementation found"
fi
```

**Don't assume agents follow path instructions - verify with evidence.**

### 2. Infrastructure Verification (AWS, Cloud Services)

**Problem:** Trusted "deployment succeeded" message without verifying actual state.

**Solution:** Run actual CLI commands to verify infrastructure:

```bash
# Don't trust deployment logs alone
aws lambda get-function --function-name [name]        # Does it exist?
aws lambda invoke --function-name [name] --payload {} # Does it work?
aws logs tail /aws/lambda/[name]                      # Are logs showing success?

# Verify IAM permissions exist
aws iam get-role-policy --role-name [role] --policy-name [policy]

# Check EventBridge schedules
aws scheduler get-schedule --name [name]  # Actually created?

# Test actual invocation with real payload
aws lambda invoke \
  --function-name [name] \
  --payload '{"action":"GET","userId":"test@example.com"}' \
  response.json
cat response.json  # Show actual response
```

**Evidence collected:**
- ✅ Lambda deployed (not assumed from CloudFormation status)
- ✅ Lambda responds to real invocations (not mocked)
- ✅ IAM permissions exist on correct role (not guessed from docs)
- ✅ Logs show actual operations (not inferred)

### 3. Build Verification (TypeScript, Compiled Languages)

**Problem:** Pushed TypeScript changes without local build, CI failed with type errors.

**Solution:** Always run local build before pushing:

```bash
# For TypeScript/Next.js projects
cd packages/admin-ui
pnpm build

# Wait for successful output
# ✓ Compiled successfully

# Only push after seeing success
```

**Common build errors caught locally:**
- Missing type definitions
- Wrong parameter counts
- Return type mismatches
- Import errors
- ESM/CJS compatibility issues

**Pattern:** If you have a build step, run it locally BEFORE pushing. Never discover build errors in CI.

### 4. Test Verification

**Problem:** Assumed tests would pass based on code inspection.

**Solution:** Run actual test suite:

```bash
# Run full test suite
pnpm test

# Check exit code
echo $?  # Should be 0

# Run specific test files if needed
pnpm test path/to/test.js

# Verify coverage if applicable
pnpm test:coverage
```

**Don't assume tests pass - run them and show the output.**

### 5. Integration Testing After Architectural Changes

**Problem:** Test infrastructure out of sync with new architecture.

**Solution:** After changing patterns (e.g., system-wide → per-user credentials):

1. **Identify affected test infrastructure:**
   ```bash
   grep -r "mockUserConfig\|test.*user\|mock.*credentials" packages/*/src/scripts/
   ```

2. **Update test fixtures to match new patterns**
3. **Run tests to verify:**
   ```bash
   pnpm test
   # Should exit 0
   ```

## Prevention Checklist

Before declaring "complete" or "deployed" or "ready to push":

### File System Changes
- [ ] Check all relevant locations (worktree AND main directory if applicable)
- [ ] Run `git status` to see what actually changed
- [ ] List files in target directory to confirm presence

### Infrastructure Deployment
- [ ] Run actual get/describe commands to verify resources exist
- [ ] Test actual invocation with realistic payload
- [ ] Check logs for recent successful operations
- [ ] Verify IAM permissions/roles exist (don't assume from docs)

### TypeScript/Build Projects
- [ ] Run `pnpm build` (or equivalent) locally
- [ ] Wait for "✓ Compiled successfully"
- [ ] Only push after local build succeeds

### Tests
- [ ] Run full test suite
- [ ] Show test output with pass/fail counts
- [ ] Exit code 0 required before claiming "tests pass"
- [ ] Update test infrastructure after architectural changes

## Examples from Sessions

### Example 1: Worktree Verification

**Bad:**
```
I checked .worktrees/chat-interface/ and found no files.
Implementation failed.
```

**Good:**
```bash
# Check worktree
ls .worktrees/chat-interface/packages/admin-ui/app/chats
# Output: (empty)

# Check main directory
ls packages/admin-ui/app/chats
# Output: page.tsx, ChatList.tsx, etc.

# Conclusion
✅ Implementation found in main directory (agent didn't use worktree,
but files exist and are correct)
```

### Example 2: Infrastructure Verification

**Bad:**
```
SAM deployment succeeded. Lambda is deployed and working.
```

**Good:**
```bash
# Verify Lambda exists
aws lambda get-function --function-name calendar-prep-schedule-manager
# Output: State: Active, LastUpdateStatus: Successful

# Test actual invocation
aws lambda invoke \
  --function-name calendar-prep-schedule-manager \
  --payload '{"action":"GET","userId":"test@example.com"}' \
  response.json
# Output: StatusCode: 200

cat response.json
# Output: {"scheduleId":"...","config":{...}}

✅ Lambda verified with actual invocation - returns expected data
```

### Example 3: Build Verification

**Bad:**
```
Fixed the type errors. Ready to push.
```

**Good:**
```bash
cd packages/admin-ui
pnpm build
# Output:
#   ✓ Compiled successfully
#   ✓ Collecting page data
#   ✓ Generating static pages
#   ✓ Finalizing page optimization

✅ Local build successful - safe to push
```

## Success Criteria

- ✅ Never declare "complete" without showing command output
- ✅ Check all relevant locations (both worktree and main if applicable)
- ✅ Run actual verification commands, not just assume based on deployment messages
- ✅ Local build passes before pushing to CI
- ✅ Tests actually run and pass, not theoretical
- ✅ Infrastructure verified with get/invoke/describe commands

## Related Skills

- `verification-before-completion` - Should require evidence for all verification steps
- `finishing-a-development-branch` - Build verification before pushing
- `systematic-debugging` - Verify fixes actually work with concrete tests

## Implementation Note

This learning consolidates three related patterns: **evidence before assertions**. Whether verifying file locations, infrastructure state, or build success, the pattern is the same: run actual commands, show concrete output, never assume. This prevents false positives and catches issues before they reach CI/production.
