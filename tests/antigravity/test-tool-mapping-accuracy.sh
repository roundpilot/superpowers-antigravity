#!/usr/bin/env bash
# Test: Tool Mapping Accuracy (Static Validation)
# Validates that antigravity-tools.md references only valid Antigravity 2.0 tool names
# and does not miss any critical tools.
#
# This test does NOT require agy to be installed — it's purely a static check.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_FILE="$REPO_ROOT/skills/using-superpowers/references/antigravity-tools.md"

echo "========================================"
echo " Test: Tool Mapping Accuracy (Static)"
echo "========================================"
echo ""

if [ ! -f "$TOOLS_FILE" ]; then
    echo "[FAIL] antigravity-tools.md not found at: $TOOLS_FILE"
    exit 1
fi

echo "Analyzing: $TOOLS_FILE"
echo ""

# Known valid Antigravity 2.0 tool names
VALID_TOOLS=(
    "view_file"
    "write_to_file"
    "replace_file_content"
    "multi_replace_file_content"
    "run_command"
    "grep_search"
    "list_dir"
    "find_by_name"
    "search_web"
    "read_url_content"
    "invoke_subagent"
    "define_subagent"
    "send_message"
    "manage_subagents"
    "ask_question"
    "schedule"
    "generate_image"
    "manage_task"
    "list_permissions"
    "ask_permission"
)

# Critical tools that MUST be mentioned
CRITICAL_TOOLS=(
    "view_file"
    "write_to_file"
    "replace_file_content"
    "run_command"
    "grep_search"
    "find_by_name"
    "invoke_subagent"
    "search_web"
    "read_url_content"
)

# Extract tool names from the right column of the mapping table
# Look for backtick-wrapped tool names: `tool_name`
REFERENCED_TOOLS=()
while IFS= read -r tool; do
    REFERENCED_TOOLS+=("$tool")
done < <(grep -oE '`[a-z_]+`' "$TOOLS_FILE" | tr -d '`' | sort -u)

echo "=== Referenced Tools ==="
echo ""
for tool in "${REFERENCED_TOOLS[@]}"; do
    echo "  - $tool"
done
echo ""
echo "Total referenced: ${#REFERENCED_TOOLS[@]}"
echo ""

FAILED=0
WARNINGS=0

# Check 1: Flag unknown tools (referenced but not in valid list)
echo "=== Check 1: Unknown Tools ==="
echo ""

for tool in "${REFERENCED_TOOLS[@]}"; do
    found=false
    for valid in "${VALID_TOOLS[@]}"; do
        if [ "$tool" = "$valid" ]; then
            found=true
            break
        fi
    done
    if [ "$found" = "false" ]; then
        # Skip common non-tool identifiers that might be backtick-wrapped
        case "$tool" in
            task|self|research|hg|git)
                # Known non-tool identifiers, skip silently
                ;;
            *)
                echo "  [WARN] Unknown tool referenced: $tool"
                WARNINGS=$((WARNINGS + 1))
                ;;
        esac
    fi
done

if [ $WARNINGS -eq 0 ]; then
    echo "  [PASS] All referenced tools are valid"
fi
echo ""

# Check 2: Flag missing critical tools
echo "=== Check 2: Missing Critical Tools ==="
echo ""

FILE_CONTENT=$(cat "$TOOLS_FILE")

for critical in "${CRITICAL_TOOLS[@]}"; do
    if echo "$FILE_CONTENT" | grep -q "$critical"; then
        echo "  [PASS] Critical tool present: $critical"
    else
        echo "  [FAIL] Critical tool MISSING: $critical"
        FAILED=$((FAILED + 1))
    fi
done
echo ""

# Check 3: Verify key mappings are sensible
echo "=== Check 3: Key Mapping Verification ==="
echo ""

# Read -> view_file
if echo "$FILE_CONTENT" | grep -q "Read.*view_file\|view_file.*Read"; then
    echo "  [PASS] Read -> view_file mapping present"
else
    echo "  [WARN] Read -> view_file mapping not clearly stated"
    WARNINGS=$((WARNINGS + 1))
fi

# Write -> write_to_file
if echo "$FILE_CONTENT" | grep -q "Write.*write_to_file\|write_to_file.*Write"; then
    echo "  [PASS] Write -> write_to_file mapping present"
else
    echo "  [WARN] Write -> write_to_file mapping not clearly stated"
    WARNINGS=$((WARNINGS + 1))
fi

# Bash -> run_command
if echo "$FILE_CONTENT" | grep -q "Bash.*run_command\|run_command.*Bash"; then
    echo "  [PASS] Bash -> run_command mapping present"
else
    echo "  [WARN] Bash -> run_command mapping not clearly stated"
    WARNINGS=$((WARNINGS + 1))
fi

# Task -> invoke_subagent
if echo "$FILE_CONTENT" | grep -q "Task.*invoke_subagent\|invoke_subagent.*Task"; then
    echo "  [PASS] Task -> invoke_subagent mapping present"
else
    echo "  [WARN] Task -> invoke_subagent mapping not clearly stated"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""

# Summary
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo "[PASS] Tool mapping accuracy test passed (0 failures, 0 warnings)"
    else
        echo "[PASS] Tool mapping accuracy test passed with $WARNINGS warning(s)"
    fi
    exit 0
else
    echo "[FAIL] Tool mapping accuracy test failed ($FAILED critical tool(s) missing, $WARNINGS warning(s))"
    exit 1
fi
