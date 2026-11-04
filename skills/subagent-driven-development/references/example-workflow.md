# Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file once: docs/superpowers/plans/feature-plan.md]
[Extract all 5 tasks with full text and context]
[Create task.md artifact with all tasks]

Task 1: Hook installation script

[Get Task 1 text and context (already extracted)]
[Record BASE; invoke_subagent TypeName: "implementer" with task + context in Prompt]
[Ledger: Task 1: dispatched implementer 3f9a2c1e (base a1b2c3d)]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/superpowers/hooks/)"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed

[Range check BASE...HEAD → 0 1]
[invoke_subagent TypeName: "spec-reviewer"]
Spec reviewer: ✅ Spec compliant - all requirements met, nothing extra

[invoke_subagent TypeName: "code-reviewer"]
Code reviewer: Strengths: Good test coverage, clean. Issues: None. Approved.

[Ledger: Task 1: complete (commits a1b2c3d..d4e5f6a, review clean)]
[Update task.md: mark Task 1 complete]

Task 2: Recovery modes

[Get Task 2 text and context (already extracted)]
[Record BASE; invoke_subagent TypeName: "implementer" with task + context in Prompt]
[Ledger: Task 2: dispatched implementer 7d41b0aa (base d4e5f6a)]

Implementer: [No questions, proceeds]
Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Committed

[Range check BASE...HEAD → 0 1]
[invoke_subagent TypeName: "spec-reviewer"]
Spec reviewer: ❌ Issues:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)

[send_message to implementer conversation: findings verbatim]
Implementer (resumed): Removed --json flag, added progress reporting. Re-ran test_recovery.py: 9/9 passing.
[invoke_subagent TypeName: "re-reviewer" — findings + fix range]
Re-reviewer: Both findings ADDRESSED. No new breakage in fix diff.
[Ledger: Task 2: fix round 1/5 (spec: 2 addressed, 0 open — json flag, progress reporting; commits d4e5f6a..b7c8d9e)]

[invoke_subagent TypeName: "code-reviewer"]
Code reviewer: Strengths: Solid. Issues (Important): Magic number (100)

[send_message to implementer conversation: findings verbatim]
Implementer (resumed): Extracted PROGRESS_INTERVAL constant. Re-ran full suite: 9/9 passing.
[invoke_subagent TypeName: "re-reviewer" — findings + fix range]
Re-reviewer: Finding ADDRESSED. No new breakage in fix diff.
[Ledger: Task 2: fix round 2/5 (quality: 1 addressed, 0 open — magic number; commits b7c8d9e..c0ffee1)]

[Ledger: Task 2: complete (commits d4e5f6a..c0ffee1, review clean)]
[Update task.md: mark Task 2 complete]

...

[After all tasks]
[Range check MERGE_BASE...HEAD → 0 7; dispatch final-reviewer]
Final reviewer: All requirements met. Deferred minors triaged: none block merge.

[Write walkthrough artifact]
[Delete this plan's workspace — the record now lives in git]

Done! Using superpowers:finishing-a-development-branch.
```
