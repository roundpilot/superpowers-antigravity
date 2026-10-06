#!/usr/bin/env bash
# Static lint for bundled agent definitions (agents/*.md): a default-deny frontmatter
# policy (spec S7.5). The platform hangs a subagent whose tools: list contains an
# unknown name, and a key the bundle did not adopt is a key nobody reviewed, so every
# check below fails the build on anything it does not recognise.
#
# Usage: bash tests/antigravity/test-agent-frontmatter.sh
#          lints <repo>/agents/*.md, then runs the negative fixtures
#        bash tests/antigravity/test-agent-frontmatter.sh --lint-only <ROOT>
#          lints only <ROOT>/agents/*.md (the form the negative fixtures use)
#   known-tools.txt is read from the directory of this script, never from ROOT.
# Exit: 0 PASS; 1 FAIL.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DATA="$SCRIPT_DIR/known-tools.txt"
FAILURES=0

# The policy. Later tasks extend these arrays in the same form. VARIANTS (the tier
# variants of the implementer, spec D5 fallback) is empty; check_5_implementer reads it.
POLICY_KEYS=(name description subagent mainAgent model tools)
WRITE_AGENTS=(implementer)
DISPATCH_AGENTS=()
VARIANTS=()
# The read-only class (S3.2): agents whose body must state that the review is read-only.
READONLY_AGENTS=(spec-reviewer code-reviewer re-reviewer)

# Negative fixtures, one per entry: label|file|kind|arg|expected reason.
# `file` is relative to agents/. Each runs the lint on a mutated copy and must fail
# with the expected reason on a [FAIL] line of its output.
NEGATIVE_FIXTURES=(
  "unknown key|implementer.md|key|mainagent: false|unknown key"
  "unvalidated gated key|implementer.md|key|hidden: true|gated: admitted only after LC3 (S3.1)"
  "hooks key|implementer.md|key|hooks: {}|not adopted"
  "reviewer write tool|code-reviewer.md|tool|write_to_file|outside WRITE_AGENTS"
  "implementer schedule|implementer.md|tool|schedule|dispatch or async tool"
  "invoke_subagent|spec-reviewer.md|tool|invoke_subagent|dispatch or async tool"
  "mainAgent true|re-reviewer.md|set|mainAgent: true|mainAgent must be false"
)

fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }
pass() { echo "  [PASS] $1"; }

usage_fail() {
  echo "[FAIL] usage: bash $0 [--lint-only <ROOT>]"
  exit 1
}

# ---------------------------------------------------------------------------
# Arguments. LINT_ROOT is the tree whose agents/ is linted.
# ---------------------------------------------------------------------------
LINT_ONLY=0
LINT_ROOT=""
case "${1:-}" in
  '') LINT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)" ;;
  --lint-only)
    [ "$#" -eq 2 ] || usage_fail
    LINT_ONLY=1
    if ! LINT_ROOT="$(cd "$2" 2>/dev/null && pwd)"; then
      echo "[FAIL] root not found: $2"
      exit 1
    fi
    ;;
  *) usage_fail ;;
esac
AGENTS_DIR="$LINT_ROOT/agents"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# in_list <needle> [item...]: success when needle equals one of the items.
in_list() {
  local needle="$1" item
  shift
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then return 0; fi
  done
  return 1
}

# tool_names <class>...: the names of the given classes in known-tools.txt
# (name<TAB>class<TAB>source), CR stripped, space-separated.
tool_names() {
  awk -F'\t' -v want="$*" '
    { sub(/\r$/, "") }
    /^#/ || $0 == "" { next }
    index(" " want " ", " " $2 " ") { printf "%s ", $1 }' "$TOOLS_DATA"
}

