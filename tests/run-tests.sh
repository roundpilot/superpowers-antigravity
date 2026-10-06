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
cd "$(dirname "$0")/.." || exit 1
ROOT="$(pwd)"

# Repo-relative paths, one array per line starting at column 0 (the runner's mutation
# self-checks rewrite these lines with sed). Later tasks append to these arrays in the
# same form.
GATE_TESTS=(tests/antigravity/test-skill-tool-purity.sh tests/antigravity/test-plugin-layout.sh tests/antigravity/test-agent-frontmatter.sh tests/antigravity/test-purity-hook.sh tests/antigravity/test-rule-sync.sh tests/antigravity/test-plugin-packaging.sh tests/diagnosing-superpowers/test-skill-structure.sh)
UNIT_TESTS=(tests/writing-skills/test-render-graphs.sh tests/systematic-debugging/test-find-polluter.sh)
LIVE_TESTS=(tests/antigravity/test-plugin-discovery.sh tests/antigravity/test-subagent-dispatch.sh tests/antigravity/test-worktree-workspace.sh tests/antigravity/test-skill-triggering/run-all.sh)
LIVE_EXTRA_TESTS=()
LIB_FILES=(tests/antigravity/test-helpers.sh tests/antigravity/lib/*)

usage() {
  echo "Usage: bash tests/run-tests.sh [--live] [--live-extra]" >&2
  echo "  default       gate and unit tiers" >&2
  echo "  --live        also the live tier (needs a signed-in agy)" >&2
  echo "  --live-extra  also the live-extra tier" >&2
}

RUN_LIVE=0
RUN_LIVE_EXTRA=0
for arg in "$@"; do
  case "$arg" in
    --live) RUN_LIVE=1 ;;
    --live-extra) RUN_LIVE_EXTRA=1 ;;
    *) echo "run-tests.sh: unknown argument: $arg" >&2; usage; exit 1 ;;
  esac
done

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
