# AI Self-Reflection Reference

Detailed implementation guide for the ai-self-reflection skill.

## AskUserQuestion Templates

### Step 1: Scope Selection

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

### Step 3: Categorized Action Selection

```json
{
  "questions": [{
    "question": "How should I handle these learnings?",
    "header": "Action",
    "multiSelect": false,
    "options": [
      {
        "label": "Implement all suggestions (Recommended)",
        "description": "Apply all categorized actions: update CLAUDE.md, update skills, save reference learnings"
      },
      {
        "label": "Project updates only",
        "description": "Only update CLAUDE.md with project-specific learnings"
      },
      {
        "label": "Skill updates only",
        "description": "Only update superpowers skills with general workflow learnings"
      },
      {
        "label": "Custom selection",
        "description": "Review each learning individually and choose actions"
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

### Step 3a: Individual Learning Action (Custom Selection Mode)

```json
{
  "questions": [{
    "question": "What should I do with this learning?",
    "header": "Action",
    "multiSelect": false,
    "options": [
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

## Learning File Format

```yaml
---
date: [DATE]
type: user-correction | backtracking | repeated-error
source: ai-detected
confidence: high | medium | low
category: project-specific | general-workflow | platform-issue | reference
tags: [relevant, tags, from, context]
project: [PROJECT_NAME]
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

[Category-specific action: CLAUDE.md update, skill modification, or reference storage]
```

**Confidence levels:**
- High: User explicit correction, repeated error 3+ times
- Medium: Clear backtracking with evidence
- Low: Ambiguous patterns

**Category assignment:**
- **project-specific**: Applies only to current project (CLAUDE.md candidate)
- **general-workflow**: Broadly applicable pattern (skill candidate)
- **platform-issue**: Claude Code/API limitation (reference only)
- **reference**: API docs, command syntax (reference only)

**Tag selection:**
- Extract from context (file operations, git, testing, etc.)
- Add tool name if relevant (tool:grep, tool:bash)
- Add "codebase-specific" if project-specific
- Add "general" if broadly applicable

## Mistake Detection Patterns

### Type A: User Corrections

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

### Type B: Backtracking

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

### Type C: Repeated Errors

**Pattern detection:**
- Same or similar error occurs 2+ times in session
- Same tool fails with same error message
- Same class of error (e.g., "file not found" from different commands)

**For each repeated error, extract:**
- Error pattern description
- Number of occurrences
- Resolution (how to prevent it)

## Learning Categorization Logic

For each learning, assign category based on scope:

### project-specific
- References specific project files, directories, or conventions
- Applies to current codebase only
- Examples: "Tests in __tests__ not tests/", "Use yarn not npm in this project"
- **Action:** Update CLAUDE.md

### general-workflow
- Broadly applicable across projects
- Represents a pattern or technique
- Examples: "Check file existence before operations", "Use condition-based waiting for async tests"
- **Action:** Create/update skill

### platform-issue
- Limitation of Claude Code, Claude API, or tooling
- Can't be changed by user
- Examples: "Read tool requires absolute paths", "Grep has 2000-line limit"
- **Action:** Save as reference (no implementation action)

### reference
- API documentation, command syntax, library usage
- Factual information, not a mistake pattern
- Examples: "git log --oneline shows abbreviated commits", "wc -w counts words"
- **Action:** Save as reference (no implementation action)

## Action Implementation Details

### Implement All Suggestions (Recommended)

Process learnings by category:

1. **Project-specific learnings:** Update CLAUDE.md
   - Read CLAUDE.md to understand current structure
   - Identify appropriate section (or create "Common Patterns" or "Lessons Learned")
   - Draft addition showing context and lesson
   - Use Edit tool to add to CLAUDE.md
   - Write learning with note: "IMPLEMENTED: Added to CLAUDE.md on [DATE]"

2. **General-workflow learnings:** Update skills
   - For each learning, ask: create new skill or update existing?
   - Use AskUserQuestion to clarify
   - Invoke superpowers:writing-skills skill
   - When complete, return here
   - Write learning with note: "IMPLEMENTED: Created/updated [SKILL] on [DATE]"

3. **Platform-issue learnings:** Save as reference
   - Write to docs/learnings/ with category:platform-issue
   - No implementation action

4. **Reference learnings:** Save as reference
   - Write to docs/learnings/ with category:reference
   - No implementation action

### Project Updates Only

- Process only project-specific learnings
- Update CLAUDE.md following procedure above
- Save all other learnings to docs/learnings/ without action

### Skill Updates Only

- Process only general-workflow learnings
- Update skills following procedure above
- Save all other learnings to docs/learnings/ without action

### Custom Selection

For each learning individually:
- Present full details
- Ask what to do: Update CLAUDE.md | Create/update skill | Fix code | Save | Skip
- Execute chosen action
- Repeat for all learnings

See main SKILL.md for detailed workflow.

### Save All for Later

- Write all learnings to docs/learnings/ with appropriate categories
- No implementation actions

### Skip All

- Do not write any learnings
- Exit skill

## File Generation

**Create directory if needed:**

```bash
mkdir -p ~/Dev/superpowers/docs/learnings
```

**Generate filename:**

```bash
DATE=$(date +%Y-%m-%d)
SUMMARY="[brief description from mistake]"
SLUG=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//')
FILE="~/Dev/superpowers/docs/learnings/${DATE}-${SLUG}.md"
```

## Committing Learnings

After writing learnings to docs/learnings/, commit them:

```bash
git add docs/learnings/*.md CLAUDE.md
git commit -m "docs: capture AI self-reflection learnings"
```

## Error Handling

**No mistakes detected:**
```
✓ Session analyzed. No significant learnings detected.
```

**User skips all:**
```
Learnings not captured. You can run /ai-self-reflection again later.
```

**Git not available:**
```
⚠️  Learning files created but could not commit (git not available).
Created: docs/learnings/[FILES]
```
