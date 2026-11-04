#!/usr/bin/env bash
# Test: Plugin Layout (R12 placement guard, static)
# Nothing tracked in this repository may be something that Antigravity's rule walk,
# plugin discovery or a hook loader would pick up for users: a plugin-root hooks.json
# loads everywhere, and the rule walk reaches into workspace installs (S7.3). The test
# reads `git ls-files`, which honours GIT_INDEX_FILE, so it checks what is staged, not
# only what is committed. All path matching is `grep -iE`, so NTFS case variants
# (`Agents.md`, `.Agents/`) are caught.
#
#   Check 1  no hooks.json or hooks.example.json; hooks/ holds only HOOKS_DIR_ALLOWED
#   Check 2  no (agents|gemini).md but ALLOWED_AGENT_FACING; no rules, skills or agents
#            .json; no root mcp_config.json; nothing under .agents/ or .agent/ but
#            ALLOWED_DOT_AGENTS
#   Check 3  the two purity data files are LF in the index and pinned by .gitattributes
#
# Self-tests prove checks 1-2 can fail: six paths are staged one at a time into a COPY
# of the index (the real index is never written). Deterministic, agy-free.
# Usage: bash tests/antigravity/test-plugin-layout.sh
# Exit: 0 PASS; 1 FAIL; 77 SKIP (no git, or not a git checkout).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TAB=$'\t'

# Exact, case-sensitive path allowances. Later tasks edit these lines.
ALLOWED_AGENT_FACING=()
ALLOWED_DOT_AGENTS=(.agents/skills/contributing-to-superpowers/SKILL.md)
HOOKS_DIR_ALLOWED=(
    hooks/purity-check.mjs
    hooks/purity-check.sh   # one-release stub: remove it and this entry in the release after v6.4.2 (S7.2 item 1)
)

echo "========================================"
echo " Test: Plugin Layout (R12 placement guard)"
echo "========================================"
echo ""

if ! command -v git >/dev/null 2>&1; then
    echo "[SKIP] git not found"
    exit 77
fi
if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[SKIP] not a git checkout: the placement guard reads git ls-files"
    exit 77
fi
FAILURES=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

# Tracked paths, one per line (-z so an odd name is never C-quoted past a regex anchor;
# a name holding a newline splits into lines, each matched on its own: fail-closed).
# A process spawn is the main cost on Windows, so the NUL split happens in bash.
list_paths() {
    local p
    while IFS= read -r -d '' p; do
        printf '%s\n' "$p"
    done < <(git -C "$REPO_ROOT" ls-files -z)
}

# in_list <needle> [item...]: exact, case-sensitive membership.
in_list() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

# scan <regex> <reason> [allowed path...]: prints "<path>: <reason>" for each path in
# $PATHS (the caller's list) that matches the regex and is not an allowed path.
# Returns 1 if it printed any.
scan() {
    local re="$1" reason="$2" p hits rc=0
    shift 2
    hits="$(grep -iE -- "$re" <<< "$PATHS")"
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        in_list "$p" "$@" && continue
        echo "$p: $reason"
        rc=1
    done <<< "$hits"
    return $rc
}

# Check 1: where hook configuration may live. A plugin-root hooks.json loads for every
# user, so none is tracked.
check_1_hook_config() {
    local PATHS rc=0
    PATHS="$(list_paths)"
    scan '(^|/)hooks(\.example)?\.json$' \
        'a hooks.json or hooks.example.json (a plugin-root hooks.json loads for every user)' || rc=1
    scan '^hooks/' 'a hooks/ file outside HOOKS_DIR_ALLOWED' \
        ${HOOKS_DIR_ALLOWED[@]+"${HOOKS_DIR_ALLOWED[@]}"} || rc=1
    return $rc
}

# Check 2: files the rule walk, plugin discovery or an agent-facing loader would read.
check_2_agent_facing() {
    local PATHS rc=0
    PATHS="$(list_paths)"
    scan '(^|/)(agents|gemini)\.md$' \
        'an agent-facing agents.md or gemini.md outside ALLOWED_AGENT_FACING (the rule walk loads it)' \
        ${ALLOWED_AGENT_FACING[@]+"${ALLOWED_AGENT_FACING[@]}"} || rc=1
    scan '(^|/)\.agents?/(agents\.md|gemini\.md|rules/|rules\.json$)' \
        'agents.md, gemini.md, rules/ or rules.json under .agents/ or .agent/' || rc=1
    scan '(^|/)(rules|skills|agents)\.json$' \
        'a rules.json, skills.json or agents.json (not a plugin component)' || rc=1
    scan '^mcp_config\.json$' \
        'a root mcp_config.json (the plugin ships none)' || rc=1
    scan '(^|/)\.agents?/' \
        'a path under .agents/ or .agent/ outside ALLOWED_DOT_AGENTS' \
        ${ALLOWED_DOT_AGENTS[@]+"${ALLOWED_DOT_AGENTS[@]}"} || rc=1
    return $rc
}

