---
name: ai-self-reflection
description: Use when verification-before-completion finishes or when analyzing the session for mistakes and capturing learnings. Detects user corrections, backtracking, and repeated errors to build institutional knowledge.
---

# AI Self-Reflection Skill

**Purpose:** Analyze the current session for mistakes and capture learnings automatically to prevent future errors.

## When to Use

- After `verification-before-completion` completes (automatic invocation)
- Via `/retrospective` command (manual trigger)
- When asked to "reflect on this session" or similar

## What It Does

1. Asks user for scope of analysis
2. Analyzes conversation for three mistake types
3. Extracts structured learnings from detected mistakes
4. **Categorizes learnings** by scope: project-specific, general workflow, platform issue, or reference
5. Shows **categorized summary** with suggested actions per category
6. Asks how to handle:
   - **Implement all suggestions** (recommended): Apply project updates, skill updates, and save reference learnings
   - **Project updates only**: Update CLAUDE.md only
   - **Skill updates only**: Update superpowers skills only
   - **Custom selection**: Review each learning individually
   - **Save all for later**: Write all to docs/learnings/ without immediate action
   - **Skip all**: Don't capture any learnings
7. Executes chosen actions for each learning
8. Increments counter for meta-learning-review trigger

---

## Execution Steps

### Step 1: Determine Scope

**Ask user for analysis scope:**

Use AskUserQuestion tool:

```json
{
  "questions": [{
    "question": "What scope should I analyze for learnings?",
    "header": "Analysis scope",
    "multiSelect": false,
    "options": [
      {
        "label": "Since last verification",
        "description": "Analyze only the conversation since verification-before-completion last ran"
      },
      {
        "label": "Full session",
        "description": "Analyze the entire session from the beginning"
      }
    ]
  }]
}
```

Set scope based on user response.

### Step 2: Analyze for Mistakes

**Silently analyze the conversation within scope for three mistake types.**

Do NOT verbalize the analysis process. Just analyze internally.

#### Mistake Type A: User Corrections

**Pattern detection:**
- User message contains negation: "no", "don't", "wrong", "not what I", "actually"
- User message contains correction after AI action: "instead", "should be", "use X not Y"
- User explicitly references AI's previous action negatively

**Examples:**
- User: "No, the tests are in __tests__ not tests/"
- User: "Wrong, use yarn not npm"
- User: "Don't use that approach, do this instead"

**For each detected correction, extract:**
- AI's assumption (what AI thought)
- User's correction (what's actually correct)
- Context (when this applies)

#### Mistake Type B: Backtracking

**Pattern detection:**
- AI stated intention: "I'll", "Let me", "I expect", "This should"
- Tool call resulted in failure or unexpected output
- AI's next action was different approach (not just retry)

**Distinguish from normal iteration:**
- Normal: "Let me try A first, then B if needed" (uncertainty stated upfront)
- Mistake: "I'll do A" → fails → "Oh, I see I need B" (confident then surprised)

**For each detected backtrack, extract:**
- AI's assumption
- Reality (what actually happened)
- Corrected approach
- Signal (how to detect this upfront)

#### Mistake Type C: Repeated Errors

**Pattern detection:**
- Same or similar error occurs 2+ times in session
- Same tool fails with same error message
- Same class of error (e.g., "file not found" from different commands)

**For each repeated error, extract:**
- Error pattern description
- Number of occurrences
- Resolution (how to prevent it)

### Step 3: Categorize and Show Summary

**If no mistakes detected:**

```
✓ Session analyzed. No significant learnings detected.
```

Exit skill.

**If mistakes detected:**

#### Step 3.1: Categorize Each Learning

For each detected learning, analyze and categorize it into one of four types:

**Categorization Criteria:**

