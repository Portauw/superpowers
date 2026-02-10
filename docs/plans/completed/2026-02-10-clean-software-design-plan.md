# Clean Software Design Skill — Implementation Plan

> **Status:** ✅ COMPLETED - 2026-02-10
>
> **Implementation:** Created cross-cutting quality gate skill with SKILL.md workflow, reference.md universal principles, baseline tests, and integration into 5 existing workflow skills (brainstorming, writing-plans, subagent-driven-development, executing-plans, requesting-code-review).

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a cross-cutting quality gate skill that enforces DDD, clean architecture, SOLID, and clean code principles throughout the development workflow — invoked explicitly by existing skills at their checkpoints.

**Architecture:** Single skill (`clean-software-design`) with a reference file for universal principles. Reads/creates a project-level `docs/architectural-principles.md` for project-specific context. Integrated into 5 existing skills via explicit invocation lines.

**Tech Stack:** Markdown skills, bash test scripts, Claude Code CLI for testing

**Design doc:** `docs/plans/2026-02-10-clean-software-design.md`

---

## Task 1: RED Phase — Write Baseline Test File

**Files:**
- Create: `tests/claude-code/test-clean-software-design.sh`

**Step 1: Create the test file with baseline scenarios**

```bash
#!/bin/bash

# Test clean-software-design skill with pressure scenarios

source "$(dirname "$0")/test-helpers.sh"

# Setup a test repo with a project that has NO architectural-principles.md
setup_test_project() {
    local test_dir=$(create_test_project)
    cd "$test_dir"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create a CLAUDE.md with no architecture reference
    cat > "$test_dir/CLAUDE.md" << 'EOF'
# Project

A simple e-commerce application.
EOF

    # Create some domain code with DDD violations
    mkdir -p "$test_dir/src"
    cat > "$test_dir/src/order-service.js" << 'EOF'
const db = require('./database');

// Domain logic mixed with infrastructure
function createOrder(userId, items) {
    const user = db.query('SELECT * FROM users WHERE id = ?', [userId]);
    const total = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    const orderId = db.query('INSERT INTO orders (user_id, total) VALUES (?, ?)', [userId, total]);
    db.query('INSERT INTO audit_log (action, order_id) VALUES (?, ?)', ['create', orderId]);
    return { id: orderId, total };
}

module.exports = { createOrder };
EOF

    git add -A
    git commit -q -m "Initial commit"
    echo "$test_dir"
}

# Pressure Scenario 1: Brainstorming without DDD awareness
# Expected WITHOUT skill: Agent discusses features without asking about bounded contexts,
# ubiquitous language, or quality attributes
test_brainstorming_no_ddd() {
    local test_dir=$(setup_test_project)

    local prompt="I want to add a payment processing feature to the e-commerce app in $test_dir. \
The app currently has an order service. Let's brainstorm how to build this."

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120)

    echo "BASELINE RESPONSE (first 30 lines):"
    echo "$response" | head -30
    echo ""

    # Check if agent naturally considers DDD concepts
    local ddd_mentions=0
    echo "$response" | grep -qi "bounded context" && ddd_mentions=$((ddd_mentions + 1))
    echo "$response" | grep -qi "ubiquitous language" && ddd_mentions=$((ddd_mentions + 1))
    echo "$response" | grep -qi "aggregate" && ddd_mentions=$((ddd_mentions + 1))
    echo "$response" | grep -qi "quality attribute" && ddd_mentions=$((ddd_mentions + 1))
    echo "$response" | grep -qi "architectural.principles" && ddd_mentions=$((ddd_mentions + 1))

    echo "DDD concept mentions: $ddd_mentions / 5"

    if [ "$ddd_mentions" -lt 2 ]; then
        echo "BASELINE: Agent did not systematically consider DDD principles (expected)"
    else
        echo "NOTE: Agent naturally mentioned DDD concepts ($ddd_mentions/5)"
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Pressure Scenario 2: Code review without architectural principles check
# Expected WITHOUT skill: Agent reviews code quality but misses DDD violations
# (infrastructure in domain, no bounded context separation)
test_review_no_architecture_check() {
    local test_dir=$(setup_test_project)

    local prompt="Please review the code in $test_dir/src/order-service.js. \
Is this code ready for production?"

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120)

    echo "BASELINE RESPONSE (first 30 lines):"
    echo "$response" | head -30
    echo ""

    # Check if agent catches architectural issues
    local arch_mentions=0
    echo "$response" | grep -qi "dependency.*direction\|inward.*depend\|depend.*inward" && arch_mentions=$((arch_mentions + 1))
    echo "$response" | grep -qi "domain.*infrastructure\|infrastructure.*domain\|layer.*separation" && arch_mentions=$((arch_mentions + 1))
    echo "$response" | grep -qi "repository.*pattern\|abstract.*data.*access" && arch_mentions=$((arch_mentions + 1))
    echo "$response" | grep -qi "single.*responsib\|SRP\|SOLID" && arch_mentions=$((arch_mentions + 1))

    echo "Architecture issue mentions: $arch_mentions / 4"

    if [ "$arch_mentions" -lt 2 ]; then
        echo "BASELINE: Agent did not systematically check architectural principles (expected)"
    else
        echo "NOTE: Agent naturally caught architectural issues ($arch_mentions/4)"
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Pressure Scenario 3: Does agent look for/create architectural-principles.md?
# Expected WITHOUT skill: Agent does not check for or suggest creating the file
test_no_principles_file_awareness() {
    local test_dir=$(setup_test_project)

    local prompt="I'm about to start building a new feature in $test_dir. \
Before I write code, is there anything I should set up or document first?"

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120)

    echo "BASELINE RESPONSE (first 30 lines):"
    echo "$response" | head -30
    echo ""

    if echo "$response" | grep -qi "architectural.principles\|architecture.*doc\|principles.*file"; then
        echo "NOTE: Agent suggested architectural documentation without skill"
    else
        echo "BASELINE: Agent did not suggest architectural principles documentation (expected)"
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Run baseline tests (RED phase)
echo "===== RED PHASE: Baseline Testing (No Skill) ====="
echo ""

echo "Test 1: Brainstorming without DDD awareness"
echo "============================================="
test_brainstorming_no_ddd
echo ""

echo "Test 2: Code review without architectural principles"
echo "===================================================="
test_review_no_architecture_check
echo ""

echo "Test 3: No architectural-principles.md awareness"
echo "================================================="
test_no_principles_file_awareness
echo ""

echo "===== BASELINE COMPLETE ====="
echo "Document observed rationalizations and failures before writing skill."
```

