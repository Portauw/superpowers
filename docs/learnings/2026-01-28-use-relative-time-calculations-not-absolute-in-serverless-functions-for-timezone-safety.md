---
date: 2026-01-28
tags:
  - timezone
  - datetime
  - lambda
  - serverless
  - bugs
workflow:
  - systematic-debugging
---

# Use relative time calculations (now + milliseconds) not absolute (setHours) in serverless functions for timezone safety

## Problem

Processor Lambda with `lookAheadDays: 0` found 0 events when it should have found all events for rest of day.

**Buggy Implementation (Attempt 1):**
```javascript
const now = new Date();
let timeMax;
if (lookAheadDays === 0) {
  // Set to end of today
  timeMax = new Date(now);
  timeMax.setHours(23, 59, 59, 999);
} else {
  // N days from now
  const lookAheadMs = lookAheadDays * 24 * 60 * 60 * 1000;
  timeMax = new Date(now.getTime() + lookAheadMs);
}
```

**What happened:**
- Lambda runs at 00:30 Brussels time (23:30 UTC)
- `setHours(23, 59, 59, 999)` sets to 23:59 **UTC** (not Brussels time)
- Time window: 00:30 Brussels → 00:59 Brussels (only 29 minutes!)
- Missed all daytime events (09:00, 14:00, etc.)

**Root cause:** `Date.setHours()` operates in UTC in Lambda execution environment, not user's local timezone.

## Solution

**Use relative time calculations** (timezone-agnostic):

```javascript
const now = new Date();

// Always add (lookAheadDays + 1) full days from current time
// This captures "rest of today + N additional days" regardless of timezone
const lookAheadMs = (lookAheadDays + 1) * 24 * 60 * 60 * 1000;
const timeMax = new Date(now.getTime() + lookAheadMs);
```

**Examples:**
- Running at 00:30 Brussels with `lookAheadDays: 0`
  - From: 00:30 Brussels
  - To: 00:30 Brussels tomorrow (+24 hours)
  - ✅ Captures all of today's events (09:00, 14:00, etc.)

- Running at 06:00 Brussels with `lookAheadDays: 1`
  - From: 06:00 Brussels
  - To: 06:00 Brussels in 2 days (+48 hours)
  - ✅ Captures today + tomorrow's events

**Why this works:**
- No timezone conversions needed
- Works identically in any timezone
- Simpler logic (no conditional branch)
- `getTime()` operates in milliseconds since epoch (universal)

## Prevention

**General principle for serverless functions:**

❌ **Avoid absolute time operations:**
```javascript
date.setHours(23, 59, 59, 999)  // UTC in Lambda!
date.setDate(date.getDate() + 1)
new Date(2026, 0, 28, 23, 59)   // Month is 0-indexed, confusing
```

✅ **Use relative time calculations:**
```javascript
now.getTime() + (24 * 60 * 60 * 1000)  // Add 24 hours
now.getTime() + daysOffset * MS_PER_DAY
Date.now() + offsetMs
```

**When you MUST use timezone-aware operations:**
1. Accept user's timezone as input parameter
2. Use a library like `date-fns-tz` or `luxon`
3. Convert to user's timezone explicitly
4. Document the timezone handling in comments

```javascript
// ✅ Explicit timezone handling
const userTime = DateTime.now().setZone(userTimezone);
const endOfDay = userTime.endOf('day');
```

**Add to systematic-debugging workflow:**

When debugging time-related bugs in Lambda:
1. Check if code uses `setHours()`, `setDate()`, or timezone-specific methods
2. Log actual Date objects in UTC and expected timezone
3. Consider: "Does this code work at midnight? At noon? In different timezones?"
4. Prefer relative time calculations when possible

**Key principle:** Serverless functions run in UTC by default. Avoid timezone assumptions. Use millisecond offsets for timezone-agnostic date math.
