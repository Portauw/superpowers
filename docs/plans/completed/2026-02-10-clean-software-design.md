# Clean Software Design Skill — Design Document

> **Status:** ✅ COMPLETED - 2026-02-10

**Date:** 2026-02-10

## Overview

A cross-cutting quality lens skill that enforces DDD, clean architecture, SOLID, and clean code principles throughout the entire development workflow. It is invoked explicitly by existing skills at their checkpoints.

**Core concept:** Opinionated software design principles, adapted to project-specific context (bounded contexts, quality attributes, ubiquitous language) that the skill discovers in or captures to a project-level `architectural-principles.md` file.

## Skill Identity

- **Name:** `clean-software-design`
- **Type:** Cross-cutting quality gate
- **Location:** `skills/clean-software-design/`
- **Trigger:** Invoked by other skills at brainstorming, planning, execution, and review stages

## Principle Categories

1. **DDD Strategic** — Bounded contexts, ubiquitous language, context mapping, anti-corruption layers
2. **DDD Tactical** — Aggregates, entities, value objects, domain events, repositories, domain services
3. **Clean Architecture** — Dependency direction (inward), layer separation, ports & adapters, no framework leakage
4. **SOLID** — Single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion
5. **Clean Code** — Meaningful naming, small functions, no side effects, DRY, single level of abstraction
6. **Quality Attributes** — Project-specific priorities (security, performance, scalability, maintainability, testability)

## File Architecture

### Skill-level (bundled with skill, universal)

```
skills/
  clean-software-design/
    SKILL.md          # Workflow: stage-aware checks, concise
    reference.md      # All universal principles: DDD, SOLID, clean code, clean architecture
```

- **SKILL.md** — Defines the workflow: how to check CLAUDE.md, what to verify at each stage, what to ask if missing, how to store decisions. Kept concise for token efficiency.
- **reference.md** — Deep reference material on all principle categories. Loaded by sub-agents when they need verification criteria.

### Project-level (created per project, living document)

```
project-root/
  CLAUDE.md                       # Contains reference to architectural-principles.md
  docs/
    architectural-principles.md   # Living document, maintained by skill
```

- **CLAUDE.md** — Gets a pointer added: `See docs/architectural-principles.md for architectural principles.`
- **architectural-principles.md** — Living document the skill creates and appends to. Never overwrites without asking.

### architectural-principles.md Structure

```markdown
# Architectural Principles

## Quality Attributes
| Attribute | Priority | Context & Rationale |
|-----------|----------|---------------------|
| Security | 1 | Handles PII, regulatory compliance (GDPR) |
| Maintainability | 2 | Small team, long-lived product |
| Performance | 3 | Sub-200ms API responses for UX |

## Bounded Contexts
- **Payments**: Order, Invoice, Payment (owns transaction lifecycle)
  - Upstream: Identity (customer data via ACL)
  - Downstream: Notifications (events)

## Ubiquitous Language
| Term | Meaning | Context | Not to confuse with |
|------|---------|---------|---------------------|
| Order | A purchase request | Payments | Sorting order |
| Tenant | An organization account | Identity | Physical tenant |

## Architecture Decisions
- Domain layer: zero infrastructure imports
- Cross-context communication: domain events only
- Data access: repository pattern, no direct DB queries in domain
- API boundaries: one controller per bounded context

## Clean Code Standards
- Functions: max 20 lines, single responsibility
- Naming: ubiquitous language terms mandatory in domain layer
- Dependencies: always point inward (infrastructure -> application -> domain)
```

## Skill Behavior

### Core Workflow (every invocation)

1. **Check CLAUDE.md** for a reference to an architectural principles file
2. **If found** — read it, use as verification criteria for the current stage
3. **If not found** — ask user where to create it (suggest `docs/architectural-principles.md`), scaffold the structure, add reference to CLAUDE.md
4. **After capturing new decisions** — append to the appropriate section
5. **Never overwrite** existing entries without asking

### Stage-Specific Checks

#### Brainstorming Stage (Strategic)

Focus: *Are we building the right thing in the right boundaries?*

