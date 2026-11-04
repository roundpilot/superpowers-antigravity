---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration

**Narration:** between tool calls, narrate at most one short line — the
ledger and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are the four named below, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

**Rulings, not stalls.** A running plan does not wait on a human. Conflicts,
ambiguities, plan defects, a cap you would have asked to exceed — decide
them. The spec is the binding authority, the plan is its argument, and your
judgment settles what neither answers. Record every decision in the ledger as
`Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep
going. A wrong ruling costs rework your human partner can see and undo; a
session parked on a question costs their whole day and buys nothing.

Four things stop you, and only these: an irreversible or destructive
operation; a security-sensitive action; a side effect outside this worktree
that norms say you ask about first (a merge, a push to a shared branch, a
publish); and a plan so broken that every path forward is a guess. For those,
stop and ask.

Your human partner may steer while the plan runs — a message, a comment on the plan or another artifact, stopping a subagent you dispatched, or, in subagent-driven development, an instruction sent straight to an implementer (a CLI `@` message) that its report mentions. That is their instruction, not your ruling: apply it, ledger it as `Task <N>: partner instruction: <one-liner>`, and rule only where it conflicts with work already finished. One that changes scope or asks you to stop — a stopped subagent is one — is handled like the four stops.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Partner chose inline, or no subagent tool?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Partner chose inline, or no subagent tool?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Partner chose inline, or no subagent tool?" -> "executing-plans" [label="yes"];
    "Partner chose inline, or no subagent tool?" -> "subagent-driven-development" [label="no"];
}
```

**vs. Executing Plans (inline):**
- Fresh subagent per task (no context pollution) instead of one context doing every task
- Review after each task (spec compliance + code quality) instead of only at the end
- Costs a fresh context per task and per review; inline costs one context plus one final reviewer
- Both run in this session, share the same plan workspace and ledger, and never pause between tasks

