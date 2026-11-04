#!/usr/bin/env bash
# Test: Plugin Discovery (Antigravity CLI)
# Installs this working tree for agy, then checks that agy lists every skill and every
# bundled agent on disk. It certifies the working tree only, so it SKIPs over any
# existing superpowers install.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
JT="$SCRIPT_DIR/lib/json-tool.mjs"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================"
echo " Test: Plugin Discovery (Antigravity)"
echo "========================================"
echo ""

if ! command -v agy &>/dev/null; then
    echo "[SKIP] 'agy' command not found"
    exit 77
fi
if agy_superpowers_installed; then
    echo "[SKIP] an installed superpowers exists; this test certifies the working tree only — uninstall it or run where none is installed"
    exit 77
fi
if [ "${SUPERPOWERS_AGY_INSTALL:-}" != "1" ]; then
    echo "[SKIP] set SUPERPOWERS_AGY_INSTALL=1 to install the working tree for this test"
    exit 77
fi

# Folder-trust ruling S7.8-trust=no: discovery runs from a scratch directory.
WORK=$(mktemp -d)
cleanup() {
    agy plugin uninstall superpowers >/dev/null 2>&1
    [ -n "${KEEP:-}" ] || rm -rf "$WORK"
}
trap cleanup EXIT

agy plugin install "$(cd "$REPO_ROOT" && node -p "process.cwd()")" || {
    echo "[FAIL] agy plugin install failed"
    exit 1
}
for store in "$HOME/.gemini/config/plugins/superpowers" "$HOME/.gemini/antigravity-cli/plugins/superpowers"; do
    if [ -e "$store" ]; then echo "[INFO] LC8 store: $store"; fi
done
agy plugin list

cd "$WORK" || exit 1
agy_run skills.json skills.err 120 -p "/skills" --output-format json
agy agents --output-format json > agents.json 2> agents.err

if ! node "$JT" skills-json skills.json > listed-skills.txt 2>/dev/null; then
    echo "[FAIL] nameless JSON, saved at $WORK/skills.json"
    KEEP=1
    exit 1
fi
if ! node "$JT" agents-json agents.json > listed-agents.txt 2>/dev/null; then
    echo "[FAIL] nameless JSON, saved at $WORK/agents.json"
    KEEP=1
    exit 1
fi

# front_name <file>: the name: value of the frontmatter
front_name() {
    sed -n '/^name:/{s/^name:[[:space:]]*//p;q;}' "$1" | tr -d '\r"'"'"
}

FAILED=0
# check_listed <kind> <name> <listed-file>: listed as <name> or as <prefix>:<name>
check_listed() {
    local as
    if grep -qxF -- "$2" "$3"; then
        as="$2"
    else
        as=$(grep -- ":$2\$" "$3" | head -n 1)
    fi
    if [ -n "$as" ]; then
        echo "[PASS] $1 $2 as $as"
    else
        echo "[FAIL] $1 $2 not listed"
        FAILED=$((FAILED + 1))
    fi
}

SKILL_FILES=("$REPO_ROOT"/skills/*/SKILL.md)
if [ "${#SKILL_FILES[@]}" -ne 16 ]; then
    echo "[FAIL] expected 16 skills on disk, found ${#SKILL_FILES[@]}"
    exit 1
fi
for f in "${SKILL_FILES[@]}"; do
    check_listed skill "$(front_name "$f")" listed-skills.txt
done
for f in "$REPO_ROOT"/agents/*.md; do
    check_listed agent "$(front_name "$f")" listed-agents.txt
done

echo ""
if [ "$FAILED" -eq 0 ]; then
    echo "[PASS] Plugin discovery test passed"
    exit 0
fi
echo "[FAIL] Plugin discovery test failed ($FAILED not listed)"
exit 1
