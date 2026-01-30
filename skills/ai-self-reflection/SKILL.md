---
name: ai-self-reflection
description: Use when verification-before-completion finishes or when analyzing the session for mistakes and capturing learnings. Detects user corrections, backtracking, and repeated errors to build institutional knowledge.
---

# AI Self-Reflection

**Purpose:** Analyze the session for mistakes, categorize learnings, and apply them where they belong.

**DETAILED REFERENCE:** See reference.md for full JSON templates, file formats, and implementation details.

## When to Use

- After `verification-before-completion` completes (automatic)
- Via `/ai-self-reflection` command (manual)
- When asked to "reflect on this session"

## Workflow Overview

**1. Determine Scope**
- Ask user: analyze since last verification OR full session
- Set scope for analysis

**2. Analyze for Mistakes**
- Silently analyze conversation within scope
- Detect three mistake types (see reference.md for patterns):
  - **Type A: User Corrections** - User says "no", "wrong", "actually", corrects AI
  - **Type B: Backtracking** - AI confident → fails → surprised pivot
  - **Type C: Repeated Errors** - Same error 2+ times in session

**3. Categorize Learnings**

Assign each learning to one category:

| Category | Criteria | Action |
|----------|----------|--------|
| **project-specific** | Project tools, file paths, tech stack patterns | Update CLAUDE.md |
| **general-workflow** | Broadly applicable, development process, skill usage | Create/update skill |
| **platform-issue** | Claude Code limitation, tool bugs, requires Anthropic fix | Save as reference, file feedback |
| **reference** | Technical examples, useful but not workflow guidance | Save as reference |

**When uncertain:** Between project/general → choose general (broader). Between general/reference → ask "prevents mistakes?" → general; "useful example?" → reference.

**4. Show Categorized Summary**

```
# Session Retrospective

Found {{COUNT}} learning(s):

## Project-Specific (→ CLAUDE.md)
1. [Brief summary] → Add to "{{SECTION}}" section

## General Patterns (→ Skills)
2. [Brief summary] → Enhance {{SKILL_NAME}} skill

## Platform Issues (→ Feedback)
(none)

## Reference Documentation
3. [Brief summary] → Save for future reference
```

**5. Ask How to Handle**

Options:
- **Implement all suggestions** (recommended) - Apply all category actions automatically
- **Project updates only** - Just update CLAUDE.md
- **Skill updates only** - Just update skills
- **Custom selection** - Review each learning individually
- **Save all for later** - Write to docs/learnings/ without action
- **Skip all** - Don't capture

See reference.md for full option definitions and AskUserQuestion template.

**6. Execute Actions by Category**

**Implement all suggestions:**
- Project-specific → Update CLAUDE.md with Edit tool
- General-workflow → Invoke writing-skills, update/create skills
- Platform-issue/reference → Save to docs/learnings/ only

**Project/Skill updates only:**
- Process selected category only
- Save others to docs/learnings/

**Custom selection:**
- Present each learning individually
- Ask: Update CLAUDE.md | Create/update skill | Fix code | Save | Skip
- Execute chosen action

**Save all/Skip all:**
- Write all to docs/learnings/ or exit

**Commit learnings:**

```bash
git add docs/learnings/*.md CLAUDE.md
git commit -m "docs: capture AI self-reflection learnings"
```

## Mistake Detection Quick Reference

| Type | Signals | Extract |
|------|---------|---------|
| **User Correction** | "no", "wrong", "actually", "instead" | AI assumption → User correction → Context |
| **Backtracking** | AI confident → tool fails → pivot (not retry) | Assumption → Reality → Signal |
| **Repeated Error** | Same error 2+ times | Pattern → Count → Resolution |

**Distinguish backtracking from normal:**
- ✅ Normal: "Let me try A, then B if needed" (uncertainty upfront)
- ❌ Mistake: "I'll do A" → fails → "Oh I need B" (confident → surprised)

## Learning File Structure

```yaml
---
date: YYYY-MM-DD
type: user-correction | backtracking | repeated-error
source: ai-detected
confidence: high | medium | low
category: project-specific | general-workflow | platform-issue | reference
tags: [context, keywords]
project: [PROJECT_NAME]
---

# One-line summary
## What Happened
## AI Assumption
## Reality
## Lesson
## Context
## Suggested Action
[Category-specific: CLAUDE.md update, skill mod, or reference note]
```

See reference.md for full template and categorization logic.

## Categorization Examples

**project-specific:**
- "Update CloudFormation template when IAM roles change" (AWS/SAM specific)
- "Tests in __tests__ not tests/" (project structure)
- "Use yarn not npm in this project" (tooling choice)

**general-workflow:**
- "Check file existence before operations" (broadly applicable)
- "Scan for redundant tests after converting to mocks" (testing pattern)
- "Invoke skill before any clarifying questions" (workflow discipline)

**platform-issue:**
- "Read tool requires absolute paths, tilde fails" (tool limitation)
- "Grep has 2000-line output limit" (tool constraint)
- "Skill tool triggers unnecessary prompts" (behavior bug)

**reference:**
- "MongoDB chainable query mocking technique" (useful example)
- "git log --oneline syntax" (command reference)
- "Jest mock.mockResolvedValue pattern" (library usage)

## Action Implementation Summary

See reference.md for detailed procedures. High-level:

**Update CLAUDE.md:**
- Read current structure → Draft addition → Edit tool → Write learning with "IMPLEMENTED: Added to CLAUDE.md on [DATE]"

**Create/update skill:**
- Ask which skill → Invoke writing-skills → When complete, return here → Write learning with "IMPLEMENTED: [SKILL] on [DATE]"

**Fix code:**
- Show fix → Confirm files → Edit tool → Write learning with "IMPLEMENTED: Fixed in [FILES] on [DATE]"

**Save as reference:**
- Write to docs/learnings/ with appropriate category, no action

## Success Criteria

- ✅ Asks user for scope
- ✅ Silently analyzes for mistakes (no verbalization)
- ✅ Detects all three mistake types correctly
- ✅ Categorizes each learning (project/general/platform/reference)
- ✅ Shows categorized summary with suggested actions per category
- ✅ Offers six handling options
- ✅ Implements category-appropriate actions (CLAUDE.md, skills, or save only)
- ✅ Writes learnings with source:ai-detected and category field
- ✅ Commits learnings with clear commit message

## Integration

**Triggered by:**
- verification-before-completion (automatic)
- `/ai-self-reflection` command (manual)

**Feeds into:**
- meta-learning-review (analyzes ai-detected learnings by category)

**Uses:**
- docs/learnings/ (storage with YAML frontmatter and category field)
