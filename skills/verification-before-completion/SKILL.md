---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## Evidence Before Assertions

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

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. INVESTIGATE: Before interpreting failures/errors:
   - Don't trust error messages at face value (symptoms ≠ root cause)
   - Verify error claims (e.g., "file not found" - check if exists elsewhere)
   - Check paths, permissions, environment before categorizing
5. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
6. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Verification Types and Commands

### File System / Worktree Verification

When using worktrees, check BOTH locations:

```bash
# Check worktree location
ls /path/to/.worktrees/feature-name/target/directory/

# Check main directory
ls /path/to/main-project/target/directory/

# Report findings
if [ worktree has files ]; then
  echo "✅ Implementation in worktree (expected)"
elif [ main has files ]; then
  echo "⚠️  Implementation in main directory (unexpected but present)"
else
  echo "❌ No implementation found"
fi
```

**Don't assume agents follow path instructions - verify with evidence.**

### Infrastructure Verification (AWS, Cloud Services)

Don't trust deployment messages alone - verify actual state:

```bash
# Lambda verification
aws lambda get-function --function-name [name]        # Does it exist?
aws lambda invoke --function-name [name] --payload {} # Does it work?
aws logs tail /aws/lambda/[name]                      # Are logs showing success?

# IAM permissions verification
aws iam get-role-policy --role-name [role] --policy-name [policy]

# EventBridge schedules verification
aws scheduler get-schedule --name [name]  # Actually created?

# Test actual invocation with real payload
aws lambda invoke \
  --function-name [name] \
  --payload '{"action":"GET","userId":"test@example.com"}' \
  response.json
cat response.json  # Show actual response
```

**Evidence required:**
- ✅ Resource exists (not assumed from CloudFormation status)
- ✅ Resource responds to real invocations (not mocked)
- ✅ IAM permissions exist on correct role (not guessed from docs)
- ✅ Logs show actual operations (not inferred)

### Build Verification (TypeScript, Compiled Languages)

**For TypeScript/Next.js/compiled projects**, always run local build before pushing:

```bash
# TypeScript/Next.js projects
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

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

### Optional: Self-Reflection

```
✅ Verification complete!

Reflect on this session and capture learnings? (optional)

1. Yes - use ai-self-reflection
2. No - skip
```

If yes: Invoke ai-self-reflection skill.

Note: You can also manually trigger retrospection later with `/retrospective` command.

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
