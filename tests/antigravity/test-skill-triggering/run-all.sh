#!/usr/bin/env bash
# Run every skill-triggering test.
# Usage: ./run-all.sh
# Exit 1 on any FAIL, else 77 on any SKIP, else 0.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

if ! command -v agy &>/dev/null; then
    echo "[SKIP] 'agy' command not found"
    exit 77
fi

SKILLS=(
    "systematic-debugging"
    "test-driven-development"
    "writing-plans"
    "dispatching-parallel-agents"
    "requesting-code-review"
    "brainstorming"
    "executing-plans"
    "diagnosing-superpowers"
)

PASSED=0
FAILED=0
SKIPPED=0
RESULTS=()

for skill in "${SKILLS[@]}"; do
    prompt_file="$PROMPTS_DIR/${skill}.txt"
    if [ ! -f "$prompt_file" ]; then
        echo "[FAIL] $skill: no prompt file"
        FAILED=$((FAILED + 1))
        RESULTS+=("FAIL $skill (no prompt file)")
        continue
    fi
    echo "Testing: $skill"
    set +e # a failing test must not stop the loop
    bash "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file" 300
    code=$?
    case "$code" in
        0) PASSED=$((PASSED + 1)); RESULTS+=("PASS $skill") ;;
        77) SKIPPED=$((SKIPPED + 1)); RESULTS+=("SKIP $skill") ;;
        *) FAILED=$((FAILED + 1)); RESULTS+=("FAIL $skill") ;;
    esac
    echo
done

echo "Summary"
printf '  %s\n' "${RESULTS[@]}"
echo "Passed: $PASSED  Failed: $FAILED  Skipped: $SKIPPED  Total: ${#SKILLS[@]}"

if [ "$FAILED" -gt 0 ]; then exit 1; fi
if [ "$SKIPPED" -gt 0 ]; then exit 77; fi
exit 0
