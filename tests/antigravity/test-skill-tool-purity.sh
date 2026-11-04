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

# Files the checks below scan, relative to ROOT.
SHIP_DIR=".agents/skills/contributing-to-superpowers"
list_md() {
    local d
    for d in "$@"; do
        [ -d "$ROOT/$d" ] && (cd "$ROOT" && find "$d" -type f -name '*.md')
    done
    return 0
}

# Check 5: no mapping files.
echo "=== Check 5: mapping files ==="
echo ""
c5=0
if [ -e "$ROOT/skills/using-superpowers/references" ]; then
    echo "  [FAIL] check 5: mapping file skills/using-superpowers/references"
    c5=1
fi
for d in skills agents rules; do
    [ -d "$ROOT/$d" ] || continue
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        echo "  [FAIL] check 5: mapping file $f"
        c5=1
    done < <(cd "$ROOT" && find "$d" -type f -name '*-tools.md')
done
if [ "$c5" -ne 0 ]; then FAILED=$((FAILED + 1)); else echo "  [PASS] check 5: no mapping files"; fi
echo ""

# Check 6: backticked tool-like tokens, by class from known-tools.txt.
echo "=== Check 6: tool tokens ==="
echo ""
KNOWN="$SCRIPT_DIR/known-tools.txt"
c6=0
class_of() { awk -F'\t' -v n="$1" '{ sub(/\r$/, "") } $1 == n { print $2; exit }' "$KNOWN"; }
TOKEN_RE='`[a-z]+(_[a-z]+)+`'
if [ ! -f "$KNOWN" ]; then
    echo "  [FAIL] check 6: data file missing: $KNOWN"
    c6=1
