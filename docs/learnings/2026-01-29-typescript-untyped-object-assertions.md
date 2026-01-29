---
date: 2026-01-29
type: reference
source: ai-detected
confidence: high
category: reference
tags: [typescript, type-safety, external-apis]
---

# Type Assertions for Untyped Objects from External Sources

## What Happened

During implementation, encountered TypeScript error: "Property 'credentials' does not exist on type 'Object'" when accessing properties on objects returned from external sources (MongoDB, APIs, libraries).

## AI Approach

Initial attempt used `any` type cast:
```typescript
const config = (await externalCall()) as any;
const nested = config.credentials.google;
```

This triggered linting error (no-explicit-any) and bypassed all type safety.

## Better Pattern

Use inline type assertion with expected structure:

```typescript
const config = await externalCall();
const nested = (config as { credentials?: { google?: object } }).credentials?.google;
```

**Benefits:**
- ✅ No linting errors
- ✅ Preserves type safety for the specific access pattern
- ✅ Documents expected structure inline
- ✅ Works with optional chaining for safe nested access

## When to Use

Anytime you receive untyped objects from:
- External APIs without TypeScript definitions
- Database queries (MongoDB, raw SQL)
- Third-party libraries without types
- Dynamic/runtime data sources

## Lesson

**Pattern:** Inline type assertion + optional chaining
```typescript
(obj as { prop?: { nested?: type } }).prop?.nested
```

**When passing to functions:**
```typescript
someFunction((obj as { prop?: object }).prop as object)
```

## Context

External sources often return generic `Object` or `unknown` types. Need to access nested properties without sacrificing type safety or triggering linting rules.

## Suggested Action

Reference pattern for future TypeScript work with untyped external data.

**Status:** SAVED as reference (2026-01-29)
