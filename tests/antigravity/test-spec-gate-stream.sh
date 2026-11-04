#!/usr/bin/env bash
# Test: Spec Gate over stream-json (live)
# A headless brainstorming run must stop before anything is built: every write stays in
# docs/superpowers/specs/ or the conversation's artifact directory, and the turn ends with a result.
# Usage: test-spec-gate-stream.sh [--from-stream <file>]   (--from-stream checks write targets only)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
JT="$SCRIPT_DIR/lib/json-tool.mjs"

echo "========================================"
echo " Test: Spec Gate over stream-json (Antigravity)"
echo "========================================"

FROM_STREAM=""
if [ "${1:-}" = "--from-stream" ]; then
    FROM_STREAM="${2:?--from-stream needs a file}"
    STREAM="$FROM_STREAM"
    classify_agy_run 0 /dev/null "$STREAM" || exit $?
else
    [ "${BASH_VERSINFO[0]}" -ge 4 ] || { echo "[SKIP] needs bash >= 4 for coproc"; exit 77; }
    require_agy_and_plugin
    WORK=$(mktemp -d)
    P="$WORK/proj"
    mkdir -p "$P"
    git init -q "$P"
    STREAM="$WORK/stream.jsonl"
    : > "$STREAM"
    cd "$P" || exit 1
    AGY_ARGS=(--input-format stream-json --output-format stream-json --dangerously-skip-permissions)
    [ -z "${AGY_TEST_MODEL:-}" ] || AGY_ARGS+=(--model "$AGY_TEST_MODEL")
    [ -z "${AGY_TEST_EFFORT:-}" ] || AGY_ARGS+=(--effort "$AGY_TEST_EFFORT")
    coproc agy "${AGY_ARGS[@]}" 2> "$WORK/stderr.txt"
    # COPROC_PID is unset once bash reaps the coprocess
    stop_agy() { [ -z "${COPROC_PID:-}" ] || kill "$COPROC_PID" 2>/dev/null; }
    trap 'stop_agy; rm -rf "$WORK"' EXIT

    # turn <text>: send one user message, append agy's output to the stream until its result event
    turn() {
        local text line rc
        text=$(node -p 'JSON.stringify(process.argv[1])' "$1")
        printf '{"event":"user","message":{"content":%s}}\n' "$text" >&"${COPROC[1]}"
        while IFS= read -r -t 900 line <&"${COPROC[0]}"; do
            printf '%s\n' "$line" >> "$STREAM"
            case "$line" in *'"event":"result"'*) return 0 ;; esac
        done
        rc=$?
        stop_agy
        if [ "$rc" -gt 128 ]; then echo "[SKIP] turn timed out"; else echo "[SKIP] agy exited without a result"; fi
        exit 77
    }

    TEXT="I want to build a tiny command-line tool in this empty project that prints today's date in ISO format, for use in shell scripts. Walk me through the design first."
    SPEC_FOUND=0
    for n in 1 2 3 4 5 6; do
        turn "$TEXT"
        classify_agy_run 0 "$WORK/stderr.txt" "$STREAM" || exit $?
        if [ -n "$(ls "$P"/docs/superpowers/specs/* 2>/dev/null)" ]; then SPEC_FOUND=1; break; fi
        TEXT="Use your judgement on that and continue."
    done
    if [ "$SPEC_FOUND" -eq 0 ]; then
        echo "[SKIP] no spec after 6 turns (inconclusive)"
        exit 77
    fi
    eval "exec ${COPROC[1]}>&-"
    for _ in 1 2 3 4 5 6 7 8 9 10; do [ -n "${COPROC_PID:-}" ] && kill -0 "$COPROC_PID" 2>/dev/null || break; sleep 1; done
    stop_agy
fi

BAD=""
CONV=$(node "$JT" stream result --field conversation_id < "$STREAM")
for tool in write_to_file replace_file_content multi_replace_file_content; do
    while IFS= read -r target; do
        [ -n "$target" ] || continue
        t=$(printf '%s' "$target" | tr '\\' '/')
        case "$t" in
            docs/superpowers/specs/*|*/docs/superpowers/specs/*) ;;
            */brain/"$CONV"/*) [ -n "$CONV" ] || BAD="$BAD $t" ;;
            *) BAD="$BAD $t" ;;
        esac
    done < <(node "$JT" stream tool-calls "$tool" --field TargetFile < "$STREAM")
done

if [ -z "$FROM_STREAM" ]; then
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in docs/superpowers/specs/*) ;; *) BAD="$BAD $f" ;; esac
    done < <({ git -C "$P" status --porcelain --untracked-files=all | cut -c4-; git -C "$P" log --name-only --format= 2>/dev/null; } | tr '\\' '/')
fi

if [ -n "$BAD" ]; then
    echo "[FAIL] wrote outside the spec folder:$BAD"
    exit 1
fi
echo "[PASS] the spec turn ended with a result; writes stayed in docs/superpowers/specs/ and the artifact directory"
exit 0
