# Port to Antigravity 2.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the Superpowers skills framework and workspace files to fully support Google Antigravity 2.0 parallel subagents, plugin architecture, and updated tool names.

**Architecture:** Add a root `plugin.json` to make the repository a valid project/global Antigravity 2.0 plugin. Create a new `antigravity-tools.md` reference to translate standard tool names to Antigravity equivalents, and update skill templates to utilize the native `invoke_subagent` (running `self`) parallel orchestration parameters.

**Tech Stack:** Markdown skill files, JSON configuration, Antigravity 2.0 plugin structure.

---

### Task 1: Create Antigravity 2.0 Plugin Manifest

**Files:**
- Create: `plugin.json`

- [ ] **Step 1: Write plugin.json at repository root**
  
  Write the following content to `plugin.json`:
  ```json
  {
    "name": "superpowers",
    "description": "Core skills library: TDD, debugging, collaboration patterns, and proven techniques",
    "version": "6.0.0"
  }
  ```

- [ ] **Step 2: Commit plugin.json**

  Run:
  ```bash
  git add plugin.json
  git commit -m "feat: add Antigravity 2.0 plugin manifest"
  ```

---

### Task 2: Create Antigravity 2.0 Tool Mapping Reference

**Files:**
- Create: `skills/using-superpowers/references/antigravity-tools.md`
- Modify: `skills/using-superpowers/SKILL.md`

- [ ] **Step 1: Write antigravity-tools.md reference**

  Create `skills/using-superpowers/references/antigravity-tools.md` with the following content:
  ```markdown
  # Antigravity 2.0 Tool Mapping

  Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

  | Skill references | Antigravity 2.0 equivalent | Description |
  |-----------------|---------------------------|-------------|
  | `Read` (file reading) | `view_file` | Read files (up to 800 lines, supports StartLine and EndLine) |
  | `Write` (file creation) | `write_to_file` | Create new files and directories |
  | `Edit` (file editing) | `replace_file_content` / `multi_replace_file_content` | Edit file content (contiguous vs non-contiguous) |
  | `Bash` (run commands) | `run_command` | Execute commands (needs user approval) |
  | `Grep` (search content) | `grep_search` | Search text or regex within files |
  | `Glob` (search filenames) | `list_dir` / `grep_search` (Includes) | Find files/directories or filter by pattern |
  | `TodoWrite` (tasks) | Markdown `task.md` | Track progress in `C:\Users\<user>\.gemini\antigravity\brain\<conv>\task.md` |
  | `Skill` tool (invoke skill) | Read `skills/<name>/SKILL.md` | Auto-loaded context, no special command needed |
  | `WebSearch` | `search_web` | Perform Google searches |
  | `WebFetch` | `read_url_content` | Fetch HTML or markdown from a URL |
  | `Task` tool (subagent) | `invoke_subagent` | Launch parallel subagents |

  ## Subagent support

  Antigravity 2.0 supports parallel subagents natively via `invoke_subagent`. To run any subagent task, invoke the built-in `self` subagent (a clone of your current environment) with the target prompt:

  | Skill instruction | Antigravity 2.0 equivalent |
  |-------------------|---------------------------|
  | `Task tool (superpowers:implementer)` | `invoke_subagent` with `TypeName: "self"`, `Role: "Implementer"`, and filled `implementer-prompt.md` |
  | `Task tool (superpowers:spec-reviewer)` | `invoke_subagent` with `TypeName: "self"`, `Role: "Spec Reviewer"`, and filled `spec-reviewer-prompt.md` |
  | `Task tool (superpowers:code-reviewer)` | `invoke_subagent` with `TypeName: "self"`, `Role: "Code Reviewer"`, and filled `code-reviewer.md` |
  | `Task tool (superpowers:code-quality-reviewer)` | `invoke_subagent` with `TypeName: "self"`, `Role: "Code Quality Reviewer"`, and filled `code-quality-reviewer-prompt.md` |

  ### Workspace Isolation

  When invoking `self` via `invoke_subagent`, you can control workspace sharing:
  - `Workspace: "inherit"` (default) - uses the same workspace session.
  - `Workspace: "branch"` - isolates the workspace on a new git branch automatically.
  - `Workspace: "share"` - shares the directory but allows independent branching (like a worktree).
  ```

- [ ] **Step 2: Modify skills/using-superpowers/SKILL.md to link reference**

  Replace lines 38-40 in `skills/using-superpowers/SKILL.md`:
  ```markdown
  ## Platform Adaptation

  Skills use Claude Code tool names. Non-CC platforms: see `references/copilot-tools.md` (Copilot CLI), `references/codex-tools.md` (Codex), or `references/antigravity-tools.md` (Antigravity 2.0) for tool equivalents. Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
  ```

- [ ] **Step 3: Commit Tool Mapping changes**

  Run:
  ```bash
  git add skills/using-superpowers/SKILL.md skills/using-superpowers/references/antigravity-tools.md
  git commit -m "docs: add Antigravity 2.0 tool mapping references"
  ```

---

### Task 3: Port Dispatching Parallel Agents Skill to Antigravity 2.0

**Files:**
- Modify: `skills/dispatching-parallel-agents/SKILL.md`