- **Bounded contexts:** Does this feature belong in an existing context or need a new one? Where are the boundaries?
- **Ubiquitous language:** What terms does the domain use? Capture a glossary if not present.
- **Context mapping:** How does this context interact with others? (shared kernel, anti-corruption layer, customer/supplier?)
- **Quality attributes:** Which non-functional requirements matter most? Ask user to rank with rationale.

Output: Constraints summary written to architectural-principles.md and the design doc.

#### Planning Stage (Tactical)

Focus: *Does the plan respect the architecture?*

- **Aggregate design:** Are aggregates identified? Do they protect invariants?
- **Entity vs value object:** Are domain concepts correctly classified?
- **Dependency direction:** Do dependencies point inward (domain <- application <- infrastructure)?
- **Layer separation:** Is domain logic free from framework/infrastructure concerns?
- **Domain events:** Are cross-context communications via events, not direct calls?

Output: Architecture checklist items added to the plan.

#### Execution Stage (Implementation)

Focus: *Is the code clean and principled?*

- **SOLID:** Single responsibility, dependency inversion in particular
- **Clean code:** Meaningful names using ubiquitous language, small functions, no side effects, DRY
- **No framework leakage:** Domain layer has zero infrastructure imports
- **Repository pattern:** Data access behind abstractions

Output: Verification criteria for the sub-agent.

#### Review Stage (Compliance)

Focus: *Full check across all principles.*

All of the above, plus:
- **Consistency:** Does new code match existing patterns in the bounded context?
- **Quality attributes:** Are the prioritized attributes actually addressed?

Output: Review findings with severity (critical / important / minor).

## Integration Points — Existing Skill Modifications

Each existing skill gets a small, explicit addition at the right point in its flow.

### 1. Brainstorming

**Where:** After "Understanding the idea" questions, before "Exploring approaches"

```markdown
**Before exploring approaches:** Invoke `clean-software-design` to establish
or verify architectural principles for this design.
```

### 2. Writing Plans

**Where:** After plan structure is drafted, before finalizing tasks

```markdown
**Before finalizing the plan:** Invoke `clean-software-design` to verify
tactical alignment with architectural principles.
```

### 3. Subagent-Driven Development

**Where:** In the sub-agent task prompt, as additional context

```markdown
**For each sub-agent task prompt:** Include architectural principles from
`architectural-principles.md` and invoke `clean-software-design` reference
criteria for implementation verification.
```

### 4. Executing Plans

**Where:** Before each batch execution

```markdown
**Before each batch:** Load architectural principles from
`architectural-principles.md` as implementation constraints.
```

### 5. Requesting Code Review

**Where:** Added to the review criteria passed to the code-reviewer agent

```markdown
**Review criteria:** In addition to spec compliance and code quality,
invoke `clean-software-design` for full architectural compliance check
against `architectural-principles.md`.
```

### Summary of Changes to Existing Skills

| Skill | Change | Size |
|-------|--------|------|
| `brainstorming` | Add 2-line invocation after understanding phase | Minimal |
| `writing-plans` | Add 2-line invocation before finalizing | Minimal |
| `subagent-driven-development` | Add context loading to sub-agent prompts | Minimal |
| `executing-plans` | Add context loading before batches | Minimal |
| `requesting-code-review` | Add compliance check to review criteria | Minimal |

## What the Skill Does NOT Do

- Does not orchestrate work (that's the execution skills' job)
- Does not replace TDD (that's `test-driven-development`)
- Does not run tests or verify builds (that's `verification-before-completion`)
- Does not own the code review process (that's `requesting-code-review`)
- Focuses purely on design principles and architectural compliance

## Implementation Order

1. Create `skills/clean-software-design/SKILL.md` (workflow)
2. Create `skills/clean-software-design/reference.md` (universal principles)
3. Test skill in isolation (can it read/create architectural-principles.md?)
4. Modify `brainstorming` to invoke the skill
5. Modify `writing-plans` to invoke the skill
6. Modify `subagent-driven-development` to invoke the skill
7. Modify `executing-plans` to invoke the skill
8. Modify `requesting-code-review` to invoke the skill
9. End-to-end test: run full workflow on a sample feature
