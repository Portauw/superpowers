#!/bin/bash

# Test clean-software-design skill with pressure scenarios

source "$(dirname "$0")/test-helpers.sh"

# Setup a test repo with a project that has NO architectural-principles.md
setup_test_project() {
    local test_dir=$(create_test_project)
    (cd "$test_dir" && git init -q && git config user.email "test@example.com" && git config user.name "Test User")

    # Create a CLAUDE.md with no architecture reference
    cat > "$test_dir/CLAUDE.md" << 'EOF'
# Project

A simple e-commerce application.
EOF

    # Create some domain code with DDD violations
    mkdir -p "$test_dir/src"
    cat > "$test_dir/src/order-service.js" << 'EOF'
const db = require('./database');

// Domain logic mixed with infrastructure
function createOrder(userId, items) {
    const user = db.query('SELECT * FROM users WHERE id = ?', [userId]);
    const total = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    const orderId = db.query('INSERT INTO orders (user_id, total) VALUES (?, ?)', [userId, total]);
    db.query('INSERT INTO audit_log (action, order_id) VALUES (?, ?)', ['create', orderId]);
    return { id: orderId, total };
}

module.exports = { createOrder };
EOF

    (cd "$test_dir" && git add -A && git commit -q -m "Initial commit")
    echo "$test_dir"
}

# Pressure Scenario 1: Brainstorming without DDD awareness
# Expected WITHOUT skill: Agent discusses features without asking about bounded contexts,
# ubiquitous language, or quality attributes
test_brainstorming_no_ddd() {
    local test_dir=$(setup_test_project)

    local prompt="I want to add a payment processing feature to the e-commerce app in $test_dir. \
The app currently has an order service. Let's brainstorm how to build this."

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120)

    echo "BASELINE RESPONSE (first 30 lines):"
    echo "$response" | head -30
    echo ""

    # Check if agent naturally considers DDD concepts
    local ddd_mentions=0
    echo "$response" | grep -qi "bounded context" && ddd_mentions=$((ddd_mentions + 1))
    echo "$response" | grep -qi "ubiquitous language" && ddd_mentions=$((ddd_mentions + 1))
    echo "$response" | grep -qi "aggregate" && ddd_mentions=$((ddd_mentions + 1))
    echo "$response" | grep -qi "quality attribute" && ddd_mentions=$((ddd_mentions + 1))
    echo "$response" | grep -qi "architectural\.principles" && ddd_mentions=$((ddd_mentions + 1))

    echo "DDD concept mentions: $ddd_mentions / 5"

    if [ "$ddd_mentions" -lt 2 ]; then
        echo "BASELINE: Agent did not systematically consider DDD principles (expected)"
    else
        echo "NOTE: Agent naturally mentioned DDD concepts ($ddd_mentions/5)"
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Pressure Scenario 2: Code review without architectural principles check
# Expected WITHOUT skill: Agent reviews code quality but misses DDD violations
# (infrastructure in domain, no bounded context separation)
test_review_no_architecture_check() {
    local test_dir=$(setup_test_project)

    local prompt="Please review the code in $test_dir/src/order-service.js. \
Is this code ready for production?"

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120)

    echo "BASELINE RESPONSE (first 30 lines):"
    echo "$response" | head -30
    echo ""

    # Check if agent catches architectural issues
    local arch_mentions=0
    echo "$response" | grep -qi "dependency.*direction\|inward.*depend\|depend.*inward" && arch_mentions=$((arch_mentions + 1))
    echo "$response" | grep -qi "domain.*infrastructure\|infrastructure.*domain\|layer.*separation" && arch_mentions=$((arch_mentions + 1))
    echo "$response" | grep -qi "repository.*pattern\|abstract.*data.*access" && arch_mentions=$((arch_mentions + 1))
    echo "$response" | grep -qi "single.*responsib\|SRP\|SOLID" && arch_mentions=$((arch_mentions + 1))

    echo "Architecture issue mentions: $arch_mentions / 4"

    if [ "$arch_mentions" -lt 2 ]; then
        echo "BASELINE: Agent did not systematically check architectural principles (expected)"
    else
        echo "NOTE: Agent naturally caught architectural issues ($arch_mentions/4)"
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Pressure Scenario 3: Does agent look for/create architectural-principles.md?
# Expected WITHOUT skill: Agent does not check for or suggest creating the file
test_no_principles_file_awareness() {
    local test_dir=$(setup_test_project)

    local prompt="I'm about to start building a new feature in $test_dir. \
Before I write code, is there anything I should set up or document first?"

    echo "Running Claude..."
    local response=$(run_claude "$prompt" 120)

    echo "BASELINE RESPONSE (first 30 lines):"
    echo "$response" | head -30
    echo ""

    if echo "$response" | grep -qi "architectural\.principles\|architecture.*doc\|principles.*file"; then
        echo "NOTE: Agent suggested architectural documentation without skill"
    else
        echo "BASELINE: Agent did not suggest architectural principles documentation (expected)"
    fi

    cleanup_test_project "$test_dir"
    return 0
}

# Run baseline tests (RED phase)
echo "===== RED PHASE: Baseline Testing (No Skill) ====="
echo ""

echo "Test 1: Brainstorming without DDD awareness"
echo "============================================="
test_brainstorming_no_ddd
echo ""

echo "Test 2: Code review without architectural principles"
echo "===================================================="
test_review_no_architecture_check
echo ""

echo "Test 3: No architectural-principles.md awareness"
echo "================================================="
test_no_principles_file_awareness
echo ""

echo "===== BASELINE COMPLETE ====="
echo "Document observed rationalizations and failures before writing skill."
