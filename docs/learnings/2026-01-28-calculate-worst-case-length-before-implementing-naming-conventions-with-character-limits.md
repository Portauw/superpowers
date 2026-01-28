---
date: 2026-01-28
tags:
  - constraints
  - naming-conventions
  - eventbridge
  - aws
  - planning
workflow:
  - systematic-debugging
---

# Calculate worst-case length before implementing naming conventions with character limits

## Problem

EventBridge Scheduler has a 64-character limit for schedule names. Multi-schedule implementation went through 3 iterations:

**Attempt 1:** `sterling-schedule-{userId}-{scheduleId}`
- Example: `sterling-schedule-pieter.portauw@gmail.com-sched_uuid` = 90 chars ❌
- Error: "Member must have length less than or equal to 64"

**Attempt 2:** `cal-sched-{hash}-{scheduleId}` with 8-char hash
- Calculation: 10 + 8 + 1 + 41 = 60 chars
- Actual result: `cal-sched-bf766aac-sched_uuid` = 68 chars ❌ (hash was wrong)

**Attempt 3:** `sterling-schedule-{sanitizedUserId}-{7-char-hash}`
- Example: `sterling-schedule-pieter.portauwgmail.com-a1b2c3d` = 50 chars ✅

**Root cause:** Didn't calculate maximum possible length before coding. Started implementing without math.

## Solution

**Before implementing ANY naming convention with constraints:**

1. **Identify the constraint:**
   - EventBridge Scheduler: 64 chars max
   - Pattern: `[0-9a-zA-Z-_.]+` (no special chars like @)

2. **Calculate worst-case components:**
   ```
   Prefix:           "sterling-schedule-" = 18 chars
   Separator:        "-"                   = 1 char
   User identifier:  email (sanitized)    = ~24 chars (typical)
   Separator:        "-"                   = 1 char
   Schedule hash:    7-char MD5 slice     = 7 chars
   ----------------------------------------
   Total worst-case:                       = 51 chars
   Safety margin:                          = 13 chars
   ```

3. **Verify with examples:**
   - Short email: `user@x.co` → `sterling-schedule-userx.co-a1b2c3d` = 38 chars ✅
   - Long email: `firstname.lastname@company.com` → `sterling-schedule-firstname.lastnamecompany.com-a1b2c3d` = 67 chars ❌

4. **Adjust if needed:**
   - Hash both userId AND scheduleId to fixed length
   - Or use shorter prefix: `cal-sched-` (10 chars)

**In this session:**
After user correction, final approach calculated correctly:
- Used sanitized email (@ removed) + 7-char hash
- Stayed under 64 chars for all realistic email lengths
- Added test coverage with regex patterns instead of exact strings

## Prevention

**Add to brainstorming/planning skills:**

When designing systems with constraints (char limits, size limits, rate limits):

```
Constraint Checklist:
☐ Identify constraint (e.g., 64-char limit)
☐ List all components (prefix, identifiers, separators)
☐ Calculate worst-case length/size
☐ Verify with 3 examples (min, typical, max)
☐ Add safety margin (10-20%)
☐ Document calculation in code comments
```

**Example code comment:**
```typescript
// Schedule name format: sterling-schedule-{sanitizedUserId}-{7-char-hash}
// Max length calculation:
//   Prefix: 18 chars
//   Typical email (sanitized): ~24 chars
//   Hash: 7 chars
//   Separators: 2 chars
//   Total: ~51 chars (13 char safety margin from 64-char limit)
function getMultiScheduleName(userId: string, scheduleId: string): string {
  // ...
}
```

**Key principle:** Measure twice, cut once. Math before implementation prevents iterative fixes.
