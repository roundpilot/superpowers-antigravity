#!/usr/bin/env bash
# Fails when any skill's SKILL.md reaches Antigravity's 24 KB body limit.
#
# `agy plugin validate` (CLI 1.4.1) warns when a SKILL.md body is over the 24 KB
# limit. Content a skill only needs sometimes belongs in its references/
# directory, which the agent reads with view_file at the step that needs it.
# Ported from upstream's tests/skill-size/test-skill-size.sh with this limit.
#
# Measures bytes, which is stricter than characters for files with non-ASCII
# text. Usage: tests/skill-size/test-skill-size.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
LIMIT=24000

failed=0
for skill in "$REPO_ROOT"/skills/*/SKILL.md; do
  size=$(wc -c <"$skill" | tr -d ' ')
  if ((size >= LIMIT)); then
    echo "FAIL: ${skill#"$REPO_ROOT"/} is $size bytes (limit: under $LIMIT)" >&2
    failed=1
  fi
done

if ((failed)); then
  echo "Move content the skill only needs sometimes into its references/ directory." >&2
  exit 1
fi
echo "PASS: every SKILL.md is under $LIMIT bytes"
