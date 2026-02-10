---
name: clean-software-design
description: Use when starting implementation, designing architecture, writing code, or reviewing code quality — verifies DDD, clean architecture, SOLID, and clean code principles against project-specific architectural context
---

# Clean Software Design

## Overview

Cross-cutting quality gate that verifies DDD, clean architecture, SOLID, and clean code principles. Adapts to project-specific context stored in `architectural-principles.md`.

**Core principle:** Opinionated defaults with project-aware context. The skill ensures design principles are considered at every workflow stage.

## Core Workflow

Every invocation follows these steps:

### Step 1: Load Project Context

1. Check CLAUDE.md for a reference to an architectural principles file
2. If found → Read the file (typically `docs/architectural-principles.md`)
3. If not found → Ask user: "This project doesn't have an architectural principles file. Should I create one at `docs/architectural-principles.md`?"
4. If user agrees → Scaffold the file (see template below), add reference to CLAUDE.md

### Step 2: Verify for Current Stage

Apply the checks relevant to the current workflow stage (see Stage-Specific Checks below). Use `reference.md` for the detailed verification criteria.

### Step 3: Capture New Decisions

If new architectural decisions are made during this invocation:
- Append to the appropriate section in `architectural-principles.md`
- Never overwrite existing entries without asking

## Stage-Specific Checks

### Brainstorming (Strategic)

Focus: *Are we building the right thing in the right boundaries?*

- **Bounded contexts:** Does this feature belong in an existing context or need a new one?
- **Ubiquitous language:** What terms does the domain use? Capture in glossary if not present.
- **Context mapping:** How does this context interact with others?
- **Quality attributes:** Which non-functional requirements matter most? Ask to rank with rationale.

Output: Constraints summary for the design doc + updates to `architectural-principles.md`.

### Planning (Tactical)

Focus: *Does the plan respect the architecture?*

- **Aggregate design:** Are aggregates identified with proper consistency boundaries?
- **Entity vs value object:** Are domain concepts correctly classified?
- **Dependency direction:** Do dependencies point inward (domain ← application ← infrastructure)?
- **Layer separation:** Is domain logic free from framework/infrastructure concerns?
- **Domain events:** Are cross-context communications via events, not direct calls?

Output: Architecture checklist items added to the plan.

### Execution (Implementation)

Focus: *Is the code clean and principled?*

- **SOLID:** Single responsibility and dependency inversion in particular
- **Clean code:** Meaningful names using ubiquitous language, small functions, no side effects, DRY
- **No framework leakage:** Domain layer has zero infrastructure imports
- **Repository pattern:** Data access behind abstractions

Output: Verification criteria for the sub-agent. Load `reference.md` for detailed checks.

### Review (Full Compliance)

Focus: *Complete check across all principles.*

All of the above, plus:
- **Consistency:** Does new code match existing patterns in the bounded context?
- **Quality attributes:** Are the prioritized attributes actually addressed?

Output: Findings with severity (critical / important / minor).

## architectural-principles.md Scaffold Template

When creating a new `architectural-principles.md`, use this template:

```markdown
# Architectural Principles

## Quality Attributes
| Attribute | Priority | Context & Rationale |
|-----------|----------|---------------------|
| | | |

## Bounded Contexts
<!-- List bounded contexts with their key entities and relationships -->

## Ubiquitous Language
| Term | Meaning | Context | Not to confuse with |
|------|---------|---------|---------------------|
| | | | |

## Architecture Decisions
<!-- Key architectural decisions and their rationale -->

## Clean Code Standards
<!-- Project-specific standards beyond universal principles -->
```

## What This Skill Does NOT Do

- Does not orchestrate work (that's executing-plans / subagent-driven-development)
- Does not replace TDD (that's test-driven-development)
- Does not run tests or verify builds (that's verification-before-completion)
- Focuses purely on design principles and architectural compliance

## Reference

For detailed verification criteria on all principles (DDD, SOLID, clean architecture, clean code), see `reference.md`.