Plans come from **superpowers:writing-plans**. This skill executes one.

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "invoke_subagent TypeName: implementer" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
        "invoke_subagent TypeName: spec-reviewer" [shape=box];
        "Spec reviewer subagent confirms code matches spec?" [shape=diamond];
        "invoke_subagent TypeName: code-reviewer" [shape=box];
        "Code quality reviewer subagent approves?" [shape=diamond];
        "Fix loop (spec): resume implementer, scoped re-review (max 5 rounds/task)" [shape=box];
        "Fix loop (quality): resume implementer, scoped re-review (max 5 rounds/task)" [shape=box];
        "Update task.md artifact" [shape=box];
    }

    "Read plan, extract all tasks, create task.md artifact" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Dispatch final code reviewer subagent for entire implementation" [shape=box];
    "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

    "Read plan, extract all tasks, create task.md artifact" -> "invoke_subagent TypeName: implementer";
    "invoke_subagent TypeName: implementer" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Implementer subagent implements, tests, commits, self-reviews";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, commits, self-reviews" [label="no"];
    "Implementer subagent implements, tests, commits, self-reviews" -> "invoke_subagent TypeName: spec-reviewer";
    "invoke_subagent TypeName: spec-reviewer" -> "Spec reviewer subagent confirms code matches spec?";
    "Spec reviewer subagent confirms code matches spec?" -> "Fix loop (spec): resume implementer, scoped re-review (max 5 rounds/task)" [label="no"];
    "Fix loop (spec): resume implementer, scoped re-review (max 5 rounds/task)" -> "Spec reviewer subagent confirms code matches spec?" [label="round clean"];
    "Spec reviewer subagent confirms code matches spec?" -> "invoke_subagent TypeName: code-reviewer" [label="yes"];
    "invoke_subagent TypeName: code-reviewer" -> "Code quality reviewer subagent approves?";
    "Code quality reviewer subagent approves?" -> "Fix loop (quality): resume implementer, scoped re-review (max 5 rounds/task)" [label="no"];
    "Fix loop (quality): resume implementer, scoped re-review (max 5 rounds/task)" -> "Code quality reviewer subagent approves?" [label="round clean"];
    "Code quality reviewer subagent approves?" -> "Update task.md artifact" [label="yes"];
    "Update task.md artifact" -> "More tasks remain?";
    "More tasks remain?" -> "invoke_subagent TypeName: implementer" [label="yes"];
    "More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
    "Dispatch final code reviewer subagent for entire implementation" -> "Use superpowers:finishing-a-development-branch";
}
```

## Setup

Ensure the work happens in an isolated workspace: use
superpowers:using-git-worktrees to create one or verify the existing one.
Never start implementation on a main/master branch without your human
partner's explicit consent.

Approvals can pause an unattended run. If your commands run in a terminal sandbox, a commit may need to run outside it — the sandbox can keep `.git` read-only — and that waits for your human partner's approval unless an allow rule covers it; where their settings review commands or edits, more waits. Before Task 1, tell your human partner in one line what may wait for approval: the git commands you and your reviewers run on every task (`git rev-parse`, `git rev-list`, `git merge-base`, `git diff`, `git log`, `git status`), the plan's test commands, `git add` and `git commit`, and — where edits pause for review — every file edit. Never change their permission settings yourself. This is a notice, not a stop: start Task 1.

Conversation memory does not survive compaction. In real sessions,
controllers that lost their place have re-dispatched entire completed task
sequences — the single most expensive failure observed. Track progress in
a ledger file, not only in the task.md artifact.

- Each plan owns a workspace: a git-ignored directory under `<repo-root>/.superpowers/sdd/`, home to every file for THIS plan — its ledger. Another plan's directory is never yours to read or write. Resolve it at skill start:
  1. Write the plan's path the way the ledger names it: relative to the repository root (`git rev-parse --show-toplevel`), with forward slashes, or absolute if the plan lives outside the repository. Normalize a ledger's first line the same way before you compare it, and on Windows compare without regard to case.
  2. Try `.superpowers/sdd/<plan-basename>/`, then `<plan-basename>-<name of the plan's parent directory>/`, then that name with `-2`, `-3`, … appended. A candidate is yours if it has no `progress.md`, or if its `progress.md` first line names your plan; one whose first line names another plan belongs to that plan — try the next.
  3. Create and extend files here with your file tools, never with shell redirection: create `progress.md` with `write_to_file`, and append each ledger line with `replace_file_content` anchored on the ledger's current last line — never rewrite the whole ledger. If a directory is missing, create each level with the shell's own command and retry. Then, if `<repo-root>/.superpowers/.gitignore` does not exist, create it with the single line `*`.
  4. If the platform refuses to read or write the ledger (the IDE's strict mode hides git-ignored files), keep the ledger in the task.md artifact instead; if that is refused too, keep the ledger lines in your messages. Either way, tell your human partner at the start that another executor, or another conversation, cannot resume from it.
- Check for this plan's ledger at `<workspace>/progress.md`. If its first
  line names your plan file, tasks with a `Task <N>: complete` line are DONE
  — do not re-dispatch them; resume at the first task without one. A task
  whose last line is a fix round is mid-loop: resume the loop at the next
  round. A ledger whose first line names a different plan file — or a stray
  ledger at the old flat path `.superpowers/sdd/progress.md` — is another
  plan's progress: leave it in place and start your own, fresh.
- Create the ledger with its identity as the first line:
  `# SDD ledger — plan: <plan file path>`.
- The ledger is your recovery map: the commits it names exist in git even
  when your context no longer remembers creating them. After compaction,
  trust the ledger and `git log` over your own recollection.
- `git clean -fdx` will destroy the workspace (it's git-ignored scratch); if
  that happens, recover from `git log`.
- Each implementer dispatch gets a ledger line, in the same step as your other bookkeeping: `Task <N>: dispatched implementer <conversation ID> (base <base7>[, round <R>])` — the bracketed part only for a rounds 4-5 dispatch. When you kill an implementer yourself (rounds 4-5), ledger `Task <N>: killed implementer <conversation ID> (round <R> takeover)` in the same step as the new dispatch line. If a dispatch result shows no conversation ID, write `(id unavailable)` in its place; that task resumes by a fresh dispatch. A task whose last line is `dispatched` is in flight: list your subagents (`manage_subagents`, `Action: "list"`) and find that conversation. Running — wait for its report. Idle — its report was lost with your context, so ask it to repeat the report (`send_message`). Errored — dispatch a fresh implementer with the task text, telling it that commits after BASE are its predecessor's and that its first action is `git status`. Killed, with no kill line of yours for it — your human partner stopped it: that is their instruction, not a failure. Ledger `Task <N>: partner instruction: stopped implementer` and handle it like the four stops; never re-dispatch it on your own.

The roles ship as bundled agents — `implementer`, `implementer-flash`, `implementer-pro`, `spec-reviewer`, `code-reviewer`, `re-reviewer` and `final-reviewer` (defined in the plugin's `agents/` directory). No registration step: dispatch them by TypeName. Bundled agents are documented on Antigravity 2.0 and the CLI and observed working on 2.0; they are unverified in the IDE. If a dispatch is rejected with an unknown TypeName, dispatch it once more as `superpowers:<name>`. If that is rejected too, the plugin's agents are not being discovered — verify the plugin installation, then read the plugin's `agents/<name>.md` (`../../agents/<name>.md` from this skill's folder), dispatch the built-in `self` subagent with that file's body, below its closing `---`, pasted ahead of the prompt, and ledger `Setup: self subagent for <name> (bundled agent unavailable)`. If you have no subagent tool, or you cannot read the plugin's agent file, this skill cannot run here, and the method was your human partner's choice. Ask once with `ask_question` — at Setup if you have no subagent tool, or at the first dispatch that exhausts these steps, before any work on that task — whether to run the plan inline with superpowers:executing-plans (same workspace and ledger, one final review) or to stop so they can fix the installation. Ledger the answer as `Setup: <answer>`; for inline, load superpowers:executing-plans and continue from this ledger. A running plan never switches executors on its own.

**Workspace isolation per role:**

| Role | Workspace Mode | Why |
|------|---------------|-----|
| Implementer (any tier) | `Workspace: "inherit"` | Works in your checkout, one at a time, so its commits land on the working branch the reviewers read |
| Spec reviewer | `Workspace: "inherit"` | Read-only — only inspects code |
| Code reviewer | `Workspace: "inherit"` | Read-only — only inspects code |
| Re-reviewer | `Workspace: "inherit"` | Read-only — verifies the fix diff |
| Final reviewer | `Workspace: "inherit"` | Read-only — reviews the whole branch |

Read the plan once, extract all tasks with full text and context, and
create a `task.md` artifact tracking each task's status — it belongs with your other artifacts, never in the repository or under `scratch/`. If the plan names
a Spec, read that too: the spec is the authority the plan argues from, and
conflicts inside the plan resolve against it. A plan with no reachable spec
gets a ledger note saying so — rulings made without one are provisional.

### Pre-Flight Plan Review

Before dispatching Task 1, scan the plan once for conflicts, writing down
what you checked as you check it:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that the review rubric treats as a
  defect (a test that asserts nothing, verbatim duplication of a logic block)

The scan's output is a table, not a verdict. One row for every pair of tasks
that share a file or an interface: the two tasks, what one produces against
what the other consumes, and what you found. One row for every task: whether
its own text agrees with itself — the tests it specifies against the code it
specifies, the files it creates against the files it later touches. "The scan
is clean" without those rows is not a scan you ran.

Write the table to the ledger. Rule on everything you find before execution
begins — each finding against the plan text that mandates it — and record
each ruling in the ledger. If the scan is clean, proceed without comment.
Rule on each conflict it surfaces — the spec is the binding authority, the
plan is its argument — record the ruling beside its row, and dispatch
Task 1. The review loop remains the net for conflicts that only emerge from
implementation.

## Model Selection

Model tiers are set in each agent file's frontmatter (`model: flash|pro|inherit`). The four bundled roles live in the plugin's `agents/` directory and all ship `model: inherit` — the session's model governs. To differentiate tiers, add a workspace-scoped variant at `.agents/agents/<name>.md` first — this is the primary escalation path — or edit the plugin's bundled agent files directly; editing plugin (or global) agent files may require the user's Agent Non-Workspace File Access setting to be enabled. Neither `define_subagent` nor `invoke_subagent` takes a model argument.

Use the least powerful tier that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a flash-tier agent type. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture, design, and review tasks**: use a pro-tier agent type.

**Task complexity signals:**
- Touches 1-2 files with a complete spec → flash-tier agent type
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → pro-tier agent type

## The Task Loop

**Batch small same-shape work.** When the plan lists several tasks that are
each a small, independent edit of the same kind — the same one-line fix,
constant change, or field addition repeated across files — do not dispatch
one subagent per task. Compose ONE dispatch brief listing every file and
its change, send the whole batch to a single subagent, and review its diff
as one unit. Reserve one-dispatch-per-task for work that needs its own
judgment, its own tests, or its own review surface.

For each task, in plan order:

1. Record BASE (`git rev-parse HEAD`) before dispatching — the review range and fix-round diffs need it. Fill `implementer-prompt.md`'s dynamic template with the task's full text and scene-setting context, choose the implementer's tier by Model Selection (it sets the TypeName or the `Model` key), and dispatch: `invoke_subagent(Subagents: [{TypeName: "implementer", Role: "Implement Task <N>", Prompt: <filled template>, Workspace: "inherit"}])`.
2. Record the implementer's agent identity from the dispatch result (its conversation ID) — fix-loop rounds 1-3 resume this agent — and ledger the dispatch line (Setup).
3. When the implementer reports DONE, check the range (below), then run the two review stages in order: `spec-reviewer` first, then `code-reviewer` (dispatch templates in Prompt Templates below). Findings from either stage enter The Fix Loop.

**Check the range before every review dispatch** — each stage, each re-review, the final review: run `git rev-list --left-right --count <BASE>...<HEAD>` (`Cwd`: the repository root). `<HEAD>` is your checkout's `git rev-parse HEAD` once the implementer reports, or once you have committed its reported work. It must print `0` and then a number above `0`: a first number above `0` means HEAD does not descend from BASE; a second number of `0` means the range is empty. Either way, do not dispatch: find where the commits went first. In a fix round whose implementer committed nothing, the check fails by design: count the round with its findings NOT ADDRESSED and do not dispatch the re-review. A reviewer's `RANGE INVALID` reply is the same failure.

**Never:**
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make subagent read plan file (provide full text instead)
- **Start code quality review before spec compliance is ✅** (wrong order)

### Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Send the missing context via `send_message` — the idle implementer resumes with its context intact.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, resume or re-dispatch with more context
2. If the task requires more reasoning, raise the agent's tier — add a workspace-scoped variant at `.agents/agents/<name>.md` first, or edit the bundled agent's frontmatter to `model: pro` (may require Agent Non-Workspace File Access) — and re-dispatch
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, rule on the correction, ledger it, and re-dispatch with the ruling carried in the dispatch

**Never** ignore an escalation or force the same agent to retry without changes. If the implementer said it's stuck, something needs to change.

**Terminal error:** if `manage_subagents` `Action: "list"` shows the subagent in an error state (terminal failure — distinct from idle), it cannot be resumed: dispatch a fresh implementer with the task text and the last known state. A subagent shown as killed that you did not kill was stopped by your human partner — handle it as Setup's dispatch-identity rule says; do not re-dispatch it.

### Constructing Reviewer Prompts

Per-task reviews are task-scoped gates. The broad review happens once, at the
final whole-branch review. When you fill a reviewer template:

- Every reviewer prompt carries the range it reviews: BASE and HEAD (the fix base and HEAD for a re-review).
- Do not add open-ended directives like "check all uses" or "run race tests
  if useful" without a concrete, task-specific reason
- Do not ask a reviewer to re-run tests the implementer already ran on the
  same code — the implementer's report carries the test evidence
- Do not pre-judge findings for the reviewer — never instruct a reviewer to
  ignore or not flag a specific issue. If you believe a finding would be a
  false positive, let the reviewer raise it and adjudicate it in the review
  loop. If the prompt you are writing contains "do not flag," "don't treat X
  as a defect," "at most Minor," or "the plan chose" — stop: you are
  pre-judging, usually to spare yourself a review loop.
- The global-constraints block you hand the reviewer is its attention lens.
  Copy the binding requirements verbatim from the plan's Global Constraints
  section or the spec: exact values, exact formats, and the stated
  relationships between components.
- A dispatch prompt describes one task, not the session's history. Do not
  paste accumulated prior-task summaries ("state after Tasks 1-3") into
  later dispatches. A fresh subagent needs its task, the interfaces it
  touches, and the global constraints. Nothing else.
- Spec-compliance failures (from the spec-reviewer) are always blocking —
  the implementer must fix them before proceeding to code quality review.
  The severity triage above (Critical/Important/Minor) applies to the
  code-quality reviewer's findings.
- A finding labeled plan-mandated — or any finding that conflicts with
  what the plan's text requires — is yours to rule on: weigh the finding
  against the plan text, decide with the spec as the binding authority, and
  ledger the ruling before you act on it. Do not dismiss the finding because
  the plan mandates it, and do not dispatch a fix that contradicts the plan
  without a recorded ruling.
- When a later dispatch touches an area with a parked finding, carry a
  one-line pointer to that ledger entry in the dispatch prompt.

### The Fix Loop

When either reviewer returns findings, the same loop runs regardless of
stage. **Record the implementer's conversation ID at dispatch time — the
loop depends on it.**

**Rounds 1–3 — resume the implementer.** `send_message` the open findings
verbatim to the implementer's conversation. The idle implementer re-awakens
with its full context — the task, the code it wrote, its test knowledge —
and fixes without re-reading anything. Every fix reply must name the
covering tests it re-ran and show their results; do not dispatch the
re-review until it does. Record Minor findings in the ledger as you go
(`Task N: minor (deferred): <one-liner>`) and point the final whole-branch
review at that list — a roll-up nobody reads is a silent discard.

**Every round ends with a scoped re-review.** Dispatch the `re-reviewer`
(see `re-review-prompt.md`) with the findings and the fix range. It
verdicts each finding ADDRESSED or NOT ADDRESSED and checks only the fix
diff for new breakage — it cannot wander into a fresh full review.
Out-of-scope observations go to the ledger, never back into the loop.

**Rounds 4–5 — fresh implementer, takeover framing.** If three resumed
rounds haven't converged, the original implementer's approach may be the
problem. Kill it (`manage_subagents`, ledgering the kill as Setup says), dispatch a fresh `implementer`
whose Prompt carries: the task text, the open findings, and this framing:
"A prior implementer attempted this task [N] times; you own it now."
followed by the prior implementer's last report. The task's commits are
already on the working branch, so it continues from them. Its first action
is `git status`: a killed implementer can leave uncommitted edits, which it
builds on or reports — it never discards them.

**Round counting is shared per task, across both stages.** Append
`Task <N>: fix round <R>/5 (<stage>: <one-line summary>)` to the ledger
each round.

**At the cap — adjudicate.** After round 5, stop dispatching. For each
open finding, rule:
- **Contested** (implementer and reviewer disagree on whether it's real) —
  park it: ledger the finding and your ruling as
  `Task <N>: parked — <finding> — Ruling: <why the code stands>`.
- **Real but not load-bearing** for this task — park it the same way; the
  final review triages it.
- **Real and load-bearing** — a later task builds on it, or it reveals a
  plan defect: rule on the smallest change that unblocks the dependent work,
  ledger it as `Task <N>: Ruling: <finding> — <what you decided and why>`,
  and carry it into the next task's dispatch. Parking a structural failure
  silently lets every dependent task build on it. Stop only when the defect
  leaves every path forward a guess.

Adjudicate only at the cap. Never fix findings yourself in the controller
session — controller fixes pollute your context and skip review.

## Async Operations

### Background Task Management

Implementers wait for their own long runs and collect them before they report (see `agents/implementer.md`, Long-Running Commands); an implementer's turn ending is what reaches you as its report.

### Agent Communication

Use `send_message` to communicate with subagents — running or idle. An idle (finished, not killed or errored) subagent re-awakens on receipt and retains its full context.

**Answering questions mid-flight:**
- When an implementer asks a question, use `send_message` with the implementer's conversation ID — this works whether it's still running or has gone idle
- Don't re-dispatch a new subagent just to answer a question — the original implementer has context

**Providing additional context:**
- If you realize an implementer needs more information after dispatch, use `send_message` to send it
- The implementer receives it as a message and can incorporate it into their work

**When to use `send_message` vs. re-dispatch:**
- Subagent (running or idle) needs info → `send_message` — an idle subagent resumes with its context intact
- Subagent reported NEEDS_CONTEXT → send the missing context via `send_message`; re-dispatch a fresh subagent only if the original was killed or in an error state
- Subagent reported BLOCKED → assess blocker, possibly resume with more context via `send_message`, break the task into smaller pieces, or dispatch a more capable custom agent type

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

### Timeout Protection

Use `schedule` as a safety net for complex tasks:

```dot
digraph timeout {
    "Dispatch implementer" [shape=box];
    "Set one-shot timer" [shape=box];
    "Timer fires" [shape=box];
    "Implementer already responded?" [shape=diamond];
    "Treat as no-op reminder, move on" [shape=box];
    "Check subagent status and intervene" [shape=box];

    "Dispatch implementer" -> "Set one-shot timer";
    "Set one-shot timer" -> "Timer fires" [label="wait"];
    "Timer fires" -> "Implementer already responded?";
    "Implementer already responded?" -> "Treat as no-op reminder, move on" [label="yes"];
    "Implementer already responded?" -> "Check subagent status and intervene" [label="no"];
}
```

- Set a one-shot timer when dispatching implementers for complex tasks (5 minutes for standard tasks, 10 for complex ones)
- If the timer fires before the implementer responds, check status and intervene if needed
- The timer's Prompt fires unconditionally at the scheduled time — if the implementer already responded, treat the firing as a no-op reminder and move on; no cancellation is documented or needed

**For test suites expected to take 5+ minutes**, use a recurring schedule instead of a one-shot timer:
```
schedule(CronExpression: "*/2 * * * *", MaxIterations: "5", Prompt: "Check implementer status for Task N")
```

### Subagent Monitoring

Use `manage_subagents` to track running subagents:

- `Action: "list"` — check which subagents are still running before dispatching the next task
- `Action: "kill"` — terminate stuck subagents that haven't responded after timeout

Don't poll in a loop — the system notifies you when subagents complete. Use `manage_subagents` only when you need an explicit status check (e.g., before cleanup or when a timer fires).

## Final Review

After all tasks are complete, dispatch a final code-reviewer subagent for
the entire implementation — the one whole-branch review that per-task
reviews don't cover.

- If the final whole-branch review returns findings, dispatch ONE fix
  subagent (`implementer`, `Workspace: "inherit"`) with the complete
  findings list — not one fixer per finding.
- Then run exactly one scoped re-review of the fix wave: dispatch the
  `re-reviewer` (see `re-review-prompt.md`) with the findings and the fix
  range FIX_BASE..HEAD, where FIX_BASE is the HEAD the final review saw.
  The fix wave's commits, nothing earlier.
  Adjudicate any residual findings as in the task loop's breaker: park with
  rulings, or rule on the load-bearing ones and ledger what you decided.
  Only the four classes above stop you here. There is no second fix wave —
  residual load-bearing findings surface to your human partner when
  **superpowers:finishing-a-development-branch** presents the options.

## Finish

Before you delete anything, collect every ledger line containing `Ruling:` —
preflight rulings, parked findings, breaker adjudications, all of them — into
your final message under "Rulings I made", in the order you made them, each
with what it costs if wrong. The list is exhaustive: if the ledger holds a
ruling, the list holds it. That list is the only place the decisions you
took on your human partner's behalf reach them — they read it and rework
whatever you got wrong. A ruling that dies with the workspace was a decision
made in secret.

When the final whole-branch review is clean and its fixes are merged,
delete this plan's workspace — the git history is the record now. Sibling
directories belong to other plans; leave them alone.

Then hand off to **superpowers:finishing-a-development-branch** to complete
the branch.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Close enough on spec compliance" | Reviewer found spec gaps = not done. Fix or hit the cap and adjudicate — those are the only exits. |
| "I'll fix it myself, dispatching is overhead" | Controller fixes pollute your context and skip review. Resume the implementer with `send_message`. |
| "One more round will converge" | Past the cap, rounds don't converge — the failure is structural. Adjudicate and route. |
| "The reviewer will just find something new anyway" | Scoped re-reviews verify fixes; they cannot wander. New findings on untouched code go to the ledger, not the loop. |
| "This finding is obviously wrong, I'll drop it" | You adjudicate only at the cap, and every ruling is a ledger entry. Silent discards are forbidden. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "Reviews slow the loop down" | The loop without reviews is just unverified churn. Reviews are the loop's brakes and steering. |
| "Ledger bookkeeping is overhead" | The ledger is what survives compaction. Controllers without one have re-dispatched entire completed task sequences. |

## Prompt Templates

- `implementer-prompt.md` (located in the `subagent-driven-development` skill directory) — dynamic dispatch template — the static role lives in `agents/implementer.md`
- `spec-reviewer-prompt.md` (located in the `subagent-driven-development` skill directory) — dynamic dispatch template — the static role lives in `agents/spec-reviewer.md`
- `code-quality-reviewer-prompt.md` (located in the `subagent-driven-development` skill directory) — dynamic dispatch template — the static role lives in `agents/code-reviewer.md`
- `re-review-prompt.md` (located in the `subagent-driven-development` skill directory) — dynamic dispatch template — the static role lives in `agents/re-reviewer.md`
- `code-reviewer.md` (located in the `requesting-code-review` skill directory) — dynamic dispatch template — the static role lives in `agents/code-reviewer.md`

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file once: docs/superpowers/plans/feature-plan.md]
[Extract all 5 tasks with full text and context]
[Create task.md artifact with all tasks]

Task 1: Hook installation script

[Get Task 1 text and context (already extracted)]
[invoke_subagent TypeName: "implementer" with task text + context in Prompt]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/superpowers/hooks/)"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed

[invoke_subagent TypeName: "spec-reviewer"]
Spec reviewer: ✅ Spec compliant - all requirements met, nothing extra

[invoke_subagent TypeName: "code-reviewer"]
Code reviewer: Strengths: Good test coverage, clean. Issues: None. Approved.

[Update task.md: mark Task 1 complete]

Task 2: Recovery modes

[Get Task 2 text and context (already extracted)]
[invoke_subagent TypeName: "implementer" with task text + context in Prompt]

Implementer: [No questions, proceeds]
Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Committed

[invoke_subagent TypeName: "spec-reviewer"]
Spec reviewer: ❌ Issues:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)

[send_message to implementer conversation: findings verbatim]
Implementer (resumed): Removed --json flag, added progress reporting. Re-ran test_recovery.py: 9/9 passing.
[invoke_subagent TypeName: "re-reviewer" — findings + fix range]
Re-reviewer: Both findings ADDRESSED. No new breakage in fix diff.
[Ledger: Task 2: fix round 1/5 (spec: json flag + progress reporting)]

[invoke_subagent TypeName: "code-reviewer"]
Code reviewer: Strengths: Solid. Issues (Important): Magic number (100)

[send_message to implementer conversation: findings verbatim]
Implementer (resumed): Extracted PROGRESS_INTERVAL constant. Re-ran full suite: 9/9 passing.
[invoke_subagent TypeName: "re-reviewer" — findings + fix range]
Re-reviewer: Finding ADDRESSED. No new breakage in fix diff.
[Ledger: Task 2: fix round 2/5 (quality: magic number extraction)]

[Update task.md: mark Task 2 complete]

...

[After all tasks]
[Dispatch final code-reviewer]
Final reviewer: All requirements met, ready to merge

Done!
```