**Step 2: Make the test file executable**

Run: `chmod +x tests/claude-code/test-clean-software-design.sh`

**Step 3: Commit the test file**

```bash
git add tests/claude-code/test-clean-software-design.sh
git commit -m "test: add baseline tests for clean-software-design skill (RED phase)"
```

---

## Task 2: RED Phase — Run Baseline Tests

**Step 1: Run the baseline tests**

Run: `cd ~/Dev/superpowers && ./tests/claude-code/run-skill-tests.sh --test test-clean-software-design.sh --verbose`

Expected: Tests document that agents do NOT systematically consider DDD, SOLID, or architectural principles without the skill.

**Step 2: Document observed baseline behavior**

Record in a scratch note:
- What DDD concepts did the agent miss?
- What architectural violations were overlooked?
- Did the agent suggest creating architectural documentation?
- What rationalizations were used? (e.g., "the code looks fine", "this is a simple function")

---

## Task 3: GREEN Phase — Create reference.md

**Files:**
- Create: `skills/clean-software-design/reference.md`

**Step 1: Create the reference file with all universal principles**

This file contains the opinionated defaults — DDD strategic, DDD tactical, clean architecture, SOLID, and clean code principles. It is loaded by sub-agents as context when they need verification criteria.

Content should cover (see design doc `docs/plans/2026-02-10-clean-software-design.md` Section "Principle Categories" for full list):

**DDD Strategic Patterns:**
- Bounded contexts: definition, identification questions, boundaries
- Ubiquitous language: why it matters, how to capture, glossary format
- Context mapping: relationship types (shared kernel, ACL, customer/supplier, conformist)
- Anti-corruption layers: when needed, how to implement

**DDD Tactical Patterns:**
- Aggregates: consistency boundaries, root entity, transactional scope
- Entities: identity-based, lifecycle, mutable state
- Value objects: equality by value, immutable, no identity
- Domain events: cross-context communication, eventual consistency
- Repositories: abstraction over data access, collection semantics
- Domain services: stateless operations that don't belong to entities

