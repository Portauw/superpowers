---
name: outgoing-api-design
description: Use when about to integrate with an external API or call another microservice, before writing integration code. Covers both third-party APIs and internal service-to-service calls within a RESTful/microservices architecture.
---

# Outgoing API Integration Design

Design outgoing API integrations properly before writing code. Prevents tight coupling and missing resilience patterns.

## Process

### Phase 1: Triage

Present this checklist. Ask the user which items apply (can be all):

1. **Abstraction boundary** — How to isolate the API from your domain
2. **Retry strategy** — What to retry, how many times, backoff approach
3. **Timeout policy** — Connection and response timeouts
4. **Circuit breaker** — When to stop calling a failing service
5. **Rate limiting** — Respecting API rate limits, queuing
6. **Fallback behavior** — What happens when the API is unavailable
7. **Error mapping** — Translating API errors to your domain errors
8. **Observability** — Logging, metrics, tracing for the integration

**STOP after presenting the checklist.** Wait for the user to select items before proceeding.

### Phase 2: Guided Deep Dive

Walk through EACH selected item **one at a time**. For each:
1. Present the pattern table below
2. Ask the follow-up questions listed
3. Record the user's decision
4. **Move to the next item only after the user responds**

**Do NOT bundle multiple items. Do NOT prescribe recommendations without asking.**

#### 1. Abstraction Boundary

| Pattern               | When to use                                    |
|-----------------------|------------------------------------------------|
| Port/Adapter          | Might swap providers, multiple implementations |
| Thin Client Wrapper   | Internal services you own, unlikely to change  |
| Anti-Corruption Layer | External API model doesn't match your domain   |

*Ask:* Which pattern? Where does the boundary sit? What operations does your domain need?

#### 2. Retry Strategy

| Pattern | When to use |
|---------|-------------|
| Exponential backoff | Network errors, 5xx responses |
| Immediate retry (1x) | Intermittent failures, idempotent calls |
| No retry | Non-idempotent writes, 4xx errors |

*Ask:* Which calls are idempotent? Max retries? Backoff ceiling?

#### 3. Timeout Policy

| Pattern | When to use |
|---------|-------------|
| Aggressive (1-3s) | User-facing, synchronous flows |
| Moderate (5-15s) | Background jobs, batch processing |
| Per-operation | Different calls have different latency profiles |

*Ask:* Is this user-facing or async? Expected response time of the API?

#### 4. Circuit Breaker

| Pattern | When to use |
|---------|-------------|
| Threshold-based | Open after N consecutive failures, half-open after cooldown |
| Sliding window | Open when failure rate exceeds X% over time window |
| No circuit breaker | Non-critical calls, already has fallback |

*Ask:* Failure threshold? Cooldown period? What state to track?

#### 5. Rate Limiting

| Pattern | When to use |
|---------|-------------|
| Token bucket | Smooth out bursts, respect API quotas |
| Request queue | Serialize calls, process in order |
| Backpressure | Let caller know to slow down (microservices) |

*Ask:* Known rate limits? Burst vs sustained traffic? Shared across instances?

#### 6. Fallback Behavior

| Pattern | When to use |
|---------|-------------|
| Cached response | Serve stale data when API is down |
| Degraded mode | Continue without the feature |
| Fail fast | Operation cannot proceed without the API |

*Ask:* Can the feature degrade gracefully? Is stale data acceptable? For how long?

#### 7. Error Mapping

| Pattern | When to use |
|---------|-------------|
| Domain exceptions | Translate API errors to your domain's error types |
| Result type | Return success/failure objects, no exceptions |
| Pass-through | Internal service, errors already meaningful |

*Ask:* How does your app handle errors today? Should callers know which API failed?

#### 8. Observability

| Pattern | When to use |
|---------|-------------|
| Structured logging | Log request/response metadata (not bodies) at boundary |
| Metrics | Track latency, error rates, circuit breaker state |
| Distributed tracing | Microservices, need to follow requests across services |

*Ask:* Existing observability stack? What do you need to debug in production?

### Phase 3: Design Output

After all selected items are covered, write a design document to `docs/plans/YYYY-MM-DD-<service>-api-integration-design.md`:

```markdown
# API Integration Design: <Service Name>

## Summary
One-liner: what API, why, which service calls it.

## Decisions

### Abstraction Boundary
Pattern: [chosen]
Boundary location: [path/module]
Domain operations: [list]

### Resilience
- Retry: [strategy, max attempts, backoff]
- Timeout: [values per operation]
- Circuit breaker: [threshold, cooldown] or N/A
- Rate limiting: [approach] or N/A
- Fallback: [behavior]

### Error Handling
Pattern: [chosen]
Mapping: [API error -> domain error examples]

### Observability
[What to log/measure/trace]

## Architecture Guidance
[Recommended file/module structure for the integration layer]
```

Only include sections the user selected in triage. No empty sections.

## Red Flags — You're Doing It Wrong

- Jumping to solutions before presenting the triage checklist
- Bundling multiple concerns into one response
- Prescribing "Recommendation: X" without asking the user
- Assuming context instead of asking ("Since you haven't answered, I'll assume...")
- Writing implementation code — this skill produces a design document, not code
- Covering all 8 items when the user only selected 3
