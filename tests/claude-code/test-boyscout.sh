#!/bin/bash

# Test boyscout skill with pressure scenarios
# Boy Scout Rule: "Always leave the code cleaner than you found it"

source "$(dirname "$0")/test-helpers.sh"

SKILL_FILE="$(cd "$(dirname "$0")/../.." && pwd)/skills/boyscout/SKILL.md"

# Run Claude with a prompt from a file (avoids bash escaping issues with markdown)
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

# Setup a test repo with git initialized
setup_git_repo() {
    local name="$1"
    local test_dir=$(create_test_project)
    cd "$test_dir"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "$test_dir"
}

# Pressure Scenario 1: Bug fix in file with obvious cleanup opportunities
# Expected WITHOUT skill: Claude fixes the bug only, ignores surrounding mess
# Expected WITH skill: Claude fixes bug AND makes small improvements nearby
test_bugfix_with_messy_surroundings() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "boyscout-bugfix")

    cat > "$test_dir/user-service.js" << 'ENDOFFILE'
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const http = require('http');

// TODO: clean this up later
var users = [];
var temp = null;

function getUser(id) {
    var usr = null;
    for (var i = 0; i < users.length; i++) {
        if (users[i].id == id) {
            usr = users[i];
        }
    }
    return usr;
}

function addUser(name, email) {
    // BUG: id should be generated, not hardcoded to 1
    var newUser = { id: 1, name: name, email: email, active: true };
    users.push(newUser);
    return newUser;
}

function removeUser(id) {
    var idx = -1;
    for (var i = 0; i < users.length; i++) {
        if (users[i].id == id) {
            idx = i;
        }
    }
    if (idx > -1) {
        users.splice(idx, 1);
    }
}

function getActiveUsers() {
    var result = [];
    for (var i = 0; i < users.length; i++) {
        if (users[i].active == true) {
            result.push(users[i]);
        }
    }
    return result;
}

module.exports = { getUser, addUser, removeUser, getActiveUsers };
ENDOFFILE

    cd "$test_dir"
    git add -A
    git commit -q -m "Add user service"

    local prompt="Fix the bug in addUser() in $test_dir/user-service.js - the id is hardcoded to 1 instead of being auto-generated. Use an incrementing counter. Only use the Read, Edit, and Write tools."

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120 "Read,Edit,Write")

    echo "RESPONSE:"
    echo "$response" | head -30
    echo ""

    # Check that the bug was fixed (primary task)
    if [ -f "$test_dir/user-service.js" ]; then
        local file_content=$(cat "$test_dir/user-service.js")

        # Primary task: bug fix applied
        assert_not_contains "$file_content" "id: 1," "Bug fix: id no longer hardcoded to 1"

        # Boyscout improvements we'd LIKE to see:
        # - Unused imports removed (fs, path, crypto, http are all unused)
        # - var -> const/let
        # - == -> ===
        # - .filter() instead of manual loops
        # - Remove unused 'temp' variable
        # - Remove TODO comment

        # Check for ANY boyscout improvements
        local improvements=0

        # Check: unused imports removed
        if ! echo "$file_content" | grep -q "require('fs')"; then
            echo "  [IMPROVEMENT] Removed unused fs import"
            improvements=$((improvements + 1))
        fi

        # Check: var replaced with const/let
        if ! echo "$file_content" | grep -q "^var "; then
            echo "  [IMPROVEMENT] Replaced var with const/let"
            improvements=$((improvements + 1))
        fi

        # Check: == replaced with ===
        if ! echo "$file_content" | grep -q "== "; then
            echo "  [IMPROVEMENT] Replaced == with ==="
            improvements=$((improvements + 1))
        fi

        # Check: unused temp variable removed
        if ! echo "$file_content" | grep -q "var temp\|let temp\|const temp"; then
            echo "  [IMPROVEMENT] Removed unused temp variable"
            improvements=$((improvements + 1))
        fi

        echo ""
        echo "BOYSCOUT IMPROVEMENTS: $improvements"
        if [ $improvements -eq 0 ]; then
            echo "BASELINE: No boyscout improvements made (agent only fixed the bug)"
        else
            echo "NOTE: Agent made $improvements improvements beyond the bug fix"
        fi
    else
        echo "  [FAIL] File not found after edit"
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Pressure Scenario 2: Feature addition near messy code with time pressure
# Expected WITHOUT skill: Claude adds feature, ignores surrounding mess
# Expected WITH skill: Claude adds feature AND makes small nearby improvements
test_feature_with_time_pressure() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "boyscout-feature")

    cat > "$test_dir/config.js" << 'ENDOFFILE'
const os = require('os');
const dns = require('dns');

var config = {
    port: 3000,
    host: 'localhost',
    debug: false,
    logLevel: 'info',
};

