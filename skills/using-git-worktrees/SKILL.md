---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace using Antigravity 2.0's native workspace isolation.

**Core principle:** Detect existing isolation first. Then isolate the session on a feature branch; give `Workspace: "branch"` only to subagents that write alongside other writers. Never use manual `git worktree add`.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

**Verify Git Repository Existence:** run `git rev-parse --is-inside-work-tree`. It prints `true` inside a repository. Anything else means you are not in one — you cannot use worktrees; check whether you need to run `git init` first.

Then run each of these on its own and note what it prints:

```
git rev-parse --path-format=absolute --git-dir --git-common-dir
git branch --show-current
```

The first prints `GIT_DIR`, then `GIT_COMMON`; the two differ in a linked worktree. The second prints `BRANCH`, or nothing on a detached HEAD. (Git older than 2.31 lacks `--path-format`: resolve each printed path to an absolute one before comparing.)

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Verify with `git rev-parse --show-superproject-working-tree`: it prints a path inside a submodule, and nothing otherwise.

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** Already isolated. Skip to Step 2.

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** Normal repo. Proceed to Step 1.

## Step 1: Create Isolated Workspace

**For subagents that write concurrently** (parallel agents editing overlapping files): `Workspace: "branch"` on `invoke_subagent`. The platform handles directory placement, branch creation, and cleanup. **For plan implementers**, which run one at a time: `Workspace: "inherit"` — they commit on your feature branch.

**For parent orchestrator feature branches:** Use `git checkout -b <branch>` directly. No worktree needed — the orchestrator works in place on a feature branch. On 2.0, a conversation started in a Project's New Worktree Mode already runs in its own worktree; Step 0 detects it.

## Step 2: Project Setup

Auto-detect and run appropriate setup — if the repository root has one of these files, run its command:

| File | Command |
|------|---------|
| `package.json` | `npm install` |
| `Cargo.toml` | `cargo build` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `pyproject.toml` | `poetry install` |
| `go.mod` | `go mod download` |

## Step 3: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.
**If tests pass:** Report ready.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Concurrent writing subagents | `Workspace: "branch"` on `invoke_subagent` |
| Plan implementer (one at a time) | `Workspace: "inherit"` on your feature branch |
| Parent orchestrator | `git checkout -b <branch>` |
| Tests fail during baseline | Report failures + ask |

## Workspace Mode Decision Table

Antigravity 2.0 supports three workspace modes for subagents. Choose based on the agent's role:

| Mode | Syntax | Use for | Example |
|------|--------|---------|----------|
| `branch` | `Workspace: "branch"` | Agents that write concurrently with other writers | Parallel fixers on overlapping files |
| `inherit` | `Workspace: "inherit"` | Agents that work in your checkout: reviewers, and writers that run one at a time | Reviewers, plan implementers |
| `share` | `Workspace: "share"` | Documented only as 'share directory storage'; its path, lifetime and git state are unverified — not recommended | — |

**Rules of thumb:**
- If agents write code at the same time → `branch`
- If one agent at a time writes, or agents only read → `inherit`

## Red Flags

**Never:**
- Use `git worktree add` — use `Workspace: "branch"` for concurrent writers instead
- Create a worktree when Step 0 detects existing isolation
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Run Step 0 detection first
- Use native workspace isolation
- Auto-detect and run project setup
- Verify clean test baseline
