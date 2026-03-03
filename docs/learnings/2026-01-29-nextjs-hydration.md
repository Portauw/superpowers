---
date: 2026-01-29
tags:
  - nextjs
  - react
  - hydration
  - mongodb
  - serialization
  - forms
  - architecture
workflow:
  - systematic-debugging
  - brainstorming
proposed-skill: nextjs-engineering-skill
generalizability: high
---

# Next.js Hydration Errors from MongoDB Serialization and Form Architecture

## Problem

Encountered React hydration mismatch errors in Next.js 15 application with two distinct root causes:

1. **MongoDB Serialization Error**:
   ```
   Only plain objects can be passed to Client Components from Server Components.
   Objects with toJSON methods are not supported.
   {_id: {buffer: ...}, scheduleId: ..., createdAt: ..., updatedAt: ...}
   ```
   - Server Component called `getUserConfig(userId)` and passed result to Client Component
   - MongoDB documents contain `_id` (ObjectId with `buffer` property) and `Date` objects
   - Next.js cannot serialize these when passing from Server to Client Components

2. **Hydration Mismatch Error**:
   ```
   A tree hydrated but some attributes of the server rendered HTML didn't match the client properties.
   data-np-intersection-state="observed"
   ```
   - Browser extensions (password managers, analytics) inject attributes into form elements
   - Server-rendered HTML has no extension attributes
   - Client-rendered HTML has injected attributes
   - React detects mismatch during hydration

**Initial Impulse:** Use `suppressHydrationWarning` to hide errors.

**Reality:** This is a band-aid that ignores two architectural issues:
1. Improper data serialization at MongoDB → React boundary
2. Mixed controlled/uncontrolled form component patterns

## Solution

### Part 1: MongoDB Document Serialization

**Fix at the data layer** (`stateManager.js`):

```javascript
/**
 * Serialize MongoDB document to plain object.
 * Removes _id and converts Dates to ISO strings.
 */
function serializeSchedule(doc) {
  if (!doc) return null;

  const { _id, ...schedule } = doc;

  return {
    ...schedule,
    lastRunAt: schedule.lastRunAt ? schedule.lastRunAt.toISOString() : null,
    nextRunAt: schedule.nextRunAt ? schedule.nextRunAt.toISOString() : null,
    createdAt: schedule.createdAt.toISOString(),
    updatedAt: schedule.updatedAt.toISOString(),
  };
}

// Apply to all query functions
async function getSchedules(userId, options = {}) {
  const schedules = await collection.find(query).toArray();
  return schedules.map(serializeSchedule); // ← Serialize before returning
}
```

**Applied to all MongoDB collections:**
- `serializeSchedule()` - schedules
- `serializeUserConfig()` - user configs
- `serializeChat()` - chat sessions
- `serializeManualExecution()` - manual executions

**Why this works:**
- Removes `_id` field (ObjectId with `buffer` property)
- Converts all `Date` objects to ISO 8601 strings
- Creates plain objects that serialize identically on server and client
- Fixed at the source (data layer) so all consumers benefit

### Part 2: Two-Pass Rendering + Controlled Components

**Architectural fix** (`SettingsSection.tsx`):

```tsx
export function SettingsSection({ settings }) {
  // Two-pass rendering
  const [isClient, setIsClient] = useState(false)

  // Fully controlled form state
  const [timezone, setTimezone] = useState(settings.timezone || "Europe/Brussels")
  const [bufferMinutes, setBufferMinutes] = useState(settings.bufferMinutes || 5)

  useEffect(() => {
    setIsClient(true) // Enable client rendering after hydration
  }, [])

  // Sync state with props
  useEffect(() => {
    setTimezone(settings.timezone || "Europe/Brussels")
    setBufferMinutes(settings.bufferMinutes || 5)
  }, [settings.timezone, settings.bufferMinutes])

  // Server: render placeholder (no form elements)
  if (!isClient) {
    return <LoadingPlaceholder />
  }

  // Client: render full form
  return (
    <form>
      <select value={timezone} onChange={(e) => setTimezone(e.target.value)}>
        {/* controlled component */}
      </select>
    </form>
  )
}
```

