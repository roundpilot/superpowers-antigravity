#!/usr/bin/env bash
# Test: Plugin Packaging (static)
# The manifests, the version mirrors and the skill frontmatter must agree with each other, so
# the plugin installs and reads the same on all three products (the 2.0 app, the IDE and the
# CLI). Static, deterministic, agy-free. Every JSON read goes through
# tests/antigravity/lib/json-tool.mjs (`keys`, `get`), so no jq and no python.
#
# Usage: [ROOT=<dir>] bash tests/antigravity/test-plugin-packaging.sh
#   ROOT  the tree whose data files are checked (default: this repository). json-tool is
#         always the repository's own, so a scratch copy of the tracked tree can be mutated
#         and checked.
# Output: one line per finding, starting at column 0, no indentation: "[PASS] check N: ..." or
#   "[FAIL] check N: ...". A check that finds several problems prints one [FAIL] line each.
#   Callers grep "^\[FAIL\] check N". Every check always runs.
# Exit: 0 PASS; 1 FAIL; 77 SKIP (no node: a blocking SKIP in the gate tier).
#
#   check 1  plugin.json keys are within PLUGIN_KEYS (so no `$schema`); its name is
#            `superpowers` and a legal plugin name; plugin.json, package.json and, if present,
#            gemini-extension.json all carry DESCRIPTION
#   check 2  one version: plugin.json `version` if it has one, else package.json's; every
#            mirror equals it: package.json, gemini-extension.json (if present), the README
#            badge URL and badge alt text, the first `## v` heading of RELEASE-NOTES.md
#   check 3  every root *.json parses as a JSON object
#   check 4  every skills/<folder>/SKILL.md opens with `---`; its frontmatter `name:` equals
#            the folder and holds no `:`; it has a `description:` line
#   check 5  gemini-extension.json and GEMINI.md are both present or both absent (the legacy
#            context channel is one pair)
#   check 7  the Environment table labels (first column) of .github/ISSUE_TEMPLATE/
#            diagnosis_report.md equal, in order, those of skills/diagnosing-superpowers/
#            templates/issue.md; bug_report.md's table carries every BUG_LABELS entry
#   check 8  CODE_OF_CONDUCT.md names no upstream contact (no `primeradiant`, no `jesse@`)
#
# check_6 is inserted before check_7 by a later task (the README skills-table check).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT="${ROOT:-$REPO_ROOT}"
JT="$SCRIPT_DIR/lib/json-tool.mjs"

# The keys plugin.json may carry (a space-separated word list). Later tasks edit this line.
PLUGIN_KEYS="name description version"
DESCRIPTION='Core skills library for Google Antigravity (2.0 app, IDE and CLI): TDD, debugging, collaboration patterns, and proven techniques'

# The Environment-table labels bug_report.md must carry (check 7), one array element each.
BUG_LABELS=("Antigravity product (2.0 app / IDE / CLI)" "Antigravity version")

echo "========================================"
echo " Test: Plugin Packaging"
echo "========================================"
echo ""

if ! command -v node >/dev/null 2>&1; then
    echo "[SKIP] node not found"
    exit 77
fi
if [ ! -f "$JT" ]; then
    echo "[FAIL] json-tool not found: $JT"
    exit 1
fi

FAILURES=0
pass() { echo "[PASS] check $1: $2"; }
fail() { echo "[FAIL] check $1: $2"; FAILURES=$((FAILURES + 1)); }

# jt_get <file> <dot.path>: sets GOT to the value exactly as json-tool printed it, minus the
# one newline it ends the value with; returns json-tool's exit status. The trailing sentinel
# keeps $(...) from eating a newline that is part of the value.
jt_get() {
    local out rc
    out="$(node "$JT" get "$1" "$2" 2>/dev/null; printf 'x%s' "$?")"
    rc="${out##*x}"
    out="${out%x*}"
    GOT="${out%$'\n'}"
    return "$rc"
}

