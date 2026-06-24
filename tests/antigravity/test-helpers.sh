#!/usr/bin/env bash
# Helper functions for Antigravity 2.0 skill tests
# Parallel to tests/claude-code/test-helpers.sh but adapted for the agy CLI

# Run Antigravity in headless mode with a prompt and capture output
# Usage: run_antigravity "prompt text" [timeout_seconds]
run_antigravity() {
    local prompt="$1"
    local timeout_secs="${2:-300}"
    local output_file
    output_file=$(mktemp)

    # Check agy is available
    if ! command -v agy &>/dev/null; then
        echo "ERROR: 'agy' command not found. Install Antigravity CLI first." >&2
        rm -f "$output_file"
        return 127
    fi

    # Run Antigravity in headless (--print) mode with timeout
    if timeout "$timeout_secs" agy --print "$prompt" > "$output_file" 2>&1; then
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
        return 1
    fi

    if [ -z "$line_b" ]; then
        echo "  [FAIL] $test_name: pattern B not found: $pattern_b"
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

# Find the most recent Antigravity transcript JSONL file
# Antigravity stores transcripts at:
#   ~/.gemini/antigravity-cli/brain/<conversation-id>/.system_generated/logs/transcript.jsonl
# Usage: transcript=$(find_transcript [minutes_ago])
find_transcript() {
    local minutes="${1:-60}"
    local brain_dir="$HOME/.gemini/antigravity-cli/brain"
    if [ ! -d "$brain_dir" ]; then
        brain_dir="$HOME/.gemini/antigravity/brain"
    fi

    if [ ! -d "$brain_dir" ]; then
        echo "ERROR: Brain directory not found: $brain_dir" >&2
        return 1
    fi

    # Find the most recently modified transcript.jsonl
    local transcript=""
    local files
    files=$(find "$brain_dir" -name "transcript.jsonl" -mmin "-${minutes}" -type f 2>/dev/null)
    if [ -n "$files" ]; then
        transcript=$(echo "$files" | xargs ls -t 2>/dev/null | head -1)
    fi

    if [ -z "$transcript" ]; then
        echo "ERROR: No transcript found in last $minutes minutes" >&2
        return 1
    fi

    echo "$transcript"
}

# Check if a transcript contains a specific tool call
# Usage: transcript_has_tool "$transcript_file" "invoke_subagent"
transcript_has_tool() {
    local transcript="$1"
    local tool_name="$2"

    grep -q "\"$tool_name\"" "$transcript" 2>/dev/null
}

# Count tool invocations in a transcript
# Usage: count=$(transcript_tool_count "$transcript_file" "invoke_subagent")
transcript_tool_count() {
    local transcript="$1"
    local tool_name="$2"

    grep -c "\"$tool_name\"" "$transcript" 2>/dev/null || echo "0"
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
export -f find_transcript
export -f transcript_has_tool
export -f transcript_tool_count
