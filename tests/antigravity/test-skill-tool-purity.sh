#!/usr/bin/env bash
# Test: Skill Tool Purity (Static Validation)
# The release gate for the purity law (S7.1). The law lives in purity-patterns.txt,
# next to this script; this script runs one `grep -E` check per row of that file.
# This test does NOT require agy: it is purely a static check.
#
# Usage: bash tests/antigravity/test-skill-tool-purity.sh [ROOT]
#   ROOT  the tree to scan (default: this repository). Hits print relative to ROOT.
#   Data files are read from the directory of this script, never from the current
#   directory or from ROOT.
# Exit: 0 PASS; 1 FAIL (a banned-vocabulary hit, a grep error, or bad data).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA="$SCRIPT_DIR/purity-patterns.txt"
TAB=$'\t'
CR=$'\r'

echo "========================================"
echo " Test: Skill Tool Purity (Static)"
echo "========================================"
echo ""

if [ ! -f "$DATA" ]; then
    echo "[FAIL] data file missing: $DATA"
    exit 1
fi

# Load and validate every row before running any check. Rows are
# group<TAB>paths<TAB>regex<TAB>example<TAB>counterexample. Fields are split by
# parameter expansion, not `read`, because `read` collapses runs of TAB and would
# lose empty fields. Row numbers count data rows (comments and blank lines skipped).
ROW_GROUP=()
ROW_PATHS=()
ROW_REGEX=()
ROW_EX=()
ROW_CEX=()
row=0
while IFS= read -r line || [ -n "$line" ]; do
    line="${line//$CR/}"
    case "$line" in
        '' | '#'*) continue ;;
    esac
    row=$((row + 1))

    tabs="${line//[!$TAB]/}"
    if [ "${#tabs}" -ne 4 ]; then
        echo "[FAIL] malformed row $row in purity-patterns.txt"
        exit 1
    fi

    group="${line%%"$TAB"*}"
    rest="${line#*"$TAB"}"
    paths="${rest%%"$TAB"*}"
    rest="${rest#*"$TAB"}"
    regex="${rest%%"$TAB"*}"
    rest="${rest#*"$TAB"}"
    example="${rest%%"$TAB"*}"
    counter="${rest#*"$TAB"}"

    if [ -z "$group" ] || [ -z "$paths" ] || [ -z "$regex" ]; then
        echo "[FAIL] malformed row $row in purity-patterns.txt"
        exit 1
    fi

    ROW_GROUP+=("$group")
    ROW_PATHS+=("$paths")
    ROW_REGEX+=("$regex")
    ROW_EX+=("$example")
    ROW_CEX+=("$counter")
done < "$DATA"

ROOT_ARG="${1:-$SCRIPT_DIR/../..}"
if ! ROOT="$(cd "$ROOT_ARG" 2>/dev/null && pwd)"; then
    echo "[FAIL] root not found: $ROOT_ARG"
    exit 1
fi

FAILED=0

# Check 0: each row's example matches and its counterexample does not, under grep -E and node.
echo "=== Check 0: examples ==="
echo ""
c0=0
for ((i = 0; i < ${#ROW_GROUP[@]}; i++)); do
    g="${ROW_GROUP[$i]}"
    re="${ROW_REGEX[$i]}"
    for t in ex cex; do
        if [ "$t" = ex ]; then s="${ROW_EX[$i]}"; else s="${ROW_CEX[$i]}"; fi
        gh=0
        nh=0
        printf '%s\n' "$s" | grep -qE -- "$re" && gh=1
        RE="$re" S="$s" node -e 'process.exit(new RegExp(process.env.RE,"m").test(process.env.S)?0:1)' && nh=1
        for e in grep node; do
            if [ "$e" = grep ]; then h=$gh; en="grep -E"; else h=$nh; en="node"; fi
            if [ "$t" = ex ] && [ "$h" -ne 1 ]; then echo "  [FAIL] check 0: $g example not matched by $en"; c0=1; fi
            if [ "$t" = cex ] && [ "$h" -ne 0 ]; then echo "  [FAIL] check 0: $g counterexample matched by $en"; c0=1; fi
        done
    done
done
if [ "$c0" -ne 0 ]; then FAILED=$((FAILED + 1)); else echo "  [PASS] check 0: examples agree under both engines"; fi
echo ""

for ((i = 0; i < ${#ROW_GROUP[@]}; i++)); do
    group="${ROW_GROUP[$i]}"
    regex="${ROW_REGEX[$i]}"
    echo "=== Check $((i + 1)): $group ==="
    echo ""

    found=0
    IFS=',' read -r -a path_list <<< "${ROW_PATHS[$i]}"
    for path in "${path_list[@]}"; do
        [ -n "$path" ] || continue
        [ -e "$ROOT/$path" ] || continue

        # grep exits 0 on a hit, 1 on none, 2 on an error; a hit and an error both fail.
        rc=0
        out="$(cd "$ROOT" && grep -rnE -- "$regex" "$path" 2>&1)" || rc=$?
        if [ "$rc" -ne 1 ]; then
            found=1
            [ -z "$out" ] || printf '%s\n' "$out"
        fi
    done

    if [ "$found" -ne 0 ]; then
        echo "  [FAIL] $group: banned vocabulary found"
        FAILED=$((FAILED + 1))
    else
        echo "  [PASS] $group: no banned vocabulary found"
    fi
    echo ""
done

# Summary
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "[PASS] Skill tool purity test passed (0 failures)"
    exit 0
else
    echo "[FAIL] Skill tool purity test failed ($FAILED checks failed)"
    exit 1
fi