# fm_load <file>: parse the frontmatter once, in this shell (no forks: a fork costs
# tens of milliseconds under Git Bash, and every fixture child runs the whole lint).
# Sets, with CR stripped:
#   FM_STATE  ok | no-open (line 1 is not `---`) | no-close (no closing `---`)
#   FM_BODY   1 when a non-blank line follows the closing `---`
#   FM_LINES  the lines between the two `---`
#   FM_KEYS   the top-level keys (`^[A-Za-z][A-Za-z0-9_]*:`), in order
#   FM_TOOLS  the entries of the `tools:` block list, in order
FM_STATE="no-open"
FM_BODY=0
FM_LINES=()
FM_KEYS=()
FM_TOOLS=()
fm_load() {
  local f="$1" line n=0 closed=0 intools=0 key
  local key_re='^([A-Za-z][A-Za-z0-9_]*):'
  local item_re='^[[:space:]]*-[[:space:]]+([^[:space:]]+)'
  FM_STATE=ok
  FM_BODY=0
  FM_LINES=()
  FM_KEYS=()
  FM_TOOLS=()
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    n=$((n + 1))
    if [ "$n" -eq 1 ]; then
      if [ "$line" != "---" ]; then FM_STATE=no-open; return 0; fi
      continue
    fi
    if [ "$closed" -eq 0 ]; then
      if [ "$line" = "---" ]; then closed=1; continue; fi
      FM_LINES+=("$line")
      if [[ $line =~ $key_re ]]; then
        key="${BASH_REMATCH[1]}"
        FM_KEYS+=("$key")
        intools=0
        if [ "$key" = tools ]; then intools=1; fi
      elif [[ $line == [A-Za-z]* ]]; then
        intools=0
      elif [ "$intools" -eq 1 ] && [[ $line =~ $item_re ]]; then
        FM_TOOLS+=("${BASH_REMATCH[1]}")
      fi
    elif [[ $line == *[![:space:]]* ]]; then
      FM_BODY=1
      break
    fi
  done < "$f"
  if [ "$n" -eq 0 ]; then
    FM_STATE=no-open
  elif [ "$closed" -eq 0 ]; then
    FM_STATE=no-close
  fi
  return 0
}

# fm_get <key>: after fm_load, sets FM_VALUE to the trimmed value of the first
# `<key>:` frontmatter line ("" when there is none).
FM_VALUE=""
fm_get() {
  local k="$1" line v
  FM_VALUE=""
  for line in ${FM_LINES[@]+"${FM_LINES[@]}"}; do
    if [[ $line == "$k:"* ]]; then
      v="${line#"$k:"}"
      v="${v#"${v%%[![:space:]]*}"}"
      v="${v%"${v##*[![:space:]]}"}"
      FM_VALUE="$v"
      return 0
    fi
  done
  return 0
}

# frontmatter_keys <file> and tools_of <file>: the keys and the tools: entries, one per
# line, for callers that want a list (a command substitution costs a fork; the checks
# below read FM_KEYS and FM_TOOLS after fm_load instead).
frontmatter_keys() {
  fm_load "$1"
  if [ "${#FM_KEYS[@]}" -gt 0 ]; then printf '%s\n' "${FM_KEYS[@]}"; fi
}
tools_of() {
  fm_load "$1"
  if [ "${#FM_TOOLS[@]}" -gt 0 ]; then printf '%s\n' "${FM_TOOLS[@]}"; fi
}

# mutate <file> key|tool|set <arg>: rewrite <file> in place, in awk (not GNU-only sed).
#   key   insert <arg> as a line before the closing `---`
#   tool  insert `  - <arg>` after the `tools:` line
#   set   replace the frontmatter line whose key is <arg>'s key (the text before ':')
# Returns 1 on a missing file, an unknown kind or an awk failure.
mutate() {
  local file="$1" kind="$2" arg="$3" tmp
  [ -f "$file" ] || return 1
  tmp="$file.mutate-tmp"
  case "$kind" in
    key)
      ARG="$arg" awk '
        NR == 1 { print; next }
        !done && /^---[[:space:]]*$/ { print ENVIRON["ARG"]; done = 1 }
        { print }' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
      ;;
    tool)
      ARG="$arg" awk '
        { print }
        !done && /^tools:[[:space:]]*$/ { print "  - " ENVIRON["ARG"]; done = 1 }' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
      ;;
    set)
      ARG="$arg" awk '
        BEGIN { line = ENVIRON["ARG"]; k = line; sub(/:.*/, "", k) }
        NR == 1 { print; infm = 1; next }
        infm && /^---[[:space:]]*$/ { infm = 0 }
        infm && !done && index($0, k ":") == 1 { print line; done = 1; next }
        { print }' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
      ;;
    *) return 1 ;;
  esac
  mv "$tmp" "$file"
}

