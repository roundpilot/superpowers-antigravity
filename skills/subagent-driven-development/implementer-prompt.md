# Implementer Dispatch Template

This role ships as the bundled `implementer` agent (`agents/implementer.md`) — no
registration needed. Fill the template below and dispatch:
`invoke_subagent(Subagents: [{TypeName: "implementer", Role: "<role for this task>", Prompt: <filled template>, Workspace: "inherit"}])`

## Dynamic Prompt Template

Pass this as the `Prompt` argument when calling `invoke_subagent`. Replace placeholders with actual values.

```
You are implementing Task {N}: {TASK_NAME}

## Task Description

{FULL_TASK_TEXT}

## Context

{SCENE_SETTING_CONTEXT}

Work from: {WORKING_DIRECTORY}
```

**Placeholders:**
- `{N}` — Task number
- `{TASK_NAME}` — Task name from plan
- `{FULL_TASK_TEXT}` — Complete task text from plan (paste it, don't make subagent read file)
- `{SCENE_SETTING_CONTEXT}` — Where this fits, dependencies, architectural context
- `{WORKING_DIRECTORY}` — Working directory path
