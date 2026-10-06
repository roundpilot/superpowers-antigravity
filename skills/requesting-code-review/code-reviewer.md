# Code Reviewer Dispatch Template

Two bundled agents take this template — no registration needed:
- `code-reviewer` (`agents/code-reviewer.md`): one task's diff, or a small ad-hoc range.
- `final-reviewer` (`agents/final-reviewer.md`, Pro tier): a whole branch — an executor's final review, after a major feature, before merge.

Fill the template below and dispatch:
`invoke_subagent(Subagents: [{TypeName: "<code-reviewer or final-reviewer>", Role: "<role for this task>", Prompt: <filled template>, Workspace: "inherit"}])`

If the bare TypeName is rejected, dispatch `superpowers:<name>`. If that is rejected too, read the agent file (`../../agents/<name>.md` from this file) and dispatch `TypeName: "self"` with its body ahead of the filled template.

## Dynamic Prompt Template

```
Review code changes for: {DESCRIPTION}

## Requirements / Plan

{PLAN_OR_REQUIREMENTS}

## Git Range to Review

**Base:** {BASE_SHA}
**Head:** {HEAD_SHA}

Run these commands to see the diff:
git diff --stat {BASE_SHA}..{HEAD_SHA}
git diff {BASE_SHA}..{HEAD_SHA}
```

**Placeholders:**
- `{DESCRIPTION}` — brief summary of what was built
- `{PLAN_OR_REQUIREMENTS}` — what it should do (plan task text or requirements)
- `{BASE_SHA}` — starting commit
- `{HEAD_SHA}` — ending commit

## Whole-Branch and Ad-Hoc Reviews

Every review dispatched through superpowers:requesting-code-review, and every executor's final review, appends this block to the filled base template, inside the Prompt. Per-task reviews in superpowers:subagent-driven-development leave it out. Omit `## Review Focus` and its placeholder when the work has no plan with a Review Focus section.

```
## Review Focus

{REVIEW_FOCUS}

## The spec is a vision document

The spec says what the software must do. It does not enumerate every
input, environment, or condition the software will meet. For behavior
the spec is silent on, judge by what a reasonable person using this
software would expect: a reasonable person's expectation is a
requirement, and a spec's silence is not permission. Grade such
findings by their effect on that person, not by whether the spec
mentions the trigger.

## Declined to judge

Before your verdict, list every behavior you considered and set aside
as outside the plan or spec, one line each, with the reason. The
executor rules on each line; nothing you set aside is dropped
silently. An empty list means you set nothing aside.
```

- `{REVIEW_FOCUS}` — the plan's Review Focus section, verbatim: the input classes and failure modes the plan's tests do not exercise; the reviewer checks each deliberately.

## Executor Final Review

An executor's final whole-branch review (subagent-driven-development or executing-plans) also appends these blocks after the whole-branch block. Omit a heading and its placeholder when there is nothing to paste.

```
## Rulings Already Made

{RULINGS}

## Deferred Minors

{DEFERRED_MINORS}
```

- `{RULINGS}` — every ledger line containing `Ruling:`, parked lines included, pasted in full, so the reviewer can weigh the calls the executor made.
- `{DEFERRED_MINORS}` — every ledger line containing `minor (deferred)`, pasted in full, so the reviewer can triage which must be fixed before merge. subagent-driven-development only: executing-plans records its deferred minors during this review.