# ---------------------------------------------------------------------------
# Data: the tools an agent may list, from known-tools.txt (baseline and retired).
# ---------------------------------------------------------------------------
[ -f "$TOOLS_DATA" ] || { echo "[FAIL] data file missing: $TOOLS_DATA"; exit 1; }
KNOWN_TOOLS="$(tool_names baseline retired)"
[ -n "$KNOWN_TOOLS" ] || { echo "[FAIL] no baseline or retired tool names in $TOOLS_DATA"; exit 1; }

# ---------------------------------------------------------------------------
# Checks, each called as check_<n>_<name> <file>.
# ---------------------------------------------------------------------------

# Tools that only the agents in WRITE_AGENTS may list, and tools no bundled agent may list
# unless it is in DISPATCH_AGENTS (check 5).
WRITE_TOOLS=(write_to_file replace_file_content multi_replace_file_content)
DISPATCH_TOOLS=(invoke_subagent define_subagent send_message manage_subagents schedule)

# 1. Frontmatter delimited (line 1 is `---`, a closing `---` exists) and a non-blank body.
# Returns 1 on failure, so the caller skips the checks that need a frontmatter.
check_1_shape() {
  local f="$1" base="${1##*/}"
  fm_load "$f"
  case "$FM_STATE" in
    no-open) fail "$base: line 1 is not '---' (no frontmatter)"; return 1 ;;
    no-close) fail "$base: no closing '---' after the frontmatter"; return 1 ;;
  esac
  if [ "$FM_BODY" -ne 1 ]; then
    fail "$base: body is empty"
    return 1
  fi
  pass "$base: frontmatter delimited, body present"
  return 0
}

# 2. name = filename, description present, model in inherit|flash|pro.
check_2_identity() {
  local f="$1" base="${1##*/}" name desc model
  fm_load "$f"
  fm_get name; name="$FM_VALUE"
  fm_get description; desc="$FM_VALUE"
  fm_get model; model="$FM_VALUE"
  if [ -n "$name" ]; then pass "$base: name present"; else fail "$base: missing name"; fi
  if [ -n "$desc" ]; then pass "$base: description present"; else fail "$base: missing description"; fi
  if [ "$name.md" = "$base" ]; then pass "$base: name matches filename"; else fail "$base: name '$name' != filename"; fi
  case "$model" in
    inherit|flash|pro) pass "$base: model '$model' valid" ;;
    *) fail "$base: model '$model' not in inherit|flash|pro" ;;
  esac
  return 0
}

# 3. Default-deny keys: every top-level frontmatter key is in POLICY_KEYS, else it fails
# with the reason the spec gives for that key (S3.1, S7.4).
check_3_keys() {
  local f="$1" base="${1##*/}" key reason bad=0
  fm_load "$f"
  for key in ${FM_KEYS[@]+"${FM_KEYS[@]}"}; do
    if in_list "$key" "${POLICY_KEYS[@]}"; then continue; fi
    case "$key" in
      inheritCustomizations | hidden | excludeDefaultComponents) reason="gated: admitted only after LC3 (S3.1)" ;;
      commandExecutionPolicy | inheritMcp) reason="not adopted (no S3.1 row)" ;;
      skills | rules | agents | plugins | mcpServers) reason="never on bundled agents (S3.1)" ;;
      hooks) reason="not adopted (S7.4)" ;;
      *) reason="unknown key" ;;
    esac
    fail "$base: key '$key' $reason"
    bad=1
  done
  if [ "$bad" -eq 0 ]; then pass "$base: frontmatter keys all in POLICY_KEYS"; fi
  return 0
}

# 4. tools is non-empty and every entry is a baseline or retired name from known-tools.txt.
check_4_tools() {
  local f="$1" base="${1##*/}" tool
  fm_load "$f"
  if [ "${#FM_TOOLS[@]}" -eq 0 ]; then
    fail "$base: tools list is empty or missing"
    return 0
  fi
  for tool in "${FM_TOOLS[@]}"; do
    case " $KNOWN_TOOLS " in
      *" $tool "*) pass "$base: tool '$tool' known" ;;
      *) fail "$base: tool '$tool' NOT in documented tool set" ;;
    esac
  done
  return 0
}

