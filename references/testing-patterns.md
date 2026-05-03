# Testing Patterns

Cross-skill reference for test design. Pair with `test-driven-development` (RED-GREEN-REFACTOR) and the `test-engineer` persona (review).

## Test Pyramid

Three layers, stacked widest at the bottom:

- **Unit (most)** — single function, class, or module. No I/O. Milliseconds. Run on every save.
- **Integration (some)** — multiple modules together, often with a real DB or in-process HTTP. Seconds. Run on every commit.
- **E2E (few)** — full system through the real UI or public API. Tens of seconds. Run on PR or nightly.

Inverted pyramid (lots of E2E, few unit) is a smell. E2E tests are slow, flaky, and hard to localize. Most coverage should come from unit tests; E2E exists to prove the wiring is real.

## Test Sizes (by resource cost)

A second axis, useful when the pyramid metaphor isn't enough:

- **Small** — in-process, no network, no filesystem (or only tmp). Deterministic. Parallelizable.
- **Medium** — single host, may touch localhost network or filesystem. Still parallelizable per host.
- **Large** — multi-host, real network, real services. Slow, fragile.

Rule: prefer the smallest size that exercises the behavior. Only escalate when you must.

## DAMP Over DRY (in tests)

Production code: DRY (Don't Repeat Yourself).
Test code: DAMP (Descriptive And Meaningful Phrases).

Tests are read more than written, and usually under pressure (something broke). Inlining the setup so the test is readable in isolation beats a clever helper that requires three jumps to understand.

```typescript
// Bad (DRY): clever, hard to scan when red
it('rejects expired tokens', () => {
  const ctx = makeCtx({ token: expired() });
  assertRejected(ctx);
});

// Good (DAMP): boring, immediately legible
it('rejects expired tokens', () => {
  const token = { value: 'abc', expiresAt: Date.now() - 1000 };
  const result = validate(token);
  expect(result.ok).toBe(false);
  expect(result.error).toBe('EXPIRED');
});
```

Helpers are still fine — for genuinely repeated infrastructure (test app, fixtures DB). Not for the assertions themselves.

## AAA: Arrange / Act / Assert

```typescript
it('trims whitespace from title', () => {
  // Arrange
  const input = { title: '  hello  ' };

  // Act
  const result = createTask(input);

  // Assert
  expect(result.title).toBe('hello');
});
```

One Act per test. Multiple Acts means multiple behaviors — split the test.

## Naming

Pattern: `<unit> <expected behavior> <condition>`.

```typescript
describe('TaskService.createTask', () => {
  it('creates a task with default pending status', () => {});
  it('throws ValidationError when title is empty', () => {});
  it('trims whitespace from title', () => {});
});
```

Bad names: `it('works')`, `it('test 1')`, `it('handles edge case')`. A reader should know what broke from the test name alone.

## Mocking

Mock at the boundary, not inside the unit.

| Mock these                | Don't mock these         |
| ------------------------- | ------------------------ |
| Database calls            | Internal utilities       |
| HTTP requests             | Business logic           |
| File system operations    | Data transformations     |
| External API calls        | Validation functions     |
| Time / Date (when needed) | Pure functions           |

Over-mocking produces tests that pass while production breaks. If your test mocks the function you're trying to test, you're testing the mock.

## Assertion Quality

Strong assertions catch regressions. Weak assertions hide them.

```typescript
// Weak: passes for almost any output
expect(result).toEqual(expect.anything());
expect(result).toBeTruthy();

// Strong: pins down behavior
expect(result).toEqual({ id: expect.any(String), title: 'hello', status: 'pending' });
```

For floating point, use `toBeCloseTo`. For arrays of unknown order, use `toContain` per element (or sort before comparing).

## Async Tests

Always `await`. A forgotten `await` produces a passing test that never ran the assertion.

```typescript
// Wrong: assertion never runs
it('rejects on bad input', () => {
  expect(asyncFn(bad)).rejects.toThrow();
});

// Right
it('rejects on bad input', async () => {
  await expect(asyncFn(bad)).rejects.toThrow();
});
```

For event-driven code, prefer event-based waiting over `setTimeout`. Sleeping for "long enough" is the source of most flakes.

## Component / API Tests (shape, not framework)

Component tests should query by accessible role and label, not test IDs:

```tsx
fireEvent.click(screen.getByRole('button', { name: /create/i }));
```

API tests should assert status, body shape, and error codes — not the entire response payload byte-for-byte.

```typescript
expect(response.status).toBe(422);
expect(response.body.error.code).toBe('VALIDATION_ERROR');
```

## Anti-Patterns

| Anti-pattern                          | Why it hurts                              | Do instead                              |
| ------------------------------------- | ----------------------------------------- | --------------------------------------- |
| Testing implementation details        | Breaks on every refactor                  | Test public inputs and outputs          |
| Snapshot everything                   | Diffs are huge, no one reads them         | Assert specific values                  |
| Shared mutable state across tests     | Order-dependent passes, ghost flakes      | Setup / teardown per test               |
| Testing third-party code              | Not your bug, wastes maintenance          | Mock the boundary; trust their tests   |
| `test.skip` left in main              | Hides regressions, rots silently          | Fix it or delete it                     |
| Mocking the unit under test           | Test passes, production breaks            | Mock dependencies, exercise the unit    |
| Over-broad assertions                 | Misses real regressions                   | Pin down the exact expected shape       |
| No async `await`                      | Assertions never run                      | `await` every async test and assertion  |
| Helper-heavy tests (DRY abuse)        | Unreadable when red                       | Inline the obvious; helpers for infra   |
| Inverted pyramid (mostly E2E)         | Slow CI, flaky signals, hard to localize  | Push coverage down to unit              |

## Coverage as a Floor, Not a Ceiling

100% line coverage with weak assertions is worse than 70% with strong ones. Use coverage to find untested branches, not as a quality metric. The `test-engineer` persona reviews for assertion strength, not just line counts.

## Cross-References

- `skills/test-driven-development/SKILL.md` — RED-GREEN-REFACTOR cycle
- `agents/test-engineer.md` — Reviewer persona using these patterns
- `skills/requesting-code-review/SKILL.md` — When to fan out the test-engineer persona
