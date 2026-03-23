---
name: outside-voice
description: "Use when you need an independent second opinion from a different AI model on a plan, code review, architecture decision, or any analysis where cross-model agreement strengthens confidence. Uses opencode CLI to dispatch to any configured model (Gemini, GPT, Claude variants, etc.) with structured output."
---

# Outside Voice — Cross-Model Second Opinion

Get an independent opinion from a different AI system. Two models agreeing = high
confidence. Disagreement = worth investigating.

---

## Step 0: Check opencode availability

```bash
which opencode 2>/dev/null && echo "FOUND" || echo "NOT_FOUND"
```

If `NOT_FOUND`: stop and tell the user:
"opencode CLI not found. Install it: https://github.com/anthropics/opencode"

List available models:

```bash
opencode models 2>/dev/null | grep -v "^warn:"
```

Store the model list — you'll need it in Step 1.

---

## Step 1: Determine role and model

### 1a: Detect role from context

Parse the user's input to determine the role:

| Role | Trigger | Prompt style |
|------|---------|-------------|
| **plan-review** | Plan file exists, user asks to review a plan | "Find what the review missed" |
| **code-review** | Branch has a diff | "Independent code review" |
| **challenge** | User says "challenge", "break", "adversarial" | "Try to break this code" |
| **consult** | Anything else | Pass user's prompt directly |

### 1b: Select model

If the user specified a model (e.g., `/outside-voice gemini` or `/outside-voice gpt-5-nano`),
match it against the available models list. Use substring matching against the model
list from Step 0 — `gemini` matches `trellis/gemini-3.1-pro-preview`, `gpt` matches
`opencode/gpt-5-nano`, etc. If multiple models match (e.g., `claude` matches several
Anthropic models), show the matches and ask the user to pick one.

If no model specified, use AskUserQuestion to let the user pick:

```
Which outside voice? Available models:
<list non-anthropic models from Step 0, lettered A, B, C...>
X) All non-Anthropic models in parallel (compare findings)
```

Exclude Anthropic models from the default list — the point of an outside voice is a
*different* model family. If the user explicitly asks for an Anthropic model, allow it.

### 1c: Multiple models

If the user chose "All" or specified multiple models (e.g., `/outside-voice gemini gpt`),
you'll dispatch to each in parallel in Step 3. Warn the user about cost: "Running N
models in parallel — each will consume tokens independently."

---

## Step 1d: Skill pass-through (optional)

If the user names a skill (e.g., `/outside-voice gemini with cso`,
`/outside-voice gpt review`), use opencode's `--command` flag to invoke it directly:

```bash
opencode run --model "<provider/model>" --format json --command "/<skill-name>" "<user's message>"
```

The model discovers the skill via `.agents/skills/` (same as when running interactively),
reads it, and follows it with full tool access. No need to read or inject the skill
content into the prompt — opencode handles skill loading natively.

**Skill name mapping:** Skills in `.agents/skills/` use `gstack-` prefixed names.
If the user says "cso", the command is `/gstack-cso`. If they say "review", try
`/gstack-review`. Check with:
```bash
ls .agents/skills/ | grep -i "<name>"
```

When a skill is provided, **skip Step 2** (prompt construction) — the skill IS the
prompt. Go directly to Step 3 with the `--command` flag.

---

## Step 1d: Skill pass-through (optional)

If the user names a skill (e.g., `/outside-voice gemini with cso`,
`/outside-voice gpt review`), include the skill name in the prompt sent to
opencode. The outside model has its own `skill` tool and will load the skill
natively from `.agents/skills/` — no need to read or inject skill content yourself.

Just reference the skill by name in the prompt:
```
"Use the review skill to review this codebase"
"Run the cso skill for a security audit"
```

The model will invoke its `skill` tool, get the full SKILL.md content, and follow it.

**When a skill is provided, skip Step 2** — the skill IS the methodology. Go directly
to Step 3, passing the skill reference as part of the message.

---

## Step 2: Construct the prompt (only when no skill is provided)

The outside model has NO conversation context. Everything it needs must be in the prompt.

### For plan-review:

Read the plan file. If content exceeds 30KB, truncate and note it.

```
You are a brutally honest technical reviewer. You are reviewing a plan that has
already been through a detailed review. Your job is NOT to repeat that review.
Find what it missed:
- Logical gaps and unstated assumptions
- Overcomplexity (is there a fundamentally simpler approach?)
- Feasibility risks taken for granted
- Missing dependencies or sequencing issues
- Strategic miscalibration (is this the right thing to build?)

Be direct. Be terse. No compliments. Just the problems.

Respond with a structured list. For each finding use this format:
SEVERITY: critical|major|minor
TOPIC: <short label>
DETAIL: <explanation>

End with:
OVERALL: pass|conditional|fail
SUMMARY: <one line>

THE PLAN:
<plan content>
```

### For code-review:

Detect the base branch dynamically, then generate the diff:
```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")
git diff "$BASE"..HEAD 2>/dev/null || git diff HEAD~5..HEAD
```

