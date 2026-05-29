# Antigravity 2.0 Tool Mapping

Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

| Skill references | Antigravity 2.0 equivalent |
|-----------------|---------------------------|
| `Read` (file reading) | `view_file` |
| `Write` (file creation) | `write_to_file` |
| `Edit` (file editing) | `replace_file_content` (single contiguous block) / `multi_replace_file_content` (multiple non-adjacent blocks) |
| `Bash` (run commands) | `run_command` |
| `Grep` (search file content) | `grep_search` |
| `Glob` (search files by name) | `find_by_name` with `Pattern` glob, optional `Extensions`, `MaxDepth`, `Type` (file/directory) |
| `TodoWrite` (task tracking) | `write_to_file` to create/update `task.md` artifact |
| `Skill` tool (invoke a skill) | Skills auto-load from plugins; use `view_file` to read any `SKILL.md` on demand |
| `WebSearch` | `search_web` |
| `WebFetch` | `read_url_content` |
| `Task` tool (dispatch subagent) | `invoke_subagent` (see [Subagent support](#subagent-support)) |

## Subagent support

Antigravity 2.0 supports parallel subagents natively via `invoke_subagent`. There are two patterns for dispatching subagent tasks:

### Pattern 1: Direct dispatch (baseline)

Use the built-in `self` subagent type to dispatch any task — it clones your full environment and follows the prompt you provide.

When a skill says to dispatch a named agent type, use `invoke_subagent` with `TypeName: "self"` and the full prompt from the skill's prompt template:

| Skill instruction | Antigravity 2.0 equivalent |
|-------------------|---------------------------|
| `Task tool (superpowers:implementer)` | `invoke_subagent` with `TypeName: "self"`, `Role: "Implementer"`, and filled `implementer-prompt.md` template |
| `Task tool (superpowers:spec-reviewer)` | `invoke_subagent` with `TypeName: "self"`, `Role: "Spec Reviewer"`, and filled `spec-reviewer-prompt.md` template |
| `Task tool (superpowers:code-reviewer)` | `invoke_subagent` with `TypeName: "self"`, `Role: "Code Reviewer"`, and filled `code-reviewer.md` template |
| `Task tool (superpowers:code-quality-reviewer)` | `invoke_subagent` with `TypeName: "self"`, `Role: "Code Quality Reviewer"`, and filled `code-quality-reviewer-prompt.md` template |
| `Task tool (general-purpose)` with inline prompt | `invoke_subagent` with `TypeName: "self"` and your inline prompt |

### Pattern 2: Define then invoke (recommended for multi-task plans)

For repeated dispatches (e.g., running a 5-task plan where each task needs an implementer + 2 reviewers), use `define_subagent` to create named agent types upfront, then `invoke_subagent` by type name. This avoids re-sending full system prompts on every invocation.

```
# Define once at the start of a plan
define_subagent(name="implementer", description="...", system_prompt="<filled implementer-prompt.md>")
define_subagent(name="spec-reviewer", description="...", system_prompt="<filled spec-reviewer-prompt.md>")
define_subagent(name="code-reviewer", description="...", system_prompt="<filled code-reviewer.md>")

# Then invoke by name for each task
invoke_subagent(TypeName="implementer", Role="Implementer", Prompt="Task 1: ...")
invoke_subagent(TypeName="spec-reviewer", Role="Spec Reviewer", Prompt="Review Task 1...")
```

### Prompt filling

Skills provide prompt templates with placeholders like `{WHAT_WAS_IMPLEMENTED}` or `[FULL TEXT of task]`. Fill all placeholders and pass the complete prompt as the `Prompt` parameter to `invoke_subagent`. The prompt template itself contains the agent's role, review criteria, and expected output format — the subagent will follow it.

### Communicating with subagents

Use `send_message` to communicate with a running subagent (e.g., to answer an implementer's questions). Each subagent has a unique conversation ID returned by `invoke_subagent`.

Use `manage_subagents` to list active subagents or kill completed ones.

### Parallel dispatch

Antigravity 2.0 supports parallel subagent dispatch. When a skill asks you to dispatch multiple independent subagent tasks in parallel, include all entries in the `Subagents` array of a single `invoke_subagent` call. Keep dependent tasks sequential, but do not serialize independent subagent tasks just to preserve a simpler history.

### Workspace isolation

When invoking subagents, you can control workspace sharing via the `Workspace` parameter:
- `"inherit"` (default) — uses the same workspace as the parent
- `"branch"` — creates an isolated workspace on a new git branch (equivalent to a native worktree)
- `"share"` — shares the parent's directory but allows independent branching

## Additional Antigravity 2.0 tools

These tools are available in Antigravity 2.0 but have no Claude Code equivalent:

| Tool | Purpose |
|------|---------|
| `find_by_name` | Search for files and directories using glob patterns (Pattern, Extensions, MaxDepth, Type) |
| `list_dir` | List files and subdirectories in a single directory |
| `ask_question` | Present structured multi-choice questions to the user |
| `schedule` | Set one-shot timers or recurring cron jobs |
| `generate_image` | Create images for UI mockups and assets |
| `define_subagent` | Create custom subagent types with specialized system prompts |
| `manage_task` | Manage background command tasks (list, kill, status, send input) |
| `manage_subagents` | List or terminate active subagents |
| `send_message` | Send a message to a running subagent by conversation ID |
| `list_permissions` | View current resource access grants |
| `ask_permission` | Request additional scoped permissions for file/command access |

## Built-in subagent types

| Type | Purpose |
|------|---------|
| `self` | Full clone of the parent agent (tools, prompt, model) — use for any general-purpose dispatch |
| `research` | Read-only subagent for codebase exploration, web search, and file reading |
