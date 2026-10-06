#!/usr/bin/env bash
# Structural checks for skills/diagnosing-superpowers. Behavior is tested by
# scenario evals kept by the maintainer; this script only checks the things a
# shell can check: frontmatter, referenced files exist, no local paths or
# names leaked into shipped files, SKILL.md word budget.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/diagnosing-superpowers"
SKILL_MD="$SKILL_DIR/SKILL.md"
WORD_BUDGET=1000

PASSES=0
FAILURES=0

pass() { echo "  [PASS] $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

echo "diagnosing-superpowers structure"

# --- SKILL.md frontmatter -------------------------------------------------
if [ -f "$SKILL_MD" ]; then
  pass "SKILL.md exists"
  frontmatter="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$SKILL_MD")"
  if printf '%s\n' "$frontmatter" | grep -q '^name: diagnosing-superpowers$'; then
    pass "frontmatter name is diagnosing-superpowers"
  else
    fail "frontmatter name is diagnosing-superpowers"
  fi
  description="$(printf '%s\n' "$frontmatter" | awk '/^description:/{sub(/^description:[ ]*/,""); print; found=1; next} found && /^[ ]/{print} found && !/^[ ]/{exit}' | tr '\n' ' ')"
  if printf '%s' "$description" | grep -q '^Use when'; then
    pass "description starts with 'Use when'"
  else
    fail "description starts with 'Use when' (got: ${description:0:60})"
  fi
  if [ "${#description}" -le 1024 ]; then
    pass "description under 1024 characters"
  else
    fail "description under 1024 characters (${#description})"
  fi
  for banned in "dispatch" "then" "step"; do
    if printf '%s' "$description" | grep -qiw "$banned"; then
      fail "description contains workflow word '$banned'"
    else
      pass "description avoids workflow word '$banned'"
    fi
  done

  # --- word budget --------------------------------------------------------
  # Fork: count in the C locale, so the result does not depend on the locale
  # (a UTF-8 locale counts each standalone em dash as a word).
  body_words="$(awk 'BEGIN{fm=0} NR==1 && $0=="---"{fm=1; next} fm==1 && $0=="---"{fm=2; next} fm==2{print}' "$SKILL_MD" | LC_ALL=C wc -w | tr -d ' ')"
  if [ "$body_words" -le "$WORD_BUDGET" ]; then
    pass "SKILL.md body within $WORD_BUDGET words ($body_words)"
  else
    fail "SKILL.md body within $WORD_BUDGET words ($body_words)"
  fi

  # --- required sections --------------------------------------------------
  for heading in "## Hard rules" "## Red Flags"; do
    if grep -q "^$heading" "$SKILL_MD"; then
      pass "SKILL.md has section '$heading'"
    else
      fail "SKILL.md has section '$heading'"
    fi
  done

  # --- every referenced skill file exists --------------------------------
  while IFS= read -r ref; do
    if [ -f "$SKILL_DIR/$ref" ]; then
      pass "referenced file exists: $ref"
    else
      fail "referenced file exists: $ref"
    fi
  done < <(grep -o '\(references\|prompts\|templates\)/[A-Za-z0-9._-]*\.md' "$SKILL_MD" | sort -u)
  # --- backticked bundled agents exist (fork) -----------------------------
  for agent in session-analyst bundle-scrubber; do
    if grep -qF "\`$agent\`" "$SKILL_MD"; then
      if [ -f "$REPO_ROOT/agents/$agent.md" ]; then
        pass "bundled agent exists: agents/$agent.md"
      else
        fail "bundled agent exists: agents/$agent.md"
      fi
    fi
  done
else
  fail "SKILL.md exists"
fi

# --- expected files -------------------------------------------------------
expected_files=(
  references/redaction-policy.md
  references/session-discovery.md
  references/context-safety.md
  references/github-issues.md
  prompts/analyst-common.md
  prompts/skill-timeline.md
  prompts/plan-adherence.md
  prompts/repeated-work.md
  prompts/stumbles.md
  prompts/quality-evidence.md
  prompts/request-conflicts.md
  prompts/cost-and-time.md
  prompts/scrub.md
  prompts/scrub-audit.md
  prompts/similar-session.md
  templates/case.md
  templates/report.md
  templates/bundle-README.md
  templates/issue.md
)
for rel in "${expected_files[@]}"; do
  if [ -f "$SKILL_DIR/$rel" ]; then
    pass "expected file present: $rel"
  else
    fail "expected file present: $rel"
  fi
done

# --- removed harness recipes stay removed --------------------------------
removed_files=(
  references/claude-code-sessions.md
  references/codex-sessions.md
  references/other-harnesses.md
)
for rel in "${removed_files[@]}"; do
  if [ ! -e "$SKILL_DIR/$rel" ]; then
    pass "removed reference absent: $rel"
  else
    fail "removed reference absent: $rel"
  fi
done

removed_reference_hits="$(grep -rn -E 'references/(claude-code-sessions|codex-sessions|other-harnesses)\.md' "$SKILL_DIR" --include='*.md' 2>/dev/null || true)"
if [ -z "$removed_reference_hits" ]; then
  pass "active skill prose has no references to removed harness recipes"
else
  fail "active skill prose has no references to removed harness recipes"
  printf '%s\n' "$removed_reference_hits" | head -10 | sed 's/^/    /'
fi

# --- no local paths or names in shipped files ----------------------------
leaks="$(grep -rn -E '/Users/|/home/|jesse|[\\]Users[\\]+[A-Za-z0-9._-]' "$SKILL_DIR" "$SCRIPT_DIR" --exclude=test-skill-structure.sh 2>/dev/null || true)"
if [ -z "$leaks" ]; then
  pass "no machine-specific paths or names in shipped files (skills + tests)"
else
  fail "no machine-specific paths or names in shipped files (skills + tests)"
  printf '%s\n' "$leaks" | head -10 | sed 's/^/    /'
fi

# --- account name: warning only, never the exit code (fork) --------------
account="${USERNAME:-${USER:-}}"
case "$(printf '%s' "$account" | tr '[:upper:]' '[:lower:]')" in
  user|runner|admin|administrator|node|vscode|ubuntu|codespace|root|system|model|guest|test) account="" ;;
esac
if [ "${#account}" -ge 4 ]; then
  grep -rniwF --exclude=test-skill-structure.sh -- "$account" "$SKILL_DIR" "$SCRIPT_DIR" 2>/dev/null \
    | cut -d: -f1,2 | while IFS= read -r loc; do echo "  [WARN] account name found at $loc"; done
fi

# --- issues go to this fork (fork) ----------------------------------------
issues_md="$SKILL_DIR/references/github-issues.md"
if grep -qF 'roundpilot/superpowers-antigravity' "$issues_md" 2>/dev/null && ! grep -qF 'obra/superpowers' "$issues_md"; then
  pass "github-issues.md targets roundpilot/superpowers-antigravity, not obra/superpowers"
else
  fail "github-issues.md targets roundpilot/superpowers-antigravity, not obra/superpowers"
fi

# --- "the user" never appears in skill prose -----------------------------
user_hits="$(grep -rn -i 'the user' "$SKILL_DIR" --include='*.md' 2>/dev/null || true)"
if [ -z "$user_hits" ]; then
  pass "skill files say 'your human partner', not 'the user'"
else
  fail "skill files say 'your human partner', not 'the user'"
  printf '%s\n' "$user_hits" | head -10 | sed 's/^/    /'
fi

echo
echo "Passed: $PASSES  Failed: $FAILURES"
[ "$FAILURES" -eq 0 ]
