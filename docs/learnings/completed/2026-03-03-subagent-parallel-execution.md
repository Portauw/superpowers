---
date: 2026-03-03
type: backtracking
source: ai-detected
confidence: high
category: general-workflow
tags: [subagents, parallel-execution, git, commits]
project: calendar-prep-mvp
---

# Subagents need project-level permissions for git commit

## What Happened
Dispatched 3 parallel Haiku agents for Tasks 1-3. All completed code changes successfully but none could execute `git commit` due to bash permission restrictions on subagents.

## AI Assumption
Subagents would have the same bash permissions as the parent agent and could commit their own changes.

## Reality
User-level permissions (`~/.claude/settings.json`) do NOT propagate to subagents (known issue #18950). Project-level permissions (`.claude/settings.json`) DO propagate. Added `Bash(git add:*)` and `Bash(git commit:*)` to user-level settings — needs testing to confirm if that's sufficient or if project-level is required.

## Lesson
If subagents need git write access, ensure `Bash(git add:*)` and `Bash(git commit:*)` are in the project's `.claude/settings.json`. User-level settings may not be inherited by subagents.

## Context
Session: Per-schedule calendar picker implementation. 4 parallel agents across 2 batches. All had the same commit permission issue. Root cause: permission inheritance, not a hard sandbox limitation.

## Suggested Action
~~If user-level permissions don't work for subagents after testing, add git write permissions to `.claude/settings.json` at project level.~~
**Applied:** Added `Bash(git add:*)` and `Bash(git commit:*)` to user-level settings. Pending verification with subagents.