**Before (problematic):**
```tsx
// Uncontrolled - defaultValue set once, can't update
<select defaultValue={settings.timezone}>

// Mixed pattern - some controlled, some uncontrolled
<input defaultValue={settings.bufferMinutes} />
<input value={workBlock.start} onChange={...} />
```

**After (correct):**
```tsx
// All controlled - value + onChange
<select value={timezone} onChange={(e) => setTimezone(e.target.value)}>

// Consistent pattern across all form inputs
<input value={bufferMinutes} onChange={(e) => setBufferMinutes(e.target.value)} />
```

**Why this works:**
1. **Server renders placeholder** with no form elements
2. **React hydrates** successfully (no form elements to compare)
3. **Client renders form** after hydration via `useEffect`
4. **Browser extensions** inject attributes after form exists (no hydration mismatch)
5. **Controlled components** provide consistent state management
6. **Props sync** ensures form updates when parent changes data

**Trade-off:** Brief loading skeleton (~100ms) visible to users on initial page load.

## Prevention

### 1. Always Serialize MongoDB Documents at the Data Layer

**Pattern:**
```javascript
// ❌ Bad - Return raw MongoDB document
async function getUserConfig(userId) {
  return collection.findOne({ userId });
}

// ✅ Good - Serialize before returning
async function getUserConfig(userId) {
  const config = await collection.findOne({ userId });
  return serializeUserConfig(config);
}
```

**Serialization checklist:**
- [ ] Remove `_id` field (ObjectId with `buffer`)
- [ ] Convert all `Date` objects to ISO strings via `.toISOString()`
- [ ] Handle `null` values gracefully
- [ ] Apply to all MongoDB query functions (find, findOne, findOneAndUpdate, etc.)

### 2. Use Consistent Component Patterns

**Form component checklist:**
- [ ] All inputs are **controlled** (`value` + `onChange`) OR all are **uncontrolled** (`defaultValue` + `ref`)
- [ ] Don't mix controlled and uncontrolled in the same form
- [ ] If form data comes from server, use controlled components + `useEffect` to sync props
- [ ] Consider two-pass rendering for forms commonly targeted by browser extensions

**When to use two-pass rendering:**
- Forms with password/email inputs (password managers inject attributes)
- Forms in authenticated pages (analytics tools track inputs)
- Complex forms where extension interference is common

**When `suppressHydrationWarning` is acceptable:**
- Browser extension attributes on specific elements (per React docs)
- Use sparingly on individual elements, not entire forms
- Document why it's needed in a comment

### 3. Architectural Boundaries Matter

**Next.js Server/Client boundary:**
```
Server Component → [Serialization] → Client Component
     ↓                                      ↓
MongoDB Document              Plain Object (JSON)
```

**Key insight:** The Server/Client boundary requires plain objects. Serialize at the **data layer** (stateManager), not at the **component layer** (page.tsx).

### 4. Testing Strategy

**Catch serialization issues early:**
```typescript
// TypeScript types should reflect serialized data
interface Schedule {
  scheduleId: string;
  // ❌ Don't type as Date
  // createdAt: Date;

  // ✅ Type as string (ISO 8601)
  createdAt: string;
}
```

**Test hydration:**
```bash
# Check for hydration errors in browser console
# Look for: "Hydration failed" or "Text content does not match"
```

### 5. Documentation

**Add comments to serialization functions:**
```javascript
/**
 * Serialize MongoDB schedule document to plain object.
 * Removes _id field and converts Date objects to ISO strings for Next.js Client Components.
 *
 * IMPORTANT: All MongoDB query functions MUST use this serializer before returning.
 */
function serializeSchedule(doc) { ... }
```

## Related Patterns

- **React Server Components** - Always pass plain objects across server/client boundary
- **Form State Management** - Controlled components for consistent behavior
- **MongoDB + TypeScript** - Type dates as `string`, not `Date`, after serialization
- **Two-Pass Rendering** - Common pattern for client-only content (date pickers, rich text editors)

## Verification Evidence

✅ **MongoDB serialization errors eliminated** - No "Objects with toJSON" errors
✅ **Hydration warnings eliminated** - No "tree hydrated but attributes didn't match" errors
✅ **Form works correctly** - Saves settings, updates from props
✅ **Loading experience smooth** - Brief skeleton, then full form

## Key Takeaway

**Don't suppress warnings - fix the architecture.**

