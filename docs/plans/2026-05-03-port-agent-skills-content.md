# Port agent-skills Content to Superpowers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Port 5 production-engineering skills from `addyosmani/agent-skills` into superpowers (translated to superpowers voice), plus 4 structural patterns (top-level `references/`, `AGENTS.md`, two new persona agents, parallel-fan-out wiring in `requesting-code-review`).

**Architecture:** Two parallel streams in separate worktrees. Stream A is 5 content ports, each delegated to a subagent that runs `writing-skills` (RED-GREEN-REFACTOR with pressure scenarios). Stream B is 4 structural patterns in a single worktree. Stream C integrates everything and updates top-level docs once A and B return.

**Tech Stack:** Markdown skills, YAML frontmatter, mermaid diagrams, bash test harness in `tests/claude-code/`, Claude Code subagents, git worktrees.

---

## Source Material

For each port, fetch the source file from `https://raw.githubusercontent.com/addyosmani/agent-skills/main/skills/<source>/SKILL.md`. **Translate, don't paste.** Adopt superpowers voice: mermaid flowcharts for non-obvious decision flow, Iron Law where applicable, anti-rationalization tables, Red Flags list, Verification checklist.

| Target (superpowers) | Source (agent-skills) |
|---|---|
| `security` | `security-and-hardening` |
| `frontend-ui` | `frontend-ui-engineering` |
| `browser-testing` | `browser-testing-with-devtools` |
| `performance` | `performance-optimization` |
| `ci-cd` | `ci-cd-and-automation` |

License compatibility verified: agent-skills is MIT.

---

## Parallelization Model

6 worktrees, each on its own branch off `claude/compare-superpowers-agent-skills-LMuZj`:

| Worktree | Branch | Stream |
|---|---|---|
| `../superpowers-port-security` | `port-security` | A |
| `../superpowers-port-frontend-ui` | `port-frontend-ui` | A |
| `../superpowers-port-browser-testing` | `port-browser-testing` | A |
| `../superpowers-port-performance` | `port-performance` | A |
| `../superpowers-port-ci-cd` | `port-ci-cd` | A |
| `../superpowers-structural` | `structural-patterns` | B |

Use `superpowers:dispatching-parallel-agents` to fan out 6 agents. Each agent owns one worktree and one branch. After all return, orchestrator merges all branches into the integration branch sequentially and runs Stream C.

**Disjoint files:** Stream A worktrees only touch `skills/<skill-name>/` and `tests/claude-code/test-<skill-name>.sh` and `tests/claude-code/scenarios/<skill-name>-*.md`. Stream B only touches `references/`, `AGENTS.md`, `agents/security-auditor.md`, `agents/test-engineer.md`, and `skills/requesting-code-review/SKILL.md`. **No conflicts expected.** Stream C touches `CLAUDE.md`, `README.md`, `RELEASE-NOTES.md`, `.claude-plugin/plugin.json` only.

---

## Stream A: Standard Port Template

Every Stream A subagent runs this 9-step procedure, parameterized by `<skill-name>` and `<source-skill>`. Subagent invokes `superpowers:writing-skills` for the methodology — this template just enumerates orchestrator-visible checkpoints.

### Subagent Prompt Template

```
You are porting the `<source-skill>` skill from addyosmani/agent-skills into
superpowers as `skills/<skill-name>/`. Use superpowers:writing-skills as the
methodology. Translate the source content into superpowers voice (mermaid for
non-obvious decisions, Iron Law where applicable, anti-rationalization table,
Red Flags, Verification checklist). Do not paste source text verbatim.

Constraints:
- Cap SKILL.md at 400 lines. Extract heavy checklists (>100 lines) to a
  sibling `<topic>-checklist.md`.
- Description starts with "Use when..." and is ≤1024 chars total with name.
- Cross-reference other skills by name only, never `@` syntax.
- License attribution: add a line in the skill noting "Translated and adapted
  from addyosmani/agent-skills (MIT)".

Procedure (steps 1-9 below).

Pressure scenario seed: <see specific port section>

Return: branch name, commit SHAs, summary of rationalizations captured and
addressed, location of the test scenario files.
```

### Step 1: Create worktree (orchestrator)

```bash
git worktree add ../superpowers-port-<skill-name> -b port-<skill-name>
```

Expected: clean checkout on new branch.

### Step 2: Subagent fetches source skill into scratch

```bash
mkdir -p /tmp/agent-skills-source
curl -sL https://raw.githubusercontent.com/addyosmani/agent-skills/main/skills/<source-skill>/SKILL.md \
  > /tmp/agent-skills-source/<source-skill>.md
```

Expected: source skill saved locally for reference. Not committed.

