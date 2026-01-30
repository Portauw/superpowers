---
date: 2026-01-28
tags: [workflow-discipline, skills, workflow-chains, proactive-suggestions]
workflow: [using-superpowers, all-skills]
consolidated-from:
  - 2026-01-15-proactively-suggest-next-skills-after-workflows.md
  - 2026-01-19-tailwind-preflight-button-cursor-and-workflow-discipline.md
  - 2026-01-20-workflow-chain-skill-selection-after-verification.md
---

# Workflow Discipline: Follow Chains, Suggest Proactively, Never Skip Steps

## Problem Pattern

Recurring violations of workflow discipline across multiple sessions:

1. **Not suggesting next skills** - Completing a skill but waiting for user to ask "what's next?" instead of proactively suggesting the next logical skill
2. **Skipping skill steps** - Not following skills exactly (e.g., skipping Step 1 of finishing-a-development-branch)
3. **Suggesting wrong skills** - Proposing compound-learning instead of ai-self-reflection after verification-before-completion
4. **Being passive** - Asking "What would you like to do next?" instead of "Next step: Use [skill]..."

## Root Cause

Treating workflow chains as optional guidance rather than mandatory discipline. Working from memory instead of consulting the actual workflow chains table and skill content.

## Correct Pattern

### 1. Always Consult Workflow Chains Table

After completing ANY skill, check the "Common Workflow Chains" table in `using-superpowers`:

```markdown
| After This Skill              | Suggest This Next              | When                    |
|-------------------------------|--------------------------------|-------------------------|
| brainstorming                 | writing-plans                  | Design validated        |
| writing-plans                 | using-git-worktrees → executing-plans OR subagent-driven-development | Plan complete |
| executing-plans               | code-simplification (optional) → verification-before-completion | All tasks complete |
| verification-before-completion| finishing-a-development-branch | All tests pass          |
| finishing-a-development-branch| ai-self-reflection             | Work integrated         |
| systematic-debugging          | verification-before-completion | Fix implemented         |
| test-driven-development       | verification-before-completion | Tests passing           |
```

**This table is the source of truth** - consult it every time, don't work from memory.

### 2. Be Directive, Not Passive

After completing a skill:

✅ **Good:**
- "✅ verification-before-completion finished - all tests pass"
- "**Next step:** Use `finishing-a-development-branch` to complete this work"
- "**Suggested:** Use `ai-self-reflection` to capture learnings from this session"

❌ **Bad:**
- "What would you like to do next?"
- "We could maybe do X or Y..."
- "Let me know when you're ready to proceed"

### 3. Never Skip Skill Steps

When using a skill, follow EVERY step exactly as written:

**Example: finishing-a-development-branch**
- **Step 0:** Pre-flight check (clean working directory)
- **Step 1:** Invoke `documenting-completed-implementation` if plan exists ← DON'T SKIP THIS
- **Step 2:** Verify tests/build
- **Step 3:** Determine base branch
- **Step 4:** Present options
- **Step 5:** Execute choice

**Red flag:** If you think "I'll skip this step because..." → STOP. Follow the skill.

### 4. Read Skill Content, Don't Guess

Before suggesting a skill:
1. **Read the skill's actual content** (if recently loaded) or the description
2. **Check if it mentions the current context** (e.g., verification-before-completion mentions ai-self-reflection at the bottom)
3. **Understand the skill's purpose** (compound-learning = quick tactical learnings; ai-self-reflection = session retrospection)

## Examples from Sessions

### Example 1: Not Suggesting Next Skill

**What happened:**
- Completed `verification-before-completion` successfully
- Didn't suggest `finishing-a-development-branch`
- User had to ask "what's next?"

**What should have happened:**
```
✅ verification-before-completion finished - all tests pass

**Next step:** Use `finishing-a-development-branch` to handle documentation,
plan updates, and git workflow (merge/PR/cleanup).
```

### Example 2: Skipped Documentation Step

**What happened:**
- Used `finishing-a-development-branch` but skipped Step 1
- Didn't invoke `documenting-completed-implementation`
- User: "you still need to update the plans and move them in the correct folder"

**What should have happened:**
- Read Step 1 of finishing-a-development-branch
- See it requires `documenting-completed-implementation` if plan exists
- Invoke that skill first before proceeding

### Example 3: Wrong Skill from Chain

**What happened:**
- Completed `verification-before-completion`
- Suggested `compound-learning` as next step
- User corrected: should use `ai-self-reflection`

**What should have happened:**
- Consult "Common Workflow Chains" table
- See: verification-before-completion → finishing-a-development-branch
- Optionally suggest ai-self-reflection (mentioned in verification skill itself)

## Prevention Checklist

After completing ANY skill:

- [ ] **State completion clearly** - "✅ [skill] complete - [outcome]"
- [ ] **Consult workflow chains table** - Check using-superpowers for next step
- [ ] **Be directive** - "**Next step:** Use [skill]..." not "What would you like to do?"
- [ ] **Provide context** - Briefly explain why this skill is next
- [ ] **Don't skip steps** - If skill has prerequisites, follow them

Before using a skill:

- [ ] **Read skill content fully** - Don't work from memory or assumptions
- [ ] **Follow every step** - No shortcuts, no "this seems optional"
- [ ] **Check prerequisites** - Does this skill require another skill first?
- [ ] **Verify you're using the right skill** - Double-check against workflow chains table

## Success Criteria

- ✅ Users never have to ask "what's next?"
- ✅ I always suggest the next logical skill immediately after completing one
- ✅ Suggestions are directive ("Next step:") not passive ("Maybe...")
- ✅ I never skip skill steps
- ✅ I always use the correct skill from the workflow chains table

## Related Skills

- `using-superpowers` - Contains the "Common Workflow Chains" table (source of truth)
- ALL skills - This pattern applies universally to all workflow transitions

## Implementation Note

This learning consolidates three separate observations into a single pattern: **workflow discipline is mandatory**. The workflow chains table is not a suggestion - it's a requirement. Skills are not flexible guidelines - they're precise procedures. Following both exactly prevents all three failure modes.