Hydration errors signal two things:
1. **Improper data serialization** - MongoDB documents must be converted to plain objects
2. **Component pattern issues** - Forms should use consistent controlled/uncontrolled patterns

The proper fix is:
1. Serialize at the **data layer** (stateManager)
2. Use **controlled components** consistently
3. Apply **two-pass rendering** for extension-targeted forms

`suppressHydrationWarning` is acceptable for unavoidable differences (browser extensions) but should be a last resort, not the first solution.

---

## Proposed Skill: `nextjs-engineering-skill`

### Rationale for Elevation

This learning should be elevated to a reusable skill because:

1. **High Recurrence Risk** (⚠️ Critical)
   - This WILL happen in every Next.js + MongoDB project
   - Error messages are misleading ("Objects with toJSON")
   - Requires understanding multiple interconnected issues

2. **Universal Applicability** (🌍 Broad)
   - Applies to ANY Next.js + document database (MongoDB, Firestore, DynamoDB)
   - Applies to ANY React app with server/client data boundaries
   - Applies to ANY form with browser extension interference

3. **Prevention > Debugging** (💰 Cost Savings)
   - Following patterns from project start saves hours of debugging
   - Architectural insight: serialization belongs at data layer
   - Universal wisdom: "Don't suppress warnings - fix the architecture"

4. **Pattern Classification** (🔧 Multi-Purpose)
   - **Architectural pattern** - How to structure data flow across boundaries
   - **Preventive pattern** - Checklists to avoid errors
   - **Debugging pattern** - How to diagnose and fix hydration errors

### Proposed Skill Structure

**Name:** `nextjs-engineering-skill`

**Trigger Conditions:**
- Starting a new Next.js + MongoDB project
- Adding new MongoDB collections to existing projects
- Seeing "Objects with toJSON methods are not supported" errors
- Seeing hydration mismatch errors in forms
- Designing Server/Client Component boundaries

**Quick Checklist:**
- [ ] All MongoDB query functions have serializers
- [ ] Serializers remove `_id` and convert Dates to ISO strings
- [ ] TypeScript types use `string` for dates, not `Date`
- [ ] Forms with extension-sensitive inputs use two-pass rendering
- [ ] All form inputs use consistent controlled/uncontrolled pattern
- [ ] Serialization happens at data layer, not component layer

**Generalizable Patterns to Extract:**

1. **MongoDB Document Serialization Pattern**
   - Generic serializer template (remove `_id`, convert Dates)
   - Apply at data layer principle
   - TypeScript type alignment

2. **Server/Client Boundary Rule**
   - Only plain objects cross the boundary
   - Serialize at source, not at consumption
   - Boundary diagram (universal)

3. **Two-Pass Rendering Pattern**
   - `useState(false)` + `useEffect(() => setIsClient(true))`
   - When to use (password managers, analytics)
   - Loading placeholder during SSR

4. **Controlled Component Consistency**
   - All controlled OR all uncontrolled
   - `useEffect` for props-to-state sync
   - Never mix patterns

5. **When `suppressHydrationWarning` is Appropriate**
   - Specific elements with known extension interference
   - Document the reason
   - Last resort, not first solution

**Project-Specific Elements (Keep in calendar-prep):**
- File paths (`stateManager.js`, `SettingsSection.tsx`)
- Collection names and field names
- Specific serializer implementations
- Default values (timezones, buffer minutes)
- Verification evidence

**Skill Location:**
- `~/.claude/skills/nextjs-engineering-skill.md`
- Or: `/Users/pieter/Dev/superpowers/skills/nextjs-engineering-skill.md`

**Success Criteria:**
- ✅ Prevents MongoDB serialization errors in new projects
- ✅ Prevents hydration mismatches from architectural issues
- ✅ Provides clear diagnostic steps for existing errors
- ✅ Includes copy-paste-ready code templates
- ✅ Documents when NOT to use patterns (edge cases)

### Implementation Recommendation

Create skill with three main sections:

1. **Quick Start Guide** - For new projects starting with Next.js + MongoDB
2. **Debugging Guide** - For existing projects with hydration errors
3. **Pattern Reference** - Detailed explanation of each pattern with examples

This elevates the learning from "how we fixed calendar-prep" to "how to engineer Next.js apps correctly from the start."