// get the config value
function getConfig(key) {
    if (config[key] != undefined) {
        return config[key];
    } else {
        return null;
    }
}

// set config value
function setConfig(key, value) {
    config[key] = value;
    return true;
}

// TODO: add validation
function validateConfig() {
    return true;
}

module.exports = { getConfig, setConfig, validateConfig, config };
ENDOFFILE

    cd "$test_dir"
    git add -A
    git commit -q -m "Add config module"

    local prompt="Add a resetConfig() function to $test_dir/config.js that resets all config values to their defaults. I'm in a hurry, just add the function. Only use the Read, Edit, and Write tools."

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120 "Read,Edit,Write")

    echo "RESPONSE:"
    echo "$response" | head -30
    echo ""

    if [ -f "$test_dir/config.js" ]; then
        local file_content=$(cat "$test_dir/config.js")

        # Primary task: resetConfig added
        assert_contains "$file_content" "resetConfig" "Feature: resetConfig function added"

        # Boyscout checks
        local improvements=0

        if ! echo "$file_content" | grep -q "require('os')"; then
            echo "  [IMPROVEMENT] Removed unused os import"
            improvements=$((improvements + 1))
        fi

        if ! echo "$file_content" | grep -q "require('dns')"; then
            echo "  [IMPROVEMENT] Removed unused dns import"
            improvements=$((improvements + 1))
        fi

        if ! echo "$file_content" | grep -q "!= undefined"; then
            echo "  [IMPROVEMENT] Fixed != undefined check"
            improvements=$((improvements + 1))
        fi

        echo ""
        echo "BOYSCOUT IMPROVEMENTS: $improvements"
        if [ $improvements -eq 0 ]; then
            echo "BASELINE: No boyscout improvements made (agent only added feature)"
        else
            echo "NOTE: Agent made $improvements improvements beyond the feature"
        fi
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Pressure Scenario 3: Scope creep guard - ensure agent doesn't over-scout
# Expected: Agent makes a few improvements but doesn't rewrite the whole file
test_scope_guard() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "boyscout-scope")

    # Create a large messy file - agent should NOT rewrite it all
    cat > "$test_dir/legacy.js" << 'ENDOFFILE'
var EventEmitter = require('events');
var util = require('util');
var assert = require('assert');
var Buffer = require('buffer').Buffer;
var stream = require('stream');

var counter = 0;
var temp1 = '';
var temp2 = '';
var temp3 = null;
var unused_flag = false;

function processItem(item) {
    if (item != null) {
        if (item.type == 'a') {
            return handleTypeA(item);
        } else if (item.type == 'b') {
            return handleTypeB(item);
        } else if (item.type == 'c') {
            return handleTypeC(item);
        } else {
            return null;
        }
    }
    return null;
}

function handleTypeA(item) {
    var result = {};
    result.name = item.name;
    result.value = item.value * 2;
    result.processed = true;
    return result;
}

function handleTypeB(item) {
    var result = {};
    result.name = item.name;
    result.value = item.value * 3;
    result.processed = true;
    return result;
}

function handleTypeC(item) {
    var result = {};
    result.name = item.name;
    result.value = item.value * 4;
    result.processed = true;
    return result;
}

function formatOutput(items) {
    var output = '';
    for (var i = 0; i < items.length; i++) {
        output = output + items[i].name + ': ' + items[i].value + '\n';
    }
    return output;
}

function calculateTotal(items) {
    var total = 0;
    for (var i = 0; i < items.length; i++) {
        total = total + items[i].value;
    }
    return total;
}

// BUG: off by one error in slice
function getPage(items, page, pageSize) {
    var start = page * pageSize;
    var end = start + pageSize + 1;
    return items.slice(start, end);
}

module.exports = { processItem, formatOutput, calculateTotal, getPage };
ENDOFFILE

    cd "$test_dir"
    git add -A
    git commit -q -m "Add legacy processing module"

    local prompt="Fix the off-by-one error in getPage() in $test_dir/legacy.js. The end index should be start + pageSize, not start + pageSize + 1. Only use the Read, Edit, and Write tools."

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120 "Read,Edit,Write")

    echo "RESPONSE:"
    echo "$response" | head -30
    echo ""

    if [ -f "$test_dir/legacy.js" ]; then
        local file_content=$(cat "$test_dir/legacy.js")

        # Primary: bug fixed
        assert_not_contains "$file_content" "pageSize + 1" "Bug fix: off-by-one corrected"

        # Scope guard: file should NOT be completely rewritten
        # The handleTypeA/B/C pattern is duplicated but refactoring it is TOO BIG for boyscouting
        assert_contains "$file_content" "handleTypeA" "Scope: handleTypeA still exists (not over-refactored)"
        assert_contains "$file_content" "handleTypeB" "Scope: handleTypeB still exists (not over-refactored)"
        assert_contains "$file_content" "handleTypeC" "Scope: handleTypeC still exists (not over-refactored)"

        # Count how many lines changed from original (rough measure)
        local original_lines=72
        local current_lines=$(wc -l < "$test_dir/legacy.js" | tr -d ' ')
        local diff=$((original_lines - current_lines))
        if [ $diff -lt 0 ]; then diff=$((-diff)); fi

        echo ""
        echo "SCOPE CHECK: Original $original_lines lines, now $current_lines lines (diff: $diff)"
        if [ $diff -gt 20 ]; then
            echo "WARNING: Large change detected - agent may have over-scouted"
        else
            echo "OK: Change scope appears reasonable"
        fi
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Run baseline tests (RED phase)
echo "===== RED PHASE: Baseline Testing (No Skill) ====="
echo ""

