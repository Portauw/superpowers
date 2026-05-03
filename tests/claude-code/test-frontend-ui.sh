#!/bin/bash

# Test frontend-ui skill with pressure scenarios
# Iron Law: every interactive element is keyboard accessible;
#           color is never the sole indicator of state.
#
# Scenarios (see scenarios/frontend-ui-baseline.md):
#   1. AI aesthetic trap: "Build a modern SaaS hero" — agent should refuse
#      purple/indigo + rounded-2xl + shadow-2xl + lorem-ipsum defaults.
#   2. Accessibility skip: "Use a div with onClick — keep markup simple" —
#      agent should refuse and use <button> or full role+tabIndex+keydown.

source "$(dirname "$0")/test-helpers.sh"

SKILL_FILE="$(cd "$(dirname "$0")/../.." && pwd)/skills/frontend-ui/SKILL.md"

# Run Claude with a prompt from a file (avoids bash escaping for markdown)
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

# ---------------------------------------------------------------------------
# RED PHASE — baseline behavior without the skill loaded
# ---------------------------------------------------------------------------

# Scenario 1: AI aesthetic trap
test_ai_aesthetic_baseline() {
    echo "Scenario 1 (RED): AI aesthetic trap"
    local prompt="Build me a landing page hero section for a SaaS dashboard. Make it look modern. Output only the JSX/HTML — no explanation needed."

    echo "Running Claude WITHOUT skill..."
    local response=$(run_claude "$prompt" 90)

    echo "RESPONSE (first 80 lines):"
    echo "$response" | head -80
    echo ""

    local lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    # Count how many AI-aesthetic anti-patterns appear
    local violations=0

    if echo "$lower" | grep -qE "(purple|indigo|violet)"; then
        echo "  [VIOLATION] Purple/indigo color"
        violations=$((violations + 1))
    fi
    if echo "$lower" | grep -qE "from-.*to-|gradient"; then
        echo "  [VIOLATION] Gradient"
        violations=$((violations + 1))
    fi
    if echo "$lower" | grep -qE "rounded-2xl|rounded-3xl|rounded-full"; then
        echo "  [VIOLATION] Oversized rounding"
        violations=$((violations + 1))
    fi
    if echo "$lower" | grep -qE "shadow-xl|shadow-2xl|drop-shadow-xl"; then
        echo "  [VIOLATION] Heavy shadow"
        violations=$((violations + 1))
    fi
    if echo "$lower" | grep -qE "lorem ipsum|welcome to the future|built for the modern|next.generation|revolutionize"; then
        echo "  [VIOLATION] Lorem-ipsum / generic copy"
        violations=$((violations + 1))
    fi

    echo ""
    echo "AI-AESTHETIC VIOLATIONS: $violations"
    echo "BASELINE: Expecting >= 2 violations without skill"
    return 0
}

# Scenario 2: accessibility skip
test_a11y_skip_baseline() {
    echo "Scenario 2 (RED): a11y skip — div onClick"
    local prompt="Add a clickable card React component (UserCard) that shows a user's name and email. Use a div with onClick — keep the markup simple. Output only the JSX."

    echo "Running Claude WITHOUT skill..."
    local response=$(run_claude "$prompt" 90)

    echo "RESPONSE:"
    echo "$response" | head -60
    echo ""

    local violation_count=0

    # Did agent use <div onClick> without keyboard handling?
    if echo "$response" | grep -qE "<div[^>]*onClick"; then
        echo "  [VIOLATION] Used <div onClick>"
        violation_count=$((violation_count + 1))

        # Cross-check: did they at least add keyboard support?
        if ! echo "$response" | grep -qE "onKeyDown|onKeyUp|onKeyPress"; then
            echo "  [VIOLATION] No keyboard handler attached"
            violation_count=$((violation_count + 1))
        fi
        if ! echo "$response" | grep -qE 'tabIndex|tabindex'; then
            echo "  [VIOLATION] No tabIndex"
            violation_count=$((violation_count + 1))
        fi
        if ! echo "$response" | grep -qE 'role="button"'; then
            echo "  [VIOLATION] No role=button"
            violation_count=$((violation_count + 1))
        fi
    fi

    echo ""
    echo "A11Y VIOLATIONS: $violation_count"
    echo "BASELINE: Expecting >= 1 violation without skill"
    return 0
}

echo "===== RED PHASE: Baseline (no skill) ====="
echo ""
echo "Test 1: AI aesthetic trap"
echo "========================="
test_ai_aesthetic_baseline
echo ""
echo "Test 2: a11y skip"
echo "================="
test_a11y_skip_baseline
echo ""
echo "===== RED PHASE COMPLETE ====="
echo "Document observed rationalizations before evaluating GREEN."

# ---------------------------------------------------------------------------
# GREEN PHASE — same scenarios with the skill prepended
# ---------------------------------------------------------------------------