# 5. Roles: write tools only on WRITE_AGENTS; no dispatch or async tool outside
# DISPATCH_AGENTS. The agent is its file name without .md (check 2 ties it to `name`).
check_5_roles() {
  local f="$1" base="${1##*/}" tool bad=0 id
  id="${base%.md}"
  fm_load "$f"
  for tool in ${FM_TOOLS[@]+"${FM_TOOLS[@]}"}; do
    if in_list "$tool" "${WRITE_TOOLS[@]}" && ! in_list "$id" ${WRITE_AGENTS[@]+"${WRITE_AGENTS[@]}"}; then
      fail "$base: write tool '$tool' on an agent outside WRITE_AGENTS"
      bad=1
    fi
    if in_list "$tool" "${DISPATCH_TOOLS[@]}" && ! in_list "$id" ${DISPATCH_AGENTS[@]+"${DISPATCH_AGENTS[@]}"}; then
      fail "$base: dispatch or async tool '$tool' is banned on bundled agents"
      bad=1
    fi
  done
  # The pass wording must not repeat a fixture's expected reason (belt and braces: the
  # fixture harness reads only [FAIL] lines).
  if [ "$bad" -eq 0 ]; then pass "$base: roles ok (no write tool outside the write agents, no banned dispatch tool)"; fi
  return 0
}

# 6. The frontmatter contains the lines `subagent: true` and `mainAgent: false`, literally.
check_6_flags() {
  local f="$1" base="${1##*/}" bad=0
  fm_load "$f"
  if ! in_list "subagent: true" ${FM_LINES[@]+"${FM_LINES[@]}"}; then
    fail "$base: subagent must be true"
    bad=1
  fi
  if ! in_list "mainAgent: false" ${FM_LINES[@]+"${FM_LINES[@]}"}; then
    fail "$base: mainAgent must be false"
    bad=1
  fi
  if [ "$bad" -eq 0 ]; then pass "$base: subagent true, mainAgent false"; fi
  return 0
}

# ---------------------------------------------------------------------------
# Roster checks, each called as check_<n>_<name> <ROOT> once, after the per-file loop:
# they look at a named set of agents under <ROOT>/agents/, not at one file. A full run
# passes the repository root, --lint-only <ROOT> passes <ROOT>, so the negative-fixture
# children run them too.
# ---------------------------------------------------------------------------

# body_of <file>: every line after the closing `---` of the frontmatter (the second
# `---` line), raw. A `---` rule inside the body is printed, not counted.
body_of() {
  awk 'seen >= 2 { print; next } /^---[[:space:]]*$/ { seen++ }' "$1"
}

# 5. Read-only class: each of READONLY_AGENTS exists and its body says "read-only"
# (case-insensitively). The body is read into a variable first, so grep -q closing
# early cannot SIGPIPE the writer under pipefail.
check_5_readonly() {
  local root="$1" name file body
  for name in "${READONLY_AGENTS[@]}"; do
    file="$root/agents/$name.md"
    if [ ! -f "$file" ]; then
      fail "$name.md: read-only class agent missing"
      continue
    fi
    body="$(body_of "$file")"
    if grep -qi 'read-only' <<< "$body"; then
      pass "$name.md: read-only class body states the review is read-only"
    else
      fail "$name.md: read-only class body lacks \"read-only\""
    fi
  done
  return 0
}

# 5. Implementer family: implementer and every VARIANTS key whose file exists list
# manage_task (the status and kill of a long run) and do not list schedule. A missing
# variant file is not reported here; the roster check for variants owns that failure.
# Reads FM_TOOLS after fm_load, which is what tools_of prints, without the fork.
check_5_implementer() {
  local root="$1" name file bad
  for name in implementer ${VARIANTS[@]+"${VARIANTS[@]}"}; do
    file="$root/agents/$name.md"
    [ -f "$file" ] || continue
    fm_load "$file"
    bad=0
    if ! in_list manage_task ${FM_TOOLS[@]+"${FM_TOOLS[@]}"}; then
      fail "$name.md: implementer family must list manage_task"
      bad=1
    fi
    if in_list schedule ${FM_TOOLS[@]+"${FM_TOOLS[@]}"}; then
      fail "$name.md: implementer family must not list schedule"
      bad=1
    fi
    if [ "$bad" -eq 0 ]; then pass "$name.md: implementer family tools ok (manage_task listed, schedule absent)"; fi
  done
  return 0
}

