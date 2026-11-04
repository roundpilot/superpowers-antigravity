#!/usr/bin/env bash
# Static checks on the execution skills (SDD, worktrees, parallel agents); checks are auto-discovered as check_E<n>.
set -uo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROBLEMS=()
FAILS=0

problem() { PROBLEMS+=("$1"); }
must_have() { grep -qF -- "$2" "$ROOT/$1" 2>/dev/null || problem "$1: missing '$2'"; }
must_lack() {
  test -f "$ROOT/$1" || test -d "$ROOT/$1" || { problem "$1: missing"; return; }
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

check_E11() {
  local f=skills/subagent-driven-development/spec-reviewer-prompt.md s
  for s in '## Git Range to Review' '{BASE_SHA}' '{HEAD_SHA}'; do must_have "$f" "$s"; done
  verdict E11 'the spec-reviewer prompt carries the git range'
}
check_E12() {
  local f=skills/subagent-driven-development/SKILL.md edges
  edges=$(grep -F '"Answer questions, provide context" ->' "$ROOT/$f" || true)
  [ -n "$edges" ] || problem "no edge leaves \"Answer questions, provide context\""
  if printf '%s\n' "$edges" | grep -qF invoke_subagent; then problem "answer edge dispatches: $edges"; fi
  verdict E12 'no answer edge leads to invoke_subagent'
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
  for t in 'mkdir -p' 'printf' 'rm -rf' '2>&1' ' && ' '$('; do must_lack skills/subagent-driven-development/SKILL.md "$t"; done
  verdict E3 'no executor contains a banned shell token'
}
MKDIR_SENTENCE="If a directory is missing, create each level with the shell's own command and retry."
e4_block() { awk '/^- Each plan owns a workspace:/{p=1; print; next} p && (/^- / || /^$/){exit} p{print}' "$ROOT/$1"; }
check_E4() {
  local ep=skills/executing-plans/SKILL.md sdd=skills/subagent-driven-development/SKILL.md a b
  a="$(e4_block "$ep")"; b="$(e4_block "$sdd")"
  [ "$(printf '%s\n' "$a" | grep -cE '^  [1-4]\. ')" = 4 ] || problem "$ep: workspace block does not have four sub-items"
  [ "$(printf '%s\n' "$a" | grep -cF -- "$MKDIR_SENTENCE")" = 1 ] || problem "$ep: MKDIR_SENTENCE not exactly once in the workspace block"
  [ "$a" = "$b" ] || problem "$sdd: workspace block differs from $ep's"
  [ "$(grep -cF -- "$MKDIR_SENTENCE" "$ROOT/skills/diagnosing-superpowers/references/session-discovery.md")" = 1 ] || problem "session-discovery.md: MKDIR_SENTENCE not exactly once"
  verdict E4 'plan-workspace block identical in both executors, MKDIR_SENTENCE once in it and in session-discovery.md'
}
check_E5() {
  local ep=skills/executing-plans/SKILL.md sdd=skills/subagent-driven-development/SKILL.md o
  for o in 'Approvals can pause an unattended run.' 'Your human partner may steer while the plan runs'; do
    [ "$(grep -cF -- "$o" "$ROOT/$ep")" = 1 ] || problem "$ep: not exactly one '$o' line"
    [ "$(grep -F -- "$o" "$ROOT/$ep")" = "$(grep -F -- "$o" "$ROOT/$sdd")" ] || problem "$sdd: '$o' line differs from $ep's"
  done
  grep -qE '^Approvals can pause an unattended run\..* Never change their permission settings yourself\. This is a notice, not a stop: start Task 1\.$' "$ROOT/$ep" || problem "$ep: block C does not end with the pinned sentence"
  verdict E5 'block C and the steering line: one line each, identical in both executors'
}
check_E6() {
  local ep=skills/executing-plans/SKILL.md s
  for s in 'Never fabricate a dispatch' 'Read a brief, not the whole plan.' 'git rev-list --left-right --count' \
    'A failing run records nothing; the task is not complete.' \
    '`Task <N>: complete (commits <base7>..<head7>, tests: <command> → <result>)`' \
    'Task <N>: partner instruction: <one-liner>' 'Plan map: Task 1 L<first>-<last>'; do must_have "$ep" "$s"; done
  for s in 'superpowers:final-reviewer' 'TypeName: "final-reviewer", Role: "Final whole-branch reviewer", Workspace: "inherit"' \
    'Final review: self-review (no subagent tool)' 'Final review: self-review (<what failed>)' \
    'Final review: self subagent (bundled agent unavailable)' 'RequestFeedback: false' \
    'and the walkthrough artifact that copies it' \
    'It asks for nothing: superpowers:finishing-a-development-branch presents the choices.'; do must_have "$ep" "$s"; done
  verdict E6 'executing-plans carries its ledger and task-loop strings'
}
check_E7() {
  local ep=skills/executing-plans/SKILL.md
  [ "$(tr -s '[:space:]' ' ' < "$ROOT/$ep" | grep -cF 'most capable')" = 0 ] || problem "$ep says 'most capable' (joined lines)"
  local sdd=skills/subagent-driven-development/SKILL.md s
  for s in '**Narration:**' 'Partner chose inline, or no subagent tool?' '**vs. Executing Plans (inline):**' \
    '- Both run in this session, share the same plan workspace and ledger, and never pause between tasks' \
    'whose last line is a fix round is mid-loop: resume the loop at the next' \
    'Task <N>: dispatched implementer <conversation ID> (base <base7>[, round <R>])' \
    'Task <N>: killed implementer <conversation ID> (round <R> takeover)' \
    'your human partner stopped it' 'Setup: self subagent for <name> (bundled agent unavailable)' \
    'git rev-list --left-right --count <BASE>...<HEAD>'; do must_have "$sdd" "$s"; done
  for s in 'commit not made' \
    'Task <N>: fix round <R>/5 (<stage>: <X> addressed, <Y> open — <one-liners>; commits <a7>..<b7>)' \
    'Task <N>: complete (commits <base7>..<head7>, review clean)' \
    'Task <N>: complete (commits <base7>..<head7>, <K> parked)' 'Never move to the next task while'; do
    must_have "$sdd" "$s"; done
  must_have "$sdd" "Task <N>: Ruling: controller committed <files> — implementer's commit could not run — cost if wrong: one amend"
  verdict E7 "executors keep their restored lines and ledger strings and never say 'most capable'"
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
