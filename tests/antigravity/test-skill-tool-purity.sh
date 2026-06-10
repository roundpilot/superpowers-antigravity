#!/usr/bin/env bash
# Test: Skill Tool Purity (Static Validation)
# Validates that skill files contain no legacy tool names or platform references.
# This test does NOT require agy — it's purely a static check.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

echo "========================================"
echo " Test: Skill Tool Purity (Static)"
echo "========================================"
echo ""

FAILED=0

# Check 1: No CC-specific tool names
echo "=== Check 1: Claude Code Tool Names ==="
echo ""

CC_TOOLS="TodoWrite|EnterWorktree|Task tool|Skill tool"
if grep -rn "$CC_TOOLS" "$SKILLS_DIR"; then
    echo "  [FAIL] Claude Code tool names found in skills"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No Claude Code tool names found"
fi
echo ""

# Check 2: No legacy platform references
echo "=== Check 2: Legacy Platform References ==="
echo ""

PLATFORMS="Claude Code|Codex CLI|Codex App|Copilot CLI|OpenCode|Factory Droid|Gemini CLI"
if grep -rn "$PLATFORMS" "$SKILLS_DIR"; then
    echo "  [FAIL] Legacy platform references found in skills"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No legacy platform references found"
fi
echo ""

# Check 3: No tool mapping file references
echo "=== Check 3: Tool Mapping References ==="
echo ""

MAPPINGS="antigravity-tools|copilot-tools|codex-tools|gemini-tools"
if grep -rn "$MAPPINGS" "$SKILLS_DIR"; then
    echo "  [FAIL] Tool mapping file references found in skills"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No tool mapping references found"
fi
echo ""

# Check 4: No executing-plans references
echo "=== Check 4: Deleted Skill References ==="
echo ""

if grep -rn "executing-plans" "$SKILLS_DIR"; then
    echo "  [FAIL] References to deleted skill 'executing-plans' found"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No references to deleted skills found"
fi
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
