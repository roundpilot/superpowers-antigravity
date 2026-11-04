#!/usr/bin/env bash
# Test: Hooks Introspection (live-extra, CLI only)
# agy's /hooks listing shows the contributor hook entry only in the repository that enables it.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================"
echo " Test: Hooks Introspection (Antigravity CLI)"
echo "========================================"
echo "[INFO] CLI only: this test does not cover 2.0 or IDE hook loading"

if ! command -v agy &>/dev/null; then
    echo "[SKIP] 'agy' command not found"
    exit 77
fi

# Folder-trust ruling S7.8-trust=no: both directories are scratch directories.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
T1="$WORK/t1"
mkdir -p "$T1/.agents" "$T1/hooks" "$T1/tests/antigravity"
git init -q "$T1"
cat > "$T1/.agents/hooks.json" <<'JSON'
{
  "skill-purity-gate": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "write_to_file|replace_file_content|multi_replace_file_content",
        "hooks": [
          { "type": "command", "command": "node ./hooks/purity-check.mjs", "timeout": 10 }
        ]
      }
    ]
  }
}
JSON
cp "$REPO_ROOT/hooks/purity-check.mjs" "$T1/hooks/"
cp "$REPO_ROOT/tests/antigravity/purity-patterns.txt" "$T1/tests/antigravity/"

(cd "$T1" && agy_run "$WORK/with.json" "$WORK/with.err" 120 -p "/hooks" --output-format json)
if ! grep -qF 'skill-purity-gate' "$WORK/with.json"; then
    echo "[SKIP] skill-purity-gate not listed (folder trust, CLI 1.1.1); S7.3 checks the entry statically"
    exit 77
fi

EMPTY="$WORK/empty"
mkdir -p "$EMPTY"
(cd "$EMPTY" && agy_run "$WORK/without.json" "$WORK/without.err" 120 -p "/hooks" --output-format json)
if grep -qF 'skill-purity-gate' "$WORK/without.json"; then
    echo "[FAIL] listed outside the enabling repository"
    exit 1
fi
echo "[PASS] skill-purity-gate listed in the enabling repository only"
exit 0
