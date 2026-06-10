#!/usr/bin/env bash
# Task 9: Final Verification
set -euo pipefail

cd /home/stolareks/superpowers

echo "========================================"
echo " Task 9: Final Verification"
echo "========================================"
echo ""

FAILED=0

# Step 1: Content verification
echo "=== Check 1: CC Tool Names ==="
if grep -rn "TodoWrite\|Task tool\|Skill tool\|EnterWorktree" skills/ 2>/dev/null; then
    echo "  [FAIL]"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No CC tool names in skills"
fi
echo ""

echo "=== Check 2: Platform References ==="
if grep -rn "Claude Code\|Codex CLI\|Codex App\|Copilot CLI\|OpenCode\|Factory Droid\|Gemini CLI" skills/ 2>/dev/null; then
    echo "  [FAIL]"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No legacy platform references in skills"
fi
echo ""

echo "=== Check 3: Tool Mapping References ==="
if grep -rn "antigravity-tools\|copilot-tools\|codex-tools\|gemini-tools" skills/ 2>/dev/null; then
    echo "  [FAIL]"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No tool mapping references in skills"
fi
echo ""

echo "=== Check 4: Deleted Skill References ==="
if grep -rn "executing-plans" skills/ 2>/dev/null; then
    echo "  [FAIL]"
    FAILED=$((FAILED + 1))
else
    echo "  [PASS] No references to deleted skills"
fi
echo ""

echo "=== Check 5: Deleted Directories ==="
ALL_DELETED=true
for dir in .claude-plugin .codex-plugin .cursor-plugin .opencode hooks skills/executing-plans; do
    if [ -d "$dir" ]; then
        echo "  [FAIL] $dir still exists"
        ALL_DELETED=false
        FAILED=$((FAILED + 1))
    fi
done
if [ "$ALL_DELETED" = true ]; then
    echo "  [PASS] All legacy directories deleted"
fi
echo ""

echo "=== Check 6: Version 6.0.0 ==="
if grep -q '"version": "6.0.0"' plugin.json 2>/dev/null && grep -q '"version": "6.0.0"' gemini-extension.json 2>/dev/null; then
    echo "  [PASS] Version is 6.0.0"
else
    echo "  [FAIL] Version not 6.0.0"
    FAILED=$((FAILED + 1))
fi
echo ""

# Step 2: Run purity test
echo "=== Check 7: Purity Test ==="
if bash tests/antigravity/test-skill-tool-purity.sh > /dev/null 2>&1; then
    echo "  [PASS] Purity test passed"
else
    echo "  [FAIL] Purity test failed"
    FAILED=$((FAILED + 1))
fi
echo ""

# Step 3: File counts
echo "=== Check 8: File Counts ==="
SKILLS=$(ls -d skills/*/SKILL.md 2>/dev/null | wc -l)
echo "  Skills: $SKILLS (expected ~13)"
TESTDIRS=$(ls -d tests/*/ 2>/dev/null | wc -l)
echo "  Test directories: $TESTDIRS (expected 1)"
MANIFESTS=$(ls plugin.json gemini-extension.json 2>/dev/null | wc -l)
echo "  Platform manifests: $MANIFESTS (expected 2)"
echo ""

# Step 4: Git log
echo "=== Recent Commits ==="
git log --oneline -10
echo ""

# Summary
echo "========================================"
echo " Final Summary"
echo "========================================"
if [ $FAILED -eq 0 ]; then
    echo "  [ALL PASS] Refactor verified successfully"
    echo ""
    echo "  Stats:"
    TOTAL_DELETED=$(git log --oneline --diff-filter=D --summary | grep "delete mode" | wc -l)
    echo "    Platform manifests: 9 → 2"
    echo "    Skills: 14 → $SKILLS"
    echo "    Test directories: 8 → $TESTDIRS"
    echo "    Version: 5.1.0 → 6.0.0"
    exit 0
else
    echo "  [FAILED] $FAILED checks failed"
    exit 1
fi
