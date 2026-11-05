#!/usr/bin/env bash
# Suite runner for the superpowers-antigravity test suite.
#
# Usage: bash tests/run-tests.sh [--live] [--live-extra]
#   (no flags)    gate tier + unit tier
#   --live        also the live tier (needs a signed-in `agy`)
#   --live-extra  also the live-extra tier
#
# Tiers (every tests/**/test-*.sh belongs to exactly one tier, or is a library file):
#   gate        static, deterministic, no agy; every gate test must PASS (a SKIP blocks)
#   unit        small script tests; a SKIP is reported as INCOMPLETE
#   live        need a signed-in agy; a SKIP is reported as INCOMPLETE
#   live-extra  optional extra live checks; a SKIP is reported as INCOMPLETE
#   lib         helpers sourced by tests; never run on their own
#
# Each test exits 0 (PASS), 77 (SKIP) or anything else (FAIL). A SKIP is never a pass.
# Exit: 0 RESULT: PASS | 1 RESULT: FAIL | 2 INCOMPLETE (a requested test was skipped).
#
# Run it from Git Bash on Windows. From PowerShell, call Git's own bash.exe
# (& "$env:ProgramFiles\Git\bin\bash.exe" tests/run-tests.sh): a bare `bash` there is often WSL.
set -uo pipefail

unset CDPATH
ORIG_PWD="$PWD"
cd "$(dirname "$0")/.." || exit 1
ROOT="$(pwd)"

