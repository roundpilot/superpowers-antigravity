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

check_E1() {
  local d; d="$(sed -n 's/^description: //p' "$ROOT/skills/executing-plans/SKILL.md" | head -n 1)"
  [ "$d" = 'Use when executing an implementation plan in the current session as the implementer yourself — your human partner chose inline execution, or no subagent tool is available' ] || problem "description is: $d"
  verdict E1 "executing-plans description is upstream v6.4.1's"
}
check_E2() {
  local d s
  for d in executing-plans subagent-driven-development; do
    [ ! -d "$ROOT/skills/$d/scripts" ] || problem "skills/$d/scripts/ exists"
    for s in sdd-workspace task-brief task-start task-done review-package; do must_lack "skills/$d/SKILL.md" "$s"; done
  done
  verdict E2 'neither executor has a scripts/ directory or names an upstream script'
}
check_E3() {
  local t
  for t in 'mkdir -p' 'printf' 'rm -rf' '2>&1' ' && ' '$('; do must_lack skills/executing-plans/SKILL.md "$t"; done
  verdict E3 'no executor contains a banned shell token'
}
check_E6() {
  local ep=skills/executing-plans/SKILL.md s
  for s in 'Never fabricate a dispatch' 'Read a brief, not the whole plan.' 'git rev-list --left-right --count' \
    'A failing run records nothing; the task is not complete.' \
    '`Task <N>: complete (commits <base7>..<head7>, tests: <command> → <result>)`' \
    'Task <N>: partner instruction: <one-liner>' 'Plan map: Task 1 L<first>-<last>'; do must_have "$ep" "$s"; done
  verdict E6 'executing-plans carries its ledger and task-loop strings'
}
check_E9() {
  local t
  for t in list_dir grep_search find_by_name define_subagent; do must_lack skills/executing-plans/SKILL.md "$t"; done
  verdict E9 'no executor names a retired or excluded tool'
}
check_E10() {
  must_lack skills 'using-superpowers/references'
  verdict E10 'no using-superpowers/references under skills/'
}

CHECKS=$(declare -F | sed 's/^declare -f //' | grep -E '^check_E[0-9]+$' | sort -t E -k2,2n)
for c in $CHECKS; do "$c"; done

if [ "$FAILS" -gt 0 ]; then
  echo "[FAIL] $FAILS check(s) failed"
  exit 1
fi
echo "[PASS] execution skills"