echo "Test 1: Bug fix with messy surroundings"
echo "========================================"
test_bugfix_with_messy_surroundings
echo ""

echo "Test 2: Feature addition with time pressure"
echo "============================================"
test_feature_with_time_pressure
echo ""

echo "Test 3: Scope guard (don't over-scout)"
echo "======================================="
test_scope_guard
echo ""

echo "===== BASELINE COMPLETE ====="
echo "Document observed rationalizations and failures before writing skill."

# ===== GREEN PHASE: Test WITH skill loaded =====

if [ ! -f "$SKILL_FILE" ]; then
    echo ""
    echo "===== GREEN PHASE: SKIPPED (no skill file found) ====="
    echo "Write the skill first, then re-run."
    exit 0
fi

# Green Test 1: Bug fix with messy surroundings (WITH skill)
test_bugfix_with_skill() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "boyscout-green-bugfix")

    cat > "$test_dir/user-service.js" << 'ENDOFFILE'
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const http = require('http');

// TODO: clean this up later
var users = [];
var temp = null;

function getUser(id) {
    var usr = null;
    for (var i = 0; i < users.length; i++) {
        if (users[i].id == id) {
            usr = users[i];
        }
    }
    return usr;
}

function addUser(name, email) {
    // BUG: id should be generated, not hardcoded to 1
    var newUser = { id: 1, name: name, email: email, active: true };
    users.push(newUser);
    return newUser;
}

function removeUser(id) {
    var idx = -1;
    for (var i = 0; i < users.length; i++) {
        if (users[i].id == id) {
            idx = i;
        }
    }
    if (idx > -1) {
        users.splice(idx, 1);
    }
}

function getActiveUsers() {
    var result = [];
    for (var i = 0; i < users.length; i++) {
        if (users[i].active == true) {
            result.push(users[i]);
        }
    }
    return result;
}

module.exports = { getUser, addUser, removeUser, getActiveUsers };
ENDOFFILE

    cd "$test_dir"
    git add -A
    git commit -q -m "Add user service"

    local prompt_file=$(mktemp)
    cat > "$prompt_file" << ENDPROMPT
You MUST follow this skill when editing files:

$(cat "$SKILL_FILE")

---

Now: Fix the bug in addUser() in $test_dir/user-service.js - the id is hardcoded to 1 instead of being auto-generated. Use an incrementing counter. Only use the Read, Edit, and Write tools.
ENDPROMPT

    echo "Running Claude WITH skill..."
    local response=$(run_claude_file "$prompt_file" 120 "Read,Edit,Write")
    rm -f "$prompt_file"

    echo "RESPONSE:"
    echo "$response" | head -30
    echo ""

    local pass=true
    if [ -f "$test_dir/user-service.js" ]; then
        local file_content=$(cat "$test_dir/user-service.js")

        # Primary task must still be done
        assert_not_contains "$file_content" "id: 1," "Bug fix: id no longer hardcoded" || pass=false

        # Now check for boyscout improvements (we expect at least 2)
        local improvements=0

        if ! echo "$file_content" | grep -q "require('fs')"; then
            echo "  [IMPROVEMENT] Removed unused fs import"
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "require('path')"; then
            echo "  [IMPROVEMENT] Removed unused path import"
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "require('crypto')"; then
            echo "  [IMPROVEMENT] Removed unused crypto import"
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "require('http')"; then
            echo "  [IMPROVEMENT] Removed unused http import"
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "^var "; then
            echo "  [IMPROVEMENT] Replaced var with const/let"
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "== "; then
            echo "  [IMPROVEMENT] Replaced == with ==="
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "var temp\|let temp\|const temp"; then
            echo "  [IMPROVEMENT] Removed unused temp variable"
            improvements=$((improvements + 1))
        fi

        echo ""
        echo "BOYSCOUT IMPROVEMENTS: $improvements"
        if [ $improvements -ge 2 ]; then
            echo "  [PASS] GREEN: Agent made $improvements boyscout improvements"
        else
            echo "  [FAIL] GREEN: Expected at least 2 improvements, got $improvements"
            pass=false
        fi
    fi

    cleanup_test_project "$test_dir"
    $pass && return 0 || return 1
}

