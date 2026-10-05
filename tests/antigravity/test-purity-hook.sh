#!/usr/bin/env bash
# Test: PreToolUse Purity Hook (Behavioral, black box)
# Feeds fixture PreToolUse payloads to `node hooks/purity-check.mjs` over stdin and
# asserts what it prints and how it exits: exit 0, one stdout line that parses as
# JSON, the decision, a substring of the reason, and, for a deny, a reason that names
# purity-patterns.txt. Payloads come from tests/antigravity/lib/json-tool.mjs
# (`payload`) and carry native paths, never MSYS /c/... forms, because the hook runs
# under a native node. Deterministic, agy-free.
# Exit: 0 PASS; 1 FAIL; 77 SKIP (no node, or a WSL shell against a Windows checkout).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================"
echo " Test: PreToolUse Purity Hook (Behavioral)"
echo "========================================"
echo ""

if ! command -v node >/dev/null 2>&1; then
    echo "[SKIP] node not found"
    exit 77
fi

native() { (cd "$1" && node -p 'process.cwd()'); }        # native paths, never MSYS
R="$(native "$REPO_ROOT")"; S="$R/skills/example-skill"
HOOK="$R/hooks/purity-check.mjs"; JT="$R/tests/antigravity/lib/json-tool.mjs"
PATTERNS="$R/tests/antigravity/purity-patterns.txt"; STUB="$R/hooks/purity-check.sh"

