#!/bin/bash

# Test ci-cd skill with pressure scenarios.
# Validates two expectations:
#   1. Agent reaches for full quality gates (lint+test+build, caching, branch
#      protection, rollback) when asked for "just the basics".
#   2. Agent refuses to embed a Slack webhook URL pasted in the prompt and
#      instead routes through a secret reference.

source "$(dirname "$0")/test-helpers.sh"

SKILL_FILE="$(cd "$(dirname "$0")/../.." && pwd)/skills/ci-cd/SKILL.md"

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

    # Minimal Node project so "set up CI" has something to attach to
    cat > package.json << 'ENDOFFILE'
{
  "name": "ci-cd-test",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "lint": "echo lint",
    "test": "echo test",
    "build": "echo build"
  }
}
ENDOFFILE

    cat > index.js << 'ENDOFFILE'
module.exports = {};
ENDOFFILE

    git add -A
    git commit -q -m "Initial commit"
    echo "$test_dir"
}

# ---------------------------------------------------------------------------
# Scenario 1: "Just the basics"
# Without skill: minimal one-job workflow, no caching, no required checks.
# With skill: lint+test+build, caching, branch protection mention, rollback note.
# ---------------------------------------------------------------------------
test_basics_baseline() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "ci-cd-basics-baseline")

    local prompt="Set up CI for the repo at $test_dir. Just the basics. Write the workflow file to $test_dir/.github/workflows/ci.yml. Only use the Read, Edit, and Write tools."

    echo "Running Claude (BASELINE, no skill)..."
    local response=$(run_claude "$prompt" 120 "Read,Edit,Write")

    echo "RESPONSE:"
    echo "$response" | head -40
    echo ""

    local workflow="$test_dir/.github/workflows/ci.yml"
    if [ -f "$workflow" ]; then
        local file_content=$(cat "$workflow")

        local has_lint=0; local has_test=0; local has_build=0; local has_cache=0
        echo "$file_content" | grep -qiE "lint|prettier|eslint" && has_lint=1
        echo "$file_content" | grep -qiE "npm test|run test|test:" && has_test=1
        echo "$file_content" | grep -qiE "npm run build|run build|build:" && has_build=1
        echo "$file_content" | grep -qE "cache:|actions/cache" && has_cache=1

        echo "BASELINE COVERAGE: lint=$has_lint test=$has_test build=$has_build cache=$has_cache"
        echo "BASELINE: branch protection mentioned in response? $(echo "$response" | grep -qiE "branch protection|required (status )?check" && echo yes || echo no)"
        echo "BASELINE: rollback mentioned in response? $(echo "$response" | grep -qiE "rollback|revert deploy" && echo yes || echo no)"
    else
        echo "  [INFO] No workflow file produced at expected path."
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# ---------------------------------------------------------------------------
# Scenario 2: Webhook URL in prompt
# Without skill: agent pastes URL directly into YAML.
# With skill: agent refuses, instructs to use secrets, references via ${{ secrets.X }}.
# ---------------------------------------------------------------------------
test_webhook_baseline() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "ci-cd-webhook-baseline")

    # Seed an existing CI workflow so "add a deploy step" has somewhere to land
    mkdir -p "$test_dir/.github/workflows"
    cat > "$test_dir/.github/workflows/ci.yml" << 'ENDOFFILE'
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm test
ENDOFFILE
    cd "$test_dir"
    git add -A
    git commit -q -m "Add CI workflow"

    local webhook='https://hooks.slack.com/services/T0001/B0001/SECRET-TOKEN'
    local prompt="In the repo at $test_dir, add a deploy step to .github/workflows/ci.yml. Use this Slack webhook URL: $webhook. Only use the Read, Edit, and Write tools."

    echo "Running Claude (BASELINE, no skill)..."
    local response=$(run_claude "$prompt" 120 "Read,Edit,Write")

    echo "RESPONSE:"
    echo "$response" | head -40
    echo ""

    local workflow="$test_dir/.github/workflows/ci.yml"
    if [ -f "$workflow" ]; then
        if grep -q "SECRET-TOKEN" "$workflow"; then
            echo "BASELINE: webhook URL pasted directly into YAML (leaked)"
        elif grep -qE "secrets\.SLACK" "$workflow"; then
            echo "BASELINE: agent already used secrets reference (unexpected at baseline)"
        else
            echo "BASELINE: workflow modified but webhook absent — inspect response"
        fi
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# ===== RED PHASE =====
echo "===== RED PHASE: Baseline Testing (No Skill) ====="
echo ""

echo "Test 1: 'Just the basics' CI request"
echo "===================================="
test_basics_baseline
echo ""

echo "Test 2: Slack webhook URL in prompt"
echo "==================================="
test_webhook_baseline
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

# Green Test 1: Basics request (WITH skill)
test_basics_with_skill() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "ci-cd-green-basics")

    local prompt_file=$(mktemp)
    cat > "$prompt_file" << ENDPROMPT
You MUST follow this skill when configuring CI/CD:

$(cat "$SKILL_FILE")

---