# Repo-relative paths, one array per line starting at column 0 (the runner's mutation
# self-checks rewrite these lines with sed). Later tasks append to these arrays in the
# same form.
GATE_TESTS=(tests/antigravity/test-skill-tool-purity.sh tests/antigravity/test-plugin-layout.sh tests/antigravity/test-agent-frontmatter.sh tests/antigravity/test-purity-hook.sh tests/antigravity/test-rule-sync.sh tests/antigravity/test-plugin-packaging.sh tests/diagnosing-superpowers/test-skill-structure.sh tests/antigravity/test-execution-skills.sh tests/skill-size/test-skill-size.sh tests/skill-layout/test-no-dev-files-in-skills.sh tests/antigravity/test-release-notes-bullets.sh)
UNIT_TESTS=(tests/writing-skills/test-render-graphs.sh tests/systematic-debugging/test-find-polluter.sh)
LIVE_TESTS=(tests/antigravity/test-plugin-discovery.sh tests/antigravity/test-tool-roster.sh tests/antigravity/test-bundled-dispatch.sh tests/antigravity/test-subagent-dispatch.sh tests/antigravity/test-inline-execution.sh tests/antigravity/test-spec-gate-stream.sh tests/antigravity/test-worktree-workspace.sh tests/antigravity/test-skill-triggering/run-all.sh)
LIVE_EXTRA_TESTS=(tests/antigravity/test-hooks-introspection.sh)
LIB_FILES=(tests/antigravity/test-helpers.sh tests/antigravity/lib/*)

usage() {
  echo "Usage: bash tests/run-tests.sh [--live] [--live-extra]" >&2
  echo "       bash tests/run-tests.sh --transcript <product>:<uuid>|<product>:token:<text> --scenario trigger:<skill>|sdd|inline|worktree [--project <dir>] [--install-root <dir>]" >&2
  echo "  default       gate and unit tiers" >&2
  echo "  --live        also the live tier (needs a signed-in agy)" >&2
  echo "  --live-extra  also the live-extra tier" >&2
  echo "  --transcript  check a session you ran yourself; runs no tiers (exit 0 PASS, 1 FAIL, 2 SKIP)" >&2
}

RUN_LIVE=0
RUN_LIVE_EXTRA=0
TRANSCRIPT="" SCENARIO="" PROJECT="" INSTALL_ROOT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --live) RUN_LIVE=1 ;;
    --live-extra) RUN_LIVE_EXTRA=1 ;;
    --transcript|--scenario|--project|--install-root)
      if [ "$#" -lt 2 ]; then echo "run-tests.sh: $1 needs a value" >&2; usage; exit 1; fi
      case "$1" in
        --transcript) TRANSCRIPT="$2" ;;
        --scenario) SCENARIO="$2" ;;
        --project) PROJECT="$2" ;;
        --install-root) INSTALL_ROOT="$2" ;;
      esac
      shift ;;
    *) echo "run-tests.sh: unknown argument: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# Transcript mode: apply a live scenario's assertions to a session's transcript. No tiers run.
if [ -n "$TRANSCRIPT$SCENARIO" ]; then
  if [ -z "$TRANSCRIPT" ] || [ -z "$SCENARIO" ]; then
    echo "run-tests.sh: --transcript and --scenario go together" >&2; usage; exit 1
  fi
  JT="$ROOT/tests/antigravity/lib/json-tool.mjs"
  # shellcheck source=antigravity/test-helpers.sh
  . "$ROOT/tests/antigravity/test-helpers.sh"
  for var in PROJECT INSTALL_ROOT; do
    dir="${!var}"
    [ -n "$dir" ] || continue
    if [ ! -d "$dir" ] && [ ! -d "$ORIG_PWD/$dir" ]; then echo "[FAIL] no such directory: $dir"; exit 1; fi
    if [ -d "$dir" ]; then resolved="$(cd "$dir" && node -p "process.cwd()")"; else resolved="$(cd "$ORIG_PWD/$dir" && node -p "process.cwd()")"; fi
    printf -v "$var" '%s' "$resolved"
  done
  product="${TRANSCRIPT%%:*}"
  spec="${TRANSCRIPT#*:}"
  case "$spec" in
    token:*) id_args=(--token "${spec#token:}") ;;
    *) id_args=(--id "$spec") ;;
  esac
  verdict() { echo "[$1] $SCENARIO on $TRANSCRIPT: $2"; case "$1" in PASS) exit 0 ;; SKIP) exit 2 ;; *) exit 1 ;; esac; }
  # tx <view> [--field k]: the view's lines in TX_OUT; a json-tool failure ends the run
  tx() {
    local view="$1" err rc
    shift
    local -a extra=("$@")
    [ -z "$INSTALL_ROOT" ] || extra+=(--root "$INSTALL_ROOT")
    err="$(mktemp)"
    TX_OUT="$(node "$JT" transcript --product "$product" "${id_args[@]}" --view "$view" ${extra[@]+"${extra[@]}"} 2>"$err")"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      msg="$(tr -d '\r' < "$err" | head -n 1)"
      rm -f "$err"
      if [ "$rc" -eq 77 ]; then verdict SKIP "$msg"; fi
      verdict FAIL "$msg"
    fi
    rm -f "$err"
  }
  project_checks() {
    [ -n "$PROJECT" ] || return 0
    local n
    n="$(git -C "$PROJECT" rev-list --count HEAD 2>/dev/null || echo 0)"
    [ "$n" -ge 3 ] || verdict FAIL "$n commits in the project, expected at least 3"
    (cd "$PROJECT" && npm test >/dev/null 2>&1) || verdict FAIL "npm test fails in the project"
  }
  has_type() { # has_type <member...>: some TypeName in TX_OUT equals a member or ends in :<member>
    local t
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      type_in_set "$t" "$@" && return 0
    done <<< "$TX_OUT"
    return 1
  }
  case "$SCENARIO" in
    trigger:*)
      skill="${SCENARIO#trigger:}"
      tx skill-reads --field path
      if printf '%s\n' "$TX_OUT" | grep -q '/zz-'; then verdict FAIL "skill read from a /zz- path"; fi
      if [ -n "$INSTALL_ROOT" ]; then pat="^\./skills/$skill/SKILL\.md$"; else pat="/skills/$skill/SKILL\.md$"; fi
      printf '%s\n' "$TX_OUT" | grep -q "$pat" || verdict FAIL "no read of skills/$skill/SKILL.md${INSTALL_ROOT:+ under the install root}"
      verdict PASS "read skills/$skill/SKILL.md" ;;
    sdd)
      tx subagents --field TypeName
      missing=""
      has_type $IMPL_FAMILY || missing="$missing implementer"
      has_type spec-reviewer || missing="$missing spec-reviewer"
      has_type code-reviewer || missing="$missing code-reviewer"
      [ -z "$missing" ] || verdict FAIL "no dispatch of:$missing"
      project_checks
      verdict PASS "implementer, spec-reviewer and code-reviewer dispatched" ;;
    inline)
      tx skill-reads --field path
      printf '%s\n' "$TX_OUT" | grep -q '/skills/executing-plans/SKILL\.md$' || verdict FAIL "no read of skills/executing-plans/SKILL.md"
      tx subagents --field TypeName
      has_type $IMPL_FAMILY spec-reviewer code-reviewer re-reviewer && verdict FAIL "per-task dispatch found"
      project_checks
      verdict PASS "executing-plans read, no per-task dispatch" ;;
    worktree)
      [ -n "$PROJECT" ] || verdict FAIL "worktree needs --project <dir>"
      variant="${WORKSPACE_VARIANT:-A}"
      branch="$(git -C "$PROJECT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
      trees="$(git -C "$PROJECT" worktree list --porcelain 2>/dev/null | grep -c '^worktree ')"
      case "$variant" in
        A)
          { [ "$branch" != main ] && [ "$trees" -eq 1 ]; } || verdict FAIL "WORKSPACE_VARIANT=A: branch $branch, $trees worktree(s); wants a branch other than main and one worktree"
          verdict PASS "WORKSPACE_VARIANT=A: on branch $branch, one worktree" ;;
        B)
          tx subagents --field Workspace
          if [ "$trees" -gt 1 ] || printf '%s\n' "$TX_OUT" | grep -qx branch; then verdict PASS "WORKSPACE_VARIANT=B: isolated workspace found"; fi
          verdict FAIL "WORKSPACE_VARIANT=B: one worktree and no Workspace of branch" ;;
        *) verdict FAIL "WORKSPACE_VARIANT must be A or B, not '$variant'" ;;
      esac ;;
    *) echo "run-tests.sh: unknown scenario: $SCENARIO" >&2; usage; exit 1 ;;
  esac
fi

# The result table: three parallel arrays, one row per precondition or test.
ROW_RESULT=()
ROW_TIER=()
ROW_TEST=()
add_row() {
  ROW_RESULT+=("$1")
  ROW_TIER+=("$2")
  ROW_TEST+=("$3")
}

print_table() {
  local i
  echo
  printf '%-6s  %-12s  %s\n' RESULT TIER TEST
  for i in "${!ROW_RESULT[@]}"; do
    printf '%-6s  %-12s  %s\n' "${ROW_RESULT[$i]}" "${ROW_TIER[$i]}" "${ROW_TEST[$i]}"
  done
  echo
}

# Every listed path, one per line. ${A[@]+"${A[@]}"} keeps empty arrays safe under
# `set -u` on bash older than 4.4.
list_all() {
  local p
  for p in \
    ${GATE_TESTS[@]+"${GATE_TESTS[@]}"} \
    ${UNIT_TESTS[@]+"${UNIT_TESTS[@]}"} \
    ${LIVE_TESTS[@]+"${LIVE_TESTS[@]}"} \
    ${LIVE_EXTRA_TESTS[@]+"${LIVE_EXTRA_TESTS[@]}"} \
    ${LIB_FILES[@]+"${LIB_FILES[@]}"}; do
    printf '%s\n' "$p"
  done
}

echo "========================================"
echo " Superpowers-Antigravity test suite"
echo "========================================"
echo
echo "Preconditions"

PRE_FAILED=0

# Precondition: node
if node_version="$(node --version 2>/dev/null)" && [ -n "$node_version" ]; then
  echo "  [PASS] node ($node_version)"
  add_row PASS precondition node
else
  echo "  [FAIL] node: 'node --version' does not work; install node >= 18 and put it on PATH"
  add_row FAIL precondition node
  PRE_FAILED=1
fi

# Precondition: not-wsl. WSL against a Windows checkout cannot run the win32 hook fixtures.
under_wsl=0
if grep -qi microsoft /proc/version 2>/dev/null || uname -r 2>/dev/null | grep -qi microsoft; then
  under_wsl=1
fi
case "$ROOT" in
  /mnt/[a-zA-Z]/*) on_windows_checkout=1 ;;
  *) on_windows_checkout=0 ;;
esac
if [ "$under_wsl" -eq 1 ] && [ "$on_windows_checkout" -eq 1 ]; then
  echo "  [FAIL] not-wsl: gate run under WSL against a Windows checkout: win32 hook fixtures would not run; run from Git Bash"
  add_row FAIL precondition not-wsl
  PRE_FAILED=1
else
  echo "  [PASS] not-wsl"
  add_row PASS precondition not-wsl
fi

# Precondition: tier-membership. Every test-*.sh is in exactly one tier array, and every
# listed file exists.
membership_problems=0
membership_problem() {
  echo "  [FAIL] tier-membership: $1"
  membership_problems=$((membership_problems + 1))
}
listing="$(list_all)"
while IFS= read -r found; do
  [ -n "$found" ] || continue
  if ! printf '%s\n' "$listing" | grep -qxF -- "$found"; then
    membership_problem "unassigned test $found"
  fi
done < <(find tests -type f -name 'test-*.sh' | LC_ALL=C sort)
while IFS= read -r twice; do
  [ -n "$twice" ] || continue
  membership_problem "test in more than one tier $twice"
done < <(printf '%s\n' "$listing" | grep -v '^$' | LC_ALL=C sort | uniq -d)
while IFS= read -r listed; do
  [ -n "$listed" ] || continue
  [ -f "$listed" ] || membership_problem "listed test missing $listed"
done < <(printf '%s\n' "$listing")
if [ "$membership_problems" -eq 0 ]; then
  echo "  [PASS] tier-membership"
  add_row PASS precondition tier-membership
else
  add_row FAIL precondition tier-membership
  PRE_FAILED=1
fi

# A failed precondition is blocking: the tests below would only report misleading results.
if [ "$PRE_FAILED" -ne 0 ]; then
  echo
  echo "A precondition failed; no tests were run."
  print_table
  echo "RESULT: FAIL"
  exit 1
fi

# Run one test as `bash <path>`, streaming its output, and record its row.
run_test() {
  local tier="$1" path="$2" code result
  echo
  echo ">>> [$tier] $path"
  bash "$path" </dev/null
  code=$?
  case "$code" in
    0) result=PASS ;;
    77) result=SKIP ;;
    *) result=FAIL ;;
  esac
  echo "<<< [$tier] $path: $result (exit $code)"
  add_row "$result" "$tier" "$path"
}

run_tier() {
  local tier="$1" path
  shift
  for path in "$@"; do
    run_test "$tier" "$path"
  done
}

if [ "$RUN_LIVE" -eq 1 ] || [ "$RUN_LIVE_EXTRA" -eq 1 ]; then
  if command -v agy >/dev/null 2>&1; then agy_version="$(agy --version 2>/dev/null | head -n 1)"; else agy_version=absent; fi
  add_row INFO live "agy ${agy_version:-absent}"
fi

run_tier gate ${GATE_TESTS[@]+"${GATE_TESTS[@]}"}
run_tier unit ${UNIT_TESTS[@]+"${UNIT_TESTS[@]}"}
if [ "$RUN_LIVE" -eq 1 ]; then
  run_tier live ${LIVE_TESTS[@]+"${LIVE_TESTS[@]}"}
fi
if [ "$RUN_LIVE_EXTRA" -eq 1 ]; then
  run_tier live-extra ${LIVE_EXTRA_TESTS[@]+"${LIVE_EXTRA_TESTS[@]}"}
fi

print_table

# FAIL on any FAIL, and on any gate test that is not PASS (a gate SKIP, 77, blocks).
# Otherwise INCOMPLETE on any SKIP in the unit, live or live-extra tiers.
failed=0
skipped=()
for i in "${!ROW_RESULT[@]}"; do
  result="${ROW_RESULT[$i]}"
  tier="${ROW_TIER[$i]}"
  if [ "$result" = FAIL ]; then
    failed=1
  elif [ "$result" = SKIP ]; then
    if [ "$tier" = gate ]; then
      failed=1
    else
      skipped+=("${ROW_TEST[$i]}")
    fi
  elif [ "$tier" = precondition ] && [ "$result" != PASS ]; then
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "RESULT: FAIL"
  exit 1
fi
if [ "${#skipped[@]}" -gt 0 ]; then
  echo "INCOMPLETE — skipped tests are not passes"
  printf '%s\n' "${skipped[@]}"
  exit 2
fi
echo "RESULT: PASS"
exit 0
