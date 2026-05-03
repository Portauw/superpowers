#!/bin/bash

# Test the `performance` skill with pressure scenarios.
# Iron Law: MEASURE FIRST, OPTIMIZE SECOND. NO OPTIMIZATION WITHOUT A PROFILE.
#
# These scenarios push the agent toward optimization-first responses.
# Without the skill, the agent should jump to code edits (memoize, cache,
# code-split) without asking for measurements.
# With the skill, the agent should refuse to optimize and demand a profile,
# repro, or numbers first.

source "$(dirname "$0")/test-helpers.sh"

SKILL_FILE="$(cd "$(dirname "$0")/../.." && pwd)/skills/performance/SKILL.md"
CHECKLIST_FILE="$(cd "$(dirname "$0")/../.." && pwd)/skills/performance/performance-checklist.md"

# Run Claude with a prompt from a file (avoids bash escaping issues).
# Usage: run_claude_file "prompt_file" [timeout] [allowed_tools]
run_claude_file() {
    local prompt_file="$1"
    local timeout="${2:-60}"
    local allowed_tools="${3:-}"
    local output_file=$(mktemp)

    local cmd_args=(-p "$(cat "$prompt_file")")
    if [ -n "$allowed_tools" ]; then
        cmd_args+=(--allowed-tools="$allowed_tools")
    fi

    if run_with_timeout "$timeout" claude "${cmd_args[@]}" > "$output_file" 2>&1; then
        cat "$output_file"
        rm -f "$output_file"
        return 0
    else
        local exit_code=$?
        cat "$output_file" >&2
        rm -f "$output_file"
        return $exit_code
    fi
}

# Heuristics for detecting optimization-first responses.
#
# A response that "demands measurement" should mention at least one of:
#   profile, profiler, measure, measurement, repro, reproduce,
#   Performance trace, Web Vitals, LCP, INP, CLS, EXPLAIN, query plan,
#   APM, "before / after"
#
# A response that "jumps to fixes" mentions optimization mechanics without
# measurement: useMemo, React.memo, useCallback, lazy(), Suspense, cache,
# Redis, CDN, virtualize, debounce — applied confidently as a fix.

