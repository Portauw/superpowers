# Model Selection Guide for Skills

**IMPORTANT**: Always use the appropriate model for each skill to balance quality and cost.

## Design & Architecture Skills (Use OPUS)

- `superpowers:brainstorming` → **Opus** - Architectural decisions, exploring approaches, creative problem-solving
- Use Task tool with `model="opus"` instead of Skill tool when invoking these

## Planning Skills (Use SONNET)

- `superpowers:writing-plans` → **Sonnet** - Structured planning, breaking down tasks, writing implementation steps
- `superpowers:requesting-code-review` → **Sonnet** - Code analysis, quality assessment, suggesting improvements

## Execution Skills (Use HAIKU)

- `superpowers:executing-plans` → **Haiku** - Following explicit plan instructions, mechanical implementation
- `superpowers:subagent-driven-development` → **Haiku** - Task-by-task execution with supervision
- `superpowers:test-driven-development` → **Haiku** - Writing tests and implementation following TDD pattern
- `superpowers:verification-before-completion` → **Haiku** - Running tests, checking outputs

## Debugging Skills (Use SONNET)

- `superpowers:systematic-debugging` → **Sonnet** - Investigating bugs, analyzing failures, root cause analysis
- `superpowers:receiving-code-review` → **Sonnet** - Understanding feedback, verifying suggestions

## General Guidelines

- **Opus** (💎 Highest cost, highest quality): Architectural decisions, ambiguous requirements, creative design
- **Sonnet** (⚖️ Balanced): Structured planning, code review, debugging, general development
- **Haiku** (⚡ Lowest cost): Mechanical execution, following explicit instructions, straightforward tasks
