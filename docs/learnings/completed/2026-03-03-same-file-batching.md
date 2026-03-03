---
date: 2026-03-03
type: backtracking
source: ai-detected
confidence: high
category: general-workflow
tags: [subagents, parallel-execution, batching, same-file]
project: calendar-prep-mvp
---

# Same-file tasks need one agent, different-file tasks can parallelize

## What Happened
Tasks 4+5+6 all modified ScheduleModal.tsx. Dispatched as one Sonnet agent (sequential within agent). Tasks 7/8/9 modified different files, dispatched as 3 parallel Haiku agents. Both strategies worked well.

## AI Assumption
Initially considered running all 6 tasks as separate parallel agents.

## Reality
Multiple agents editing the same file would cause conflicts. Group same-file tasks into one agent, parallelize different-file tasks.

## Lesson
When batching tasks for parallel execution:
- Group tasks that touch the same file into a single agent (sequential within)
- Use Sonnet for complex multi-task agents, Haiku for simple single-task agents
- Different-file tasks can safely run as separate parallel agents

## Context
4 agents completed 6 tasks simultaneously. Sonnet for complex ScheduleModal (3 tasks, 20 tool uses), Haiku for simple backend changes (4-7 tool uses each).

## Suggested Action
~~Add batching guidance to executing-plans skill: "Group same-file tasks, parallelize different-file tasks."~~
**Applied:** Added Step 2 "Batch by File Overlap" to `dispatching-parallel-agents` and same-file conflict warning to `subagent-driven-development` Red Flags.