- [ ] **Step 1: Modify skills/dispatching-parallel-agents/SKILL.md**

  Update the tool references in `skills/dispatching-parallel-agents/SKILL.md` around line 68-74 to use `invoke_subagent` syntax instead of Claude Code's `Task` CLI command syntax:
  ```json
  // In Antigravity 2.0
  invoke_subagent({
    "Subagents": [
      { "TypeName": "self", "Role": "Bug Fixer", "Prompt": "Fix agent-tool-abort.test.ts failures..." },
      { "TypeName": "self", "Role": "Bug Fixer", "Prompt": "Fix batch-completion-behavior.test.ts failures..." },
      { "TypeName": "self", "Role": "Bug Fixer", "Prompt": "Fix tool-approval-race-conditions.test.ts failures..." }
    ]
  })
  // All three subagents will be launched concurrently by the platform.
  ```

- [ ] **Step 2: Commit changes to dispatching-parallel-agents**

  Run:
  ```bash
  git add skills/dispatching-parallel-agents/SKILL.md
  git commit -m "refactor: port dispatching-parallel-agents to invoke_subagent"
  ```

---

### Task 4: Port Subagent-Driven Development Skill and Prompt Templates to Antigravity 2.0

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `skills/subagent-driven-development/spec-reviewer-prompt.md`
- Modify: `skills/subagent-driven-development/code-quality-reviewer-prompt.md`

- [ ] **Step 1: Modify skills/subagent-driven-development/SKILL.md**

  Update `skills/subagent-driven-development/SKILL.md` to reference `invoke_subagent` instead of the old `Task` tool. Update the flowchart text and descriptions of roles.

  Replace:
  - "Mark task complete in TodoWrite" -> "Mark task complete in task.md"
  - References to `./implementer-prompt.md` -> show invocation using `invoke_subagent` with `TypeName: "self"` and prompt templates.

- [ ] **Step 2: Update implementer-prompt.md**

  Replace lines 5-8 in `skills/subagent-driven-development/implementer-prompt.md`:
  ```markdown
  invoke_subagent:
    Subagents:
      - TypeName: "self"
        Role: "Implementer"
        Prompt: |
          You are implementing Task N: [task name]
  ```

- [ ] **Step 3: Update spec-reviewer-prompt.md**

  Replace lines 7-10 in `skills/subagent-driven-development/spec-reviewer-prompt.md`:
  ```markdown
  invoke_subagent:
    Subagents:
      - TypeName: "self"
        Role: "Spec Reviewer"
        Prompt: |
          You are reviewing whether an implementation matches its specification.
  ```

- [ ] **Step 4: Update code-quality-reviewer-prompt.md**

  Replace lines 9-17 in `skills/subagent-driven-development/code-quality-reviewer-prompt.md`:
  ```markdown
  invoke_subagent:
    Subagents:
      - TypeName: "self"
        Role: "Code Quality Reviewer"
        Prompt: |
          Use template at requesting-code-review/code-reviewer.md

          DESCRIPTION: [task summary, from implementer's report]
          PLAN_OR_REQUIREMENTS: Task N from [plan-file]
          BASE_SHA: [commit before task]
          HEAD_SHA: [current commit]
  ```

- [ ] **Step 5: Commit subagent-driven development changes**

  Run:
  ```bash
  git add skills/subagent-driven-development/*
  git commit -m "refactor: update subagent-driven-development prompts and skill for Antigravity 2.0"
  ```

---

### Task 5: Port Brainstorming, Writing Plans, and Requesting Code Review Skill Prompts

**Files:**
- Modify: `skills/brainstorming/spec-document-reviewer-prompt.md`
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md`
- Modify: `skills/requesting-code-review/code-reviewer.md`
- Modify: `skills/requesting-code-review/SKILL.md`

- [ ] **Step 1: Update brainstorming spec-document-reviewer-prompt.md**

  Replace lines 9-12 in `skills/brainstorming/spec-document-reviewer-prompt.md`:
  ```markdown
  invoke_subagent:
    Subagents:
      - TypeName: "self"
        Role: "Spec Document Reviewer"
        Prompt: |
          You are a spec document reviewer. Verify this spec is complete and ready for planning.
  ```

- [ ] **Step 2: Update writing-plans plan-document-reviewer-prompt.md**

  Replace lines 9-12 in `skills/writing-plans/plan-document-reviewer-prompt.md`:
  ```markdown
  invoke_subagent:
    Subagents:
      - TypeName: "self"
        Role: "Plan Document Reviewer"
        Prompt: |
          You are a plan document reviewer. Verify this plan is complete and ready for implementation.
  ```

- [ ] **Step 3: Update requesting-code-review code-reviewer.md**

  Replace lines 7-10 in `skills/requesting-code-review/code-reviewer.md`:
  ```markdown
  invoke_subagent:
    Subagents:
      - TypeName: "self"
        Role: "Code Reviewer"
        Prompt: |
          You are a Senior Code Reviewer with expertise in software architecture...
  ```

- [ ] **Step 4: Update requesting-code-review SKILL.md**

  Replace line 34 in `skills/requesting-code-review/SKILL.md`:
  ```markdown
  Use `invoke_subagent` with `TypeName: "self"` and role `Code Reviewer`, using prompt template at `code-reviewer.md`.
  ```

- [ ] **Step 5: Commit Task 5 changes**

  Run:
  ```bash
  git add skills/brainstorming/spec-document-reviewer-prompt.md skills/writing-plans/plan-document-reviewer-prompt.md skills/requesting-code-review/*
  git commit -m "refactor: port brainstorming, writing-plans, and requesting-code-review templates to invoke_subagent"
  ```

---

## Verification Plan

### Manual Verification
- Review all modified markdown files to check if the new `invoke_subagent` instructions, tool translation mappings, and prompt definitions are correct and format cleanly.
- Verify that `plugin.json` parses successfully as valid JSON.
- Verify git status to confirm all files are correctly updated and committed.
