#!/usr/bin/env bash
# Fails when a SKILL.md reaches the 24 KB body limit `agy plugin validate` warns on (CLI 1.4.1); ported from upstream.
# Usage: tests/skill-size/test-skill-size.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
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