# Green Test 2: Scope guard with skill (should improve but not over-refactor)
test_scope_guard_with_skill() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "boyscout-green-scope")

    cat > "$test_dir/legacy.js" << 'ENDOFFILE'
var EventEmitter = require('events');
var util = require('util');
var assert = require('assert');
var Buffer = require('buffer').Buffer;
var stream = require('stream');

var counter = 0;
var temp1 = '';
var temp2 = '';
var temp3 = null;
var unused_flag = false;

function processItem(item) {
    if (item != null) {
        if (item.type == 'a') {
            return handleTypeA(item);
        } else if (item.type == 'b') {
            return handleTypeB(item);
        } else if (item.type == 'c') {
            return handleTypeC(item);
        } else {
            return null;
        }
    }
    return null;
}

function handleTypeA(item) {
    var result = {};
    result.name = item.name;
    result.value = item.value * 2;
    result.processed = true;
    return result;
}

function handleTypeB(item) {
    var result = {};
    result.name = item.name;
    result.value = item.value * 3;
    result.processed = true;
    return result;
}

function handleTypeC(item) {
    var result = {};
    result.name = item.name;
    result.value = item.value * 4;
    result.processed = true;
    return result;
}

function formatOutput(items) {
    var output = '';
    for (var i = 0; i < items.length; i++) {
        output = output + items[i].name + ': ' + items[i].value + '\n';
    }
    return output;
}

function calculateTotal(items) {
    var total = 0;
    for (var i = 0; i < items.length; i++) {
        total = total + items[i].value;
    }
    return total;
}

// BUG: off by one error in slice
function getPage(items, page, pageSize) {
    var start = page * pageSize;
    var end = start + pageSize + 1;
    return items.slice(start, end);
}

module.exports = { processItem, formatOutput, calculateTotal, getPage };
ENDOFFILE

    cd "$test_dir"
    git add -A
    git commit -q -m "Add legacy processing module"

    local prompt_file=$(mktemp)
    cat > "$prompt_file" << ENDPROMPT
You MUST follow this skill when editing files:

$(cat "$SKILL_FILE")

---

Now: Fix the off-by-one error in getPage() in $test_dir/legacy.js. The end index should be start + pageSize, not start + pageSize + 1. Only use the Read, Edit, and Write tools.
ENDPROMPT

    echo "Running Claude WITH skill..."
    local response=$(run_claude_file "$prompt_file" 120 "Read,Edit,Write")
    rm -f "$prompt_file"

    echo "RESPONSE:"
    echo "$response" | head -30
    echo ""

    local pass=true
    if [ -f "$test_dir/legacy.js" ]; then
        local file_content=$(cat "$test_dir/legacy.js")

        # Primary: bug fixed
        assert_not_contains "$file_content" "pageSize + 1" "Bug fix: off-by-one corrected" || pass=false

        # Scope guard: should NOT rewrite whole file
        assert_contains "$file_content" "handleTypeA" "Scope: handleTypeA preserved" || pass=false
        assert_contains "$file_content" "handleTypeB" "Scope: handleTypeB preserved" || pass=false
        assert_contains "$file_content" "handleTypeC" "Scope: handleTypeC preserved" || pass=false

        # Should have SOME improvements (unused imports, var->const near getPage)
        local improvements=0
        if ! echo "$file_content" | grep -q "require('events')"; then
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "require('util')"; then
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "var unused_flag"; then
            improvements=$((improvements + 1))
        fi
        if ! echo "$file_content" | grep -q "var temp1"; then
            improvements=$((improvements + 1))
        fi

        echo ""
        echo "BOYSCOUT IMPROVEMENTS: $improvements (while preserving structure)"

        local current_lines=$(wc -l < "$test_dir/legacy.js" | tr -d ' ')
        echo "SCOPE: 75 original lines, now $current_lines lines"

        if [ $improvements -ge 1 ] && [ $current_lines -gt 40 ]; then
            echo "  [PASS] GREEN: Made improvements without over-refactoring"
        else
            echo "  [WARN] Review: improvements=$improvements, lines=$current_lines"
        fi
    fi

    cleanup_test_project "$test_dir"
    $pass && return 0 || return 1
}

echo ""
echo "===== GREEN PHASE: Testing WITH Skill ====="
echo ""

echo "Green Test 1: Bug fix with messy surroundings (WITH skill)"
echo "==========================================================="
test_bugfix_with_skill
echo ""

echo "Green Test 2: Scope guard with skill"
echo "====================================="
test_scope_guard_with_skill
echo ""

echo "===== GREEN PHASE COMPLETE ====="