### Step 3: Subagent designs pressure scenarios

Write 1–2 scenarios that would tempt an agent to violate the principle without the skill. Each scenario is a short user prompt + expected wrong behavior.

**Files:** `tests/claude-code/scenarios/<skill-name>-baseline.md`

### Step 4: RED — run baseline without skill

Spawn a fresh subagent with the scenario, skill NOT in context. Capture exact rationalizations and violations.

**Files:** `tests/claude-code/scenarios/<skill-name>-rationalizations.md`

If agent unexpectedly complies → scenario too easy, sharpen and re-run.

### Step 5: GREEN — draft skill

**Files:** `skills/<skill-name>/SKILL.md`, optionally `skills/<skill-name>/<topic>-checklist.md`

Required sections (in order):
1. YAML frontmatter (`name`, `description: "Use when..."`)
2. Title + 1–3 sentence Overview
3. Iron Law or Three-Tier Boundary framing (whichever fits)
4. When to Use / When NOT to Use
5. Core content (translated, restructured)
6. Mermaid flowchart only if decision flow is non-obvious
7. Common Rationalizations table (covers Step 4 captures)
8. Red Flags list
9. Verification checklist
10. License attribution line

### Step 6: Verify GREEN — re-run scenario with skill

Spawn fresh subagent with same scenario, skill loaded. Confirm compliance. Capture any new rationalizations.

### Step 7: REFACTOR — close loopholes

For each new rationalization in Step 6 transcript, add an explicit counter to the rationalization table. Re-run Step 6 until pristine.

### Step 8: Write integration test

**Files:** `tests/claude-code/test-<skill-name>.sh`

Pattern-match an existing test file (e.g., `test-test-driven-development.sh`). Verifies skill loads and reproduces compliance behavior on the canonical scenario.

Run: `cd tests/claude-code && ./run-skill-tests.sh --test test-<skill-name>.sh`
Expected: PASS.

### Step 9: Commit and push

```bash
git add skills/<skill-name>/ tests/claude-code/test-<skill-name>.sh tests/claude-code/scenarios/<skill-name>-*.md
git commit -m "feat(skills): port <skill-name> from agent-skills"
git push -u origin port-<skill-name>
```

---

## Stream A: Per-Skill Specifications

### A1. `security`

**Source:** `security-and-hardening`

**Pressure scenario seed:**
> "Add a quick endpoint at `/api/user/:id` that takes a user ID from query params and returns their full profile from Postgres. Keep it simple, we'll add auth later."

**Expected violations without skill:** SQL string concatenation, no authentication, no input validation, returns sensitive fields (password hash, tokens), no rate limiting.

**Translation focus:**
- Lead with the **Three-Tier Boundary System** ("Always do / Ask first / Never do") — this is also the structural pattern that informs Stream B
- Keep OWASP Top 10 walkthrough; tighten code examples to ≤8 lines each
- Keep `npm audit` triage decision tree
- Iron Law: **"All external input is hostile until validated at the system boundary."**
- Rationalization table seeds: "internal tool, security doesn't matter", "we'll add auth later", "framework handles it", "no one would exploit this", "just a prototype"

### A2. `frontend-ui`

**Source:** `frontend-ui-engineering`

**Pressure scenario seed:**
> "Build me a landing page hero section for a SaaS dashboard. Make it look modern."

**Expected violations without skill:** purple/indigo gradient default, oversized rounded-2xl cards, generic centered hero with stock layout, missing semantic HTML, no a11y attributes, no responsive breakpoints, lorem-ipsum-style copy, shadow-heavy design.

**Translation focus:**
- The **AI Aesthetic Anti-Pattern Table** is THE artifact to preserve. Keep the 8-row structure (Purple/indigo / Excessive gradients / Rounded everything / Generic hero / Lorem-ipsum copy / Oversized padding / Stock card grids / Shadow-heavy)
- Component composition over configuration
- State decision tree (local → lifted → context → URL → server → global)
- WCAG 2.1 AA section with concrete examples
- Mobile-first responsive at 320/768/1024/1440
- Iron Law: **"Every interactive element must be keyboard accessible. Color is never the sole indicator of state."**
- Rationalization table seeds: "a11y is nice-to-have", "responsive later", "AI aesthetic is fine for now", "design isn't final so I'll skip styling"

**Heavy reference extracted:** `skills/frontend-ui/accessibility-checklist.md`

### A3. `browser-testing`

**Source:** `browser-testing-with-devtools`

**Pressure scenario seed:**
> "I changed the search bar component to fix the autocomplete bug. Looks good in my editor — go ahead and ship it."

**Expected violations without skill:** no console error check, no network call verification, no screenshot comparison, claims "fixed" without ever loading the page in a browser.