# Check 3: the tab-separated purity data files are read by bash and node, so they stay
# LF in the index and .gitattributes pins that by exact path.
check_3_data_file_eol() {
    local f line meta rc=0
    for f in tests/antigravity/purity-patterns.txt tests/antigravity/known-tools.txt; do
        line="$(git -C "$REPO_ROOT" ls-files --eol -- "$f")"
        if [ -z "$line" ]; then
            echo "$f is not tracked"
            rc=1
            continue
        fi
        meta="${line%%"$TAB"*}"
        if ! grep -qiE '(^|[[:space:]])i/lf([[:space:]]|$)' <<< "$meta"; then
            echo "$f lacks i/lf ($meta)"
            rc=1
        fi
        if ! grep -qiE 'attr/text eol=lf([[:space:]]|$)' <<< "$meta"; then
            echo "$f lacks attr/text eol=lf ($meta)"
            rc=1
        fi
    done
    return $rc
}

# run_check <function> <message when clean>: prints the function's output as [WARN] or
# [FAIL] lines (a line starting "[WARN] " is a warning, every other line a failure).
run_check() {
    local out rc line fails=0
    out="$("$1")"
    rc=$?
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        case "$line" in
            "[WARN] "*) echo "  $line" ;;
            *) fail "$line"; fails=1 ;;
        esac
    done <<< "$out"
    if [ "$rc" -ne 0 ] && [ "$fails" -eq 0 ]; then
        fail "$1 returned $rc without naming a problem"
    elif [ "$rc" -eq 0 ]; then
        pass "$2"
    fi
}

# names_path <output> <path>: whether a problem line starts "<path>: ".
names_path() {
    local line
    while IFS= read -r line; do
        [[ "$line" == "$2: "* ]] && return 0
    done <<< "$1"
    return 1
}

# self_test_mutations: stage each path alone into a copy of the index and require
# check 1 or check 2 to fail and to name that path. The real index is never written:
# git reads and writes the copy through GIT_INDEX_FILE.
self_test_mutations() {
    local idx tmp blob p out1 out2 caught before after
    if ! idx="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-path index 2>/dev/null)" \
        || [ ! -f "$idx" ]; then
        fail "self-test: cannot locate the index"
        return
    fi
    tmp="$(mktemp -d)"
    blob="$(git -C "$REPO_ROOT" hash-object --stdin </dev/null)"
    before="$(git -C "$REPO_ROOT" ls-files -s)"
    for p in .agents/rules/x.md .agent/rules/x.md docs/Agents.md rules.json sub/.agents/hooks.json .agents/hooks.json; do
        cp "$idx" "$tmp/index"
        if ! GIT_INDEX_FILE="$tmp/index" git -C "$REPO_ROOT" update-index --add \
            --cacheinfo "100644,$blob,$p" >/dev/null 2>"$tmp/err"; then
            fail "self-test: could not stage $p in the index copy: $(tr '\n' ' ' <"$tmp/err")"
            continue
        fi
        # A check names the staged path only if the copy holds it, so a staging that
        # missed the copy cannot pass here; one that landed in the real index fails the
        # comparison after the loop.
        caught=""
        out1="$(GIT_INDEX_FILE="$tmp/index" check_1_hook_config)" || true
        out2="$(GIT_INDEX_FILE="$tmp/index" check_2_agent_facing)" || true
        names_path "$out1" "$p" && caught="check 1"
        names_path "$out2" "$p" && caught="${caught:+$caught and }check 2"
        if [ -n "$caught" ]; then
            pass "self-test: staging $p fails $caught"
        else
            fail "self-test: staging $p was not caught"
        fi
    done
    rm -rf "$tmp"
    after="$(git -C "$REPO_ROOT" ls-files -s)"
    if [ "$before" != "$after" ]; then
        fail "self-test: the real index changed (the self-tests must only write a copy)"
    fi
}

echo "=== Check 1: hook configuration files ==="
echo ""
run_check check_1_hook_config "no hooks.json; hooks/ holds only the allowed files"
echo ""

echo "=== Check 2: agent-facing files and .agents/ ==="
echo ""
run_check check_2_agent_facing "no agent-facing file, rules/skills/agents json, mcp_config.json or .agents/ path beyond the allowances"
echo ""

echo "=== Check 3: purity data files are LF and pinned ==="
echo ""
run_check check_3_data_file_eol "purity-patterns.txt and known-tools.txt are i/lf with attr/text eol=lf"
echo ""

echo "=== Self-test: staging a banned path must be caught ==="
echo ""
self_test_mutations
echo ""

echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ "$FAILURES" -eq 0 ]; then
    echo "[PASS] Plugin layout test passed (0 failures)"
    exit 0
else
    echo "[FAIL] Plugin layout test failed ($FAILURES failures)"
    exit 1
fi
