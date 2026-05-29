#!/usr/bin/env bash
# Test: Workspace Isolation Guidance (Antigravity 2.0)
# Verifies that Antigravity correctly handles workspace isolation
# when triggered with a prompt that invokes the using-git-worktrees skill.
#
# In Antigravity, workspace isolation uses the invoke_subagent Workspace parameter
# ("branch" or "share") instead of git worktree commands.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "========================================"
echo " Test: Workspace Isolation (Antigravity)"
echo "========================================"
echo ""

# Check agy is available
if ! command -v agy &>/dev/null; then
    echo "[SKIP] 'agy' command not found. Install Antigravity CLI to run this test."
    exit 0
fi

# Create a test project with git initialized
TEST_PROJECT=$(create_test_project)
echo "Test project: $TEST_PROJECT"

trap "cleanup_test_project $TEST_PROJECT" EXIT

cd "$TEST_PROJECT"
git init --quiet
git config user.email "test@test.com"
git config user.name "Test User"
echo '{"name": "test-project"}' > package.json
git add .
git commit -m "Initial commit" --quiet

echo ""
echo "=== Running Antigravity with workspace isolation prompt ==="
echo ""

PROMPT="I want to start a new feature branch for adding user authentication. Set up an isolated workspace for this work.

Do NOT implement the feature — just set up the isolated workspace and report what approach you used.
Tell me exactly what tool or method you used for workspace isolation."

OUTPUT=$(run_antigravity "$PROMPT" 120) || true
OUTPUT_FILE="$TEST_PROJECT/agy-output.txt"
echo "$OUTPUT" > "$OUTPUT_FILE"

echo ""
echo "=== Verification ==="
echo ""

FAILED=0
EVIDENCE_FOUND=false

# Check 1: Workspace: branch or share parameter mentioned
echo "Check 1: Workspace isolation parameter..."
if echo "$OUTPUT" | grep -qiE 'workspace.*branch|workspace.*share|"branch"|"share"|isolated.*workspace'; then
    echo "  [PASS] Workspace isolation parameter referenced"
    EVIDENCE_FOUND=true
else
    echo "  [INFO] No explicit workspace parameter mention"
fi

# Check 2: invoke_subagent with workspace isolation
echo "Check 2: Subagent workspace dispatch..."
if echo "$OUTPUT" | grep -qiE 'invoke_subagent.*workspace|subagent.*branch|subagent.*isolat'; then
    echo "  [PASS] Subagent workspace dispatch referenced"
    EVIDENCE_FOUND=true
else
    echo "  [INFO] No subagent workspace dispatch mention"
fi

# Check 3: Git branch / worktree concepts
echo "Check 3: Branch/worktree concepts..."
if echo "$OUTPUT" | grep -qiE 'worktree|feature.branch|git.*branch|isolated.*branch|branch.*isolat'; then
    echo "  [PASS] Branch/worktree concept referenced"
    EVIDENCE_FOUND=true
else
    echo "  [INFO] No branch/worktree concept mention"
fi

# Check 4: Check transcript if available
echo "Check 4: Transcript analysis..."
TRANSCRIPT=$(find_transcript 10 2>/dev/null) || true
if [ -n "$TRANSCRIPT" ]; then
    if transcript_has_tool "$TRANSCRIPT" "invoke_subagent"; then
        echo "  [PASS] invoke_subagent found in transcript"
        EVIDENCE_FOUND=true
    else
        echo "  [INFO] No invoke_subagent in transcript"
    fi

    # Check for Workspace parameter in transcript
    if grep -q '"Workspace"' "$TRANSCRIPT" 2>/dev/null; then
        echo "  [PASS] Workspace parameter found in transcript"
        EVIDENCE_FOUND=true
    else
        echo "  [INFO] No Workspace parameter in transcript"
    fi
else
    echo "  [INFO] No recent transcript found (this is OK for output-only checks)"
fi

echo ""

# Overall result
echo "========================================"
echo " Test Result"
echo "========================================"
echo ""

if [ "$EVIDENCE_FOUND" = "true" ]; then
    echo "[PASS] Workspace isolation test passed"
    echo "  Evidence of workspace isolation guidance was found."
    exit 0
else
    echo "[FAIL] Workspace isolation test failed"
    echo "  No evidence of workspace isolation guidance found."
    echo ""
    echo "  Expected one of:"
    echo "    - Workspace: 'branch' or 'share' parameter mention"
    echo "    - invoke_subagent with workspace isolation"
    echo "    - Git branch/worktree concepts"
    echo ""
    echo "  Output excerpt:"
    echo "$OUTPUT" | head -c 500 | sed 's/^/    /'
    exit 1
fi