count_measurement_mentions() {
    local text="$1"
    local count=0
    for term in profile profiler measure measurement repro reproduce \
                "Web Vitals" LCP INP CLS EXPLAIN "query plan" APM \
                "before and after" "before/after" baseline; do
        if echo "$text" | grep -iqE "\\b${term}\\b|${term}"; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

count_optimization_jumps() {
    local text="$1"
    local count=0
    for term in useMemo React.memo useCallback "lazy(" Suspense \
                "in-memory cache" Redis CDN virtualize virtualization debounce; do
        if echo "$text" | grep -iqE "${term}"; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

# Pressure Scenario 1: Vague slowness report.
# Expected WITHOUT skill: agent sprinkles useMemo, adds caching, code-splits.
# Expected WITH skill:    agent refuses to optimize, demands repro + profile.
test_vague_slowness_baseline() {
    local prompt="Users say the dashboard feels slow. Make it faster. The app is in this directory: /tmp/dashboard-app (assume it's a typical React + Node app). Plan your approach. Only use the Read tool — do not edit yet."

    echo "Running Claude (RED, no skill)..."
    local response=$(run_claude "$prompt" 90 "Read")

    echo "RESPONSE (first 40 lines):"
    echo "$response" | head -40
    echo ""

    local meas=$(count_measurement_mentions "$response")
    local jumps=$(count_optimization_jumps "$response")

    echo "MEASUREMENT MENTIONS: $meas"
    echo "OPTIMIZATION JUMPS:   $jumps"

    if [ "$jumps" -gt "$meas" ]; then
        echo "BASELINE: Agent jumped to optimizations without measurement (expected without skill)"
    else
        echo "NOTE: Agent already demanded measurement — baseline weaker than expected"
    fi
    return 0
}

# Pressure Scenario 2: User prescribes the wrong fix.
# Expected WITHOUT skill: agent applies React.memo as instructed.
# Expected WITH skill:    agent challenges the premise (50 items shouldn't be slow),
#                         asks for profile, suggests alternatives (N+1, layout thrash).
test_wrong_prescription_baseline() {
    local prompt="This list of 50 items renders slowly in our React app. Memoize the items. Plan your approach — do not edit any files. Only use the Read tool."

    echo "Running Claude (RED, no skill)..."
    local response=$(run_claude "$prompt" 90 "Read")

    echo "RESPONSE (first 40 lines):"
    echo "$response" | head -40
    echo ""

    local meas=$(count_measurement_mentions "$response")
    local jumps=$(count_optimization_jumps "$response")

    # Did the agent push back on the premise that 50 items should be slow?
    local pushback=0
    if echo "$response" | grep -iqE "50 items.*(should not|shouldn't|isn't|not.*many)|premise|investigate.*cause|other.*cause|N\\+1|layout thrash|profile.*first"; then
        pushback=1
    fi

    echo "MEASUREMENT MENTIONS: $meas"
    echo "OPTIMIZATION JUMPS:   $jumps"
    echo "PUSHBACK ON PREMISE:  $pushback"

    if [ "$pushback" -eq 0 ] && [ "$jumps" -gt 0 ]; then
        echo "BASELINE: Agent accepted the user's prescription without challenge (expected without skill)"
    else
        echo "NOTE: Agent already pushed back — baseline weaker than expected"
    fi
    return 0
}

echo "===== RED PHASE: Baseline Testing (No Skill) ====="
echo ""

echo "Test 1: Vague slowness report"
echo "============================="
test_vague_slowness_baseline
echo ""

echo "Test 2: User prescribes the wrong fix"
echo "====================================="
test_wrong_prescription_baseline
echo ""

echo "===== BASELINE COMPLETE ====="
echo "Document observed rationalizations and failures before evaluating GREEN."

# ===== GREEN PHASE: Test WITH skill loaded =====

if [ ! -f "$SKILL_FILE" ]; then
    echo ""
    echo "===== GREEN PHASE: SKIPPED (no skill file found) ====="
    echo "Expected at: $SKILL_FILE"
    exit 0
fi

# Green Test 1: Vague slowness report WITH skill — agent should demand measurement.
test_vague_slowness_with_skill() {
    local prompt_file=$(mktemp)
    cat > "$prompt_file" << ENDPROMPT
You MUST follow this skill when handling performance work:

$(cat "$SKILL_FILE")

---

Users say the dashboard feels slow. Make it faster. The app is in this directory: /tmp/dashboard-app (assume it's a typical React + Node app). Plan your approach. Only use the Read tool — do not edit yet.
ENDPROMPT

    echo "Running Claude WITH skill..."
    local response=$(run_claude_file "$prompt_file" 120 "Read")
    rm -f "$prompt_file"

    echo "RESPONSE (first 40 lines):"
    echo "$response" | head -40
    echo ""

    local meas=$(count_measurement_mentions "$response")
    local jumps=$(count_optimization_jumps "$response")

    echo "MEASUREMENT MENTIONS: $meas"
    echo "OPTIMIZATION JUMPS:   $jumps"

    local pass=true
    # GREEN expectation: at least 3 measurement-related mentions, and
    # measurement mentions should outweigh optimization jumps.
    if [ "$meas" -lt 3 ]; then
        echo "  [FAIL] GREEN: Expected >=3 measurement mentions, got $meas"
        pass=false
    fi
    if [ "$jumps" -gt "$meas" ]; then
        echo "  [FAIL] GREEN: Optimization jumps ($jumps) outweigh measurement ($meas)"
        pass=false
    fi

    # Did the agent ask for a repro / specifics?
    if echo "$response" | grep -iqE "which page|which device|what.*device|network|repro|reproduce|how slow|specifically"; then
        echo "  [PASS] Agent asked for repro / specifics"
    else
        echo "  [FAIL] GREEN: Agent did not ask for repro details"
        pass=false
    fi

    $pass && echo "  [PASS] GREEN: skill held the line on measurement-first" \
          || echo "  [FAIL] GREEN: skill did not hold the line"
    $pass && return 0 || return 1
}

# Green Test 2: Wrong prescription WITH skill — agent should challenge the premise.
test_wrong_prescription_with_skill() {
    local prompt_file=$(mktemp)
    cat > "$prompt_file" << ENDPROMPT
You MUST follow this skill when handling performance work:

$(cat "$SKILL_FILE")

---

This list of 50 items renders slowly in our React app. Memoize the items. Plan your approach — do not edit any files. Only use the Read tool.
ENDPROMPT

    echo "Running Claude WITH skill..."
    local response=$(run_claude_file "$prompt_file" 120 "Read")
    rm -f "$prompt_file"

    echo "RESPONSE (first 40 lines):"
    echo "$response" | head -40
    echo ""

    local meas=$(count_measurement_mentions "$response")
    local pass=true

    # Did the agent push back on "50 items should be slow"?
    if echo "$response" | grep -iqE "50 items.*(should not|shouldn't|small|not.*many|surprising)|premise|N\\+1|layout thrash|other.*cause|alternative cause"; then
        echo "  [PASS] Agent challenged the premise that 50 items should be slow"
    else
        echo "  [FAIL] GREEN: Agent did not challenge the premise"
        pass=false
    fi

    # Did the agent ask for a profile?
    if echo "$response" | grep -iqE "profiler|profile.*first|React Profiler|Performance trace|measure"; then
        echo "  [PASS] Agent asked for a profile"
    else
        echo "  [FAIL] GREEN: Agent did not ask for a profile"
        pass=false
    fi

    # At least 2 measurement-related mentions overall.
    if [ "$meas" -lt 2 ]; then
        echo "  [FAIL] GREEN: Expected >=2 measurement mentions, got $meas"
        pass=false
    fi

    $pass && echo "  [PASS] GREEN: skill challenged the prescription correctly" \
          || echo "  [FAIL] GREEN: skill failed to challenge the prescription"
    $pass && return 0 || return 1
}

echo ""
echo "===== GREEN PHASE: Testing WITH Skill ====="
echo ""

echo "Green Test 1: Vague slowness report (WITH skill)"
echo "================================================="
test_vague_slowness_with_skill
echo ""

echo "Green Test 2: User prescribes the wrong fix (WITH skill)"
echo "========================================================="
test_wrong_prescription_with_skill
echo ""

echo "===== GREEN PHASE COMPLETE ====="
