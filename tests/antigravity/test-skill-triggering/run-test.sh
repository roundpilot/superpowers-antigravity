#!/usr/bin/env bash
# Skill triggering with a natural prompt: agy must view_file <skill>/SKILL.md.
# Usage: run-test.sh <skill> <prompt-file> [secs=300]
# Exit 0 PASS, 1 FAIL, 77 SKIP.
set -uo pipefail

SKILL="${1:-}"
PROMPT_FILE="${2:-}"
SECS="${3:-300}"
if [ -z "$SKILL" ] || [ -z "$PROMPT_FILE" ]; then
    echo "Usage: $0 <skill> <prompt-file> [secs]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"
JT="$SCRIPT_DIR/../lib/json-tool.mjs"

require_agy_and_plugin
if [ ! -f "$PROMPT_FILE" ]; then
    echo "[FAIL] Prompt file not found: $PROMPT_FILE"
    exit 1
fi
PROMPT=$(tr -d '\r' < "$PROMPT_FILE")

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
agy_run stream.jsonl stderr.txt "$SECS" -p "$PROMPT" --output-format stream-json
classify_agy_run $? stderr.txt stream.jsonl || exit $?

READS=$(node "$JT" stream tool-calls view_file --field AbsolutePath < stream.jsonl | tr '\\' '/')
if printf '%s\n' "$READS" | grep -q "/${SKILL}/SKILL\.md$"; then
    echo "[PASS] $SKILL: read $(printf '%s\n' "$READS" | grep "/${SKILL}/SKILL\.md$" | head -n 1)"
    RC=0
else
    echo "[FAIL] $SKILL: no view_file of $SKILL/SKILL.md"
    printf '%s\n' "$READS" | grep 'SKILL\.md$' | sed 's/^/  read: /'
    RC=1
fi
if [ -n "$(node "$JT" stream tool-calls view_file --field IsSkillFile < stream.jsonl)" ]; then
    echo "[INFO] IsSkillFile was present"
else
    echo "[INFO] IsSkillFile was absent"
fi
echo "[INFO] text: $(node "$JT" stream text < stream.jsonl | head -c 300)"
exit $RC
