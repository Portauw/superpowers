# Performance Checklist

Quick reference for web application performance work. Use alongside the `performance` skill.

This is a checklist, not a process. Run the investigation workflow from `performance/SKILL.md` first. Use this list to verify nothing obvious is missed once you've identified the layer.

## Table of Contents

- [Core Web Vitals Targets](#core-web-vitals-targets)
- [TTFB Diagnosis](#ttfb-diagnosis)
- [Frontend Checklist](#frontend-checklist)
- [Backend Checklist](#backend-checklist)
- [Measurement Commands](#measurement-commands)
- [Common Anti-Patterns](#common-anti-patterns)

## Core Web Vitals Targets

| Metric | Good | Needs Work | Poor |
|--------|------|------------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| INP (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |
| FCP (First Contentful Paint) | ≤ 1.8s | ≤ 3.0s | > 3.0s |

## TTFB Diagnosis

When TTFB > 800ms, isolate the slow component in DevTools Network waterfall:

- [ ] **DNS resolution** slow → add `<link rel="dns-prefetch">` / `<link rel="preconnect">` for known origins
- [ ] **TCP/TLS handshake** slow → enable HTTP/2 or HTTP/3, consider edge deployment, verify keep-alive
- [ ] **Server "Waiting (TTFB)"** slow → profile backend, check slow queries, add caching

## Frontend Checklist

### Images

- [ ] Modern formats (WebP, AVIF) where supported
- [ ] Responsively sized (`srcset` and `sizes`)
- [ ] Explicit `width` and `height` on every `<img>` and `<source>` (prevents CLS)
- [ ] Below-the-fold images: `loading="lazy"` and `decoding="async"`
- [ ] Hero / LCP image: `fetchpriority="high"` and **no** lazy loading

### JavaScript

- [ ] Initial-load bundle < 200KB gzipped
- [ ] Route-level and heavy-feature code splitting via dynamic `import()`
- [ ] Tree shaking working (dependency ships ESM, marks `sideEffects: false`)
- [ ] No render-blocking JS in `<head>` (use `defer` or `async`)
- [ ] Heavy CPU work moved to Web Workers
- [ ] `React.memo` only where profiler shows wasted re-renders
- [ ] `useMemo` / `useCallback` only where profiling shows benefit
- [ ] Long tasks (> 50ms) broken up — primary lever for INP
- [ ] `scheduler.yield()` (preferred), `scheduler.postTask()`, or `yieldToMain` pattern inside long loops
- [ ] `requestIdleCallback` for deferrable, non-urgent work (analytics flush, prefetch)
- [ ] Non-critical work (analytics, logging) deferred out of event handlers
- [ ] Third-party scripts: `async` / `defer`, audited for size, facade for heavy widgets (chat, embeds)

### CSS

- [ ] Critical CSS inlined or preloaded
- [ ] Non-critical CSS not render-blocking
- [ ] No CSS-in-JS runtime cost in production (use static extraction)

### Fonts

- [ ] Limited to 2–3 families, 2–3 weights each
- [ ] WOFF2 only (skip WOFF / TTF / EOT)
- [ ] Self-hosted when possible (third-party CDNs add DNS + TCP + TLS round-trips)
- [ ] LCP-critical fonts preloaded: `<link rel="preload" as="font" type="font/woff2" crossorigin>`
- [ ] `font-display: swap` (or `optional` for non-critical) to avoid FOIT
- [ ] Subsetted via `unicode-range`
- [ ] Variable fonts when multiple weights/styles needed (one file replaces many)
- [ ] Fallback metrics tuned: `size-adjust`, `ascent-override`, `descent-override` to reduce CLS on font swap
- [ ] System font stack considered before any custom font

### Network

- [ ] Static assets: long `max-age` + content-hashed filenames
- [ ] API responses: `Cache-Control` where appropriate
- [ ] HTTP/2 or HTTP/3 enabled
- [ ] `<link rel="preconnect">` for known origins on the LCP path
- [ ] `fetchpriority` on critical non-image resources too (preload links, above-the-fold scripts)
- [ ] No unnecessary redirects

### Rendering

- [ ] No layout thrashing (forced synchronous layouts)
- [ ] Animations use `transform` and `opacity` only (GPU-accelerated)
- [ ] Long lists use virtualization (`react-window`, `@tanstack/react-virtual`) — only past ~200 items
- [ ] No unnecessary full-page re-renders
- [ ] Off-screen sections use `content-visibility: auto` with `contain-intrinsic-size`
- [ ] No `unload` event handlers and no `Cache-Control: no-store` on HTML — preserves bfcache eligibility

## Backend Checklist

### Database

- [ ] No N+1 query patterns (use eager loading / joins / batch loading)
- [ ] Queries have appropriate indexes (verified via `EXPLAIN`)
- [ ] List endpoints paginated (never `SELECT *` unbounded)
- [ ] Connection pool sized for concurrency
- [ ] Slow query logging enabled
- [ ] Long transactions audited for lock contention

### API

- [ ] p95 response time within budget (typically < 200ms for user-facing)
- [ ] No synchronous heavy compute in request handlers
- [ ] Bulk operations instead of loops of individual calls
- [ ] Response compression (gzip / brotli)
- [ ] Caching layers: in-memory, Redis, CDN — chosen against the cost-benefit table

### Infrastructure

- [ ] CDN for static assets
- [ ] Server / edge close to users
- [ ] Horizontal scaling configured if needed
- [ ] Health check endpoint for load balancer

## Measurement Commands

### INP / field data workflow

1. **Field data first** — check CrUX or your RUM tool for real-user INP before optimising. Lab data lies about INP.
2. **Identify slow interactions** — DevTools → Performance panel → record while clicking/typing. Look for long tasks attached to interactions.
3. **Test on mid-range Android** — INP issues only surface on slower hardware. Use a real device or DevTools CPU throttling (4×–6× slowdown).

```bash
# Lighthouse CLI (lab data)
npx lighthouse https://localhost:3000 --output json --output-path ./report.json

# Bundle analysis
npx webpack-bundle-analyzer stats.json
# or for Vite
npx vite-bundle-visualizer

# Bundle size budget
npx bundlesize

# Lighthouse CI (regression detection)
npx lhci autorun
```

```typescript
// Web Vitals in code (RUM)
import { onLCP, onINP, onCLS, onFCP } from 'web-vitals';

onLCP(console.log);
onINP(console.log);
onCLS(console.log);
onFCP(console.log);

// INP with interaction-level attribution
import { onINP } from 'web-vitals/attribution';
onINP(({ value, attribution }) => {
  const {
    interactionTarget,
    inputDelay,
    processingDuration,
    presentationDelay,
  } = attribution;
  console.log({ value, interactionTarget, inputDelay, processingDuration, presentationDelay });
});
```

```typescript
// Backend: simple timing for hot paths
console.time('db-query');
const result = await db.query(/* ... */);
console.timeEnd('db-query');
```

## Performance Budget

Set budgets and enforce them in CI:

```
JavaScript bundle: < 200KB gzipped (initial load)
CSS:               < 50KB gzipped
Images:            < 200KB per image (above the fold)
Fonts:             < 100KB total
API response:      < 200ms (p95)
Time to Interactive: < 3.5s on 4G
Lighthouse Performance score: ≥ 90
```

## Common Anti-Patterns

| Anti-Pattern | Impact | Fix |
|---|---|---|
| N+1 queries | Linear DB load growth with parent rows | Use joins, includes, or batch loading |
| Unbounded queries | Memory exhaustion, timeouts | Always paginate, add `LIMIT` |
| Missing indexes | Slow reads as data grows | Add indexes for filtered/sorted columns |
| Layout thrashing | Jank, dropped frames | Batch DOM reads, then batch writes |
| Unoptimized images | Slow LCP, wasted bandwidth | WebP/AVIF, responsive sizes, lazy load |
| Large bundles | Slow Time to Interactive | Code split, tree shake, audit dependencies |
| Blocking main thread | Poor INP, unresponsive UI | Chunk long tasks (`scheduler.yield()`), Web Workers |
| Memory leaks | Growing memory, eventual crash | Clean up listeners, intervals, refs, subscriptions |
| Sprinkled `useMemo` | Bookkeeping cost without benefit | Profile first; remove memos that don't help |
| Caching everywhere | Stale data, invalidation bugs | Cache only what measurements show benefits |

> Adapted from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT License).