**Clean Architecture:**
- Dependency rule: always point inward (infrastructure → application → domain)
- Layer separation: domain (pure business logic, no imports), application (use cases, orchestration), infrastructure (frameworks, DB, external)
- Ports & adapters: interfaces in domain, implementations in infrastructure
- No framework leakage: domain layer has zero framework imports

**SOLID Principles:**
- Single Responsibility: one reason to change
- Open/Closed: extend behavior without modifying existing code
- Liskov Substitution: subtypes must be substitutable
- Interface Segregation: small, focused interfaces
- Dependency Inversion: depend on abstractions, not concretions

**Clean Code:**
- Naming: meaningful, intention-revealing, using ubiquitous language
- Functions: small (max ~20 lines), single level of abstraction, no side effects
- DRY: eliminate duplication of knowledge (not just code)
- Single level of abstraction per function
- Error handling: use exceptions, not error codes; don't return null

**Step 2: Commit**

```bash
git add skills/clean-software-design/reference.md
git commit -m "feat: add universal principles reference for clean-software-design"
```

---

## Task 4: GREEN Phase — Create SKILL.md

**Files:**
- Create: `skills/clean-software-design/SKILL.md`

**Step 1: Write the skill workflow**

The SKILL.md defines:
- YAML frontmatter with name and description (triggering conditions only, no workflow summary)
- Core workflow: check CLAUDE.md → read/create architectural-principles.md → verify for current stage
- Stage-specific checks (brainstorming, planning, execution, review)
- How to store/update architectural-principles.md

Key constraints:
- Description starts with "Use when..." and only describes triggering conditions
- Concise — workflow steps, not verbose explanations
- References `reference.md` for deep principle content
- Defines the `architectural-principles.md` scaffold template

Use the design doc (`docs/plans/2026-02-10-clean-software-design.md`) sections "Skill Behavior" and "Stage-Specific Checks" as the source for content.

**Step 2: Commit**

```bash
git add skills/clean-software-design/SKILL.md
git commit -m "feat: add clean-software-design skill workflow"
```

---

## Task 5: GREEN Phase — Run Tests WITH Skill

**Step 1: Run the same baseline tests**

Run: `cd ~/Dev/superpowers && ./tests/claude-code/run-skill-tests.sh --test test-clean-software-design.sh --verbose`

**Step 2: Verify improvement**

Compare results with baseline from Task 2:
- Does the agent now consider DDD principles during brainstorming?
- Does the agent catch architectural violations during review?
- Does the agent check for/suggest architectural-principles.md?

**Step 3: If tests don't show improvement, iterate on SKILL.md**

Adjust skill content to address specific baseline failures that weren't fixed. Re-run tests.

---

## Task 6: REFACTOR Phase — Close Loopholes

**Step 1: Identify new rationalizations from Task 5 testing**

Look for:
- Agent loaded skill but skipped certain checks ("this project is too small for DDD")
- Agent mentioned principles but didn't act on violations
- Agent didn't create/update architectural-principles.md

**Step 2: Add explicit counters to SKILL.md**

For each rationalization found, add an explicit counter. For example:

| Rationalization | Counter |
|----------------|---------|
| "This is too simple for DDD" | All projects benefit from clear boundaries. Check anyway. |
| "I'll add architecture docs later" | Create architectural-principles.md NOW, even minimal. |
| "The code works fine" | Working code can still violate principles. Check reference.md. |

**Step 3: Re-run tests to verify**

Run: `cd ~/Dev/superpowers && ./tests/claude-code/run-skill-tests.sh --test test-clean-software-design.sh --verbose`

**Step 4: Commit**

```bash
git add skills/clean-software-design/SKILL.md
git commit -m "refactor: close loopholes in clean-software-design skill"
```

---

## Task 7: Integrate with Brainstorming Skill

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Step 1: Add invocation line**

In `skills/brainstorming/SKILL.md`, in "## The Process" section, after the "Understanding the idea" block (line 154) and before "Exploring approaches" (line 156), add:

```markdown
**Architectural principles check:**
- Invoke `clean-software-design` to establish or verify architectural principles before exploring approaches
```

**Step 2: Verify skill file is valid**

Run: `cd ~/Dev/superpowers && node -e "const s = require('./lib/skills-core.js'); console.log(s.extractFrontmatter(require('fs').readFileSync('skills/brainstorming/SKILL.md', 'utf8')))"`

