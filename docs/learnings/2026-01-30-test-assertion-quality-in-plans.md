# Test Assertion Quality in Implementation Plans

**Date:** 2026-01-30
**Category:** general-workflow
**Related Skills:** writing-plans, test-driven-development

## Context

While implementing AI-driven event filtering, the implementation plan included a test example with weak assertions using `expect.anything()`:

```javascript
expect(mockAnalyze).toHaveBeenCalledWith(
  expect.anything(),
  expect.anything(),
  expect.anything(),
  expect.anything()
);
```

The executing agent copied this pattern literally, resulting in weak test coverage.

## Investigation

Baseline test revealed agents naturally write strong assertions when not given weak examples:

```javascript
// Agent naturally wrote this WITHOUT a plan example
expect(mockAnalyze).toHaveBeenCalledWith(
  events,
  'Focus on client meetings',
  'Skip all-day events',  // Actual filterPrompt value
  geminiClient
);
```

**Key insight:** The problem wasn't agent capability - it was the plan providing a weak example that got copied.

## Root Cause

Test examples in implementation plans set the quality bar. Agents copy what they see. Providing weak placeholder examples (expect.anything()) trains agents to write weak tests.

## Solution

Enhanced writing-plans skill with "Test Code Quality in Plans" section:

1. **Strong assertions (recommended):** Verify actual values, especially new parameters
2. **Weak placeholders (avoid):** Don't use expect.anything() - agents copy it literally
3. **Decision rule:** Either provide strong test examples OR omit test code entirely

Agents write good tests naturally when not given bad examples to copy.

## Impact

- Prevents weak test coverage from implementation plans
- Guides plan writers to either show strong examples or trust agent capability
- Improves overall test quality across subagent-driven implementations

## Tags

#testing #implementation-plans #agent-behavior #code-quality