1. **Project-Specific** (→ Add to project's CLAUDE.md)
   - Mentions project-specific tools, frameworks, or infrastructure (AWS, SAM, EventBridge, specific file paths)
   - Architecture decisions specific to this codebase
   - Deployment procedures unique to this project
   - Configuration patterns specific to tech stack
   - Example: "Update CloudFormation template proactively when IAM role changes"

2. **General Workflow** (→ Update superpowers skill)
   - Applies across multiple projects
   - About development process (testing, git, verification, planning)
   - About skill usage patterns or workflow discipline
   - Could benefit any project using superpowers
   - Example: "Scan for redundant manual tests after converting to mocks"

3. **Platform Issues** (→ File feedback, no action in skills)
   - About Claude Code behavior (not skill content)
   - Tool limitations or bugs
   - Permission/capability issues
   - Requires Anthropic team action
   - Example: "Skill tool invocation triggers unnecessary permission prompts"

4. **Reference Documentation** (→ Keep as learning file only)
   - Technical patterns (mocking, testing techniques)
   - Useful examples but not workflow guidance
   - Could apply in many contexts
   - Not urgent to add to docs or skills
   - Example: "MongoDB chainable query mocking technique"

**Categorization Process:**
- Analyze context, tags, and suggested action for each learning
- Assign category based on criteria above
- When uncertain between project-specific and general workflow, err toward general workflow (broader applicability)
- When uncertain between general workflow and reference, consider: "Would this prevent future mistakes?" → workflow; "Is this a useful example?" → reference

#### Step 3.2: Show Categorized Summary

Show summary grouped by category:

```
# Session Retrospective

Found {{COUNT}} potential learning(s) from this session:

## Project-Specific (→ CLAUDE.md)
{{#IF_PROJECT_LEARNINGS}}
1. [{{BRIEF_SUMMARY}}]
   → Suggested: Add to "{{SECTION_NAME}}" section in CLAUDE.md
{{/IF_PROJECT_LEARNINGS}}
{{#IF_NO_PROJECT}}
(none)
{{/IF_NO_PROJECT}}

## General Patterns (→ Update Skills)
{{#IF_SKILL_LEARNINGS}}
2. [{{BRIEF_SUMMARY}}]
   → Suggested: Enhance {{SKILL_NAME}} skill
3. [{{BRIEF_SUMMARY}}]
   → Suggested: Platform feedback (not actionable in skills)
{{/IF_SKILL_LEARNINGS}}
{{#IF_NO_SKILL}}
(none)
{{/IF_NO_SKILL}}

## Platform Issues (→ File Feedback)
{{#IF_PLATFORM_LEARNINGS}}
4. [{{BRIEF_SUMMARY}}]
   → Suggested: Report to Claude Code team
{{/IF_PLATFORM_LEARNINGS}}
{{#IF_NO_PLATFORM}}
(none)
{{/IF_NO_PLATFORM}}

## Reference Documentation (→ Keep as Learning)
{{#IF_REFERENCE_LEARNINGS}}
5. [{{BRIEF_SUMMARY}}]
   → Suggested: Save to docs/learnings/ for reference
{{/IF_REFERENCE_LEARNINGS}}
{{#IF_NO_REFERENCE}}
(none)
{{/IF_NO_REFERENCE}}
```

#### Step 3.3: Ask How to Proceed

Use AskUserQuestion tool:

```json
{
  "questions": [{
    "question": "How would you like to proceed with these categorized learnings?",
    "header": "Action",
    "multiSelect": false,
    "options": [
      {
        "label": "Implement all suggestions (Recommended)",
        "description": "Apply project updates (CLAUDE.md), skill updates, and save reference learnings"
      },
      {
        "label": "Project updates only",
        "description": "Only update this project's CLAUDE.md, save others for later"
      },
      {
        "label": "Skill updates only",
        "description": "Only update superpowers skills, save others for later"
      },
      {
        "label": "Custom selection",
        "description": "Review each learning individually and decide what to do"
      },
      {
        "label": "Save all for later",
        "description": "Write all learnings to docs/learnings/ without immediate action"
      },
      {
        "label": "Skip all",
        "description": "Don't capture any learnings from this session"
      }
    ]
  }]
}
```

**Handle user choice:**

- If user chooses "Skip all", exit skill.
- If user chooses "Save all for later", proceed to Step 4.
- If user chooses "Implement all suggestions", proceed to Step 3a with filter: all categories
- If user chooses "Project updates only", proceed to Step 3a with filter: project-specific only
- If user chooses "Skill updates only", proceed to Step 3a with filter: general workflow only
- If user chooses "Custom selection", proceed to Step 3a with all learnings (user decides per-learning)

### Step 3a: Act on Learnings Immediately

**Filter learnings based on user's Step 3.3 choice:**
- "Implement all suggestions" → Process all categories
- "Project updates only" → Process only project-specific category
- "Skill updates only" → Process only general workflow category
- "Custom selection" → Process all, but ask per-learning

**For each learning in scope:**

1. **Present the learning:**

```
## Learning {{N}} of {{TOTAL}}: {{BRIEF_SUMMARY}}

**Category:** {{CATEGORY}} (project-specific | general workflow | platform issue | reference)

**Type:** {{TYPE}} (user-correction | backtracking | repeated-error)

**What Happened:**
{{DESCRIPTION}}

**AI Assumption:**
{{ASSUMPTION}}

**Reality:**
{{REALITY}}

**Lesson:**
{{TAKEAWAY}}

**Suggested Action:**
{{SUGGESTED_ACTION}}
```

2. **Determine action automatically or ask user:**

**If user chose "Implement all suggestions" OR "Project updates only" OR "Skill updates only":**
- Use the suggested action from categorization automatically
- Don't ask user for confirmation (they already approved the category)
- Project-specific → Execute "Update CLAUDE.md"
- General workflow → Execute "Create/update skill"
- Platform issue → Execute "Save for later" (with note to file feedback)
- Reference → Execute "Save for later"

**If user chose "Custom selection":**

Use AskUserQuestion tool:

```json
{
  "questions": [{
    "question": "What should I do with this learning?",
    "header": "Action",
    "multiSelect": false,
    "options": [
      {
        "label": "Use suggested action (Recommended)",
        "description": "[Show the suggested action from categorization]"
      },
      {
        "label": "Update CLAUDE.md",
        "description": "Add this pattern to project documentation"
      },
      {
        "label": "Create/update skill",
        "description": "Create a new skill or enhance an existing one"
      },
      {
        "label": "Fix code now",
        "description": "Make code changes to address this issue"
      },
      {
        "label": "Save for later",
        "description": "Just write to docs/learnings/ for future reference"
      },
      {
        "label": "Skip this one",
        "description": "Don't capture this particular learning"
      }
    ]
  }]
}
```

3. **Execute the chosen action:**

**If "Update CLAUDE.md":**
- Read CLAUDE.md (in current project) to understand current structure
- Identify appropriate section (or create new section like "Common Patterns" or "Lessons Learned")
- Draft the addition showing context and lesson learned
- Use Edit tool to add to CLAUDE.md
- Write learning to docs/learnings/ with added note in Suggested Action section: "IMPLEMENTED: Added to CLAUDE.md on [DATE]"
- Continue to next learning

**If "Create/update skill":**
- Ask which skill to modify: Use AskUserQuestion with two options:
  - "Create new skill" - then ask for skill name suggestion
  - "Update existing skill" - then ask which skill name
- Invoke superpowers:writing-skills skill
- When writing-skills completes, return to ai-self-reflection workflow
- Write learning to docs/learnings/ with added note: "IMPLEMENTED: Created/updated [SKILL-NAME] skill on [DATE]"
- Continue to next learning

**If "Fix code now":**
- Show the suggested fix from the learning
- Ask user to confirm files to change or provide file paths
- Make the recommended code changes using Edit tool
- Write learning to docs/learnings/ with added note: "IMPLEMENTED: Fixed code in [FILES] on [DATE]"
- Continue to next learning

**If "Save for later":**
- Write this learning to docs/learnings/ without implementation notes
- If this is a platform issue (category = platform), add note: "NOTE: This is a Claude Code platform issue. Consider filing feedback at https://github.com/anthropics/claude-code/issues"
- Continue to next learning

**If "Skip this one":**
- Do NOT write this learning to docs/learnings/
- Continue to next learning

4. **Repeat for all learnings**

5. **After processing all learnings:**
- Count how many learnings were actually saved (excludes "Skip this one" choices)
- If count > 0, proceed to Step 5 (increment counter and commit)
- If count = 0, skip to success message: "Processed {{TOTAL}} learning(s), none were saved."

### Step 4: Create Learning Files

**For each detected learning:**

Create directory if needed:

```bash
mkdir -p ~/Dev/superpowers/docs/learnings
```

Generate filename:

```bash
DATE=$(date +%Y-%m-%d)
SUMMARY="[brief description from mistake]"
SLUG=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//')
FILE="~/Dev/superpowers/docs/learnings/${DATE}-${SLUG}.md"
```

Write learning file with YAML frontmatter:

```yaml
---
date: [DATE]
type: user-correction | backtracking | repeated-error
source: ai-detected
confidence: high | medium | low
category: project-specific | general-workflow | platform-issue | reference
tags: [relevant, tags, from, context]
project: [PROJECT_NAME or 'superpowers']
---

# [One-line summary]

## What Happened

[Brief description of the mistake]

## AI Assumption

[What the AI expected/believed]

## Reality

[What actually happened]

## Lesson

[The takeaway - what to do differently]

## Context

[When this applies - codebase-specific? General?]

## Suggested Action

[Proposed action based on category]
[For project-specific: "Add to CLAUDE.md section: ..."]
[For general-workflow: "Update [SKILL-NAME] skill to ..."]
[For platform-issue: "File feedback at https://github.com/anthropics/claude-code/issues"]
[For reference: "Keep as reference documentation"]

[If implemented: "IMPLEMENTED: [action taken] on [DATE]"]
```

**Confidence levels:**
- High: User explicit correction, repeated error 3+ times
- Medium: Clear backtracking with evidence
- Low: Ambiguous patterns

**Tag selection:**
- Extract from context (file operations, git, testing, etc.)
- Add tool name if relevant (tool:grep, tool:bash)
- Add "codebase-specific" if project-specific
- Add "general" if broadly applicable

### Step 5: Increment Counter

```bash
node ~/Dev/superpowers/lib/meta-learning-state.js record
COUNT=$(node ~/Dev/superpowers/lib/meta-learning-state.js count)
```

If count reaches 10:

```
💡 10 learnings captured! Run /review-learnings to detect patterns.
```

### Step 6: Commit Learnings

```bash
git add ~/Dev/superpowers/docs/learnings/*.md
git commit -m "docs: capture AI self-reflection learnings from session"
```

Report success:

```
✓ Captured {{COUNT}} learning(s):
- docs/learnings/[DATE]-[SLUG-1].md
- docs/learnings/[DATE]-[SLUG-2].md

These learnings will be analyzed by meta-learning-review for patterns.
```

---

## Success Criteria

- ✅ Asks user for scope (since last verification OR full session)
- ✅ Silently analyzes conversation for mistakes
- ✅ Detects user corrections, backtracking, repeated errors
- ✅ **Categorizes learnings** into: project-specific, general-workflow, platform-issue, or reference
- ✅ Shows **categorized summary** grouped by category
- ✅ Suggests appropriate actions for each category
- ✅ Asks how to handle: implement all, project only, skills only, custom selection, save all, or skip all
- ✅ For "Implement all": automatically applies suggested actions per category
- ✅ For "Project only": updates CLAUDE.md only
- ✅ For "Skill only": updates skills only
- ✅ For "Custom selection": presents each learning with category and asks per-learning
- ✅ For "Save all for later": writes all to docs/learnings/ without interaction
- ✅ Executes chosen actions (edits CLAUDE.md, invokes writing-skills, makes code fixes)
- ✅ Writes YAML frontmatter with source:ai-detected and category field
- ✅ For platform issues: adds note to file feedback
- ✅ Increments meta-learning counter
- ✅ Commits learnings to git
- ✅ Suggests meta-learning-review at 10 learnings

---

## Error Handling

**No mistakes detected:**
```
✓ Session analyzed. No significant learnings detected.
```

**User declines capture:**
```
Learnings not captured. You can run /retrospective again later.
```

**Git not available:**
```
⚠️  Learning files created but could not commit (git not available).
Created: docs/learnings/[FILES]
```

---

## Integration

**Triggered by:**
- verification-before-completion skill (automatic)
- `/retrospective` command (manual)
- User request to reflect

**Feeds into:**
- meta-learning-review (consumes ai-detected learnings)

**Uses:**
- lib/meta-learning-state.js (counter)
- docs/learnings/ (storage)
