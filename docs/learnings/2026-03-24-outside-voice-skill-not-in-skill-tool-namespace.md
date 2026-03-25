---
date: 2026-03-24
type: repeated-error
source: ai-detected
confidence: high
category: general-workflow
tags: [outside-voice, skill-tool, namespace, registration]
project: superpowers
---

# Outside-voice skill not discoverable via Skill tool

## What Happened
Tried to invoke outside-voice via `Skill` tool: first as `outside-voice`, then as `superpowers:outside-voice`. Both failed with "Unknown skill". Had to manually Read the SKILL.md and follow it step-by-step.

## AI Assumption
The outside-voice skill would be registered and invocable like other superpowers skills (e.g., `superpowers:ai-self-reflecting` works fine).

## Reality
The Skill tool didn't recognize outside-voice under any namespace. This may be a registration issue, a naming mismatch, or the skill was added after the session's skill index was built.

## Lesson
When a skill isn't found via the Skill tool:
1. Don't retry with namespace variations — if it's not registered, prefixing won't help
2. Immediately fall back to reading the SKILL.md directly and following it manually
3. Check if the skill is listed in the session's available skills list before invoking

## Suggested Action
Verify outside-voice is properly registered in the superpowers plugin. Check that `skills/outside-voice/SKILL.md` frontmatter matches the expected format and that the plugin index includes it.
