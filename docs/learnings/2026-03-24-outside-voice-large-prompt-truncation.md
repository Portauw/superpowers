---
date: 2026-03-24
type: backtracking
source: ai-detected
confidence: high
category: general-workflow
tags: [outside-voice, opencode, prompt-size, gemini]
project: superpowers
---

# Large prompts via opencode shell expansion return empty responses from Gemini

## What Happened
Dispatched an 18KB document to Gemini via `opencode run --model "trellis/gemini-3.1-pro-preview" --format json "$(cat $PROMPT_FILE)"`. Got 26K total tokens but 0 response text. A second attempt with a ~1KB summary prompt worked perfectly.

## AI Assumption
Shell expansion of `$(cat $PROMPT_FILE)` with an 18KB file would work fine as an inline argument to opencode.

## Reality
Gemini returned empty text with the large prompt. Likely hit input processing limits, silent truncation, or the shell argument exceeded practical limits for the model's context window via this pathway.

## Lesson
When using outside-voice with large content (plans, full documents, long diffs):
1. Summarize the key claims/questions instead of sending raw content
2. Keep the prompt under ~2KB for reliable results
3. If the full document is needed, consider chunking or asking the outside model to read files directly

## Suggested Action
Update outside-voice SKILL.md Step 2 to add a size guard: if prompt content exceeds 5KB, summarize key claims and send the summary instead of the raw content.