Expected: Frontmatter parses correctly, no errors.

**Step 3: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat: integrate clean-software-design into brainstorming skill"
```

---

## Task 8: Integrate with Writing Plans Skill

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

**Step 1: Add invocation line**

In `skills/writing-plans/SKILL.md`, after "**Save plans to:**" (line 16) and before "## Bite-Sized Task Granularity" (line 18), add:

```markdown
**Before finalizing the plan:** Invoke `clean-software-design` to verify tactical alignment with architectural principles (dependency direction, aggregate boundaries, layer separation).
```

**Step 2: Verify skill file is valid**

Run: `cd ~/Dev/superpowers && node -e "const s = require('./lib/skills-core.js'); console.log(s.extractFrontmatter(require('fs').readFileSync('skills/writing-plans/SKILL.md', 'utf8')))"`

**Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat: integrate clean-software-design into writing-plans skill"
```

---

## Task 9: Integrate with Subagent-Driven Development Skill

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

**Step 1: Add to "Subagents should use" section**

In `skills/subagent-driven-development/SKILL.md`, in the "## Integration" section, after line 237 (`superpowers:test-driven-development`), add:

```markdown
- **superpowers:clean-software-design** - Subagents verify implementation against architectural principles and clean code standards
```

**Step 2: Verify skill file is valid**

Run: `cd ~/Dev/superpowers && node -e "const s = require('./lib/skills-core.js'); console.log(s.extractFrontmatter(require('fs').readFileSync('skills/subagent-driven-development/SKILL.md', 'utf8')))"`

**Step 3: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "feat: integrate clean-software-design into subagent-driven-development skill"
```

---

## Task 10: Integrate with Executing Plans Skill

**Files:**
- Modify: `skills/executing-plans/SKILL.md`

**Step 1: Add to "Remember" section**

In `skills/executing-plans/SKILL.md`, in the "## Remember" section (line 74), add a new bullet:

```markdown
- Check `architectural-principles.md` if present — use `clean-software-design` for compliance verification
```

**Step 2: Verify skill file is valid**

Run: `cd ~/Dev/superpowers && node -e "const s = require('./lib/skills-core.js'); console.log(s.extractFrontmatter(require('fs').readFileSync('skills/executing-plans/SKILL.md', 'utf8')))"`

**Step 3: Commit**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "feat: integrate clean-software-design into executing-plans skill"
```

---

## Task 11: Integrate with Requesting Code Review Skill

**Files:**
- Modify: `skills/requesting-code-review/SKILL.md`

**Step 1: Add new self-review checklist item**

In `skills/requesting-code-review/SKILL.md`, after "### 1. Code Simplification (Optional)" section (line 30), add a new section:

```markdown
### 2. Architectural Compliance (Optional)

**Consider:** Use `clean-software-design` to verify architectural compliance against `architectural-principles.md` before requesting review. Catches DDD violations, dependency direction issues, and SOLID breaches.
```

Then renumber the existing sections: "### 2. Proactive Cleanup" → "### 3. Proactive Cleanup", etc.

**Step 2: Verify skill file is valid**

Run: `cd ~/Dev/superpowers && node -e "const s = require('./lib/skills-core.js'); console.log(s.extractFrontmatter(require('fs').readFileSync('skills/requesting-code-review/SKILL.md', 'utf8')))"`

**Step 3: Commit**

```bash
git add skills/requesting-code-review/SKILL.md
git commit -m "feat: integrate clean-software-design into requesting-code-review skill"
```

---

## Task 12: Final Verification

**Step 1: Run all skill tests**

Run: `cd ~/Dev/superpowers && ./tests/claude-code/run-skill-tests.sh`

Expected: All existing tests still pass. No regressions from the skill modifications.

**Step 2: Run clean-software-design specific tests**

Run: `cd ~/Dev/superpowers && ./tests/claude-code/run-skill-tests.sh --test test-clean-software-design.sh --verbose`

Expected: All scenarios show improvement over baseline.

**Step 3: Verify skill discovery**

Run: `cd ~/Dev/superpowers && claude -p "I'm about to implement a new feature. What skills should I use?"`

Expected: `clean-software-design` appears in the suggested skills (CSO check).

**Step 4: Final commit if any adjustments needed**

```bash
git add -A
git commit -m "test: verify clean-software-design skill integration"
```
