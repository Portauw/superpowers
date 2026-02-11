# Superpowers Architecture Visualization

## Complete System Flow

```mermaid

graph TB
    User([User]) --> CC[Claude Code CLI]

    %% Plugin Loading
    CC -->|loads at startup| Plugin[.claude-plugin/plugin.json]
    CC -->|SessionStart event| Hook[hooks/session-start.sh]
    Hook -->|injects content| UsingSuperpowers[using-superpowers skill]
    User -->|/brainstorm| CmdBrainstorm["/brainstorm command"]
    User -->|/write-plan| CmdWritePlan["/write-plan command"]
    User -->|/execute-plan| CmdExecutePlan["/execute-plan command"]
    User -->|/simplify| CmdSimplify["/simplify command"]
    User -->|/compound| CmdCompound["/compound command"]
    User -->|/review-learnings| CmdReviewLearnings["/review-learnings command"]
    User -->|/ai-self-reflect| CmdAiReflection["/ai-self-reflect command"]

    %% Skill Discovery
    CC -->|uses| SkillsCore["lib/skills-core.js<br/>• findSkillsInDir<br/>• resolveSkillPath<br/>• extractFrontmatter"]
    SkillsCore -->|discovers| SkillsLib[(skills/ directory)]

    %% Commands to Skills Mapping
    CmdBrainstorm -.->|invokes| Brainstorming
    CmdWritePlan -.->|invokes| WritingPlans
    CmdExecutePlan -.->|invokes| ExecutingPlans
    CmdSimplify -.->|invokes| CodeSimplification
    CmdCompound -.->|invokes| CompoundLearning
    CmdReviewLearnings -.->|invokes| MetaLearningReview
    CmdAiReflection -.->|invokes| AiReflection

    %% Skills organized by phase
    subgraph DesignPhase[Design & Planning Skills]
        Brainstorming[brainstorming<br/>design exploration]
        OutgoingApi[outgoing-api-design<br/>API integration design]
        WritingPlans[writing-plans<br/>implementation plan]
    end

    subgraph SetupPhase[Setup Skills]
        GitWorktrees[using-git-worktrees<br/>isolated workspace]
    end

    subgraph ExecutionPhase[Execution Skills]
        ExecutingPlans[executing-plans<br/>batch with checkpoints]
        SubagentDev[subagent-driven-development<br/>parallel task execution]
        DispatchingAgents[dispatching-parallel-agents<br/>concurrent workflows]
        TDD[test-driven-development<br/>RED-GREEN-REFACTOR]
    end

    subgraph QualityPhase[Quality Skills]
        CleanDesign[clean-software-design<br/>DDD/SOLID/clean arch quality gate]
        SystematicDebug[systematic-debugging<br/>4-phase process]
        SafeRefactoring[safe-refactoring<br/>rename/delete with reference checks]
        CodeSimplification[code-simplification<br/>optional cleanup via agent]
        RequestingReview[requesting-code-review<br/>pre-review checklist]
        ReceivingReview[receiving-code-review<br/>feedback verification]
        Verification[verification-before-completion<br/>ensure it works]
    end

    subgraph CompletionPhase[Completion Skills]
        Documenting[documenting-completed-implementation<br/>update docs/plan/commit]
        FinishingBranch[finishing-a-development-branch<br/>invokes documenting + git workflow]
        ReleasingVersions[releasing-versions<br/>semver + release notes + tag]
    end

    subgraph MetaLearningPhase[Meta-Learning Skills]
        AiReflection[ai-self-reflecting<br/>automatic mistake detection]
        CompoundLearning[compound-learning<br/>quick learning capture]
        MetaLearningReview[meta-learning-review<br/>pattern detection + skill suggestions]
    end

    subgraph MetaSkills[Meta Skills]
        WritingSkills[writing-skills<br/>TDD for documentation]
    end

    %% Main Workflow Chain
    Brainstorming ==>|1a. if APIs identified| OutgoingApi
    Brainstorming ==>|1b. otherwise| WritingPlans
    OutgoingApi ==>|API design complete| WritingPlans
    WritingPlans ==>|2. plan complete| GitWorktrees
    GitWorktrees ==>|3. in clean workspace| SubagentDev
    GitWorktrees ==>|3. or batch mode| ExecutingPlans
    SubagentDev ==>|enforces during impl| TDD
    ExecutingPlans ==>|enforces during impl| TDD
    TDD ==>|optional cleanup| CodeSimplification
    CodeSimplification ==>|before verification| Verification
    TDD ==>|or skip to| Verification
    Verification ==>|optional learning| AiReflection
    Verification ==>|or to review| RequestingReview
    RequestingReview ==>|all tasks done| FinishingBranch
    FinishingBranch -->|invokes if plan exists| Documenting
    FinishingBranch ==>|after completion| CompoundLearning
    FinishingBranch -.->|if publishing| ReleasingVersions
    CompoundLearning -.->|every 10 learnings| MetaLearningReview

    %% Cross-cutting quality gate (invoked at checkpoints by other skills)
    CleanDesign -.->|checkpoint in| Brainstorming
    CleanDesign -.->|checkpoint in| WritingPlans
    CleanDesign -.->|checkpoint in| SubagentDev
    CleanDesign -.->|checkpoint in| RequestingReview

    %% Agent System
    SubagentDev -->|spawns for review| CodeReviewer[agents/code-reviewer.md<br/>2-stage review:<br/>1. spec compliance<br/>2. code quality]
    CodeSimplification -.->|if plugin available| CodeSimplifierAgent[code-simplifier agent<br/>external plugin]

    %% Supporting Files
    SystematicDebug -.->|references| SupportingFiles["Supporting Files:<br/>• condition-based-waiting.md<br/>• root-cause-tracing.md<br/>• defense-in-depth.md<br/>• example scripts"]

    %% Debugging Flow
    SystematicDebug -->|after fix| Verification

    %% Testing System
    WritingSkills -.->|uses for TDD| TestRunner[tests/run-skill-tests.sh]
    TestRunner -->|invokes headless| CC
    TestRunner -->|runs| FastTests["Fast Tests<br/>skill verification<br/>~2 minutes"]
    TestRunner -->|--integration flag| IntegrationTests[Integration Tests<br/>full workflow<br/>10-30 minutes]

    %% Styling
    classDef userClass fill:#87CEEB,stroke:#333,stroke-width:2px
    classDef pluginClass fill:#FFE4B5,stroke:#333,stroke-width:2px
    classDef skillClass fill:#E6E6FA,stroke:#333,stroke-width:2px
    classDef agentClass fill:#FFB6C1,stroke:#333,stroke-width:2px
    classDef testClass fill:#B0C4DE,stroke:#333,stroke-width:2px
    classDef workflowClass fill:#98FB98,stroke:#333,stroke-width:3px

    class User,CC userClass
    class Plugin,Hook,UsingSuperpowers pluginClass
    class Brainstorming,OutgoingApi,WritingPlans,GitWorktrees,ExecutingPlans,SubagentDev,DispatchingAgents,TDD,CleanDesign,SystematicDebug,SafeRefactoring,CodeSimplification,RequestingReview,ReceivingReview,Verification,Documenting,FinishingBranch,ReleasingVersions,AiReflection,CompoundLearning,MetaLearningReview,WritingSkills skillClass
    class CodeReviewer,CodeSimplifierAgent agentClass
    class TestRunner,FastTests,IntegrationTests testClass
```

