#!/usr/bin/env bash
# Test: Bootstrap Rule Form and Sync (Static Validation)
# This test does NOT require agy: it is purely a static check, bash text checks only.
#
# Usage: [RULE=<file>] [SKILL=<file>] bash tests/antigravity/test-rule-sync.sh
#   RULE   the rule to check (default: rules/using-superpowers.md in this repository)
#   SKILL  its source of truth (default: skills/using-superpowers/SKILL.md)
# Output: one line per check, starting at column 0: "[PASS] <label>..." or
#   "[FAIL] <label>: ...". Labels: frontmatter, no-comment, wrapper, body (mirror|include),
#   size. Callers grep "^\[FAIL\] <label>". All five checks always run.
# Exit: 0 PASS; 1 FAIL (any check failed, or RULE or SKILL is missing).
#
# What rules/using-superpowers.md must be (spec S2.1, S2.2), top to bottom:
#   line 1-4   YAML frontmatter with exactly two keys: `trigger: always_on` and a `description`
#              string-equal to the one in SKILL.md. Antigravity silently discards a file in
#              `rules/` that lacks frontmatter declaring a `trigger`; `always_on` injects the
#              rule into every conversation; `description` is the fallback Antigravity uses
#              when the rules exceed their token budget.
#   line 5     blank
#   line 6-10  upstream's session-start wrapper opening: <EXTREMELY_IMPORTANT>, "You have
#              superpowers." and the "Below is the full content..." line. Upstream names
#              another harness's tool there; here it ends "read their full `SKILL.md` when
#              they apply:" (the one recorded divergence, R3).
#   line 11..  the body, then </EXTREMELY_IMPORTANT> as the last line, then a newline.
# The whole file uses LF line endings (.gitattributes sets `*.md text eol=lf`).
#
# Body forms. The default is a mirror: SKILL.md after its frontmatter and the blank line that
# follows it, byte for byte. SKILL.md stays the source of truth: copy every change to its body
# or `description` into the rule in the same change. The @-import form
#   @[using-superpowers](../skills/using-superpowers/SKILL.md)
# was avoided because the platform docs are self-contradictory on relative-path resolution for
# rule files, and @[label](path) inlining is documented only for AGENTS.md, GEMINI.md and
# `.agents/rules/*.md`. This test accepts either form, so switching between them needs no test
# edit. Never `@filename` and never a bare `@path`.
#
# Rules carry no HTML comment (a comment before the frontmatter makes Antigravity discard the
# whole file, and anywhere else it is noise in every conversation). The notes that used to sit
# in a 17-line comment at the top of the rule are these header lines and CONTRIBUTING.md,
# "Packaging and bootstrap". They said: the rule ships through the documented plugin `rules/`
# channel, in addition to the GEMINI.md + gemini-extension.json `contextFileName` channel kept
# for the CLI and legacy compatibility; and the Rules docs describe four activation modes
# (Manual, Always On, Model Decision, Glob) set at the rule level. The `trigger` frontmatter key
# is how a rule file declares its mode.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RULE="${RULE:-$REPO_ROOT/rules/using-superpowers.md}"
SKILL="${SKILL:-$REPO_ROOT/skills/using-superpowers/SKILL.md}"
WRAP_OPEN=('<EXTREMELY_IMPORTANT>' 'You have superpowers.' '' "**Below is the full content of your 'superpowers:using-superpowers' skill - your introduction to using skills. For all other skills, read their full \`SKILL.md\` when they apply:**" '')
WRAP_CLOSE='</EXTREMELY_IMPORTANT>'
INCLUDE_LINE='@[using-superpowers](../skills/using-superpowers/SKILL.md)'
MAX_BYTES=24000

# Fixed layout: 4 frontmatter lines, 1 blank line, 5 wrapper lines, then the body.
BODY_FIRST=11

FAILS=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1"; FAILS=$((FAILS + 1)); }

echo "========================================"
echo " Test: Bootstrap Rule Form and Sync (Static)"
echo "========================================"
echo ""

