#!/usr/bin/env bash
# Test: Subagent Dispatch Workflow (Antigravity 2.0)
# Verifies that the subagent-driven-development skill correctly:
#   1. Dispatches subagents via invoke_subagent
#   2. Creates implementation files
#   3. Makes git commits
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "========================================"
echo " Test: Subagent Dispatch (Antigravity)"
echo "========================================"
echo ""
echo "This test creates a temp project with a 2-task plan,"
echo "executes it via subagent-driven-development, and verifies"
echo "subagent dispatch, file creation, and git commits."
echo ""
echo "WARNING: This test may take 10-30 minutes to complete."
echo ""

# Check agy is available
if ! command -v agy &>/dev/null; then
    echo "[SKIP] 'agy' command not found. Install Antigravity CLI to run this test."
    exit 0
fi

# Create test project
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"

# Trap to cleanup
trap "cleanup_test_project $TEST_PROJECT" EXIT

# Set up minimal Node.js project
cd "$TEST_PROJECT"

cat > package.json <<'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

mkdir -p src test docs/superpowers/plans

# Create a simple 2-task implementation plan
PLAN_PATH="docs/superpowers/plans/implementation-plan.md"

cat > "$PLAN_PATH" <<'EOF'
# Test Implementation Plan

This is a minimal plan to test the subagent-driven-development workflow on Antigravity.

## Task 1: Create Hello Function

Create a function that returns a greeting.

**File:** `src/hello.js`

**Requirements:**
- Function named `hello`
- Takes an optional `name` parameter (defaults to "World")
- Returns `"Hello, <name>!"`
- Export the function

**Implementation:**
```javascript
export function hello(name = "World") {
  return `Hello, ${name}!`;
}
```

**Tests:** Create `test/hello.test.js` that verifies:
- `hello()` returns `"Hello, World!"`
- `hello("Alice")` returns `"Hello, Alice!"`

**Verification:** `npm test`

## Task 2: Create Goodbye Function

Create a function that returns a farewell message.

**File:** `src/goodbye.js`

**Requirements:**
- Function named `goodbye`
- Takes a required `name` parameter
- Returns `"Goodbye, <name>!"`
- Export the function

**Implementation:**
```javascript
export function goodbye(name) {
  return `Goodbye, ${name}!`;
}
```

**Tests:** Create `test/goodbye.test.js` that verifies:
- `goodbye("Alice")` returns `"Goodbye, Alice!"`
- `goodbye("Bob")` returns `"Goodbye, Bob!"`

**Verification:** `npm test`
EOF

# Initialize git repo
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -m "Initial commit" --quiet

echo ""
echo "Project setup complete. Starting execution..."
echo ""

# Run Antigravity with subagent-driven-development
OUTPUT_FILE="$TEST_PROJECT/agy-output.txt"

PROMPT="Execute the implementation plan at $PLAN_PATH using superpowers:subagent-driven-development. The plan is at: $PLAN_PATH

IMPORTANT: Follow the skill exactly. I will be verifying that you:
1. Read the plan once at the beginning
2. Dispatch subagents for implementation tasks
3. Create all specified files
4. Commit changes to git

Begin now. Execute the plan."

echo "Running agy (cwd: $TEST_PROJECT)..."
echo "================================================================================"
cd "$TEST_PROJECT" && timeout 1800 agy --print "$PROMPT" 2>&1 | tee "$OUTPUT_FILE" || {
    echo ""
    echo "================================================================================"
    echo "EXECUTION COMPLETED (exit code: $?)"
    echo ""
}
echo "================================================================================"

echo ""
echo "Execution complete. Analyzing results..."
echo ""

# Verification tests
FAILED=0
PASSED=0

echo "=== Verification Tests ==="
echo ""

# Test 1: Check output/transcript for invoke_subagent calls
echo "Test 1: Subagent dispatch..."

# Check output text for subagent evidence
if echo "$(cat "$OUTPUT_FILE")" | grep -qiE "invoke_subagent|subagent|dispatching.*agent|launching.*agent"; then
    echo "  [PASS] Subagent dispatch evidence found in output"
    PASSED=$((PASSED + 1))
