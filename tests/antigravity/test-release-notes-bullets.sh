#!/usr/bin/env bash
# Test: the newest release-notes entry has plain bullets of about 12 words (owner rule, spec B.4).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1
FAIL=0
MAX=15
N=0
# Top entry only: from the first "## v" heading to the next.
while IFS= read -r line; do
    N=$((N + 1))
    n=$(printf '%s' "${line:2}" | LC_ALL=C wc -w | tr -d ' ')
    if [ "$n" -gt "$MAX" ]; then echo "FAIL: bullet of $n words (max $MAX): ${line:0:70}"; FAIL=1; fi
    case "$line" in *'**'*) echo "FAIL: bullet not plain (bold): ${line:0:70}"; FAIL=1 ;; esac
done < <(awk '/^## v/{c++; next} c==1 && /^[*-] /' RELEASE-NOTES.md)
[ "$N" -gt 0 ] || { echo "FAIL: no bullets in the newest entry"; FAIL=1; }
[ "$FAIL" = 0 ] && echo "PASS: $N bullets" && exit 0
exit 1