# ---------------------------------------------------------------------------
# The lint over <LINT_ROOT>/agents/*.md.
# ---------------------------------------------------------------------------
[ -d "$AGENTS_DIR" ] || { echo "[FAIL] agents/ directory missing: $AGENTS_DIR"; exit 1; }

shopt -s nullglob
AGENT_FILES=("$AGENTS_DIR"/*.md)
shopt -u nullglob
[ "${#AGENT_FILES[@]}" -gt 0 ] || { echo "[FAIL] no agent files under $AGENTS_DIR"; exit 1; }

for f in "${AGENT_FILES[@]}"; do
  # Without a frontmatter the other checks only repeat the same failure.
  check_1_shape "$f" || continue
  check_2_identity "$f"
  check_3_keys "$f"
  check_4_tools "$f"
  check_5_roles "$f"
  check_6_flags "$f"
done

check_5_readonly "$LINT_ROOT"
check_5_implementer "$LINT_ROOT"

# ---------------------------------------------------------------------------
# Negative fixtures: each copies agents/ to a scratch ROOT, applies one mutation and
# runs this script with --lint-only on it. The lint must exit 1 with the reason on one
# of its [FAIL] lines. Skipped under --lint-only, so a fixture never starts fixtures.
# ---------------------------------------------------------------------------
FIXTURE_ROOT=""
cleanup_fixture() {
  if [ -n "$FIXTURE_ROOT" ] && [ -d "$FIXTURE_ROOT" ]; then rm -rf "$FIXTURE_ROOT"; fi
  FIXTURE_ROOT=""
}
trap cleanup_fixture EXIT

# fail_line_has <output> <reason>: success when a `[FAIL]` line of the child's output
# contains the reason, literally. Never the whole output: a [PASS] line that happens to
# repeat the reason would otherwise satisfy a fixture whose failure came from elsewhere.
# In-process (no fork), like fm_load.
fail_line_has() {
  local out="$1" reason="$2" line
  while IFS= read -r line; do
    if [[ $line == *"[FAIL]"* && $line == *"$reason"* ]]; then return 0; fi
  done <<< "$out"
  return 1
}

run_negative_fixtures() {
  local entry label file kind arg reason out code
  echo ""
  echo "Negative fixtures"
  for entry in "${NEGATIVE_FIXTURES[@]}"; do
    IFS='|' read -r label file kind arg reason <<< "$entry"
    FIXTURE_ROOT="$(mktemp -d)"
    cp -R "$AGENTS_DIR" "$FIXTURE_ROOT/agents"
    if ! mutate "$FIXTURE_ROOT/agents/$file" "$kind" "$arg" || cmp -s "$AGENTS_DIR/$file" "$FIXTURE_ROOT/agents/$file"; then
      cleanup_fixture
      fail "negative fixture '$label' mutation did not apply"
      continue
    fi
    code=0
    out="$(bash "$0" --lint-only "$FIXTURE_ROOT" 2>&1)" || code=$?
    cleanup_fixture
    if [ "$code" -eq 0 ]; then
      fail "negative fixture '$label' passed the lint"
    elif [ "$code" -eq 1 ] && fail_line_has "$out" "$reason"; then
      pass "negative fixture '$label' failed as expected"
    else
      fail "negative fixture '$label' failed with the wrong reason (exit $code, expected: $reason)"
    fi
  done
}

if [ "$LINT_ONLY" -eq 0 ]; then
  run_negative_fixtures
fi

# 8. Say what the lint can and cannot see.
echo ""
echo "[NOTE] checks declared frontmatter only, not the effective tool roster (Live check 3)."
if [ "$FAILURES" -eq 0 ]; then echo "[PASS] Agent frontmatter lint passed"; else echo "[FAIL] $FAILURES failure(s)"; exit 1; fi