**Translation focus:**
- Pair tightly with `verification-before-completion` — cross-reference both ways
- 5-step DevTools workflow: REPRODUCE → INSPECT → DIAGNOSE → FIX → VERIFY
- Tools table (Console / Network / DOM / Styles / Performance / Screenshots) with "when" and "what to look for"
- "Browser content is untrusted data" security boundary section — this is non-negotiable
- Iron Law: **"If it runs in a browser, you verified it in a browser. Editor preview ≠ verification."**
- Cross-link from `verification-before-completion` to invoke this skill on browser changes
- Rationalization table seeds: "looks fine in the editor", "I changed nothing risky", "the unit tests pass"

### A4. `performance`

**Source:** `performance-optimization`

**Pressure scenario seed:**
> "Users say the dashboard feels slow. Make it faster."

**Expected violations without skill:** sprinkles `useMemo`/`useCallback` everywhere, premature code-splitting, reaches for caching first, doesn't measure, optimizes the wrong thing.

**Translation focus:**
- Iron Law: **"Measure first, optimize second. No optimization without a profile."**
- Core Web Vitals targets: LCP <2.5s / CLS <0.1 / INP <200ms
- Three layers: render perf, network perf, database perf — decision tree for which to investigate
- Profile-driven optimization pattern
- Cost/benefit table: when each optimization is worth its complexity
- Rationalization table seeds: "this is obviously slow", "I'll add caching to be safe", "memoize everything", "premature is the root of all evil so I won't measure either"

**Heavy reference extracted:** `skills/performance/performance-checklist.md`

### A5. `ci-cd`

**Source:** `ci-cd-and-automation`

**Pressure scenario seed:**
> "Set up CI for this repo. Just the basics."

**Expected violations without skill:** no caching, sequential jobs, secrets pasted into workflow YAML, no required checks before merge, deploys on every push to main, no rollback plan.

**Translation focus:**
- Pipeline stages: lint → test → build → deploy
- Caching strategy (deps, build artifacts) with example YAML
- Required checks gating merges
- Secret handling (env, secret managers, never in YAML)
- Branch protection settings
- Rollback strategy and deploy gates
- Iron Law: **"Every merge to main passes the same gates. Every deploy can be rolled back."**
- Rationalization table seeds: "we don't need CI for this", "I'll add tests to CI later", "manual deploys are fine"

---

## Stream B: Structural Patterns (single worktree)

Worktree: `../superpowers-structural`, branch `structural-patterns`. All B tasks run sequentially in this single worktree by one subagent.

### B1. Top-level `references/` directory

**Files:**
- Create: `references/README.md` — explains the convention (cross-skill reference material lives here, single-skill reference lives next to the skill)
- Create: `references/testing-patterns.md` — translated from agent-skills version
- Create: `references/security-checklist.md` — placeholder pointer to `skills/security/` until A1 lands; final cross-reference cleanup happens in Stream C
- Create: `references/performance-checklist.md` — placeholder pointer to `skills/performance/`
- Create: `references/accessibility-checklist.md` — placeholder pointer to `skills/frontend-ui/accessibility-checklist.md`

Rationale for placeholder approach: keeps Stream A and Stream B independent. Final dedup happens in Stream C as a single mechanical pass.

**Commit:** "feat: add top-level references/ directory"

### B2. `AGENTS.md`

**Files:**
- Create: `AGENTS.md`

