#!/usr/bin/env bash
# Test: Tool Roster (live)
# Every baseline tool that skills/ names in backticks must be in the CLI's tool list,
# read from the init event of a stream-json run.
# Usage: test-tool-roster.sh [--from-stream <file>]   (--from-stream skips agy)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
JT="$SCRIPT_DIR/lib/json-tool.mjs"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
KNOWN="$SCRIPT_DIR/known-tools.txt"

echo "========================================"
echo " Test: Tool Roster (Antigravity)"
echo "========================================"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--from-stream" ]; then
    STREAM="${2:?--from-stream needs a file}"
    classify_agy_run 0 /dev/null "$STREAM" || exit $?
else
    require_agy_and_plugin
    STREAM="$WORK/stream.jsonl"
    (cd "$WORK" && agy_run "$STREAM" "$WORK/stderr.txt" 120 -p "Reply with the single word OK." --output-format stream-json)
    classify_agy_run $? "$WORK/stderr.txt" "$STREAM" || exit $?
fi

BASELINE=$(awk -F'\t' '$2=="baseline"{print $1}' "$KNOWN" | tr -d '\r')
# NEED: the baseline tokens that skills/**/*.md name in backticks
NEED=$(grep -rhoE '`[a-z][a-z_]*`' "$REPO_ROOT/skills" --include='*.md' | tr -d '`' | sort -u | grep -Fx -f <(printf '%s\n' "$BASELINE") || true)
if ! HAVE=$(node "$JT" stream init-tools < "$STREAM"); then
    echo "[FAIL] no init event in the stream"
    exit 1
fi

FAILED=0
while IFS= read -r tool; do
    [ -n "$tool" ] || continue
    if printf '%s\n' "$HAVE" | grep -qxF -- "$tool"; then
        echo "[PASS] $tool"
    elif [ "$tool" = ask_question ] || [ "$tool" = generate_image ]; then
        echo "[UNVERIFIED] $tool absent from init.tools (headless may omit)"
    else
        echo "[FAIL] $tool named in skills/ but absent from init.tools"
        FAILED=$((FAILED + 1))
    fi
done <<< "$NEED"

# retired and one-product names present in the list
EXTRA=$(awk -F'\t' '$2=="retired"||$2=="one-product"{print $1}' "$KNOWN" | tr -d '\r' | grep -Fx -f <(printf '%s\n' "$HAVE") | paste -sd, - | sed 's/,/, /g' || true)
echo "[INFO] init.tools also lists: ${EXTRA:-none}"

[ "$FAILED" -eq 0 ]
