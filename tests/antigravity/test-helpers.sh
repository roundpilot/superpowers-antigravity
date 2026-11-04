#!/usr/bin/env bash
# Helper functions for Antigravity 2.0 skill tests
# Parallel to tests/claude-code/test-helpers.sh but adapted for the agy CLI

# Run Antigravity in headless mode with a prompt and capture output.
#
# Explicit --print-timeout: the headless docs give a 5-minute default, while CLI 1.2.6's
# changelog made headless runs unlimited; passing the flag keeps these tests independent of
# which holds. --dangerously-skip-permissions keeps a writing run from waiting on review.
#
# Two optional env vars pin model/effort for a whole test run:
#   AGY_TEST_MODEL  -> passed as --model  ("Model slug for this run", see `agy models`)
#   AGY_TEST_EFFORT -> passed as --effort ("Reasoning effort: low, medium, or high")
#
# Usage: run_antigravity "prompt text" [timeout_seconds] [output_format]
#   output_format: text|json|stream-json (omit for agy's own default, "text")
run_antigravity() {
    local prompt="$1"
    local timeout_secs="${2:-300}"
    local output_format="${3:-}"
    local output_file
    output_file=$(mktemp)

    # Check agy is available
    if ! command -v agy &>/dev/null; then
        echo "ERROR: 'agy' command not found. Install Antigravity CLI first." >&2
        rm -f "$output_file"
        return 127
    fi

    # agy's own --print-timeout documents only whole-minute durations
    # (default "5m", example "15m" -- no seconds unit is ever shown), so
    # round the requested budget up to the nearest whole minute.
    local print_timeout_minutes=$(( (timeout_secs + 59) / 60 ))
    if [ "$print_timeout_minutes" -lt 1 ]; then
        print_timeout_minutes=1
    fi

    # The external `timeout` wrapper stays as a backstop for hangs that
    # happen before agy's own --print-timeout can engage (auth prompts,
    # network stalls, etc). It must never be tighter than the internal
    # budget it is backstopping, so widen it to that budget plus margin.
    local external_timeout_secs=$(( print_timeout_minutes * 60 + 60 ))
    if [ "$external_timeout_secs" -lt "$timeout_secs" ]; then
        external_timeout_secs="$timeout_secs"
    fi

    local -a agy_args=(--print "$prompt" --print-timeout "${print_timeout_minutes}m" --dangerously-skip-permissions)
    if [ -n "$output_format" ]; then
        agy_args+=(--output-format "$output_format")
    fi
    if [ -n "${AGY_TEST_MODEL:-}" ]; then
        agy_args+=(--model "$AGY_TEST_MODEL")
    fi
    if [ -n "${AGY_TEST_EFFORT:-}" ]; then
        agy_args+=(--effort "$AGY_TEST_EFFORT")
    fi

    # Run Antigravity in headless (--print) mode with timeout
    if timeout "$external_timeout_secs" agy "${agy_args[@]}" > "$output_file" 2>&1; then
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

# Check if output contains a pattern
# Usage: assert_contains "output" "pattern" "test name"
assert_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -qi "$pattern"; then
        echo "  [PASS] $test_name"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /' | head -30
        return 1
    fi
}

# Check if output does NOT contain a pattern
# Usage: assert_not_contains "output" "pattern" "test name"
assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -qi "$pattern"; then
        echo "  [FAIL] $test_name"
        echo "  Did not expect to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /' | head -30
        return 1
    else
        echo "  [PASS] $test_name"
        return 0
    fi
}

# Check if output matches a count
# Usage: assert_count "output" "pattern" expected_count "test name"
assert_count() {
    local output="$1"
    local pattern="$2"
    local expected="$3"
    local test_name="${4:-test}"

    local actual
    actual=$(echo "$output" | grep -ci "$pattern" || echo "0")

    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $test_name (found $actual instances)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected $expected instances of: $pattern"
        echo "  Found $actual instances"
        echo "  In output:"
        echo "$output" | sed 's/^/    /' | head -30
        return 1
    fi
}

# Check if pattern A appears before pattern B
# Usage: assert_order "output" "pattern_a" "pattern_b" "test name"
assert_order() {
    local output="$1"
    local pattern_a="$2"
    local pattern_b="$3"
    local test_name="${4:-test}"

    # Get line numbers where patterns appear
    local line_a
    local line_b
    line_a=$(echo "$output" | grep -ni "$pattern_a" | head -1 | cut -d: -f1)
    line_b=$(echo "$output" | grep -ni "$pattern_b" | head -1 | cut -d: -f1)

    if [ -z "$line_a" ]; then
        echo "  [FAIL] $test_name: pattern A not found: $pattern_a"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi

    if [ -z "$line_b" ]; then
        echo "  [FAIL] $test_name: pattern B not found: $pattern_b"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi

    if [ "$line_a" -lt "$line_b" ]; then
        echo "  [PASS] $test_name (A at line $line_a, B at line $line_b)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected '$pattern_a' before '$pattern_b'"
        echo "  But found A at line $line_a, B at line $line_b"
        return 1
    fi
}

# Create a temporary test project directory
# Usage: test_project=$(create_test_project)
create_test_project() {
    local test_dir
    test_dir=$(mktemp -d)
    echo "$test_dir"
}