## Workflow Sequence (Typical Development Session)

```mermaid
sequenceDiagram
    participant U as User
    participant CC as Claude Code
    participant H as Session Hook
    participant S as Skills System
    participant A as Subagent

    U->>CC: Start Claude Code
    CC->>H: Trigger SessionStart
    H->>CC: Inject using-superpowers skill
    Note over CC: Now aware of skills framework

    U->>CC: "Let's build feature X"
    CC->>S: Load brainstorming skill
    S-->>CC: Skill content
    CC->>U: Ask clarifying questions
    U->>CC: Answer questions
    CC->>S: Load clean-software-design skill (strategic checks)
    S-->>CC: Verify bounded contexts, ubiquitous language
    CC->>U: Present design in sections
    U->>CC: Approve design

    opt APIs identified during brainstorming
        CC->>S: Load outgoing-api-design skill
        S-->>CC: Skill content
        CC->>U: Present API integration design
        U->>CC: Approve API design
    end

    CC->>S: Load writing-plans skill
    S-->>CC: Skill content
    CC->>S: Load clean-software-design skill (tactical checks)
    S-->>CC: Verify dependency direction, layer separation
    CC->>U: Present implementation plan
    U->>CC: Approve plan

    CC->>S: Load using-git-worktrees skill
    S-->>CC: Skill content
    CC->>CC: Create isolated workspace

    CC->>S: Load subagent-driven-development skill
    S-->>CC: Skill content
    Note over CC,A: Per-task loop with 3 subagent types<br/>See "Subagent-Driven Development" diagram below
    CC->>CC: Execute all tasks (implement → spec review → quality review each)

    opt Substantial changes (5+ files or 100+ lines)
        CC->>S: Load code-simplification skill
        S-->>CC: Skill content
        CC->>A: Spawn code-simplifier agent (if available)
        A-->>CC: Simplified code
    end

    CC->>S: Load verification-before-completion skill
    S-->>CC: Skill content
    CC->>CC: Run tests/build
    CC->>U: Show verification results

    opt After verification
        CC->>S: Load ai-self-reflecting skill
        S-->>CC: Skill content
        CC->>CC: Analyze session for mistakes
        CC->>CC: Capture learnings automatically
    end

    CC->>S: Load finishing-a-development-branch skill
    S-->>CC: Skill content
    CC->>U: Present completion options<br/>(merge/PR/keep/discard)
    U->>CC: Choose option
    CC->>CC: Execute completion

    opt After completion
        CC->>S: Load compound-learning skill
        S-->>CC: Skill content
        CC->>CC: Quick learning capture
    end
```