else
    # (a) skills, rules and the ship skill: baseline or not-a-tool only.
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        while IFS=: read -r ln tok; do
            [ -n "$ln" ] || continue
            tok="${tok//\`/}"
            cls="$(class_of "$tok")"
            case "$cls" in
                baseline | not-a-tool) ;;
                *) echo "  [FAIL] check 6: $f:$ln: $tok is ${cls:-unknown}, not allowed here"; c6=1 ;;
            esac
        done < <(cd "$ROOT" && grep -noE -- "$TOKEN_RE" "$f" || true)
    done < <(list_md skills rules "$SHIP_DIR")

    # (b) agent bodies: baseline, retired or not-a-tool, and listed in that file's tools:.
    if [ -d "$ROOT/agents" ]; then
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            body_start="$(awk '/^---\r?$/ { c++; if (c == 2) { print NR; exit } }' "$ROOT/$f")"
            [ -n "$body_start" ] || body_start=0
            listed="$(awk -v s="$body_start" 'NR < s && /^[[:space:]]*-[[:space:]]+[a-z_]+/ { sub(/^[[:space:]]*-[[:space:]]+/, ""); sub(/[[:space:]\r]+$/, ""); print }' "$ROOT/$f")"
            while IFS=: read -r ln tok; do
                [ -n "$ln" ] || continue
                [ "$ln" -gt "$body_start" ] || continue
                tok="${tok//\`/}"
                cls="$(class_of "$tok")"
                case "$cls" in
                    baseline | retired)
                        if ! printf '%s\n' "$listed" | grep -qxF -- "$tok"; then
                            echo "  [FAIL] check 6: $f:$ln: $tok not in this agent's tools:"
                            c6=1
                        fi
                        ;;
                    not-a-tool) ;;
                    *) echo "  [FAIL] check 6: $f:$ln: $tok is ${cls:-unknown}, not allowed here"; c6=1 ;;
                esac
            done < <(cd "$ROOT" && grep -noE -- "$TOKEN_RE" "$f" || true)
        done < <(cd "$ROOT" && find agents -maxdepth 1 -type f -name '*.md')
    fi

    # (c) row 4's names group equals retired + one-product, and browser_[a-z] is present.
    nb_regex=""
    for ((i = 0; i < ${#ROW_GROUP[@]}; i++)); do
        [ "${ROW_GROUP[$i]}" = "non-baseline-tools" ] && nb_regex="${ROW_REGEX[$i]}"
    done
    if [ -z "$nb_regex" ]; then
        echo "  [FAIL] check 6: non-baseline-tools row missing"
        c6=1
    else
        after="${nb_regex#*'(^|[^A-Za-z0-9_])('}"
        got="$(printf '%s\n' "${after%%')'*}" | tr '|' '\n' | LC_ALL=C sort | paste -sd, -)"
        want="$(awk -F'\t' '{ sub(/\r$/, "") } $2 == "retired" || $2 == "one-product" { print $1 }' "$KNOWN" | LC_ALL=C sort | paste -sd, -)"
        if [ "$got" != "$want" ]; then
            echo "  [FAIL] check 6: non-baseline-tools names $got != retired + one-product $want"
            c6=1
        fi
        case "$nb_regex" in
            *'browser_[a-z]'*) ;;
            *) echo "  [FAIL] check 6: non-baseline-tools lacks browser_[a-z]"; c6=1 ;;
        esac
    fi
fi
if [ "$c6" -ne 0 ]; then FAILED=$((FAILED + 1)); else echo "  [PASS] check 6: tool tokens match their classes"; fi
echo ""

# Check 7: scripts are invoked through their interpreter; bash/sh calls need an R6 exception.
echo "=== Check 7: script invocation ==="
echo ""
c7=0
R6_EXCEPTIONS="$(cat <<'EOF'
skills/systematic-debugging/root-cause-tracing.md	bash ./find-polluter.sh	S5.11
skills/writing-skills/SKILL.md	bash scripts/tool.sh	S5.11 (C9a)
EOF
)"
R6_EXCEPTIONS="$R6_EXCEPTIONS"$'\n'"$SHIP_DIR/SKILL.md	bash tests/run-tests.sh	S7.11"
BARE_A='^[[:space:]]*(\$[[:space:]]+)?\./[A-Za-z0-9_./-]+\.(sh|js|mjs|cjs|py)([[:space:]]|$)'
BARE_B='`\./[A-Za-z0-9_./-]+\.(sh|js|mjs|cjs|py)'
INTERP='(^|[^A-Za-z0-9_./-])(bash|sh)[[:space:]]+[A-Za-z0-9_./-]+\.sh([^A-Za-z0-9_]|$)'
while IFS= read -r f; do
    [ -n "$f" ] || continue
    while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        echo "  [FAIL] check 7: $f:${hit%%:*}: bare script path; invoke it through its interpreter"
        c7=1
    done < <(cd "$ROOT" && { grep -nE -- "$BARE_A" "$f" || true; grep -nE -- "$BARE_B" "$f" || true; } | sort -t: -k1,1n -u)
    while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        text="${hit#*:}"
        ok=0
        while IFS="$TAB" read -r ep ef _; do
            [ "$ep" = "$f" ] || continue
            case "$text" in *"$ef"*) ok=1 ;; esac
        done <<< "$R6_EXCEPTIONS"
        if [ "$ok" -eq 0 ]; then
            echo "  [FAIL] check 7: $f:${hit%%:*}: bash/sh invocation not in R6_EXCEPTIONS"
            c7=1
        fi
    done < <(cd "$ROOT" && grep -nE -- "$INTERP" "$f" || true)
done < <(list_md skills "$SHIP_DIR")
while IFS="$TAB" read -r ep ef _; do
    [ -n "$ep" ] || continue
    if ! { [ -f "$ROOT/$ep" ] && grep -qF -- "$ef" "$ROOT/$ep"; }; then
        echo "  [FAIL] check 7: stale R6 exception: $ep $ef"
        c7=1
    fi
done <<< "$R6_EXCEPTIONS"
if [ "$c7" -ne 0 ]; then FAILED=$((FAILED + 1)); else echo "  [PASS] check 7: script invocations are clean"; fi
echo ""

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
