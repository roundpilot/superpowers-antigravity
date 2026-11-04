#!/usr/bin/env bash
# Test: Workspace Isolation Guidance (Antigravity 2.0)
# Verifies that Antigravity correctly handles workspace isolation
# when triggered with a prompt that invokes the using-git-worktrees skill.
# Usage: test-worktree-workspace.sh [--from-stream <file>]   (--from-stream checks the stream only)
#
# WORKSPACE_VARIANT names the expected isolation: A = feature branch with inherit
# implementers (default), B = branch worktrees for implementers.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
WORKSPACE_VARIANT="${WORKSPACE_VARIANT:-A}"
case "$WORKSPACE_VARIANT" in
  A) ISOLATION_RE='feature.branch|checkout -b|"inherit"' ;;
  B) ISOLATION_RE='"branch"|workspace.*branch' ;;
  *) echo "[FAIL] WORKSPACE_VARIANT must be A or B, not '$WORKSPACE_VARIANT'"; exit 1 ;;
esac


JT="$SCRIPT_DIR/lib/json-tool.mjs"

echo "========================================"
echo " Test: Workspace Isolation (Antigravity)"
echo "========================================"
echo ""

FROM_STREAM=""
if [ "${1:-}" = "--from-stream" ]; then
    FROM_STREAM="${2:?--from-stream needs a file}"
    STREAM="$FROM_STREAM"
    classify_agy_run 0 /dev/null "$STREAM" || exit $?
else
    require_agy_and_plugin
    TEST_PROJECT=$(create_test_project)
    echo "Test project: $TEST_PROJECT"
    trap 'cleanup_test_project "$TEST_PROJECT"' EXIT
    git -C "$TEST_PROJECT" init --quiet
    git -C "$TEST_PROJECT" config user.email "test@test.com"
    git -C "$TEST_PROJECT" config user.name "Test User"
    echo '{"name": "test-project"}' > "$TEST_PROJECT/package.json"
    git -C "$TEST_PROJECT" add .
    git -C "$TEST_PROJECT" commit -m "Initial commit" --quiet
    INITIAL=$(git -C "$TEST_PROJECT" rev-parse --abbrev-ref HEAD)

    STREAM_DIR=$(mktemp -d)
    STREAM="$STREAM_DIR/stream.jsonl"
    trap 'cleanup_test_project "$TEST_PROJECT"; rm -rf "$STREAM_DIR"' EXIT
    (cd "$TEST_PROJECT" && agy_run "$STREAM" "$STREAM_DIR/stderr.txt" 300 \
        -p "$(bash "$SCRIPT_DIR/lib/fixture-plan-project.sh" --print-prompt worktree)" --output-format stream-json)
    classify_agy_run $? "$STREAM_DIR/stderr.txt" "$STREAM" || exit $?
fi

# Evidence from the stream and, live, from the project
HAVE_A=0; HAVE_B=0; HAVE_C=0; HAVE_D=0
if node "$JT" stream subagents --field at_init_cwd < "$STREAM" | grep -qx false; then HAVE_C=1; fi
if ! node "$JT" stream tool-calls run_command --field CommandLine < "$STREAM" | grep -q 'git worktree add'; then HAVE_D=1; fi
if [ -z "$FROM_STREAM" ]; then
    [ "$(git -C "$TEST_PROJECT" rev-parse --abbrev-ref HEAD)" != "$INITIAL" ] && HAVE_A=1
    [ "$(git -C "$TEST_PROJECT" worktree list --porcelain | grep -c '^worktree ')" -gt 1 ] && HAVE_B=1
fi
echo "[INFO] (a) branch changed: $HAVE_A  (b) more than one worktree: $HAVE_B  (c) subagent outside the init cwd: $HAVE_C  (d) no 'git worktree add': $HAVE_D"

# The old prose checks, kept as information
TEXT=$(node "$JT" stream text < "$STREAM")
if printf '%s' "$TEXT" | grep -qiE "$ISOLATION_RE"; then echo "[INFO] isolation parameter referenced in the reply"; else echo "[INFO] no isolation parameter in the reply"; fi
if printf '%s' "$TEXT" | grep -qiE 'invoke_subagent.*workspace|subagent.*branch|subagent.*isolat'; then echo "[INFO] subagent workspace dispatch referenced"; fi
if printf '%s' "$TEXT" | grep -qiE 'worktree|feature.branch|git.*branch|isolated.*branch|branch.*isolat'; then echo "[INFO] branch or worktree concept referenced"; fi

MISSING=""
if [ -n "$FROM_STREAM" ]; then
    # the stream alone: A needs (d); B needs (c) and (d)
    [ "$HAVE_D" -eq 1 ] || MISSING="$MISSING (d)"
    if [ "$WORKSPACE_VARIANT" = B ] && [ "$HAVE_C" -ne 1 ]; then MISSING="$MISSING (c)"; fi
elif [ "$WORKSPACE_VARIANT" = A ]; then
    [ "$HAVE_A" -eq 1 ] || MISSING="$MISSING (a)"
    [ "$HAVE_D" -eq 1 ] || MISSING="$MISSING (d)"
else
    if [ "$HAVE_B" -ne 1 ] && [ "$HAVE_C" -ne 1 ]; then MISSING="$MISSING (b) or (c)"; fi
    [ "$HAVE_D" -eq 1 ] || MISSING="$MISSING (d)"
fi

if [ -n "$MISSING" ]; then
    echo "[FAIL] WORKSPACE_VARIANT=$WORKSPACE_VARIANT: missing evidence$MISSING"
    exit 1
fi
echo "[PASS] WORKSPACE_VARIANT=$WORKSPACE_VARIANT: workspace isolation evidence found"
exit 0