## File Organization Structure

```mermaid
graph TB
    subgraph Repository["superpowers/"]
        subgraph Plugin[".claude-plugin/"]
            P1[plugin.json]
            P2[marketplace.json]
        end

        subgraph Hooks["hooks/"]
            H1[hooks.json]
            H2[session-start.sh]
            H3[skill-workflow-reminder.sh]
            H4[run-hook.cmd]
        end

        subgraph Lib["lib/"]
            L1[skills-core.js]
            L2[meta-learning-state.js]
        end

        subgraph Commands["commands/"]
            C1[brainstorm.md]
            C2[write-plan.md]
            C3[execute-plan.md]
            C4[simplify.md]
            C5[compound.md]
            C6[review-learnings.md]
            C7[ai-self-reflect.md]
        end

        subgraph Skills["skills/ (23 skills)"]
            S1[using-superpowers/SKILL.md]
            S2[brainstorming/SKILL.md]
            S3[outgoing-api-design/SKILL.md]
            S4[writing-plans/SKILL.md]
            S5[using-git-worktrees/SKILL.md]
            S6[executing-plans/SKILL.md]
            S7[subagent-driven-development/<br/>SKILL.md + prompt templates]
            S8[dispatching-parallel-agents/SKILL.md]
            S9[test-driven-development/SKILL.md]
            S10[systematic-debugging/<br/>SKILL.md + supporting files]
            S11[clean-software-design/SKILL.md]
            S12[safe-refactoring/SKILL.md]
            S13[code-simplification/SKILL.md]
            S14[requesting-code-review/SKILL.md]
            S15[receiving-code-review/SKILL.md]
            S16[verification-before-completion/SKILL.md]
            S17[documenting-completed-implementation/SKILL.md]
            S18[finishing-a-development-branch/SKILL.md]
            S19[releasing-versions/SKILL.md]
            S20[ai-self-reflecting/SKILL.md]
            S21[compound-learning/SKILL.md]
            S22[meta-learning-review/SKILL.md]
            S23[writing-skills/SKILL.md]
        end

        subgraph Agents["agents/"]
            A1[code-reviewer.md]
        end

        subgraph Tests["tests/claude-code/"]
            T1[run-skill-tests.sh]
            T2[test-helpers.sh]
            T3[test-*.sh files]
        end
    end

    Plugin -.->|loaded by| CC[Claude Code]
    Hooks -.->|triggered by| CC
    Lib -.->|used by| CC
    Commands -.->|invoke| Skills
    Skills -.->|spawn| Agents
    Tests -.->|verify| Skills
```