else
    # Fall back to transcript check
    TRANSCRIPT=$(find_transcript 60 2>/dev/null) || true
    if [ -n "$TRANSCRIPT" ] && transcript_has_tool "$TRANSCRIPT" "invoke_subagent"; then
        echo "  [PASS] invoke_subagent found in transcript"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] No subagent dispatch evidence found"
        FAILED=$((FAILED + 1))
    fi
fi
echo ""

# Test 2: Implementation files created
echo "Test 2: Implementation files..."

if [ -f "$TEST_PROJECT/src/hello.js" ]; then
    echo "  [PASS] src/hello.js created"
    PASSED=$((PASSED + 1))

    if grep -q "function hello" "$TEST_PROJECT/src/hello.js"; then
        echo "  [PASS] hello function exists"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] hello function missing from src/hello.js"
        FAILED=$((FAILED + 1))
    fi
else
    echo "  [FAIL] src/hello.js not created"
    FAILED=$((FAILED + 1))
fi

if [ -f "$TEST_PROJECT/src/goodbye.js" ]; then
    echo "  [PASS] src/goodbye.js created"
    PASSED=$((PASSED + 1))

    if grep -q "function goodbye" "$TEST_PROJECT/src/goodbye.js"; then
        echo "  [PASS] goodbye function exists"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] goodbye function missing from src/goodbye.js"
        FAILED=$((FAILED + 1))
    fi
else
    echo "  [FAIL] src/goodbye.js not created"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 3: Test files created
echo "Test 3: Test files..."

test_file_found=false
for tf in "$TEST_PROJECT/test/hello.test.js" "$TEST_PROJECT/test/hello.test.mjs" "$TEST_PROJECT/tests/hello.test.js"; do
    if [ -f "$tf" ]; then
        echo "  [PASS] Hello test file created: $(basename "$tf")"
        PASSED=$((PASSED + 1))
        test_file_found=true
        break
    fi
done
if [ "$test_file_found" = "false" ]; then
    echo "  [FAIL] No hello test file found"
    FAILED=$((FAILED + 1))
fi

test_file_found=false
for tf in "$TEST_PROJECT/test/goodbye.test.js" "$TEST_PROJECT/test/goodbye.test.mjs" "$TEST_PROJECT/tests/goodbye.test.js"; do
    if [ -f "$tf" ]; then
        echo "  [PASS] Goodbye test file created: $(basename "$tf")"
        PASSED=$((PASSED + 1))
        test_file_found=true
        break
    fi
done
if [ "$test_file_found" = "false" ]; then
    echo "  [FAIL] No goodbye test file found"
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 4: Tests pass
echo "Test 4: Tests pass..."
if cd "$TEST_PROJECT" && npm test > test-output.txt 2>&1; then
    echo "  [PASS] npm test passes"
    PASSED=$((PASSED + 1))
else
    echo "  [FAIL] npm test failed"
    cat test-output.txt | sed 's/^/    /'
    FAILED=$((FAILED + 1))
fi
echo ""

# Test 5: Git commits
echo "Test 5: Git commit history..."
commit_count=$(git -C "$TEST_PROJECT" log --oneline | wc -l)
if [ "$commit_count" -gt 1 ]; then
    echo "  [PASS] Multiple commits created ($commit_count total)"
    PASSED=$((PASSED + 1))
else
    echo "  [FAIL] Too few commits ($commit_count, expected >1)"
    FAILED=$((FAILED + 1))
fi
echo ""

# Summary
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "STATUS: PASSED ($PASSED checks passed)"
    echo ""
    echo "The subagent-driven-development skill correctly:"
    echo "  ✓ Dispatched subagents via invoke_subagent"
    echo "  ✓ Created implementation files"
    echo "  ✓ Created test files"
    echo "  ✓ Tests pass"
    echo "  ✓ Made git commits"
    exit 0
else
    echo "STATUS: FAILED ($FAILED checks failed, $PASSED passed)"
    echo ""
    echo "Output saved to: $OUTPUT_FILE"
    echo "Review the output to see what went wrong."
    exit 1
fi