# jt_keys <file>: sets KEYS to json-tool's output (one key per line, final newline kept);
# returns json-tool's exit status. Read it back with: while IFS= read -r k; do ...; done < <(printf '%s' "$KEYS")
jt_keys() {
    local out rc
    out="$(node "$JT" keys "$1" 2>/dev/null; printf 'x%s' "$?")"
    rc="${out##*x}"
    KEYS="${out%x*}"
    return "$rc"
}

# in_words <needle> [word...]: exact word membership (never a substring match).
in_words() {
    local needle="$1" word
    shift
    for word in "$@"; do
        [ "$word" = "$needle" ] && return 0
    done
    return 1
}

# trim_value <text>: sets VALUE to the text without surrounding whitespace and without one
# pair of matching surrounding quotes.
trim_value() {
    VALUE="$1"
    VALUE="${VALUE#"${VALUE%%[![:space:]]*}"}"
    VALUE="${VALUE%"${VALUE##*[![:space:]]}"}"
    case "$VALUE" in
        \"?*\" | \'?*\') VALUE="${VALUE:1:${#VALUE}-2}" ;;
    esac
}

# expect_version <label> <actual>: the actual value must equal CANON.
expect_version() {
    [ "$2" = "$CANON" ] || fail 2 "$1 is $2, expected $CANON (the version in $CANON_SRC)"
}

check_1() {
    local before=$FAILURES f key re='^[a-zA-Z0-9_-]+$'
    if ! jt_keys "$ROOT/plugin.json"; then
        fail 1 "plugin.json is missing or is not a JSON object"
    else
        while IFS= read -r key; do
            in_words "$key" $PLUGIN_KEYS || fail 1 "plugin.json has the key \"$key\", outside: $PLUGIN_KEYS"
        done < <(printf '%s' "$KEYS")
    fi
    if ! jt_get "$ROOT/plugin.json" name; then
        fail 1 "plugin.json has no name"
    else
        [ "$GOT" = superpowers ] || fail 1 "plugin.json name is \"$GOT\", expected superpowers"
        [[ $GOT =~ $re ]] || fail 1 "plugin.json name \"$GOT\" does not match $re"
    fi
    for f in plugin.json package.json gemini-extension.json; do
        if [ "$f" = gemini-extension.json ] && [ ! -f "$ROOT/$f" ]; then
            continue
        fi
        if ! jt_get "$ROOT/$f" description; then
            fail 1 "$f has no description"
        elif [ "$GOT" != "$DESCRIPTION" ]; then
            fail 1 "$f description is \"$GOT\", expected \"$DESCRIPTION\""
        fi
    done
    if [ "$FAILURES" -eq "$before" ]; then
        pass 1 "plugin.json keys, name and description are right"
    fi
}

check_2() {
    local before=$FAILURES got
    if jt_get "$ROOT/plugin.json" version; then
        CANON="$GOT"
        CANON_SRC=plugin.json
    elif jt_get "$ROOT/package.json" version; then
        CANON="$GOT"
        CANON_SRC=package.json
    else
        fail 2 "neither plugin.json nor package.json has a version"
        return
    fi

    if jt_get "$ROOT/package.json" version; then
        expect_version "package.json version" "$GOT"
    else
        fail 2 "package.json has no version"
    fi
    if [ -f "$ROOT/gemini-extension.json" ]; then
        if jt_get "$ROOT/gemini-extension.json" version; then
            expect_version "gemini-extension.json version" "$GOT"
        else
            fail 2 "gemini-extension.json has no version"
        fi
    fi

    if [ ! -f "$ROOT/README.md" ]; then
        fail 2 "README.md is missing"
    else
        got="$(grep -oE 'Version-[0-9]+\.[0-9]+\.[0-9]+-green' "$ROOT/README.md" | head -n 1)"
        got="${got#Version-}"
        got="${got%-green}"
        if [ -z "$got" ]; then
            fail 2 "README.md has no Version-X.Y.Z-green badge"
        else
            expect_version "README.md badge Version-X.Y.Z-green" "$got"
        fi
        got="$(grep -oE 'alt="Version [0-9]+\.[0-9]+\.[0-9]+"' "$ROOT/README.md" | head -n 1)"
        got="${got#alt=\"Version }"
        got="${got%\"}"
        if [ -z "$got" ]; then
            fail 2 "README.md has no alt=\"Version X.Y.Z\" badge text"
        else
            expect_version "README.md badge alt text" "$got"
        fi
    fi

    if [ ! -f "$ROOT/RELEASE-NOTES.md" ]; then
        fail 2 "RELEASE-NOTES.md is missing"
    else
        got="$(grep -m 1 -oE '^## v[0-9]+\.[0-9]+\.[0-9]+' "$ROOT/RELEASE-NOTES.md")"
        got="${got#\#\# v}"
        if [ -z "$got" ]; then
            fail 2 "RELEASE-NOTES.md has no '## vX.Y.Z' heading"
        else
            expect_version "RELEASE-NOTES.md first heading" "$got"
        fi
    fi

    if [ "$FAILURES" -eq "$before" ]; then
        pass 2 "every version mirror equals $CANON ($CANON_SRC)"
    fi
}

check_3() {
    local before=$FAILURES f n=0
    for f in "$ROOT"/*.json; do
        [ -f "$f" ] || continue
        n=$((n + 1))
        jt_keys "$f" || fail 3 "${f##*/} does not parse as a JSON object"
    done
    [ "$n" -gt 0 ] || fail 3 "no root *.json file found in $ROOT"
    if [ "$FAILURES" -eq "$before" ]; then
        pass 3 "$n root JSON files parse"
    fi
}

check_4() {
    local before=$FAILURES n=0 dir folder file first line name has_name has_desc closed
    for dir in "$ROOT"/skills/*/; do
        [ -d "$dir" ] || continue
        folder="${dir%/}"
        folder="${folder##*/}"
        n=$((n + 1))
        file="${dir}SKILL.md"
        if [ ! -f "$file" ]; then
            fail 4 "skills/$folder has no SKILL.md"
            continue
        fi
        first=""
        IFS= read -r first < "$file" || true
        first="${first%$'\r'}"
        if [ "$first" != '---' ]; then
            fail 4 "skills/$folder/SKILL.md line 1 is \"$first\", expected ---"
            continue
        fi
        name=""
        has_name=0
        has_desc=0
        closed=0
        {
            IFS= read -r line || true # line 1, already checked
            while IFS= read -r line || [ -n "$line" ]; do
                line="${line%$'\r'}"
                if [ "$line" = '---' ]; then
                    closed=1
                    break
                fi
                case "$line" in
                    name:*)
                        if [ "$has_name" -eq 0 ]; then
                            has_name=1
                            trim_value "${line#name:}"
                            name="$VALUE"
                        fi
                        ;;
                    description:*) has_desc=1 ;;
                esac
            done
        } < "$file"
        if [ "$closed" -eq 0 ]; then
            fail 4 "skills/$folder/SKILL.md frontmatter has no closing ---"
            continue
        fi
        if [ "$has_name" -eq 0 ]; then
            fail 4 "skills/$folder/SKILL.md frontmatter has no name:"
        else
            [ "$name" = "$folder" ] || fail 4 "skills/$folder/SKILL.md name is \"$name\", expected \"$folder\""
            case "$name" in
                *:*) fail 4 "skills/$folder/SKILL.md name \"$name\" contains a colon" ;;
            esac
        fi
        [ "$has_desc" -eq 1 ] || fail 4 "skills/$folder/SKILL.md frontmatter has no description:"
    done
    [ "$n" -gt 0 ] || fail 4 "no skills/*/ folder found in $ROOT"
    if [ "$FAILURES" -eq "$before" ]; then
        pass 4 "$n skills"
    fi
}