## Skill Discovery & Loading (CSO)

```mermaid
graph LR
    User[User: I need to fix a bug] --> Claude[Claude Code]

    Claude --> Search{Search Skills<br/>via CSO}

    Search --> Desc[Check Descriptions<br/>for triggers]
    Search --> Keywords[Scan for Keywords<br/>error messages, symptoms]
    Search --> Names[Match Skill Names<br/>verb-first patterns]

    Desc --> Match{Match Found?}
    Keywords --> Match
    Names --> Match

    Match -->|Yes| Load[Load Skill via<br/>skills-core.js]
    Match -->|No| Continue[Continue without skill]

    Load --> Parse[Parse YAML Frontmatter]
    Parse --> Strip[Strip Frontmatter]
    Strip --> Inject[Inject Content to Claude]

    Inject --> Follow[Follow Skill Instructions]

    subgraph Namespace[Namespace Resolution]
        Load --> CheckPersonal{"Personal Skill<br/>~/.claude/skills?"}
        CheckPersonal -->|Yes| UsePersonal[Use Personal]
        CheckPersonal -->|No| CheckSuperpowers{Superpowers Skill?}
        CheckSuperpowers -->|Yes| UseSuperpowers[Use Superpowers]
        CheckSuperpowers -->|No| NotFound[Not Found]
    end
```

## Testing Workflow (TDD for Skills)

```mermaid
graph TB
    Start([Creating/Editing Skill]) --> RED

    subgraph RED[RED Phase: Write Failing Test]
        R1[Create pressure scenarios]
        R2[Run WITHOUT skill]
        R3[Document baseline behavior<br/>capture rationalizations]
        R1 --> R2 --> R3
    end

    RED --> GREEN

    subgraph GREEN[GREEN Phase: Write Minimal Skill]
        G1[Write SKILL.md with<br/>YAML frontmatter]
        G2[Address specific failures<br/>from baseline]
        G3[Run scenarios WITH skill]
        G4{Agent complies?}
        G1 --> G2 --> G3 --> G4
    end

    G4 -->|No| G2
    G4 -->|Yes| REFACTOR

    subgraph REFACTOR[REFACTOR Phase: Close Loopholes]
        RF1[Identify new rationalizations]
        RF2[Add explicit counters]
        RF3[Build rationalization table]
        RF4[Create red flags list]
        RF5[Re-test]
        RF6{Bulletproof?}
        RF1 --> RF2 --> RF3 --> RF4 --> RF5 --> RF6
    end

    RF6 -->|No| RF1
    RF6 -->|Yes| Deploy[Deploy Skill]

    Deploy --> Commit[Commit to git]
    Commit --> End([Skill Ready])
```

## Subagent-Driven Development (Detailed)

The subagent-driven-development skill orchestrates implementation by spawning fresh subagents per task with a two-stage review after each. The controller (main Claude session) never implements directly — it reads the plan once, extracts all tasks, and dispatches subagents sequentially.