```
You are an expert code reviewer examining a diff. Find:
- Bugs, logic errors, off-by-one mistakes
- Security vulnerabilities (injection, auth bypass, data exposure)
- Race conditions, resource leaks, error handling gaps
- API misuse or contract violations

Be direct. No compliments. Just the problems.

For each finding:
SEVERITY: critical|major|minor
FILE: <path>
DETAIL: <explanation>

End with:
OVERALL: pass|conditional|fail
SUMMARY: <one line>

THE DIFF:
<diff content>
```

### For challenge:

```
Your job is to find ways this code will fail in production. Think like an attacker
and a chaos engineer. Find edge cases, race conditions, security holes, resource
leaks, and silent data corruption paths. Be adversarial. Be thorough.
No compliments — just the problems.

For each attack vector:
SEVERITY: critical|major|minor
VECTOR: <attack type>
EXPLOIT: <how to exploit it>

End with:
RISK: high|medium|low
SUMMARY: <one line>

THE CODE:
<diff or file content>
```

### For consult:

Pass the user's prompt directly. Prepend:
```
Answer concisely and directly. No preamble.
```

---

## Step 3: Dispatch

### With a skill (from Step 1d):

```bash
opencode run --model "<provider/model>" --format json "Use the <skill-name> skill to <user's task description>" 2>/dev/null
```

Use `timeout: 300000` (5 minutes). The model will invoke its `skill` tool, load the
full SKILL.md, and follow it with full tool access (read files, run bash, search code).

### Without a skill (prompt from Step 2):

Write the constructed prompt to a temp file to avoid shell escaping issues:

```bash
PROMPT_FILE=$(mktemp /tmp/ov-prompt-XXXXXX.txt)
```

Write the prompt content to `$PROMPT_FILE`. Then:

```bash
opencode run --model "<provider/model>" --format json "$(cat $PROMPT_FILE)" 2>/dev/null
```

Use `timeout: 300000` (5 minutes).

**Note:** `--format json` controls how *opencode wraps* its output (as JSONL events),
not the format requested from the model. The model prompt asks for structured text
(SEVERITY/TOPIC/DETAIL). These are two separate concerns.

Parse the JSONL output. Each line is a JSON event. Extract:
- `type: "text"` events → concatenate `.part.text` for the full response
- `type: "step_finish"` → extract `.part.tokens` for token usage and `.part.cost` for cost

Use this inline Python parser to extract the response:
```bash
... | python3 -c "
import sys, json
texts, tokens = [], {}
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        obj = json.loads(line)
        t = obj.get('type','')
        if t == 'text': texts.append(obj['part']['text'])
        elif t == 'step_finish': tokens = obj['part'].get('tokens', {})
    except: pass
print(''.join(texts))
if tokens: print(f'\\ntokens: {tokens.get(\"total\", 0)}')
"
```

### Multiple models (parallel):

Dispatch each model as a separate Bash call, all in the same message (parallel execution).
Each writes to its own temp file. Collect all results before presenting.

### Fallback:

If opencode fails for a model (auth error, timeout, etc.), fall back to dispatching a
Claude subagent via the Agent tool. Use a different model than the current session
(e.g., if running on Opus, dispatch Sonnet, and vice versa). The subagent gets a fresh
context — genuine independence.

---

## Step 4: Present results

### Single model:

```
OUTSIDE VOICE (<model name>):
════════════════════════════════════════════════════════════
<full response text, verbatim>
════════════════════════════════════════════════════════════
Tokens: <input + output> | Cost: $<cost>
```

### Multiple models:

Present each model's output in its own block, then synthesize:

```
CROSS-MODEL ANALYSIS:
  All found:           [findings that overlap across models]
  Only <Model A> found: [unique findings]
  Only <Model B> found: [unique findings]
  Agreement rate:      X% (N/M unique findings overlap)
```

### Cross-model tension

If the outside voice disagrees with your own earlier analysis in this conversation:

```
CROSS-MODEL TENSION:
  [Topic]: You (Claude) said X. Outside voice says Y. [Your assessment.]
```

For each substantive tension point, flag it to the user.

If no tension: "No cross-model tension — both reviewers agree."

---

## Step 5: Cleanup

Clean up only the temp files created in THIS invocation (use the exact filenames
from the `mktemp` calls, not wildcards):

```bash
rm -f "$PROMPT_FILE" 2>/dev/null
```

---

## Error Handling

All errors are **non-blocking** — the outside voice is a quality enhancement, not a gate.

| Error | Action |
|-------|--------|
| opencode not found | Stop with install instructions |
| Model not available | List available models, ask user to pick another |
| Auth/rate limit (429, "Token refresh failed") | "Model rate-limited. Try a different model or wait." |
| Timeout (5 min) | "Model timed out. Input may be too large." |
| Empty response | "Model returned no response." |
| All models failed | Fall back to Claude subagent via Agent tool |

---

## Important Rules

- **Never modify files.** This skill is read-only.
- **Present output verbatim.** Show full output before any synthesis.
- **Synthesis comes after, not instead of.** Your commentary follows the raw output.
- **Self-contained prompts.** The outside model has zero conversation context.
- **Use structured text format.** Request SEVERITY/TOPIC/DETAIL format rather than JSON —
  most models produce cleaner structured text than valid JSON.
- **Prefer non-Anthropic models.** The value is cross-family diversity. Claude subagent
  is the fallback, not the default.
