#!/usr/bin/env bash
# Test skill triggering with naive prompts (Antigravity 2.0 version)
# Usage: ./run-test.sh <skill-name> <prompt-file> [max-timeout]
#
# Tests whether Antigravity triggers a skill based on a natural prompt
# (without explicitly mentioning the skill name)
#
# In Antigravity, skills auto-load from plugins. There is no explicit
# "Skill" tool call. Instead, we look for:
#   - Skill name mentions in the output text
#   - "I'm using the" / "using the ... skill" announcements
#   - view_file calls on SKILL.md files
#   - Behavioral evidence (e.g., subagent dispatch for dispatching-parallel-agents)

set -e

SKILL_NAME="$1"
PROMPT_FILE="$2"
TIMEOUT="${3:-300}"

if [ -z "$SKILL_NAME" ] || [ -z "$PROMPT_FILE" ]; then
    echo "Usage: $0 <skill-name> <prompt-file> [timeout-seconds]"
    echo "Example: $0 systematic-debugging ../../skill-triggering/prompts/systematic-debugging.txt"
    exit 1
fi

# Get script and repo directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPERS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$HELPERS_DIR/test-helpers.sh"

# Check agy is available
if ! command -v agy &>/dev/null; then
    echo "[SKIP] 'agy' command not found. Install Antigravity CLI to run this test."
    exit 0
fi

TIMESTAMP=$(date +%s)
OUTPUT_DIR="/tmp/superpowers-agy-tests/${TIMESTAMP}/skill-triggering/${SKILL_NAME}"
mkdir -p "$OUTPUT_DIR"

# Read prompt from file
if [ ! -f "$PROMPT_FILE" ]; then
    echo "[FAIL] Prompt file not found: $PROMPT_FILE"
    exit 1
fi
PROMPT=$(cat "$PROMPT_FILE")

echo "=== Skill Triggering Test (Antigravity) ==="
echo "Skill: $SKILL_NAME"
echo "Prompt file: $PROMPT_FILE"
echo "Timeout: ${TIMEOUT}s"
echo "Output dir: $OUTPUT_DIR"
echo ""

# Copy prompt for reference
cp "$PROMPT_FILE" "$OUTPUT_DIR/prompt.txt"

# Run Antigravity
LOG_FILE="$OUTPUT_DIR/agy-output.txt"
cd "$OUTPUT_DIR"

echo "Running agy --print with naive prompt..."
OUTPUT=$(run_antigravity "$PROMPT" "$TIMEOUT") || true
echo "$OUTPUT" > "$LOG_FILE"

echo ""
echo "=== Results ==="
echo ""

TRIGGERED=false

# Detection strategy for Antigravity:
# 1. Check for skill name mentions in output text
# 2. Check for "using the ... skill" announcements
# 3. Check for SKILL.md file reads (skill was loaded)
# 4. Check for skill-specific behavioral evidence

# Check 1: Direct skill name mention
if echo "$OUTPUT" | grep -qi "$SKILL_NAME"; then
    echo "  ✓ Skill name '$SKILL_NAME' mentioned in output"
    TRIGGERED=true
fi

# Check 2: "I'm using" / "using the" skill announcements
if echo "$OUTPUT" | grep -qiE "(I'm using|using the|I will use|invoking|activating).*${SKILL_NAME}"; then
    echo "  ✓ Skill usage announcement detected"
    TRIGGERED=true
fi

# Check 3: SKILL.md file read (skill was loaded from plugin)
if echo "$OUTPUT" | grep -qi "SKILL.md"; then
    echo "  ✓ SKILL.md file reference detected"
    TRIGGERED=true
fi

# Check 4: Skill-specific behavioral evidence
case "$SKILL_NAME" in
    dispatching-parallel-agents|subagent-driven-development)
        if echo "$OUTPUT" | grep -qi "subagent\|invoke_subagent\|parallel"; then
            echo "  ✓ Subagent dispatch behavior detected"
            TRIGGERED=true
        fi
        ;;
    systematic-debugging)
        if echo "$OUTPUT" | grep -qiE "hypothes[ie]s|bisect|isolat|diagnos"; then
            echo "  ✓ Systematic debugging behavior detected"
            TRIGGERED=true
        fi
        ;;
    test-driven-development)
        if echo "$OUTPUT" | grep -qiE "red.green.refactor|test.first|write.*test.*before"; then
            echo "  ✓ TDD behavior detected"
            TRIGGERED=true
        fi
        ;;
    writing-plans)
        if echo "$OUTPUT" | grep -qiE "implementation.plan|plan.*task|break.*down"; then
            echo "  ✓ Planning behavior detected"
            TRIGGERED=true
        fi
        ;;
    requesting-code-review)
        if echo "$OUTPUT" | grep -qiE "code.review|review.*code|reviewer"; then
            echo "  ✓ Code review behavior detected"
            TRIGGERED=true
        fi
        ;;
    executing-plans)
        if echo "$OUTPUT" | grep -qiE "execut.*plan|follow.*plan|implement.*plan"; then
            echo "  ✓ Plan execution behavior detected"
            TRIGGERED=true
        fi
        ;;
    brainstorming)
        if echo "$OUTPUT" | grep -qiE "brainstorm|ideas|options|approaches|alternatives"; then
            echo "  ✓ Brainstorming behavior detected"
            TRIGGERED=true
        fi
        ;;
esac

echo ""
if [ "$TRIGGERED" = "true" ]; then
    echo "✅ PASS: Skill '$SKILL_NAME' was triggered"
else
    echo "❌ FAIL: Skill '$SKILL_NAME' was NOT triggered"
fi

# Show first portion of output for debugging
echo ""
echo "Output excerpt (first 500 chars):"
echo "$OUTPUT" | head -c 500
echo ""

echo ""
echo "Full log: $LOG_FILE"
echo "Timestamp: $TIMESTAMP"

if [ "$TRIGGERED" = "true" ]; then
    exit 0
else
    exit 1
fi
