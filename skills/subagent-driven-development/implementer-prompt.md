# Implementer Dispatch Template

This role ships as the bundled `implementer` agent (`agents/implementer.md`) — no
registration needed. Fill the template below and dispatch:
`invoke_subagent(Subagents: [{TypeName: "implementer", Role: "<role for this task>", Prompt: <filled template>, Workspace: "inherit"}])`

## Dynamic Prompt Template

Pass this as the `Prompt` argument when calling `invoke_subagent`. Replace placeholders with actual values.

```
You are implementing Task {N}: {TASK_NAME}

## Task Description

Your task is `{PLAN_PATH}` lines {START}-{END}. Read exactly that range with `view_file` before anything else — it is your requirements, with the exact values to use verbatim. Its first line is the `Task {N}` heading; if it is not, stop and report NEEDS_CONTEXT.

## Context

{SCENE_SETTING_CONTEXT}

Work from: {WORKING_DIRECTORY}
```

**Placeholders:**
- `{N}` — Task number
- `{TASK_NAME}` — Task name from plan
- `{PLAN_PATH}` — the plan's absolute path
- `{START}`, `{END}` — the task's first and last line, from the ledger's `Plan map:`
- For a plan outside the repository, or one `git check-ignore <plan>` prints, replace the range paragraph with the task's complete text, pasted
- `{SCENE_SETTING_CONTEXT}` — Where this fits, dependencies, architectural context
- `{WORKING_DIRECTORY}` — Working directory path
