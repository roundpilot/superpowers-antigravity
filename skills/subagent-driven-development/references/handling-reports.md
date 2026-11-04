# Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

An implementer — a task's, a fix round's, or the final fixer — that reports `commit not made` left its work uncommitted in your checkout. Run `git status`: if it shows changed files the report does not name, commit nothing and ask the implementer about them (`send_message`). Otherwise stage exactly the reported files and commit them yourself with the plan's commit message — committing reported work is not a code fix. Ledger `Task <N>: Ruling: controller committed <files> — implementer's commit could not run — cost if wrong: one amend`, then run the range check.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Send the missing context via `send_message` — the idle implementer resumes with its context intact.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, resume or re-dispatch with more context
2. If the task requires more reasoning, re-dispatch one tier up (Model Selection)
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, rule on the correction, ledger it, and re-dispatch with the ruling carried in the dispatch

**Never** ignore an escalation or force the same agent to retry without changes. If the implementer said it's stuck, something needs to change.

**Terminal error:** if `manage_subagents` `Action: "list"` shows the subagent in an error state (terminal failure — distinct from idle), it cannot be resumed: dispatch a fresh implementer with the task text and the last known state. A subagent shown as killed that you did not kill was stopped by your human partner — handle it as Setup's dispatch-identity rule says; do not re-dispatch it.
