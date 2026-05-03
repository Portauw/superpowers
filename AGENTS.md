# AGENTS.md

Guidance for AI coding agents working in this repository — Claude Code, Cursor, Antigravity, Aider, OpenCode, Codex, GitHub Copilot agents, and any tool that picks up `AGENTS.md`.

For Claude Code-specific details (plugin layout, hooks, marketplace), see `CLAUDE.md`.

## Repository Overview

**Superpowers** is a skills-based workflow system. Skills are structured process documentation (TDD, debugging, planning, review). Agents pick up the relevant skill for the current intent and follow its workflow rather than improvising. The result is consistent, reviewable output across tools.

## Skill Discovery

Skills live in `skills/<skill-name>/SKILL.md`. Each has YAML frontmatter:

```yaml
---
name: <skill-name>
description: Use when <triggering condition>
---
```

The description **must** start with "Use when..." and describe triggering conditions only — never summarize the workflow. Agents discover skills by matching the user's intent against the description.

When a user request matches a skill description, **load the skill and follow it**. Do not paraphrase the workflow from memory.

Cross-skill reference material is in `references/`. Single-skill reference material lives next to the skill (e.g., `skills/<name>/<topic>.md`).

## Intent → Skill Mapping

| User intent / signal                                         | Skill                                  |
| ------------------------------------------------------------ | -------------------------------------- |
| New feature, fuzzy idea, "should we build X"                 | `brainstorming`                        |
| External API or service integration                          | `outgoing-api-design`                  |
| "Plan this out" / break work into tasks                      | `writing-plans`                        |
| Isolated workspace for a feature branch                      | `using-git-worktrees`                  |
| Execute a written plan                                       | `executing-plans`                      |
| Multiple independent tasks, parallel execution               | `subagent-driven-development`          |
| 2+ unrelated investigations / failures                       | `dispatching-parallel-agents`          |
| Writing or modifying code                                    | `test-driven-development`              |
| While editing, surrounding code is messy                     | `boyscout`                             |
| Bug, unexpected behavior, "why is this failing"              | `systematic-debugging`                 |
| Architecture / DDD / SOLID concern raised                    | `clean-software-design`                |
| Substantial changes done, want cleanup                       | `code-simplification`                  |
| "Is this done?" — pre-completion check                       | `verification-before-completion`       |
| Pre-PR / pre-merge / "review this"                           | `requesting-code-review`               |
| Responding to review feedback                                | `receiving-code-review`                |
| User corrected me, I backtracked, repeated mistake           | `ai-self-reflecting`                   |
| Captured insight after verification                          | `compound-learning`                    |
| Periodic learning rollup (every ~10 captures)                | `meta-learning-review`                 |
| Update docs after implementation                             | `documenting-completed-implementation` |
| Merge / PR / branch cleanup                                  | `finishing-a-development-branch`       |
| Creating or editing a skill                                  | `writing-skills`                       |

When two skills could apply, the more specific one wins (e.g., `outgoing-api-design` beats `brainstorming` for API work).

## Lifecycle Mapping

| Phase   | Skills                                                                                      |
| ------- | ------------------------------------------------------------------------------------------- |
| DEFINE  | `brainstorming`, `outgoing-api-design`                                                      |
| PLAN    | `writing-plans`                                                                             |
| BUILD   | `using-git-worktrees`, `subagent-driven-development` or `executing-plans`, `test-driven-development`, `boyscout` |
| VERIFY  | `systematic-debugging`, `verification-before-completion`                                    |
| REVIEW  | `requesting-code-review`, `receiving-code-review`, `clean-software-design`                  |
| SHIP    | `documenting-completed-implementation`, `finishing-a-development-branch`                    |
| REFLECT | `ai-self-reflecting`, `compound-learning`, `meta-learning-review`                           |

The chain is normative, not rigid. Skip phases when they don't apply (a one-line typo fix doesn't need brainstorming). Don't skip them because they feel like overhead.

## Anti-Rationalization Rules

The following thoughts are wrong and must be ignored:

- "This is too small for a skill."
- "I can just quickly implement this."
- "I'll gather context first, then decide."
- "The skill is overkill for this case."
- "I already know how to do this."

Correct behavior: **always check for a matching skill first, even if the task feels trivial.** If a skill matches, load it and follow it. The whole point of the system is that "I know how" is the moment you most need the structure.

When you genuinely believe no skill applies, name that explicitly ("no skill matches this intent because…") rather than silently skipping the check.

## Persona Orchestration Rules

This repo has three composable layers:

- **Skills** (`skills/<name>/SKILL.md`) — workflows. The *how*. Required hops when intent matches.
- **Personas** (`agents/<role>.md`) — review and analysis roles with a perspective and an output format. The *who*.
- **Commands** (`commands/<name>.md`) — user-facing entry points. The *when*.

Composition rule: **the user, or a skill that explicitly orchestrates, is the orchestrator. Personas do not invoke other personas.** A persona may invoke skills, but it does not call another persona.

The only multi-persona pattern this repo endorses is **parallel fan-out with a merge step**. `requesting-code-review` runs `code-reviewer`, and may run `security-auditor` and `test-engineer` concurrently when the surface warrants. After all return, the orchestrator merges findings into one severity-tagged report.

Do not build a router persona that decides which other persona to invoke. That's the orchestrator's job.

**Tool interop note:** subagents (Claude Code) and teammates (Agent Teams) cannot spawn other subagents/teammates. The personas in `agents/` respect this constraint by design.

## Auto-Loaded Skill

`using-superpowers` is injected into every Claude Code session at startup via `hooks/session-start.sh`. It is the system's entry point. Other tools without a session-start hook should treat `skills/using-superpowers/SKILL.md` as required reading on first load.

## Quick Reference

- Skills: `skills/<skill-name>/SKILL.md`
- Personas: `agents/<role>.md`
- Commands: `commands/<command-name>.md`
- Cross-skill references: `references/<topic>.md`
- Hooks: `hooks/session-start.sh`
- Plugin config: `.claude-plugin/plugin.json`

## Common Anti-Patterns

- Loading a skill via `@skills/...` (forces full file into context — costly). Reference by name instead: "Use `superpowers:test-driven-development`".
- Summarizing a skill's workflow instead of loading and following it.
- Skipping the description check because the task seems obvious.
- Spawning a persona from inside another persona.
- Adding a fifth persona to a fan-out without checking whether a single reviewer would do.

---

> AGENTS.md structure adapted from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT License).