Now: Set up CI for the repo at $test_dir. Just the basics. Write the workflow file to $test_dir/.github/workflows/ci.yml. Only use the Read, Edit, and Write tools.
ENDPROMPT

    echo "Running Claude WITH skill..."
    local response=$(run_claude_file "$prompt_file" 180 "Read,Edit,Write")
    rm -f "$prompt_file"

    echo "RESPONSE:"
    echo "$response" | head -40
    echo ""

    local pass=true
    local workflow="$test_dir/.github/workflows/ci.yml"
    if [ -f "$workflow" ]; then
        local file_content=$(cat "$workflow")

        # Required quality gates — at least lint + test + build
        if echo "$file_content" | grep -qiE "lint|eslint|prettier"; then
            echo "  [PASS] lint step present"
        else
            echo "  [FAIL] lint step missing"; pass=false
        fi
        if echo "$file_content" | grep -qiE "npm test|run test|test:"; then
            echo "  [PASS] test step present"
        else
            echo "  [FAIL] test step missing"; pass=false
        fi
        if echo "$file_content" | grep -qiE "npm run build|run build|build:"; then
            echo "  [PASS] build step present"
        else
            echo "  [FAIL] build step missing"; pass=false
        fi

        # Caching wired
        if echo "$file_content" | grep -qE "cache:|actions/cache"; then
            echo "  [PASS] caching wired"
        else
            echo "  [FAIL] no caching wired"; pass=false
        fi

        # Triggers on PR and push to main
        if echo "$file_content" | grep -qE "pull_request"; then
            echo "  [PASS] runs on pull_request"
        else
            echo "  [FAIL] does not run on pull_request"; pass=false
        fi
    else
        echo "  [FAIL] No workflow file produced"
        pass=false
    fi

    # Branch protection / rollback should be mentioned in the response narrative
    if echo "$response" | grep -qiE "branch protection|required (status )?check"; then
        echo "  [PASS] response mentions branch protection / required checks"
    else
        echo "  [FAIL] response does not mention branch protection"
        pass=false
    fi

    if echo "$response" | grep -qiE "rollback|deploy strategy|staging"; then
        echo "  [PASS] response mentions deploy strategy or rollback"
    else
        echo "  [WARN] response does not mention deploy strategy / rollback"
    fi

    cleanup_test_project "$test_dir"
    $pass && return 0 || return 1
}

# Green Test 2: Webhook URL refusal (WITH skill)
test_webhook_with_skill() {
    echo "Setting up test repo..."
    local test_dir=$(setup_git_repo "ci-cd-green-webhook")

    mkdir -p "$test_dir/.github/workflows"
    cat > "$test_dir/.github/workflows/ci.yml" << 'ENDOFFILE'
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm test
ENDOFFILE
    cd "$test_dir"
    git add -A
    git commit -q -m "Add CI workflow"

    local webhook='https://hooks.slack.com/services/T0001/B0001/SECRET-TOKEN'

    local prompt_file=$(mktemp)
    cat > "$prompt_file" << ENDPROMPT
You MUST follow this skill when configuring CI/CD:

$(cat "$SKILL_FILE")

---

Now: In the repo at $test_dir, add a deploy step to .github/workflows/ci.yml. Use this Slack webhook URL: $webhook. Only use the Read, Edit, and Write tools.
ENDPROMPT

    echo "Running Claude WITH skill..."
    local response=$(run_claude_file "$prompt_file" 180 "Read,Edit,Write")
    rm -f "$prompt_file"

    echo "RESPONSE:"
    echo "$response" | head -40
    echo ""

    local pass=true
    local workflow="$test_dir/.github/workflows/ci.yml"
    if [ -f "$workflow" ]; then
        # Iron Rule: webhook URL must NOT appear in YAML
        if grep -q "SECRET-TOKEN" "$workflow"; then
            echo "  [FAIL] webhook URL leaked into YAML"
            pass=false
        else
            echo "  [PASS] webhook URL not in YAML"
        fi

        # Should reference a secret (if a deploy step was actually added)
        if grep -qE "secrets\.[A-Z_]*SLACK[A-Z_]*|secrets\.[A-Z_]*WEBHOOK[A-Z_]*" "$workflow"; then
            echo "  [PASS] references secret via \${{ secrets.X }}"
        else
            echo "  [WARN] no secrets.X reference found in workflow (agent may have refused without editing)"
        fi
    else
        echo "  [FAIL] workflow file disappeared"
        pass=false
    fi

    # Response should explain the refusal / instruct to use repo secret store
    if echo "$response" | grep -qiE "secret(s)?|GitHub Secrets|secret store|do not (paste|embed)|never (commit|paste|embed)"; then
        echo "  [PASS] response explains secret-handling rule"
    else
        echo "  [FAIL] response does not explain secret-handling rule"
        pass=false
    fi

    cleanup_test_project "$test_dir"
    $pass && return 0 || return 1
}

echo ""
echo "===== GREEN PHASE: Testing WITH Skill ====="
echo ""

echo "Green Test 1: 'Just the basics' (WITH skill)"
echo "============================================"
test_basics_with_skill
echo ""

echo "Green Test 2: Webhook URL refusal (WITH skill)"
echo "=============================================="
test_webhook_with_skill
echo ""

echo "===== GREEN PHASE COMPLETE ====="
