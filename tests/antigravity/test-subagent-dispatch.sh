#!/usr/bin/env bash
# Test: Subagent Dispatch Workflow (Antigravity)
# Verifies that the subagent-driven-development skill, on a two-task plan:
#   1. Dispatches an implementer, a spec reviewer and a code reviewer (read from the stream)
#   2. Creates implementation files
#   3. Makes git commits
# Usage: test-subagent-dispatch.sh [--from-stream <file>]   (--from-stream runs Test 1 only)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
JT="$SCRIPT_DIR/lib/json-tool.mjs"

echo "========================================"
echo " Test: Subagent Dispatch (Antigravity)"
echo "========================================"
echo ""

FROM_STREAM=""
if [ "${1:-}" = "--from-stream" ]; then
    FROM_STREAM="${2:?--from-stream needs a file}"
    OUTPUT_FILE="$FROM_STREAM"
    classify_agy_run 0 /dev/null "$OUTPUT_FILE" || exit $?
else
    echo "This test creates a temp project with a 2-task plan,"
    echo "executes it via subagent-driven-development, and verifies"
    echo "subagent dispatch, file creation, and git commits."
    echo ""
    echo "WARNING: This test may take 10-30 minutes to complete."
    echo ""

    require_agy_and_plugin

    TEST_PROJECT=$(create_test_project)
    echo "Test project: $TEST_PROJECT"
    OUT_DIR=$(mktemp -d)
    trap 'cleanup_test_project "$TEST_PROJECT"; rm -rf "$OUT_DIR"' EXIT
    PLAN_PATH=$(bash "$SCRIPT_DIR/lib/fixture-plan-project.sh" "$TEST_PROJECT") || exit 1

    OUTPUT_FILE="$OUT_DIR/stream.jsonl"
    echo "Running agy (cwd: $TEST_PROJECT)..."
    (cd "$TEST_PROJECT" && agy_run "$OUTPUT_FILE" "$OUTPUT_FILE.err" 1800 \
        -p "$(bash "$SCRIPT_DIR/lib/fixture-plan-project.sh" --print-prompt sdd)" --output-format stream-json)
    classify_agy_run $? "$OUTPUT_FILE.err" "$OUTPUT_FILE" || exit $?
fi

FAILED=0
PASSED=0

echo "=== Verification Tests ==="
echo ""

# Test 1: subagent dispatch, read from the stream
echo "Test 1: Subagent dispatch..."
TYPES=$(node "$JT" stream subagents --field type_name < "$OUTPUT_FILE")
for role in implementer spec-reviewer code-reviewer; do
    members="$role"
    [ "$role" = implementer ] && members="$IMPL_FAMILY"
    found=""
    while IFS= read -r t; do
        [ -n "$t" ] || continue
        if type_in_set "$t" $members; then found="$t"; break; fi
    done <<< "$TYPES"
    if [ -n "$found" ]; then
        echo "  [PASS] $role dispatched as $found"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] no $role dispatch"
        FAILED=$((FAILED + 1))
    fi
done
while IFS= read -r t; do
    [ -n "$t" ] || continue
    if type_in_set "$t" final-reviewer; then echo "  [INFO] final-reviewer dispatched as $t"; fi
done <<< "$TYPES"
echo ""

if [ -n "$FROM_STREAM" ]; then
    [ "$FAILED" -eq 0 ]
    exit $?
fi

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