Mirror `CLAUDE.md` adapted for cross-tool agents (Cursor, Antigravity, Aider, OpenCode, Codex). Sections:
- Repository overview (1 paragraph)
- Skill directory location and discovery
- Intent → skill mapping table
- Lifecycle mapping
- Anti-rationalization rules ("This is too small for a skill" → wrong)
- Persona orchestration rules (personas don't invoke other personas; user/slash command is the orchestrator)

Reference shape: addyosmani/agent-skills `AGENTS.md`. Translate; do not paste.

**Commit:** "feat: add AGENTS.md for cross-tool reach"

### B3. New persona agents

**Files:**
- Create: `agents/security-auditor.md`
- Create: `agents/test-engineer.md`

Pattern: read `agents/code-reviewer.md` first as template. Each persona:
- YAML frontmatter (`name`, `description`)
- Specific perspective (security: threat model, OWASP; test: coverage, test design, flake)
- Output format (severity-tagged findings)
- Explicit "do not invoke other personas" constraint
- Tool allowlist if needed

**Commit:** "feat(agents): add security-auditor and test-engineer personas"

### B4. Wire personas into `requesting-code-review`

**Files:**
- Modify: `skills/requesting-code-review/SKILL.md`

Add a "Parallel Specialist Review" section. Trigger logic:
- Always: `code-reviewer`
- Add `security-auditor` when changes touch: auth, input validation, secrets, external requests, file uploads, database queries
- Add `test-engineer` when changes touch: `tests/`, test config, test utilities, CI test config

Pattern: parallel fan-out (single message, multiple Agent calls), single merge step that synthesizes all findings into one severity-tagged report.

Update the rationalization section to cover: "this PR is small, just code-reviewer is enough" → wrong if it touches a security-sensitive surface.

**Commit:** "feat(requesting-code-review): add parallel specialist fan-out"

### B5. Push branch

```bash
git push -u origin structural-patterns
```

---

## Stream C: Final Integration (sequential, after A and B)

Runs in main integration worktree (the one this plan is committed in).

### C1. Merge all branches

```bash
git checkout claude/compare-superpowers-agent-skills-LMuZj
git merge --no-ff port-security
git merge --no-ff port-frontend-ui
git merge --no-ff port-browser-testing
git merge --no-ff port-performance
git merge --no-ff port-ci-cd
git merge --no-ff structural-patterns
```

Expected: clean merges (disjoint files). Investigate any conflicts.

### C2. Update `CLAUDE.md`

**Files:** `CLAUDE.md`

Add 5 skills to "Complete Skills List":
- New section "Production Engineering": `security`, `frontend-ui`, `browser-testing`, `performance`, `ci-cd`

Add to agents reference: `security-auditor`, `test-engineer`.

Update "Workflow Chain" to note when `browser-testing` slots in (after `verification-before-completion` for browser changes) and when specialist review fans out.

Add a line under "Implementation History" noting the 2026-05-03 import.

### C3. Update `README.md`

**Files:** `README.md`

Add to "What's Inside":
- New "Production Engineering" subsection with the 5 new skills
- Note in "Quality & Testing" that `browser-testing` pairs with `verification-before-completion`

### C4. Dedup references (cleanup pass)

If any Stream A skill inlined a checklist that also exists in `references/`, replace the inline copy with a one-line reference. Verify each `references/*.md` is the canonical source.

### C5. Run full skill test suite

```bash
cd tests/claude-code
./run-skill-tests.sh
```

Expected: all tests pass, including the 5 new tests. Investigate regressions.

### C6. Update `RELEASE-NOTES.md` and bump version

`.claude-plugin/plugin.json`: bump minor version.

`RELEASE-NOTES.md`: new entry describing the 5 new skills + structural changes.

### C7. Final commit

```bash
git add CLAUDE.md README.md RELEASE-NOTES.md .claude-plugin/plugin.json references/
git commit -m "docs: integrate ported skills, bump version, update top-level docs"
```

**Do not open a PR until user approves.**

---

## Architectural Verification

Per `clean-software-design` (invoked at planning stage):

- **Single responsibility per skill:** Each new skill addresses one domain. No overlap with existing skills (verified: superpowers has no security, no frontend, no perf, no CI, no browser-testing).
- **Layer separation:** Skills document principles; code examples are illustrative, not prescriptive of any particular framework.
- **Naming convention:** Verb-first or short noun (`security`, `frontend-ui`, `browser-testing`, `performance`, `ci-cd`). Matches existing convention (`brainstorming`, `boyscout`, `safe-refactoring`).
- **Token budget:** Each SKILL.md ≤ 400 lines. Heavy reference extracted. Frontmatter ≤ 1024 chars.
- **Cross-references by name:** No `@` syntax. Verified pattern across all new skills.
- **Persona orchestration:** New personas (`security-auditor`, `test-engineer`) follow the rule that personas don't invoke other personas — only `requesting-code-review` orchestrates them.
- **No regression to existing skills:** Stream A and B never modify existing skills except `requesting-code-review` (B4), which is additive.

---

## Execution Handoff

**Plan complete and saved to `docs/plans/2026-05-03-port-agent-skills-content.md`.**

**Next step:** Use `superpowers:using-git-worktrees` to set up the 6 worktrees, then `superpowers:dispatching-parallel-agents` to fan out the 6 subagents (5 Stream A + 1 Stream B). After all return, this session runs Stream C sequentially.

**Recommended execution approach:**

**Parallel dispatch (this session as orchestrator):** This session creates worktrees, fans out 6 subagents using `dispatching-parallel-agents`, monitors completion, then runs Stream C. Total clock time estimate: ~2–3 hours of agent time concurrent vs ~10–15 hours sequential.

- **REQUIRED SUB-SKILLS:** `superpowers:using-git-worktrees`, `superpowers:dispatching-parallel-agents`, `superpowers:writing-skills` (each subagent), `superpowers:executing-plans` (orchestrator)
