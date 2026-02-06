---
date: 2026-02-06
type: backtracking
source: ai-detected
confidence: high
category: general-workflow
tags: [typescript, build-verification, compilation, verification-before-completion]
project: calendar-prep-mvp
---

# TypeScript build verification must be mandatory in Gate Function

## What Happened

During feature implementation (folder display), made three TypeScript changes and pushed all three without running local build verification. All three had compilation errors caught by CI, not locally:

1. Push 1: Missing type definitions for ScheduleConfig
2. Push 2: `undefined` vs `null` type mismatch
3. Push 3: Missing connections directory (untracked in git)

## AI Assumption

Assumed build verification guidance in the "Reference" section of verification-before-completion skill was sufficient. Thought simple TypeScript changes (adding optional fields) didn't need build verification.

## Reality

Build verification guidance existed in skill (lines 113-136) but was in a reference section, NOT in the mandatory Gate Function workflow (lines 40-56). This made it optional rather than required.

**Rationalizations used:**
- "Simple change, build not needed"
- "Just added optional field"
- "It's just types, no logic"
- End-of-session fatigue

## Lesson

For TypeScript/compiled projects, build verification must be Step 0 in the Gate Function, BEFORE any other checks. Reference sections are easy to skip under pressure.

**Evidence from baseline testing:** Haiku agent DID include build verification when it was in reference section, but Sonnet (me) skipped it. Shows reference guidance is inconsistent.

**Evidence from enhanced skill testing:** After moving build verification to mandatory Step 0 in Gate Function, Haiku agent explicitly identified it as non-negotiable and listed exact evidence needed.

## Context

**Session:** ai-self-reflecting skill invoked after folder display feature
**Skill modified:** verification-before-completion (4.4.0)
**Test methodology:** RED-GREEN-REFACTOR with pressure scenarios

**Real-world impact:** 3 broken pushes, Amplify CI caught errors, manual fixes required

## Suggested Action

✅ IMPLEMENTED: Enhanced verification-before-completion skill on 2026-02-06

**Changes made:**

1. **Added Step 0 to Gate Function** - Build verification is now first mandatory step for TypeScript/compiled projects
2. **Added build-specific rationalizations** - "Simple change, build not needed", "Just types", "CI will catch it"
3. **Updated Red Flags** - Added TypeScript-specific red flags about skipping builds
4. **Tested with pressure scenarios** - Confirmed agents now follow Step 0 rigorously

**Files modified:**
- `/Users/pieter/Dev/superpowers/skills/verification-before-completion/SKILL.md`

**Commit:** (pending - skill work in progress)