# WSL guard: a WSL shell running a Windows checkout would feed win32 fixtures to a
# linux node, so none of the win32 path rows could run.
if { grep -qi microsoft /proc/version 2>/dev/null || uname -r | grep -qi microsoft; } \
    && [[ "$REPO_ROOT" == /mnt/[A-Za-z]/* ]]; then
    echo "gate run under WSL against a Windows checkout: win32 hook fixtures would not run; run from Git Bash"
    exit 77
fi

[ -f "$HOOK" ] || { echo "  [FAIL] hook not found: $HOOK"; exit 1; }

PLAT="$(node -p 'process.platform')"
FAILURES=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }
na() { echo "  [N/A] $1"; }

TMPD="$(native "$(mktemp -d)")"
trap 'rm -rf "$TMPD"' EXIT
OUTF="$TMPD/out.txt"
ERRF="$TMPD/err.txt"

# What every assertion checks on the captured stdout: exactly one line that parses as
# JSON, starts {"decision":"<want>", carries SUB in its reason (unless "-"), and, for a
# deny, names purity-patterns.txt. Prints OK or the first problem.
CHECK_JS='
const fs = require("fs");
const want = process.env.WANT, sub = process.env.SUB;
function check() {
  const out = fs.readFileSync(0, "utf8");
  const bad = (m) => m + " (stdout=" + JSON.stringify(out).slice(0, 240) + ")";
  const lines = out.split("\n");
  if (lines.length !== 2 || lines[0] === "" || lines[1] !== "") return bad("stdout is not exactly one line");
  let d;
  try { d = JSON.parse(lines[0]); } catch (e) { return bad("stdout is not JSON"); }
  if (!lines[0].startsWith("{\"decision\":\"" + want + "\"")) return bad("decision is not " + want);
  const reason = d && typeof d.reason === "string" ? d.reason : "";
  if (sub !== "-" && !reason.includes(sub)) return bad("reason lacks " + JSON.stringify(sub));
  if (want === "deny" && !reason.includes("purity-patterns.txt")) return bad("deny reason does not name purity-patterns.txt");
  return "OK";
}
console.log(check());
'

# payload <json-tool flags...>: one fixture payload line. Path conversion is off so a
# win32 form such as x:/Tools/... or \\host\share reaches the hook exactly as written.
payload() { MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' node "$JT" payload "$@"; }

HOOK_CODE=0
# run_hook <cwd> <stdin text>: sets HOOK_CODE; stdout goes to $OUTF.
run_hook() {
    printf '%s' "$2" | (cd "$1" && node "$HOOK") > "$OUTF" 2> "$ERRF"
    HOOK_CODE=$?
}
# assert <desc> <decision> <substr|->: checks HOOK_CODE and $OUTF.
assert() {
    local desc="$1" want="$2" sub="$3" res
    if [ "$HOOK_CODE" -ne 0 ]; then
        fail "$desc (hook exit=$HOOK_CODE)"
        return
    fi
    res="$(WANT="$want" SUB="$sub" node -e "$CHECK_JS" < "$OUTF")"
    if [ "$res" = "OK" ]; then pass "$desc"; else fail "$desc: $res"; fi
}
# expect_in <cwd> <desc> <decision> <substr|-> <payload flags...>
expect_in() {
    local cwd="$1" desc="$2" want="$3" sub="$4" pl
    shift 4
    if ! pl="$(payload "$@")"; then
        fail "$desc (json-tool payload failed)"
        return
    fi
    run_hook "$cwd" "$pl"
    assert "$desc" "$want" "$sub"
}
# expect <desc> <decision> <substr|-> <payload flags...>
expect() {
    local desc="$1" want="$2" sub="$3"
    shift 3
    expect_in "$PWD" "$desc" "$want" "$sub" "$@"
}
# expect_raw <desc> <decision> <substr|-> <stdin text>
expect_raw() {
    run_hook "$PWD" "$4"
    assert "$1" "$2" "$3"
}

echo "=== Fixtures ==="
echo ""

BAN='Use the TodoWrite tool to track your progress through the plan.'
F="$TMPD/f"; mkdir -p "$F"                              # a folder that is not this repo
G="$TMPD/g"; mkdir -p "$G"; git init -q "$G"            # a foreign git repository
W="$TMPD/w"; mkdir -p "$W"                              # a linked worktree of this repo
A="$TMPD/a"; mkdir -p "$A"                              # an artifact directory
COMMON="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [ -z "$COMMON" ]; then
    fail "fixtures: git rev-parse --git-common-dir found nothing for $REPO_ROOT (the hook test needs a git checkout)"
fi
printf 'gitdir: %s/worktrees/zz-fixture\n' "$COMMON" > "$W/.git"
CH='[{"TargetContent":"old header","ReplacementContent":"# Example Skill\n","StartLine":1,"EndLine":2,"AllowMultiple":false},{"TargetContent":"old footer","ReplacementContent":"Use TodoWrite","StartLine":40,"EndLine":42,"AllowMultiple":false}]'
CH5='[{"StartLine":1,"EndLine":2,"TargetContent":"old header","ReplacementContent":"# Example Skill\n\nClean chunk, nothing wrong here.\n"},{"StartLine":40,"EndLine":42,"TargetContent":"old footer","ReplacementContent":"Historically this workflow was Claude Code specific.\n"}]'

echo "=== Rows 1-12: the original fixtures, now with native paths ==="
echo ""

expect "row 1: clean skills/ write, no workspace -> ask" ask "outside the workspace" \
    --tool write_to_file --target "$S/SKILL.md" \
    --code $'# Example Skill\n\nThis skill helps with a task. It mentions no legacy tool names.\n'
expect "row 2: TodoWrite in a skills/ write -> deny" deny "(cc-tools): 'TodoWrite'" \
    --tool replace_file_content --target "$S/SKILL.md" --replacement "$BAN"
expect "row 3: relative target, no workspace -> ask" ask "cannot place" \
    --tool replace_file_content --target "docs/notes.md" --replacement "$BAN"
expect_raw "row 4: malformed JSON -> ask" ask "purity gate error" \
    '{"toolCall": {"name": "write_to_file", "args": {'
expect "row 5: multi_replace, second chunk bad -> deny" deny "Claude Code" \
    --tool multi_replace_file_content --target "$S/SKILL.md" --chunks "$CH5"
expect "row 6: Codex CLI in skills/ -> deny" deny "(platforms): 'Codex CLI'" \
    --tool write_to_file --target "$S/reference.md" --code $'This used to require Codex CLI specifically.\n'
expect "row 7: antigravity-tools in skills/ -> deny" deny "(mappings)" \
    --tool replace_file_content --target "$S/reference.md" --replacement $'See antigravity-tools for the mapping.\n'
expect "row 8: pattern text under tests/ -> allow" allow - \
    --tool write_to_file --target "$R/tests/antigravity/test-skill-tool-purity.sh" \
    --code $'CC_TOOLS="TodoWrite|EnterWorktree|Task tool|Skill tool"\n' --workspace "$R"
expect "row 9: banned term quoted in prose in skills/ -> deny" deny "TodoWrite" \
    --tool write_to_file --target "$S/history.md" \
    --code $'Historically, some agents used a tool called TodoWrite for planning.\n'
expect "row 10: banned content in a foreign folder's skills/ -> ask" ask "outside the workspace" \
    --tool write_to_file --target "$F/skills/x.md" --code "$BAN"
expect_in "$F" "row 11a: relative target, no workspace, run from a foreign cwd -> ask" ask "cannot place" \
    --tool write_to_file --target "skills/evil.md" --code "$BAN"
expect_in "$REPO_ROOT" "row 11b: same payload run from the repo root -> ask" ask "cannot place" \
    --tool write_to_file --target "skills/evil.md" --code "$BAN"
expect "row 12: relative target, workspace is this repo -> deny" deny "TodoWrite" \
    --tool write_to_file --target "skills/evil.md" --code "$BAN" --workspace "$R"

echo ""
echo "=== Rows 13-19: workspace membership and placement ==="
echo ""

expect "row 13: clean skills/ write, workspace is this repo -> allow" allow - \
    --tool write_to_file --target "$S/SKILL.md" --code '# Example Skill' --workspace "$R"
expect "row 14: this repo's skills/, workspace elsewhere -> ask" ask "outside the workspace" \
    --tool write_to_file --target "$S/SKILL.md" --code "$BAN" --workspace "$F"
expect "row 15: foreign skills/ inside a workspace, this repo also open -> allow" allow - \
    --tool write_to_file --target "$F/skills/x.md" --code "$BAN" --workspace "$F" --workspace "$R"
expect "row 16: relative target, two workspaces -> ask" ask "cannot place" \
    --tool write_to_file --target "skills/x.md" --code "$BAN" --workspace "$F" --workspace "$R"
expect "row 17: a worktree of this repo (gitdir: file) -> deny" deny "TodoWrite" \
    --tool write_to_file --target "$W/skills/x.md" --code "$BAN" --workspace "$W"
expect "row 18: a foreign git repository -> allow" allow - \
    --tool write_to_file --target "$G/skills/x.md" --code "$BAN" --workspace "$G"
expect "row 19: a mapping file name is a hit through rel -> deny" deny "(mappings)" \
    --tool write_to_file --target "$S/codex-tools.md" --code '# notes' --workspace "$R"

echo ""
echo "=== Row 20: every patterns row, every path: example denied, counterexample allowed ==="
echo ""

TAB=$'\t'
while IFS= read -r -u 3 line || [ -n "$line" ]; do
    line="${line//$'\r'/}"
    case "$line" in
        '' | '#'*) continue ;;
    esac
    group="${line%%"$TAB"*}"; rest="${line#*"$TAB"}"
    paths="${rest%%"$TAB"*}"; rest="${rest#*"$TAB"}"
    rest="${rest#*"$TAB"}"                                  # skip the regex
    example="${rest%%"$TAB"*}"; counter="${rest#*"$TAB"}"
    IFS=, read -r -a PATHS <<< "$paths"
    for p in "${PATHS[@]}"; do
        expect "row 20: $group example under $p -> deny" deny "($group)" \
            --tool write_to_file --target "$R/$p/zz-fixture.md" --code "$example"
        expect "row 20: $group counterexample under $p -> allow" allow - \
            --tool write_to_file --target "$R/$p/zz-fixture.md" --code "$counter" --workspace "$R"
    done
done 3< "$PATTERNS"

echo ""
echo "=== Rows 21-28: chunk forms, artifacts, bad payloads ==="
echo ""

expect "row 21: ReplacementChunks as an array -> deny" deny "TodoWrite" \
    --tool multi_replace_file_content --target "$S/SKILL.md" --chunks "$CH"
expect "row 22: ReplacementChunks as JSON text -> deny" deny "TodoWrite" \
    --tool multi_replace_file_content --target "$S/SKILL.md" --chunks-text "$CH"
expect "row 23: ReplacementChunks as unparseable text, scanned raw -> deny" deny "TodoWrite" \
    --tool multi_replace_file_content --target "$S/SKILL.md" --chunks-text '[{"ReplacementContent":"Use TodoWrite"'
expect "row 24: write under the artifact directory -> allow" allow - \
    --tool write_to_file --target "$A/walkthrough.md" --code '# walkthrough' --artifact-dir "$A"
expect "row 25: write outside the workspace and the artifact directory -> ask" ask "outside the workspace" \
    --tool write_to_file --target "$F/notes.md" --code '# notes' --artifact-dir "$A" --workspace "$R"
expect_raw "row 26: run_command is not a file tool -> ask" ask "not a file tool" \
    '{"toolCall":{"name":"run_command","args":{"CommandLine":"echo TodoWrite"}}}'
expect_raw "row 27: args null -> ask" ask "purity gate error" \
    '{"toolCall":{"name":"write_to_file","args":null}}'
expect_raw "row 28: empty stdin -> ask" ask "purity gate error" ''

echo ""
echo "=== Rows 29-33: win32 path forms ==="
echo ""

BS='\'
if [ "$PLAT" = "win32" ]; then
    if [[ "$R" =~ ^[A-Za-z]:\\ ]]; then
        drive="${R:0:1}"; stem="${R:2}"                      # stem: \Tools\sp-native-sync
        up="$(printf '%s' "$drive" | tr 'a-z' 'A-Z')"; lo="$(printf '%s' "$drive" | tr 'A-Z' 'a-z')"
        fwd="$(printf '%s' "$stem" | tr '\\' '/')"
        expect "row 29: X:\\ form -> deny" deny "TodoWrite" \
            --tool write_to_file --target "$up:$stem${BS}skills${BS}x.md" --code "$BAN"
        expect "row 30: x:\\ form -> deny" deny "TodoWrite" \
            --tool write_to_file --target "$lo:$stem${BS}skills${BS}x.md" --code "$BAN"
        expect "row 31: x:/ form -> deny" deny "TodoWrite" \
            --tool write_to_file --target "$lo:$fwd/skills/x.md" --code "$BAN"
        expect "row 32: drive-stripped form -> deny" deny "TodoWrite" \
            --tool write_to_file --target "$stem${BS}skills${BS}x.md" --code "$BAN"
    else
        for n in 29 30 31 32; do na "row $n: the checkout is not on a drive letter ($R)"; done
    fi
    UNC="${BS}${BS}localhost${BS}zz-fixture-share${BS}proj"
    expect "row 33: UNC path inside a UNC workspace -> allow" allow - \
        --tool write_to_file --target "$UNC${BS}skills${BS}x.md" --code "$BAN" --workspace "$UNC"
else
    for n in 29 30 31 32 33; do na "row $n: win32 only"; done
fi

echo ""
echo "=== Rows 34-35: the stub and the printed global entry ==="
echo ""

STUB_OUT="$(printf '{"x":1}' | bash "$STUB")"; STUB_CODE=$?
if [ "$STUB_CODE" -eq 0 ] && [ "$STUB_OUT" = '{"decision":"allow"}' ]; then
    pass "row 34: the retired bash stub prints exactly {\"decision\":\"allow\"}"
else
    fail "row 34: the retired bash stub (exit=$STUB_CODE out=$STUB_OUT)"
fi

ENTRY="$(node "$HOOK" --print-global-entry)"; ENTRY_CODE=$?
ENTRY_JS='
const fs = require("fs");
function check() {
  let d;
  try { d = JSON.parse(fs.readFileSync(0, "utf8")); } catch (e) { return "not JSON"; }
  if (Object.keys(d).join() !== "superpowers-purity-gate") return "top-level keys are " + Object.keys(d).join();
  const pre = d["superpowers-purity-gate"].PreToolUse;
  if (!Array.isArray(pre) || pre.length < 1) return "no PreToolUse[0]";
  if (pre[0].matcher !== "write_to_file|replace_file_content|multi_replace_file_content") return "matcher is " + pre[0].matcher;
  const h = pre[0].hooks && pre[0].hooks[0];
  if (!h) return "no hooks[0]";
  if (h.type !== "command") return "type is " + h.type;
  if (h.timeout !== 10) return "timeout is " + h.timeout;
  let want = "node \"" + process.env.RN.split("\\").join("/") + "/hooks/purity-check.mjs\"";
  let got = String(h.command);
  if (process.platform === "win32") { want = want.toLowerCase(); got = got.toLowerCase(); }
  if (got !== want) return "command is " + h.command + ", want " + want;
  return "OK";
}
console.log(check());
'
ENTRY_RES="$(printf '%s' "$ENTRY" | RN="$R" node -e "$ENTRY_JS")"
if [ "$ENTRY_CODE" -eq 0 ] && [ "$ENTRY_RES" = "OK" ]; then
    pass "row 35: --print-global-entry prints the superpowers-purity-gate entry with this checkout's path"
else
    fail "row 35: --print-global-entry (exit=$ENTRY_CODE: $ENTRY_RES)"
fi

echo ""
echo "=== Review Focus rows 36-38 ==="
echo ""

# Row 36: a checkout path with a space. The printed command must run from there under
# bash and under the platform shell (cmd.exe on win32).
SP="$TMPD/sp space"
mkdir -p "$SP/hooks" "$SP/tests/antigravity"
cp "$HOOK" "$SP/hooks/" && cp "$PATTERNS" "$SP/tests/antigravity/" && git init -q "$SP"
CMD="$(node "$SP/hooks/purity-check.mjs" --print-global-entry \
    | node -e 'const d=JSON.parse(require("fs").readFileSync(0,"utf8")); process.stdout.write(d["superpowers-purity-gate"].PreToolUse[0].hooks[0].command)')"
PL36="$(payload --tool write_to_file --target "$SP/skills/x/SKILL.md" --code "$BAN" --workspace "$SP")"
printf '%s' "$PL36" | bash -c "$CMD" > "$OUTF" 2> "$ERRF"; HOOK_CODE=$?
assert "row 36a: the printed command from a path with a space, under bash -c -> deny" deny "TodoWrite"
printf '%s' "$PL36" | CMD="$CMD" node -e 'process.stdout.write(require("child_process").spawnSync(process.env.CMD,{shell:true,input:require("fs").readFileSync(0),encoding:"utf8"}).stdout)' > "$OUTF" 2> "$ERRF"; HOOK_CODE=$?
assert "row 36b: the printed command from a path with a space, under the platform shell -> deny" deny "TodoWrite"

# Row 37: NTFS writes SKILLS\ and Skills\ into skills/, so the hook must deny them.
if [ "$PLAT" = "win32" ]; then
    expect "row 37a: <repo>/SKILLS/ -> deny" deny "TodoWrite" \
        --tool write_to_file --target "$R/SKILLS/example-skill/x.md" --code "$BAN" --workspace "$R"
    expect "row 37b: <repo>/Skills/ -> deny" deny "TodoWrite" \
        --tool write_to_file --target "$R/Skills/example-skill/x.md" --code "$BAN" --workspace "$R"
    # Not in the plan's row list: the checkout's own path in another case is still this repo.
    RUP="$(printf '%s' "$R" | tr 'a-z' 'A-Z')"
    expect "row 37c: the repo path in upper case -> deny" deny "TodoWrite" \
        --tool write_to_file --target "$RUP/skills/example-skill/x.md" --code "$BAN" --workspace "$R"
else
    na "row 37: win32 only"
fi

# Row 38: node 18 is the documented floor, development runs on a newer node.
NEWER='import\.meta\.(dirname|filename)|\.(toSorted|toReversed|toSpliced)\(|(Object|Map)\.groupBy|Promise\.withResolvers|Array\.fromAsync|fs\.globSync|process\.getBuiltinModule'
HITS="$(grep -nE "$NEWER" "$REPO_ROOT"/hooks/*.mjs "$REPO_ROOT"/tests/antigravity/lib/*.mjs 2>/dev/null || true)"
if [ -z "$HITS" ]; then
    pass "row 38: no API newer than node 18 in hooks/*.mjs or tests/antigravity/lib/*.mjs"
else
    while IFS= read -r hit; do
        fail "row 38: API newer than node 18: $hit"
    done <<< "$HITS"
fi

echo ""
echo "========================================"
echo " Test Summary"
echo "========================================"
echo ""

if [ "$FAILURES" -eq 0 ]; then
    echo "[PASS] PreToolUse purity hook test passed (0 failures)"
    exit 0
else
    echo "[FAIL] PreToolUse purity hook test failed ($FAILURES checks failed)"
    exit 1
fi