HAVE_RULE=0
HAVE_SKILL=0
[ -f "$RULE" ] && HAVE_RULE=1
[ -f "$SKILL" ] && HAVE_SKILL=1

# Line N of $RULE, without its newline. N beyond the end gives an empty string, so every
# caller also checks the line count first.
rule_line() { sed -n "${1}p" "$RULE"; }

# Line count of $RULE, counting a final line that lacks its newline.
RULE_LINES=0
[ "$HAVE_RULE" -eq 1 ] && RULE_LINES="$(grep -c '' "$RULE")"

# Line number of SKILL's closing frontmatter delimiter; empty when SKILL does not start with
# a frontmatter block.
SKILL_FM_END=""
if [ "$HAVE_SKILL" -eq 1 ] && [ "$(sed -n 1p "$SKILL")" = '---' ]; then
    SKILL_FM_END="$(grep -n '^---$' "$SKILL" | sed -n 2p | cut -d: -f1)"
fi

# ---------------------------------------------------------------- frontmatter
check_frontmatter() {
    if [ "$HAVE_RULE" -ne 1 ]; then
        fail "frontmatter: rule file not found: $RULE"
        return
    fi
    if [ "$HAVE_SKILL" -ne 1 ]; then
        fail "frontmatter: source file not found: $SKILL"
        return
    fi
    if [ -z "$SKILL_FM_END" ]; then
        fail "frontmatter: $SKILL has no closing '---' frontmatter delimiter"
        return
    fi

    local dline D
    dline="$(sed -n "2,$((SKILL_FM_END - 1))p" "$SKILL" | grep -m 1 '^description:' || true)"
    if [ -z "$dline" ]; then
        fail "frontmatter: no 'description:' key in the frontmatter of $SKILL"
        return
    fi
    D="${dline#description:}"
    D="${D# }"
    case "$D" in
        \"*\") D="${D#\"}"; D="${D%\"}" ;;
        \'*\') D="${D#\'}"; D="${D%\'}" ;;
    esac
    case "$D" in
        *\"* | *\\*)
            fail "frontmatter: SKILL.md's description contains a double quote or a backslash; the rule's double-quoted value would need YAML escaping, which this test does not model"
            return
            ;;
    esac

    local bad=""
    [ "$(rule_line 1)" = '---' ] || bad="$bad line 1 is not '---';"
    [ "$(rule_line 2)" = 'trigger: always_on' ] || bad="$bad line 2 is not 'trigger: always_on';"
    [ "$(rule_line 3)" = "description: \"$D\"" ] || bad="$bad line 3 is not 'description: \"<SKILL.md description>\"';"
    [ "$(rule_line 4)" = '---' ] || bad="$bad line 4 is not '---' (exactly two keys, no comments);"
    if [ -n "$bad" ]; then
        fail "frontmatter:${bad%;}"
    else
        pass "frontmatter: trigger: always_on and a description string-equal to SKILL.md's"
    fi
}

# ----------------------------------------------------------------- no-comment
check_no_comment() {
    if [ "$HAVE_RULE" -ne 1 ]; then
        fail "no-comment: rule file not found: $RULE"
        return
    fi
    local hits
    hits="$(grep -n '<!--' "$RULE" || true)"
    if [ -n "$hits" ]; then
        fail "no-comment: an HTML comment appears in the rule"
        echo "$hits"
    else
        pass "no-comment: no HTML comment anywhere in the rule"
    fi
}

# -------------------------------------------------------------------- wrapper
check_wrapper() {
    if [ "$HAVE_RULE" -ne 1 ]; then
        fail "wrapper: rule file not found: $RULE"
        return
    fi
    if [ "$RULE_LINES" -lt "$BODY_FIRST" ]; then
        fail "wrapper: the rule has $RULE_LINES lines, fewer than the $BODY_FIRST its frontmatter and wrapper need"
        return
    fi
    local bad="" i want got last
    [ -z "$(rule_line 5)" ] || bad="$bad line 5 is not empty;"
    for i in 0 1 2 3 4; do
        want="${WRAP_OPEN[$i]}"
        got="$(rule_line $((6 + i)))"
        [ "$got" = "$want" ] || bad="$bad line $((6 + i)) differs from the upstream wrapper;"
    done
    last="$(sed -n '$p' "$RULE")"
    [ "$last" = "$WRAP_CLOSE" ] || bad="$bad the last line is not '$WRAP_CLOSE';"
    [ "$(tail -c 1 "$RULE" | od -An -tx1 | tr -d ' \n')" = '0a' ] || bad="$bad the file does not end with a newline;"
    # sed and grep under Git Bash on Windows drop a carriage return from each line they read,
    # so no line check above can see CRLF; count the bytes with tr instead.
    [ "$(tr -cd '\r' < "$RULE" | wc -c | tr -d ' ')" = '0' ] || bad="$bad the file contains carriage returns (it must use LF line endings);"
    if [ -n "$bad" ]; then
        fail "wrapper:${bad%;}"
    else
        pass "wrapper: upstream's opening on lines 6-10, $WRAP_CLOSE last, final newline"
    fi
}

# ----------------------------------------------------------------------- body
check_body() {
    if [ "$HAVE_RULE" -ne 1 ]; then
        fail "body: rule file not found: $RULE"
        return
    fi
    local last=$((RULE_LINES - 1))

    # Include form: the body is exactly the one @-import line, and its target exists.
    if [ "$RULE_LINES" -eq $((BODY_FIRST + 1)) ] && [ "$(rule_line "$BODY_FIRST")" = "$INCLUDE_LINE" ]; then
        local target
        target="$(dirname "$RULE")/../skills/using-superpowers/SKILL.md"
        if [ -f "$target" ]; then
            pass "body (include): $INCLUDE_LINE resolves to an existing file"
        else
            fail "body (include): the import target does not exist: $target"
        fi
        return
    fi

    # Mirror form: byte-identical to SKILL.md after its frontmatter and the blank line after it.
    if [ "$HAVE_SKILL" -ne 1 ]; then
        fail "body (mirror): source file not found: $SKILL"
        return
    fi
    if [ -z "$SKILL_FM_END" ]; then
        fail "body (mirror): $SKILL has no closing '---' frontmatter delimiter"
        return
    fi
    if [ -n "$(sed -n "$((SKILL_FM_END + 1))p" "$SKILL")" ]; then
        fail "body (mirror): the line after SKILL.md's frontmatter is not blank"
        return
    fi

    tail -n "+$((SKILL_FM_END + 2))" "$SKILL" > "$TMP/skill-body"
    if [ "$last" -ge "$BODY_FIRST" ]; then
        sed -n "${BODY_FIRST},${last}p" "$RULE" > "$TMP/rule-body"
    else
        : > "$TMP/rule-body"
    fi
    if cmp -s "$TMP/skill-body" "$TMP/rule-body"; then
        pass "body (mirror): lines $BODY_FIRST-$last are byte-identical to SKILL.md past its frontmatter"
    else
        fail "body (mirror): lines $BODY_FIRST-$last of the rule differ from SKILL.md past its frontmatter (diff -u skill-body rule-body)"
        diff -u "$TMP/skill-body" "$TMP/rule-body"
    fi
}

# ----------------------------------------------------------------------- size
check_size() {
    if [ "$HAVE_RULE" -ne 1 ]; then
        fail "size: rule file not found: $RULE"
        return
    fi
    local n
    n="$(wc -c < "$RULE")"
    n=$((n + 0))
    if [ "$n" -le "$MAX_BYTES" ]; then
        pass "size: $n bytes (limit $MAX_BYTES)"
    else
        fail "size: $n bytes exceeds the limit of $MAX_BYTES"
    fi
}

check_frontmatter
check_no_comment
check_wrapper
check_body
check_size

echo ""
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""
if [ "$FAILS" -eq 0 ]; then
    echo "[PASS] Rule sync test passed"
    exit 0
fi
echo "[FAIL] Rule sync test failed"
exit 1
