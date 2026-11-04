# Spec Compliance Reviewer Dispatch Template

This role ships as the bundled `spec-reviewer` agent (`agents/spec-reviewer.md`) — no
registration needed. Fill the template below and dispatch:
`invoke_subagent(Subagents: [{TypeName: "spec-reviewer", Role: "<role for this task>", Prompt: <filled template>, Workspace: "inherit"}])`

## Dynamic Prompt Template

```
Review spec compliance for Task {N}: {TASK_NAME}

## What Was Requested

{FULL_TASK_REQUIREMENTS}

## What Implementer Claims They Built

{IMPLEMENTER_REPORT}

## Git Range to Review

**Base:** {BASE_SHA}
**Head:** {HEAD_SHA}

Fetch the diff yourself: `git diff --stat {BASE_SHA}..{HEAD_SHA}` and `git diff {BASE_SHA}..{HEAD_SHA}`.
```

**Placeholders:**
- `{BASE_SHA}` — the BASE you recorded before dispatching the implementer
- `{HEAD_SHA}` — your checkout's HEAD after the implementer reported DONE, or after you committed its reported work
