# Performance Skill — Pressure Scenarios

Baseline scenarios for the `performance` skill. Run each scenario WITHOUT the skill loaded to capture rationalizations, then again WITH the skill to verify behavior changes.

The Iron Law of this skill is **MEASURE FIRST, OPTIMIZE SECOND. NO OPTIMIZATION WITHOUT A PROFILE.** Every scenario tests whether the agent jumps to optimization without measurement, which is the failure mode we are trying to prevent.

## Scenario 1: Vague slowness report

**User prompt**

> Users say the dashboard feels slow. Make it faster.

**Expected behavior WITHOUT the skill (RED / failure mode)**

The agent treats this as an optimization request and starts producing code:

- Sprinkles `useMemo` / `useCallback` / `React.memo` over components without checking which actually re-render
- Adds `lazy()` + `<Suspense>` to routes without checking bundle size
- Adds an in-memory cache to "obviously hot" data without checking hit rate or repeat-fetch cost
- Suggests Redis / a CDN preemptively
- Maybe adds a debounce somewhere
- Never asks "how slow?" "where?" "on what device?" "what does the profile show?"

The output is plausible-looking diff churn with no evidence the user's actual problem is touched.

**Expected behavior WITH the skill (GREEN / desired)**

The agent refuses to optimize and demands evidence first. Concretely, it should:

1. **Refuse to change code yet.** State the Iron Law: no optimization without a profile.
2. **Ask for repro.** Which page? Which interaction? Which device? Which network conditions? Time of day? How many users affected?
3. **Ask for measurement.** What do the Core Web Vitals look like (LCP, INP, CLS)? Is there a Performance trace? An APM dashboard? Server response logs?
4. **Identify the layer.** Based on symptoms, propose investigating render / network / database — not all three at once.
5. **Form a hypothesis** in the form "X is the bottleneck because Y — confirm with Z."
6. Only then propose a targeted fix.

**Failure indicators in the agent's response**

- Any code edit before measurement is requested
- Use of words "obviously", "probably", "let me just" before any data gathering
- Sweeping fixes across multiple layers at once
- Suggesting `useMemo`, `React.memo`, caching, code splitting, or virtualization without first confirming the bottleneck

## Scenario 2: User prescribes the wrong fix

**User prompt**

> This list of 50 items renders slowly. Memoize the items.

**Expected behavior WITHOUT the skill (RED / failure mode)**

The agent obliges. It wraps the item component in `React.memo`, possibly adds `useMemo` for derived data, and ships it. It does not push back on the premise that 50 items should render slowly.

**Expected behavior WITH the skill (GREEN / desired)**

The agent treats "50 items renders slowly" as the symptom and "memoize the items" as the user's hypothesis — and the skill demands evidence before committing to either.

Concrete expected behavior:

1. **Push back on the premise.** 50 items is a small list. It should not be slow on its own. If it *is* slow, the cause is almost certainly elsewhere.
2. **Ask for a profile.** What does the React Profiler / Performance trace show? What's the per-render cost? Are items re-rendering when they shouldn't? Or is each item's render genuinely expensive?
3. **Probe likely real causes.** Common alternatives at 50 items:
   - **N+1 fetches** in each item (data lookup per render)
   - **Layout thrash** from per-item DOM measurements
   - **Expensive per-item compute** (date formatting, large object spread, deep clone)
   - **Parent re-rendering on every keystroke** of an unrelated input
   - **A new object/array created in props** on every parent render, breaking referential equality
4. **State the cost of the proposed fix.** `React.memo` adds bookkeeping and dependency-array drift; if it isn't the bottleneck, it's pure complexity tax.
5. **Only memoize after the profiler shows wasted re-renders are the cause.** If the cause is N+1 fetches or layout thrash, fix that — memoization wouldn't have helped.

**Failure indicators in the agent's response**

- Adds `React.memo` / `useMemo` without asking for a profile
- Treats the user's prescription as the spec
- Doesn't mention any alternative cause for "50 items is slow"
- Doesn't ask what the React Profiler shows
- Adds memoization "to be safe"

## Notes for the test author

These scenarios are pressure tests — the user's framing pushes the agent toward an optimization-first response. The skill must hold the line: no code change without measurement. Both scenarios should produce *questions and a measurement plan*, not edits, on the first turn.

For Scenario 1, the strongest signal is whether the agent asks "how slow?" before writing any code.

For Scenario 2, the strongest signal is whether the agent challenges the premise that 50 items should be slow, and proposes alternative causes (N+1 fetch, layout thrash) before reaching for memoization.
