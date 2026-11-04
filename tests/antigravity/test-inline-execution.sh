#!/usr/bin/env bash
# Test: Inline Execution (live)
# executing-plans must run the two-task plan in the session itself: it reads its skill,
# dispatches no implementer or per-task reviewer, and the project ends up built and committed.
# Usage: test-inline-execution.sh [--from-stream <file>]   (--from-stream checks the stream only)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
JT="$SCRIPT_DIR/lib/json-tool.mjs"
FIXTURE="$SCRIPT_DIR/lib/fixture-plan-project.sh"

echo "========================================"
echo " Test: Inline Execution (Antigravity)"
echo "========================================"
echo ""

FROM_STREAM=""
if [ "${1:-}" = "--from-stream" ]; then
    FROM_STREAM="${2:?--from-stream needs a file}"
    STREAM="$FROM_STREAM"
    classify_agy_run 0 /dev/null "$STREAM" || exit $?
else
    require_agy_and_plugin
    WORK=$(mktemp -d)
    trap 'rm -rf "$WORK"' EXIT
    P="$WORK/proj"
    bash "$FIXTURE" "$P" >/dev/null || exit 1
    STREAM="$WORK/stream.jsonl"
    (cd "$P" && agy_run "$STREAM" "$WORK/stderr.txt" 1800 \
        -p "$(bash "$FIXTURE" --print-prompt inline)" --output-format stream-json)
    classify_agy_run $? "$WORK/stderr.txt" "$STREAM" || exit $?
fi

FAILED=0

# 1: the skill was read
if node "$JT" stream tool-calls view_file --field AbsolutePath < "$STREAM" | tr '\\' '/' | grep -q '/executing-plans/SKILL\.md$'; then
    echo "[PASS] read executing-plans/SKILL.md"
else
    echo "[FAIL] no view_file of executing-plans/SKILL.md"
    FAILED=$((FAILED + 1))
fi

# 2: no per-task dispatch
while IFS= read -r t; do
    [ -n "$t" ] || continue
    if type_in_set "$t" $IMPL_FAMILY spec-reviewer code-reviewer re-reviewer; then
        echo "[FAIL] per-task dispatch: $t"
        FAILED=$((FAILED + 1))
    else
        echo "[INFO] subagent dispatched: $t"
    fi
done < <(node "$JT" stream subagents --field type_name < "$STREAM")

# 3: the project result
if [ -n "$FROM_STREAM" ]; then
    echo "[N/A] project checks (commits, files, npm test) need a live run"
else
    COMMITS=$(git -C "$P" rev-list --count HEAD)
    if [ "$COMMITS" -ge 3 ]; then
        echo "[PASS] $COMMITS commits"
    else
        echo "[FAIL] $COMMITS commits, expected at least 3"
        FAILED=$((FAILED + 1))
    fi
    for f in src/hello.js src/goodbye.js; do
        if [ -f "$P/$f" ]; then echo "[PASS] $f exists"; else echo "[FAIL] $f missing"; FAILED=$((FAILED + 1)); fi
    done
    if (cd "$P" && npm test >"$WORK/npm.txt" 2>&1); then
        echo "[PASS] npm test passes"
    else
        echo "[FAIL] npm test failed"
        sed 's/^/    /' "$WORK/npm.txt"
        FAILED=$((FAILED + 1))
    fi
fi

[ "$FAILED" -eq 0 ]