check_5() {
    local has_ext=0 has_md=0
    [ -f "$ROOT/gemini-extension.json" ] && has_ext=1
    [ -f "$ROOT/GEMINI.md" ] && has_md=1
    if [ "$has_ext" -eq "$has_md" ]; then
        if [ "$has_ext" -eq 1 ]; then
            pass 5 "gemini-extension.json and GEMINI.md are both present"
        else
            pass 5 "gemini-extension.json and GEMINI.md are both absent"
        fi
    elif [ "$has_ext" -eq 1 ]; then
        fail 5 "gemini-extension.json is present but GEMINI.md is missing"
    else
        fail 5 "GEMINI.md is present but gemini-extension.json is missing"
    fi
}

# env_labels <file>: the trimmed first-column cells of the first table after the first line
# starting "## Environment", one per line, without the "Field" header row and the separator
# row. A CR before the line end is ignored. Prints nothing if there is no such table.
env_labels() {
    local line cell state=0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        case "$state" in
            0)
                case "$line" in
                    '## Environment'*) state=1 ;;
                esac
                ;;
            *)
                line="${line#"${line%%[![:space:]]*}"}"
                case "$line" in
                    '|'*)
                        cell="${line#|}"
                        cell="${cell%%|*}"
                        cell="${cell#"${cell%%[![:space:]]*}"}"
                        cell="${cell%"${cell##*[![:space:]]}"}"
                        if [ "$state" -eq 1 ]; then
                            state=2
                            [ "$cell" = Field ] && continue
                        fi
                        case "$cell" in
                            '' | *[!:-]*) printf '%s\n' "$cell" ;;
                        esac
                        ;;
                    *)
                        [ "$state" -eq 2 ] && break
                        ;;
                esac
                ;;
        esac
    done < "$1"
}

