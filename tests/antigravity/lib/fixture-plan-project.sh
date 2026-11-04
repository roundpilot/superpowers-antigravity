#!/usr/bin/env bash
# Fixture for the live execution tests: a two-task plan in a fresh git project.
#   fixture-plan-project.sh <dir>                      create the project, print the plan path
#   fixture-plan-project.sh --print-prompt sdd|inline|worktree
set -euo pipefail

print_prompt() {
    case "$1" in
        sdd) cat <<'PROMPT'
Execute the implementation plan at docs/superpowers/plans/implementation-plan.md using superpowers:subagent-driven-development. The plan is at: docs/superpowers/plans/implementation-plan.md

IMPORTANT: Follow the skill exactly. I will be verifying that you:
1. Read the plan once at the beginning
2. Dispatch subagents for implementation tasks
3. Create all specified files
4. Commit changes to git

When the tasks and the final review are done, stop and report; skip the finishing step.

Begin now. Execute the plan.
PROMPT
            ;;
        inline) cat <<'PROMPT'
Execute the implementation plan at docs/superpowers/plans/implementation-plan.md yourself in this session with superpowers:executing-plans, task by task. Do not dispatch subagents for the tasks. When the tasks and the final review are done, stop and report; skip the finishing step.
PROMPT
            ;;
        worktree) cat <<'PROMPT'
I want to start a new feature branch for adding user authentication. Set up an isolated workspace for this work.

Do NOT implement the feature — just set up the isolated workspace and report what approach you used.
Tell me exactly what tool or method you used for workspace isolation.
PROMPT
            ;;
        *) echo "usage: fixture-plan-project.sh --print-prompt sdd|inline|worktree" >&2; return 2 ;;
    esac
}

if [ "${1:-}" = "--print-prompt" ]; then
    print_prompt "${2:-}"
    exit $?
fi

DIR="${1:-}"
if [ -z "$DIR" ]; then
    echo "usage: fixture-plan-project.sh <dir> | --print-prompt sdd|inline|worktree" >&2
    exit 2
fi
if [ -e "$DIR" ] && [ -n "$(ls -A "$DIR" 2>/dev/null)" ]; then
    echo "[FAIL] $DIR is not empty"
    exit 1
fi
mkdir -p "$DIR"
cd "$DIR"

cat > package.json <<'JSON'
{
  "name": "test-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
JSON

PLAN_PATH="docs/superpowers/plans/implementation-plan.md"
mkdir -p "$(dirname "$PLAN_PATH")" src test
cat > "$PLAN_PATH" <<'PLAN'
# Test Implementation Plan

This is a minimal plan to test the subagent-driven-development workflow on Antigravity.

## Task 1: Create Hello Function

Create a function that returns a greeting.

**File:** `src/hello.js`

**Requirements:**
- Function named `hello`
- Takes an optional `name` parameter (defaults to "World")
- Returns `"Hello, <name>!"`
- Export the function

**Implementation:**
```javascript
export function hello(name = "World") {
  return `Hello, ${name}!`;
}
```

**Tests:** Create `test/hello.test.js` that verifies:
- `hello()` returns `"Hello, World!"`
- `hello("Alice")` returns `"Hello, Alice!"`

**Verification:** `npm test`

## Task 2: Create Goodbye Function

Create a function that returns a farewell message.

**File:** `src/goodbye.js`

**Requirements:**
- Function named `goodbye`
- Takes a required `name` parameter
- Returns `"Goodbye, <name>!"`
- Export the function

**Implementation:**
```javascript
export function goodbye(name) {
  return `Goodbye, ${name}!`;
}
```

**Tests:** Create `test/goodbye.test.js` that verifies:
- `goodbye("Alice")` returns `"Goodbye, Alice!"`
- `goodbye("Bob")` returns `"Goodbye, Bob!"`

**Verification:** `npm test`
PLAN

git init -q
git symbolic-ref HEAD refs/heads/main
git config user.email "test@test.com"
git config user.name "Test User"
git add .
git commit -q -m "Initial commit"
echo "$PLAN_PATH"
