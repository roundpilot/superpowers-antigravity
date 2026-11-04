#!/usr/bin/env bash
# Test: Bundled final-reviewer dispatch (live)
# The bundled final-reviewer must resolve when the agent dispatches it by TypeName.
# Usage: test-bundled-dispatch.sh [--from-stream <file>]   (--from-stream skips agy)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
JT="$SCRIPT_DIR/lib/json-tool.mjs"

echo "========================================"
echo " Test: Bundled Dispatch (Antigravity)"
echo "========================================"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--from-stream" ]; then
    STREAM="${2:?--from-stream needs a file}"
    classify_agy_run 0 /dev/null "$STREAM" || exit $?
else
    require_agy_and_plugin
    git init -q "$WORK/proj"
    STREAM="$WORK/stream.jsonl"
    P='Dispatch the bundled final-reviewer subagent with invoke_subagent (TypeName "final-reviewer") and the prompt "Reply with the single word OK." Report its reply and do nothing else.'
    (cd "$WORK/proj" && agy_run "$STREAM" "$WORK/stderr.txt" 600 -p "$P" --output-format stream-json)
    classify_agy_run $? "$WORK/stderr.txt" "$STREAM" || exit $?
fi

SEEN=$(node "$JT" stream subagents --field type_name < "$STREAM")
HIT=$(printf '%s\n' "$SEEN" | grep -E '^(.*:)?final-reviewer$' | head -n 1 || true)
if [ -n "$HIT" ]; then
    echo "[PASS] final-reviewer resolved as $HIT"
    exit 0
fi
echo "[FAIL] no final-reviewer dispatch; type_names seen: $(printf '%s\n' "$SEEN" | grep . | paste -sd, - | sed 's/,/, /g' | grep . || echo none)"
exit 1