check_7() {
    local diag_f="$ROOT/.github/ISSUE_TEMPLATE/diagnosis_report.md"
    local issue_f="$ROOT/skills/diagnosing-superpowers/templates/issue.md"
    local bug_f="$ROOT/.github/ISSUE_TEMPLATE/bug_report.md"
    local before=$FAILURES diag issue bug label
    if [ ! -f "$diag_f" ]; then
        fail 7 ".github/ISSUE_TEMPLATE/diagnosis_report.md is missing"
    elif [ ! -f "$issue_f" ]; then
        fail 7 "skills/diagnosing-superpowers/templates/issue.md is missing"
    else
        diag="$(env_labels "$diag_f")"
        issue="$(env_labels "$issue_f")"
        if [ -z "$issue" ]; then
            fail 7 "templates/issue.md has no Environment table"
        elif [ "$diag" != "$issue" ]; then
            fail 7 "diagnosis_report.md labels differ from templates/issue.md"
        fi
    fi
    if [ ! -f "$bug_f" ]; then
        fail 7 ".github/ISSUE_TEMPLATE/bug_report.md is missing"
    else
        bug="$(env_labels "$bug_f")"
        for label in "${BUG_LABELS[@]}"; do
            printf '%s\n' "$bug" | grep -qxF -e "$label" || fail 7 "bug_report.md lacks $label"
        done
    fi
    if [ "$FAILURES" -eq "$before" ]; then
        pass 7 "the issue-template Environment labels agree"
    fi
}

check_8() {
    local f="$ROOT/CODE_OF_CONDUCT.md" before=$FAILURES hits line
    if [ ! -f "$f" ]; then
        fail 8 "CODE_OF_CONDUCT.md is missing"
        return
    fi
    hits="$(grep -niE 'primeradiant|jesse@' "$f")"
    if [ -n "$hits" ]; then
        while IFS= read -r line; do
            line="${line%$'\r'}"
            fail 8 "CODE_OF_CONDUCT.md:$line"
        done <<< "$hits"
    fi
    if [ "$FAILURES" -eq "$before" ]; then
        pass 8 "CODE_OF_CONDUCT.md names no upstream contact"
    fi
}

check_1
check_2
check_3
check_4
check_5
check_7
check_8

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "[PASS] Plugin packaging test passed"
    exit 0
else
    echo "[FAIL] Plugin packaging test failed ($FAILURES problems)"
    exit 1
fi
