---
name: second-opinion
description: Use when you need an independent second opinion from a different AI model on a plan, code review, architecture decision, or any analysis where cross-model agreement strengthens confidence. Dispatches to other models via opencode CLI.
---

# Second Opinion — Cross-Model Review

Two models agreeing = high confidence. Disagreement = worth investigating.

## Step 1: Setup & Model Selection

```bash
which opencode 2>/dev/null && echo "FOUND" || echo "NOT_FOUND"
opencode models 2>/dev/null | grep -v "^warn:"
```

If `NOT_FOUND`: stop and tell the user "opencode CLI is not installed. Install from
https://opencode.ai — or you can use a Claude subagent (Agent tool) as a lighter
alternative for a second opinion from a different Claude model."
Do NOT automatically fall back — let the user decide.

**Model selection — auto-select unless user specified one:**

1. **Classify the review context** from what's being reviewed:

   | Context type | Keywords to look for |
   |---|---|
   | `code` | diff, PR, implementation, function, bug, refactor, test |
   | `architecture` | design, system, API, schema, database, pattern, structure |
   | `reasoning` | logic, proof, algorithm, math, tradeoffs, decision |
   | `security` | vulnerability, auth, injection, attack, exploit, CVE |
   | `general` | anything else |

2. **Match models** — scan available non-Anthropic models against these strength patterns:

   | Model pattern | Strong at |
   |---|---|
   | `codex`, `deepseek`, `coder` | code review, implementation |
   | `gemini` | architecture, long context, multimodal |
   | `thinking`, `kimi`, `r1` | chain-of-thought reasoning, logic |
   | `o1`, `o3`, `o4` | complex reasoning, math, security |
   | `gpt`, `big-pickle` | general analysis, code review |
   | `mistral`, `llama`, `command` | alternative perspective, open-source view |

3. **Pick the best match** for the classified context. If multiple match equally well, dispatch 2 in parallel for higher confidence. If user specified a model, use that instead (substring-match against the list).

4. **Prefer non-Anthropic** — cross-family diversity is the point. Allow Anthropic only if user explicitly requests it or no other models are available.

## Step 2: Build the prompt

The outside model has NO conversation context. Build a self-contained prompt from
whatever the user wants reviewed (plan, diff, code, question — you have the context).
Ask for structured findings (SEVERITY/TOPIC/DETAIL) and an overall verdict.

If the user names a skill to pass through, reference it by name in the prompt
(e.g., "Use the /review skill"). The outside model loads skills via its own skill tool.

## Step 3: Dispatch

```bash
opencode run "<prompt>" --file <path/to/content> -m "<provider/model>" --format json 2>&1 | python3 -c "
import sys, json
texts, tokens = [], {}
for line in sys.stdin:
    line = line.strip()
    if not line or not line.startswith('{'): continue
    try:
        obj = json.loads(line)
        if obj.get('type') == 'text': texts.append(obj['part']['text'])
        elif obj.get('type') == 'step_finish': tokens = obj['part'].get('tokens', {})
    except Exception as e: print(f'parse error: {e}', file=sys.stderr)
print(''.join(texts))
if tokens: print(f'tokens: {tokens.get(\"total\", 0)}')
"
```

**Arg order matters:** message first, then `--file`, then other flags. Use `--file` to
attach files (plans, code, diffs) — avoids shell escaping issues with inline content.
For simple text-only prompts, `--file` can be omitted.

Use `timeout: 300000` (5 minutes). The `2>&1` merges Bun stderr warnings — the
parser skips non-JSON lines.

**Multiple models:** dispatch each via the Agent tool in parallel.
Each agent runs its own opencode command independently.

## Step 4: Present results

Show the full response verbatim first, then your synthesis after. Never summarize
instead of showing the raw output.

If multiple models: show each, then a cross-model comparison (what overlaps, what's unique).

If the outside voice disagrees with your earlier analysis, flag the tension explicitly.

State which model(s) were selected and why (e.g., "Selected `trellis/gpt-codex` for
code review context — strong at implementation analysis").

## Error Handling

All errors are **non-blocking** — outside voice is a quality enhancement, not a gate.

| Error | Action |
|-------|--------|
| opencode not installed | Stop. Suggest install or Claude subagent alternative — let user decide |
| Model not available | Try next best match from the model list |
| Auth/rate limit | Suggest a different model |
| Timeout / empty response | Retry once, then report and move on |
| Permission rejected | Try a different model, simplify the prompt, or ask the user — never retry the same command |
| All models failed | Report failure. Suggest Claude subagent as alternative — let user decide |

## Rules

- **Never modify files.** Read-only skill.
- **Auto-select model from context** — never ask unless no good match exists.
- **Verbatim first, synthesis second.**
- **Self-contained prompts.** Zero conversation context for the outside model.
- **Prefer non-Anthropic models.** Cross-family diversity is the point.
- **On rejection, change approach.** Try a different model, simplify, or ask the user.
- **State your selection.** Always tell the user which model was picked and the reason.