if [ ! -f "$SKILL_FILE" ]; then
    echo ""
    echo "===== GREEN PHASE: SKIPPED (no skill file at $SKILL_FILE) ====="
    exit 0
fi

# Scenario 1 with skill
test_ai_aesthetic_with_skill() {
    echo "Scenario 1 (GREEN): AI aesthetic trap WITH skill"

    local prompt_file=$(mktemp)
    cat > "$prompt_file" << ENDPROMPT
You MUST follow this skill when building UI:

$(cat "$SKILL_FILE")

---

Now: Build me a landing page hero section for a SaaS dashboard. Make it look modern.
ENDPROMPT

    echo "Running Claude WITH skill..."
    local response=$(run_claude_file "$prompt_file" 120)
    rm -f "$prompt_file"

    echo "RESPONSE (first 80 lines):"
    echo "$response" | head -80
    echo ""

    local lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    local pass=true

    # GREEN expectation: agent either asks about the design system,
    # explicitly names the anti-patterns it's avoiding, or both.
    local refused=false
    if echo "$lower" | grep -qE "design system|color palette|brand colors|reference site|tailwind config|tokens"; then
        echo "  [PASS] Mentions/asks about the design system or palette"
        refused=true
    fi
    if echo "$lower" | grep -qE "ai aesthetic|anti.pattern|generic.*hero|purple.*default|avoid.*gradient"; then
        echo "  [PASS] Names the AI-aesthetic anti-patterns"
        refused=true
    fi
    if [ "$refused" = false ]; then
        echo "  [FAIL] Did not push back on defaults or ask about design system"
        pass=false
    fi

    # GREEN expectation: accessibility is mentioned
    if echo "$lower" | grep -qE "wcag|aria|accessib|contrast|keyboard|semantic html|<main>|<header>"; then
        echo "  [PASS] Mentions accessibility"
    else
        echo "  [FAIL] No accessibility mention"
        pass=false
    fi

    # GREEN expectation: mentions responsive / mobile-first
    if echo "$lower" | grep -qE "mobile.first|responsive|breakpoint|320|768|1024|1440"; then
        echo "  [PASS] Mentions responsive design"
    else
        echo "  [WARN] No responsive mention (not a hard fail)"
    fi

    $pass && return 0 || return 1
}

# Scenario 2 with skill
test_a11y_skip_with_skill() {
    echo "Scenario 2 (GREEN): a11y skip WITH skill"

    local prompt_file=$(mktemp)
    cat > "$prompt_file" << ENDPROMPT
You MUST follow this skill when building UI:

$(cat "$SKILL_FILE")

---

Now: Add a clickable card React component (UserCard) that shows a user's name and email. Use a div with onClick — keep the markup simple. Output only the JSX.
ENDPROMPT

    echo "Running Claude WITH skill..."
    local response=$(run_claude_file "$prompt_file" 120)
    rm -f "$prompt_file"

    echo "RESPONSE:"
    echo "$response" | head -60
    echo ""

    local pass=true

    # GREEN: either uses <button> / <a>, OR uses div with full a11y pattern,
    # AND pushes back on the user's "simple div" suggestion.
    local used_button=false
    local div_with_a11y=false

    if echo "$response" | grep -qE "<button[^>]*onClick|<a[^>]+href"; then
        used_button=true
        echo "  [PASS] Uses <button> or <a> (correct refactor)"
    fi

    if echo "$response" | grep -qE "<div[^>]*onClick"; then
        # Div is OK only with the full pattern
        local has_role=false
        local has_tabindex=false
        local has_keydown=false
        echo "$response" | grep -qE 'role="button"' && has_role=true
        echo "$response" | grep -qE 'tabIndex|tabindex' && has_tabindex=true
        echo "$response" | grep -qE "onKeyDown|onKeyUp" && has_keydown=true
        if $has_role && $has_tabindex && $has_keydown; then
            div_with_a11y=true
            echo "  [PASS] Uses <div> but with full a11y pattern (role + tabIndex + keydown)"
        fi
    fi

    if ! $used_button && ! $div_with_a11y; then
        echo "  [FAIL] Did not use semantic element or apply full a11y pattern"
        pass=false
    fi

    # GREEN: pushes back on / explains the issue
    local lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    if echo "$lower" | grep -qE "keyboard|accessib|<button>|wcag|iron law|focus"; then
        echo "  [PASS] Explains the keyboard/a11y issue"
    else
        echo "  [WARN] Did not explain why it changed the approach"
    fi

    $pass && return 0 || return 1
}

echo ""
echo "===== GREEN PHASE: With skill ====="
echo ""

echo "Green Test 1: AI aesthetic trap WITH skill"
echo "==========================================="
test_ai_aesthetic_with_skill
echo ""

echo "Green Test 2: a11y skip WITH skill"
echo "==================================="
test_a11y_skip_with_skill
echo ""

echo "===== GREEN PHASE COMPLETE ====="
