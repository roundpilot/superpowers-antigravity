#!/usr/bin/env bash
# Static checks on the execution skills (SDD, worktrees, parallel agents); checks are auto-discovered as check_E<n>.
set -uo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROBLEMS=()
FAILS=0

problem() { PROBLEMS+=("$1"); }
must_have() { grep -qF -- "$2" "$ROOT/$1" 2>/dev/null || problem "$1: missing '$2'"; }
must_lack() {
  local line
  while IFS= read -r line; do problem "$line"; done < <(grep -rnHF -- "$2" "$ROOT/$1" 2>/dev/null)
}
verdict() {
  local p
  if [ "${#PROBLEMS[@]}" -eq 0 ]; then
    echo "[PASS] $1: $2"
  else
    echo "[FAIL] $1: $2"
    for p in "${PROBLEMS[@]}"; do echo "  $p"; done
    FAILS=$((FAILS + 1))
  fi
  PROBLEMS=()
}

check_E8() {
  must_lack skills/subagent-driven-development 'Workspace: "branch"'
  verdict E8 'no Workspace: "branch" under skills/subagent-driven-development/'
}

check_E13() {
  local p
  for p in '&>' '2>/dev/null' '$(' 'pwd -P' 'if ['; do must_lack skills/using-git-worktrees/SKILL.md "$p"; done
  verdict E13 'using-git-worktrees is shell-neutral'
}
check_E14() {   # the share MODE, never the substring: 'shared state' lines do not count
  local f hits
  for f in skills/using-git-worktrees/SKILL.md skills/dispatching-parallel-agents/SKILL.md; do
    hits=$(grep -nE '`share`|"share"' "$ROOT/$f" | grep -vF 'not recommended' || true)
    [ -z "$hits" ] || problem "$f: share line without 'not recommended': $hits"
    must_lack "$f" 'No write access needed'
  done
  verdict E14 'the share mode is not recommended'
}

CHECKS=$(declare -F | sed 's/^declare -f //' | grep -E '^check_E[0-9]+$' | sort -t E -k2,2n)
for c in $CHECKS; do "$c"; done

if [ "$FAILS" -gt 0 ]; then
  echo "[FAIL] $FAILS check(s) failed"
  exit 1
fi
echo "[PASS] execution skills"
