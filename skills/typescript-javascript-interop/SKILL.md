---
name: typescript-javascript-interop
description: Use when TypeScript compilation errors occur accessing properties on objects from JavaScript modules, external APIs, or untyped sources. Includes type assertions, CommonJS interop patterns, and safe nested property access.
---

# TypeScript/JavaScript Interop Patterns

Quick reference for type-safe patterns when working with untyped JavaScript sources in TypeScript.

## When to Use

- TypeScript error: "Property does not exist on type 'Object'"
- Calling JavaScript CommonJS modules from TypeScript
- Handling data from external APIs without type definitions
- Linting error: `no-explicit-any` rule blocks `as any` cast

## CommonJS Module Interop

**Problem:** JavaScript module returns object, TypeScript doesn't know its structure.

**Pattern: Inline Type Assertion**

```typescript
// For quick fixes - type assertion at call site
import { createSchedule } from './stateManager.js';

const schedule = await createSchedule(data) as { scheduleId: string };
const id = schedule.scheduleId; // ✅ Type-safe
```

**Pattern: Declaration File (Reusable)**

```typescript
// stateManager.d.ts - for shared types across files
export interface CreateScheduleResult {
  scheduleId: string;
}

export function createSchedule(data: unknown): Promise<CreateScheduleResult>;
```

```typescript
// Now import works everywhere with full types
import { createSchedule } from './stateManager.js';

const schedule = await createSchedule(data);
const id = schedule.scheduleId; // ✅ Autocomplete works
```

**When to use each:**
- Inline assertion: One-off usage, quick fix
- Declaration file: Reused across multiple files, team collaboration

## External API Type Assertions

**Problem:** External API/library returns `Object` or `unknown` type.

**Pattern: Interface + Type Assertion + Optional Chaining**

```typescript
interface GoogleCredentials {
  apiKey: string;
  clientId: string;
  clientSecret: string;
}

interface ConfigWithCredentials {
  credentials?: {
    google?: GoogleCredentials;
  };
}

async function getGoogleCredentials(userId: string) {
  const config = await externalAPI.getConfig(userId) as ConfigWithCredentials;

  // Safe nested access with optional chaining
  return config.credentials?.google;
}
```

**Why this works:**
- ✅ No `any` type - satisfies linters
- ✅ Type-safe after assertion - autocomplete works
- ✅ Safe property access - won't crash on missing data
- ✅ Documents expected structure - clear contract

## Common Mistakes

### ❌ Using `any`
```typescript
const config = await getConfig() as any; // Loses all type safety
const nested = config.credentials.google; // No autocomplete, no checking
```

### ❌ Accessing Without Optional Chaining
```typescript
const config = await getConfig() as ConfigWithCredentials;
const google = config.credentials.google; // ❌ Crashes if credentials is undefined
```

### ✅ Correct Pattern
```typescript
const config = await getConfig() as ConfigWithCredentials;
const google = config.credentials?.google; // ✅ Returns undefined safely
```

## Function Parameters from JavaScript Modules

**Problem:** JavaScript function signature unclear, TypeScript thinks wrong parameter count.

**Before calling, verify actual signature:**

```javascript
// stateManager.js - READ THIS FIRST
function authorizeUserAccess(userId) {
  // Only accepts 1 parameter
}
```

```typescript
// TypeScript caller
await authorizeUserAccess(userId); // ✅ Correct

// ❌ Don't assume option objects exist
await authorizeUserAccess(userId, { adminOnly: false });
// Error: Expected 1 arguments, but got 2
```

**Checklist for JavaScript → TypeScript calls:**
- [ ] Read JavaScript implementation to verify parameter count
- [ ] Check actual return value structure
- [ ] Add type assertion if accessing nested properties
- [ ] Use optional chaining for potentially missing properties

## Runtime Validation (Optional)

For untrusted external APIs, add runtime type guards:

```typescript
function isGoogleCredentials(obj: unknown): obj is GoogleCredentials {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'apiKey' in obj &&
    'clientId' in obj &&
    typeof (obj as GoogleCredentials).apiKey === 'string'
  );
}

const creds = config.credentials?.google;
if (!isGoogleCredentials(creds)) {
  return undefined; // Invalid structure
}
// creds is now GoogleCredentials type
```

**When to use:**
- External APIs that might change without notice
- Critical data integrity requirements
- Debugging type mismatches in production

## Quick Reference

| Situation | Pattern |
|-----------|---------|
| Call JS module once | Inline `as { prop: type }` |
| Call JS module many times | Create `.d.ts` file |
| External API response | Interface + type assertion + `?.` |
| Nested property access | Optional chaining `?.` |
| Function parameters | Read JS source first |
| Untrusted API data | Add runtime type guard |

## Related Patterns

- **TypeScript Date Handling:** After MongoDB serialization, dates are ISO strings (not Date objects)
- **Next.js Server/Client Boundary:** Only plain objects cross boundary - serialize at data layer
- **CommonJS ESM Interop:** Use `import` for CommonJS modules in TypeScript (works in Node.js 12+)