# Cleanup test project
# Usage: cleanup_test_project "$test_dir"
cleanup_test_project() {
    local test_dir="$1"
    if [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
}

# Create a simple plan file for testing
# Usage: create_test_plan "$project_dir" "$plan_name"
create_test_plan() {
    local project_dir="$1"
    local plan_name="${2:-test-plan}"
    local plan_file="$project_dir/docs/superpowers/plans/$plan_name.md"

    mkdir -p "$(dirname "$plan_file")"

    cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Task 1: Create Hello Function

Create a simple hello function that returns "Hello, World!".

**File:** `src/hello.js`

**Implementation:**
```javascript
export function hello() {
  return "Hello, World!";
}
```

**Tests:** Write a test that verifies the function returns the expected string.

**Verification:** `npm test`

## Task 2: Create Goodbye Function

Create a goodbye function that takes a name and returns a goodbye message.

**File:** `src/goodbye.js`

**Implementation:**
```javascript
export function goodbye(name) {
  return `Goodbye, ${name}!`;
}
```

**Tests:** Write tests for:
- Default name
- Custom name
- Edge cases (empty string, null)

**Verification:** `npm test`
EOF

    echo "$plan_file"
}

# json-tool.mjs, for the stream views below
_SP_JT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/json-tool.mjs"

# agy_run <out> <err> <secs> <agy-args...>: one headless agy run; stdout to <out>, stderr to
# <err>; returns agy's exit code. The print timeout is secs rounded up to whole minutes.
agy_run() {
    local out="$1" err="$2" secs="$3"
    shift 3
    local m=$(( (secs + 59) / 60 ))
    [ "$m" -ge 1 ] || m=1
    local -a args=("$@" --print-timeout "${m}m" --dangerously-skip-permissions)
    [ -z "${AGY_TEST_MODEL:-}" ] || args+=(--model "$AGY_TEST_MODEL")
    [ -z "${AGY_TEST_EFFORT:-}" ] || args+=(--effort "$AGY_TEST_EFFORT")
    timeout $(( m * 60 + 60 )) agy "${args[@]}" > "$out" 2> "$err"
}

# classify_agy_run <exit> <stderr-file> <stream-file>: 0 run usable, 1 FAIL, 77 SKIP; prints why.
classify_agy_run() {
    local code="$1" errfile="$2" stream="$3" status conv denied n
    status=$(node "$_SP_JT" stream result --field status < "$stream")
    conv=$(node "$_SP_JT" stream result --field conversation_id < "$stream")
    denied=$(node "$_SP_JT" stream result --field denied_actions < "$stream")
    if [ -z "$status" ]; then
        echo "[SKIP] no result event (infrastructure or timeout)"; return 77
    fi
    n=$(node -p 'JSON.parse(process.argv[1]).length' "${denied:-[]}")
    if [ "$n" -gt 0 ]; then
        echo "[SKIP] permissions: $n denied action(s)"; return 77
    fi
    case "$status" in
        ERROR)
            if [ -z "$conv" ]; then
                echo "[SKIP] run did not start"; return 77
            fi
            if [ "$code" = 3 ] || grep -q 'AGY_ERROR' "$errfile" 2>/dev/null; then
                echo "[SKIP] infrastructure: ERROR (AGY_ERROR)"; return 77
            fi
            echo "[FAIL] run ended with $status"; return 1 ;;
        INVALID) echo "[FAIL] run ended with $status"; return 1 ;;
        RUNNING) echo "[SKIP] print timeout reached"; return 77 ;;
        CANCELED|INTERRUPTED) echo "[SKIP] run $status"; return 77 ;;
        WAITING) echo "[FAIL] run stopped waiting for input"; return 1 ;;
        SUCCESS) return 0 ;;
        *) echo "[FAIL] run ended with $status"; return 1 ;;
    esac
}

# agy_superpowers_installed: 0, printing the evidence, when agy has a superpowers install.
agy_superpowers_installed() {
    local found=1 d
    if agy plugin list 2>/dev/null | grep -qi superpowers; then
        echo "agy plugin list mentions superpowers"; found=0
    fi
    for d in "$HOME/.gemini/config/plugins/superpowers" "$HOME/.gemini/antigravity-cli/plugins/superpowers"; do
        if [ -e "$d" ]; then echo "found $d"; found=0; fi
    done
    return $found
}

# require_agy_and_plugin: exit 77 (SKIP) without agy or without a superpowers install for it.
require_agy_and_plugin() {
    if ! command -v agy &>/dev/null; then
        echo "[SKIP] 'agy' command not found"; exit 77
    fi
    if ! agy_superpowers_installed >/dev/null; then
        echo "[SKIP] no superpowers install for agy (see tests/antigravity/README.md)"; exit 77
    fi
}

# Export functions for use in tests
export -f run_antigravity
export -f assert_contains
export -f assert_not_contains
export -f assert_count
export -f assert_order
export -f create_test_project
export -f cleanup_test_project
export -f create_test_plan
export -f agy_run
export -f classify_agy_run
export -f agy_superpowers_installed
export -f require_agy_and_plugin

# IMPL_FAMILY: implementer agent names under S3.4 variant-files
IMPL_FAMILY="implementer implementer-flash implementer-pro"

# type_in_set <type_name> <member...>: 0 when the name equals a member or ends in :<member>
type_in_set() {
    local name="$1" m
    shift
    for m in "$@"; do
        case "$name" in "$m"|*":$m") return 0 ;; esac
    done
    return 1
}
export -f type_in_set
export IMPL_FAMILY
