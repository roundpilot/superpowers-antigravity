#!/usr/bin/env bash
# Test: Plugin Discovery
# Verifies that Antigravity loads the superpowers plugin and exposes skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

PLUGIN_DIR="$HOME/.gemini/config/plugins"
PLUGIN_NAME="superpowers"
PLUGIN_PATH="$PLUGIN_DIR/$PLUGIN_NAME"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================"
echo " Test: Plugin Discovery (Antigravity)"
echo "========================================"
echo ""

# Check agy is available
if ! command -v agy &>/dev/null; then
    echo "[SKIP] 'agy' command not found. Install Antigravity CLI to run this test."
    exit 0
fi

# Track whether we created the symlink (for cleanup)
CREATED_SYMLINK=false

cleanup() {
    if [ "$CREATED_SYMLINK" = "true" ] && [ -L "$PLUGIN_PATH" ]; then
        echo ""
        echo "Cleaning up test symlink..."
        rm -f "$PLUGIN_PATH"
        echo "  Removed $PLUGIN_PATH"
    fi
}
trap cleanup EXIT

# Ensure plugin directory exists
mkdir -p "$PLUGIN_DIR"

# Create symlink if not already present
if [ -L "$PLUGIN_PATH" ] || [ -d "$PLUGIN_PATH" ]; then
    echo "Plugin already installed at: $PLUGIN_PATH"
    CREATED_SYMLINK=false
else
    echo "Creating test symlink: $PLUGIN_PATH -> $REPO_ROOT"
    ln -sfn "$REPO_ROOT" "$PLUGIN_PATH"
    CREATED_SYMLINK=true
fi

echo ""

# Verify symlink points to correct location
if [ -f "$PLUGIN_PATH/plugin.json" ]; then
    echo "  [PASS] plugin.json found in plugin directory"
else
    echo "  [FAIL] plugin.json not found at $PLUGIN_PATH/plugin.json"
    exit 1
fi

echo ""
echo "=== Running Antigravity with skill discovery prompt ==="
echo ""

# Run agy and ask it to list its skills
PROMPT="List your available skills from installed plugins. For each skill, mention its name. Do not execute any skills — just list what is available to you."

OUTPUT=$(run_antigravity "$PROMPT" 120) || {
    echo ""
    echo "[FAIL] Antigravity execution failed (exit code: $?)"
    echo "Output:"
    echo "$OUTPUT" | sed 's/^/  /'
    exit 1
}

echo ""
echo "=== Verification ==="
echo ""

FAILED=0

# Check that the output mentions superpowers-related skills
assert_contains "$OUTPUT" "superpowers" "Output mentions 'superpowers'" || FAILED=$((FAILED + 1))

# Check for key skill names in the output
EXPECTED_SKILLS=(
    "writing-plans"
    "systematic-debugging"
    "test-driven-development"
    "subagent-driven-development"
    "using-superpowers"
)

for skill in "${EXPECTED_SKILLS[@]}"; do
    assert_contains "$OUTPUT" "$skill" "Skill '$skill' mentioned in output" || FAILED=$((FAILED + 1))
done

echo ""
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "[PASS] Plugin discovery test passed"
    echo "  All expected skills were found in Antigravity output"
    exit 0
else
    echo "[FAIL] Plugin discovery test failed ($FAILED checks failed)"
    echo ""
    echo "Full output:"
    echo "$OUTPUT" | sed 's/^/  /'
    exit 1
fi
