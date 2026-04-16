---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. **Check for parallel execution signals:**
   - Look for handoff documents (EXECUTION_SESSION.md, README.md in worktree)
   - Keywords: "parallel execution", "independent tasks", "can run simultaneously"
   - If found AND tasks have no dependencies: Use `dispatching-parallel-agents` instead
5. If no parallel signals or dependencies exist: Create TodoWrite and proceed with sequential execution

### Step 2: Execute Batch (Sequential)
**Default: First 3 tasks**

**Architectural compliance:** If `architectural-principles.md` exists, use `clean-software-design` to verify implementation against architectural principles and clean code standards.

**Boy scout rule:** While editing files, use superpowers:boyscout to make small improvements to surrounding code you touch.

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Post-Implementation Quality Loop

After all tasks complete and tests pass, run iterative refinement:

```
1. /simplify     → reduce complexity, remove verbosity
2. /review       → find correctness, security, and logic issues → fix them
3. Dead code     → remove unused exports, bloat tests, unreachable branches
4. Simplify loop → repeat simplify+fix for N iterations (default: 2)
```

**Iteration guidance:**
- **2 iterations** for routine features — iteration 1 catches real issues, iteration 2 confirms clean
- **3 iterations** for security-sensitive code (auth, credentials, network, process spawning)
- **Stop early** when an iteration finds no meaningful changes
- Simplify first, then review — reviewer finds logic/security bugs, not style complaints

**Subagent dispatch:** Each step can be a separate subagent. Pass full file list and "make no changes unless they improve the code" to prevent churn.

### Step 6: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
