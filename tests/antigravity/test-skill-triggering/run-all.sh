#!/usr/bin/env bash
# Run all skill triggering tests for Antigravity 2.0
# Usage: ./run-all.sh

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

# Check agy is available
if ! command -v agy &>/dev/null; then
    echo "[SKIP] 'agy' command not found. Install Antigravity CLI to run this test."
    exit 0
fi

SKILLS=(
    "systematic-debugging"
    "test-driven-development"
    "writing-plans"
    "dispatching-parallel-agents"
    "requesting-code-review"
    "brainstorming"
)

echo "=========================================="
echo " Skill Triggering Tests (Antigravity 2.0)"
echo "=========================================="
echo ""
echo "Prompts directory: $PROMPTS_DIR"
echo ""

PASSED=0
FAILED=0
SKIPPED=0
RESULTS=()

for skill in "${SKILLS[@]}"; do
    prompt_file="$PROMPTS_DIR/${skill}.txt"

    if [ ! -f "$prompt_file" ]; then
        echo "⚠️  SKIP: No prompt file for $skill"
        SKIPPED=$((SKIPPED + 1))
        RESULTS+=("⚠️  $skill (skipped — no prompt)")
        continue
    fi

    echo "Testing: $skill"
    echo "  Prompt: $prompt_file"

    if "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file" 300 2>&1 | tee /tmp/agy-skill-test-$skill.log; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✅ $skill")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("❌ $skill")
    fi

    echo ""
    echo "---"
    echo ""
done

echo ""
echo "=========================================="
echo " Summary"
echo "=========================================="
echo ""
for result in "${RESULTS[@]}"; do
    echo "  $result"
done
echo ""
echo "Passed:  $PASSED"
echo "Failed:  $FAILED"
echo "Skipped: $SKIPPED"
echo "Total:   ${#SKILLS[@]}"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