```mermaid
sequenceDiagram
    box rgb(52,101,164) Controller
    participant CC as Claude Code<br/>(Controller)
    end
    box rgb(92,83,138) Skills
    participant S as Skills System
    end
    box rgb(173,68,90) Agents
    participant I as Implementer<br/>Subagent
    participant SR as Spec Reviewer<br/>Subagent
    participant QR as Quality Reviewer<br/>Subagent
    end

    Note over CC: Read plan file once, extract all tasks
    CC->>CC: Create TodoWrite with all tasks

    loop For each task (sequential, never parallel)
        rect rgb(70,90,160)
            Note over CC,I: Phase 1: Implementation
            CC->>I: Dispatch with full task text + context<br/>(implementer-prompt.md)
            I->>S: Load test-driven-development
            I->>S: Load clean-software-design (execution checks)

            opt Subagent has questions
                I-->>CC: Ask questions
                CC->>I: Answer with context
            end

            I->>I: Write test (RED)
            I->>I: Write minimal code (GREEN)
            I->>I: Refactor
            I->>I: Self-review
            I->>I: Commit
            I-->>CC: Report: files changed, tests, concerns
        end

        rect rgb(180,90,60)
            Note over CC,SR: Phase 2: Spec Compliance Review
            CC->>SR: Dispatch with spec + implementer report<br/>(spec-reviewer-prompt.md)
            Note over SR: No skills loaded — independent verification
            SR->>SR: Read actual code (don't trust report)
            SR->>SR: Compare code vs requirements line-by-line

            alt Spec issues found
                SR-->>CC: ❌ Missing/extra/misunderstood requirements
                CC->>I: Fix spec gaps
                I-->>CC: Fixed
                CC->>SR: Re-review
                SR-->>CC: ✅ Spec compliant
            else All good
                SR-->>CC: ✅ Spec compliant
            end
        end

        rect rgb(50,120,130)
            Note over CC,QR: Phase 3: Code Quality Review
            CC->>QR: Dispatch with git SHAs + task summary<br/>(code-quality-reviewer-prompt.md)
            QR->>S: Load requesting-code-review (via code-reviewer agent)
            QR->>S: Load clean-software-design (full review checks)
            QR->>QR: Review quality, tests, architecture

            alt Quality issues found
                QR-->>CC: ❌ Issues: critical/important/minor
                CC->>I: Fix quality issues
                I-->>CC: Fixed
                CC->>QR: Re-review
                QR-->>CC: ✅ Approved
            else All good
                QR-->>CC: ✅ Approved
            end
        end

        CC->>CC: Mark task complete in TodoWrite
    end

    rect rgb(55,130,70)
        Note over CC,QR: Finalize
        CC->>QR: Dispatch final code-reviewer for entire implementation
        QR-->>CC: Final review results
        CC->>S: Load finishing-a-development-branch
    end
```

**Color key:**
- **Blue** = Controller (main Claude session)
- **Lavender** = Skills (loaded for guidance, not actors)
- **Pink** = Agents (subagents that do the actual work)

**Key rules:**
- **Never dispatch implementation subagents in parallel** (conflicts)
- **Never start code quality review before spec compliance passes**
- **Controller provides full task text** to subagents (they never read the plan file)
- Review loops repeat until approved (no "close enough")

**Prompt templates** (in `skills/subagent-driven-development/`):

| Template                          | Subagent Type                  | Purpose                                            |
|-----------------------------------|--------------------------------|----------------------------------------------------|
| `implementer-prompt.md`           | Task (general-purpose)         | Full implementation with TDD, self-review, commit  |
| `spec-reviewer-prompt.md`         | Task (general-purpose)         | Independent verification: code matches spec        |
| `code-quality-reviewer-prompt.md` | Task (superpowers:code-reviewer) | Code quality, tests, architecture review         |

**Skills loaded by subagents:**
- **Implementer**: `test-driven-development`, `clean-software-design` (execution checks)
- **Spec reviewer**: None (independent verification from spec text only)
- **Quality reviewer**: `requesting-code-review` (via code-reviewer agent), `clean-software-design` (full review checks)

## Legend

- **Solid thick arrows (==>)**: Main workflow sequence
- **Solid arrows (-->)**: Direct usage/invocation
- **Dashed arrows (-.->)**: References/points to
- **User layer**: Light blue
- **Plugin/Hook system**: Light orange
- **Skills**: Lavender
- **Agents**: Pink
- **Testing**: Steel blue
