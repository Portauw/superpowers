# Skill Design: Outgoing API Integration Design

> **Status:** ✅ COMPLETED - 2026-02-10
>
> **Implementation:** New skill at skills/outgoing-api-design/SKILL.md. Guides developers through triage checklist, guided deep dive with pattern tables, and design document output for outgoing API integrations.

## Purpose

A skill that guides developers through designing outgoing API integrations — both third-party APIs and internal microservice calls — before writing integration code. Prevents tight coupling and missing resilience patterns.

## Trigger

"I'm about to integrate with an external API or call another microservice — let me design the integration properly first."

## Core Concerns

1. **Resilience** — Retries, timeouts, circuit breakers, fallbacks, rate limits
2. **Abstraction layer** — Clean boundary so your domain doesn't know which specific API it talks to

## Skill Flow

### Phase 1: Triage Checklist

Present numbered checklist of design concerns:

1. Abstraction boundary
2. Retry strategy
3. Timeout policy
4. Circuit breaker
5. Rate limiting
6. Fallback behavior
7. Error mapping
8. Observability

User selects which items apply to their integration.

### Phase 2: Guided Deep Dive

For each selected item, walk through one at a time:

#### 1. Abstraction Boundary

| Pattern | When to use |
|---------|-------------|
| Port/Adapter | Might swap providers, multiple implementations |
| Thin Client Wrapper | Internal services you own, unlikely to change |
| Anti-Corruption Layer | External API model doesn't match your domain |

Asks: Which pattern? Where does the boundary sit? What operations does your domain need?

#### 2. Retry Strategy

| Pattern | When to use |
|---------|-------------|
| Exponential backoff | Network errors, 5xx responses |
| Immediate retry (1x) | Intermittent failures, idempotent calls |
| No retry | Non-idempotent writes, 4xx errors |

Asks: Which calls are idempotent? Max retries? Backoff ceiling?

#### 3. Timeout Policy

| Pattern | When to use |
|---------|-------------|
| Aggressive (1-3s) | User-facing, synchronous flows |
| Moderate (5-15s) | Background jobs, batch processing |
| Per-operation | Different calls have different latency profiles |

Asks: Is this user-facing or async? Expected response time of the API?

#### 4. Circuit Breaker

| Pattern | When to use |
|---------|-------------|
| Threshold-based | Open after N consecutive failures, half-open after cooldown |
| Sliding window | Open when failure rate exceeds X% over time window |
| No circuit breaker | Non-critical calls, already has fallback |

Asks: Failure threshold? Cooldown period? What state to track?

#### 5. Rate Limiting

| Pattern | When to use |
|---------|-------------|
| Token bucket | Smooth out bursts, respect API quotas |
| Request queue | Serialize calls, process in order |
| Backpressure | Let caller know to slow down (microservices) |

Asks: Known rate limits? Burst vs sustained traffic? Shared across instances?

#### 6. Fallback Behavior

| Pattern | When to use |
|---------|-------------|
| Cached response | Serve stale data when API is down |
| Degraded mode | Continue without the feature |
| Fail fast | Operation cannot proceed without the API |

Asks: Can the feature degrade gracefully? Is stale data acceptable? For how long?

#### 7. Error Mapping

| Pattern | When to use |
|---------|-------------|
| Domain exceptions | Translate API errors to your domain's error types |
| Result type | Return success/failure objects, no exceptions |
| Pass-through | Internal service, errors already meaningful |

Asks: How does your app handle errors today? Should callers know which API failed?

#### 8. Observability

| Pattern | When to use |
|---------|-------------|
| Structured logging | Log request/response metadata (not bodies) at boundary |
| Metrics | Track latency, error rates, circuit breaker state |
| Distributed tracing | Microservices, need to follow requests across services |

Asks: Existing observability stack? What do you need to debug in production?

### Phase 3: Design Output

Write design document to `docs/plans/YYYY-MM-DD-<service>-api-integration-design.md`:

```markdown
# API Integration Design: <Service Name>

## Summary
One-liner: what API, why, which service calls it.

## Decisions

### Abstraction Boundary
Pattern: [chosen pattern]
Boundary location: [path/module]
Domain operations: [list]

### Resilience
- Retry: [strategy, max attempts, backoff]
- Timeout: [values per operation]
- Circuit breaker: [threshold, cooldown] or N/A
- Rate limiting: [approach] or N/A
- Fallback: [behavior]

### Error Handling
Pattern: [chosen pattern]
Mapping: [API error → domain error examples]

### Observability
[What to log/measure/trace]

## Architecture Guidance
[Recommended file/module structure for the integration layer]
```

Only sections selected in triage appear — no empty sections.

## Design Principles

- Language/framework agnostic — patterns apply to any stack
- Concise — tables over paragraphs, decisions over discussion
- Hybrid interaction — quick triage first, then guided deep dive only where needed
- YAGNI — skip items that don't apply, no empty boilerplate