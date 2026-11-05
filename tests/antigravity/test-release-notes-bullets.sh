#!/usr/bin/env bash
# Test: release-notes bullets are short; the platform reference's "used by" rows hit a skill.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1
FAIL=0
MAX=30
# Top entry only: from the first "## v" heading to the next.
while IFS= read -r line; do
    n=$(printf '%s' "$line" | wc -w)
    if [ "$n" -gt "$MAX" ]; then echo "FAIL: bullet of $n words (max $MAX): ${line:0:70}"; FAIL=1; fi
done < <(awk '/^## v/{c++; next} c==1 && /^\* /' RELEASE-NOTES.md)
REF=docs/superpowers/specs/2026-09-25-antigravity-platform-reference.md
if grep -F '| CLI `/fork`' "$REF" | grep -q 'used by'; then
    git grep -q -i -F '/fork' -- skills || { echo "FAIL: /fork row says used, no skill names /fork"; FAIL=1; }
fi
[ "$FAIL" = 0 ] && echo "PASS" && exit 0
exit 1
