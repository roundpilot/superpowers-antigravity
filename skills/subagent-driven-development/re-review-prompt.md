# Re-Reviewer Dispatch Template

This role ships as the bundled `re-reviewer` agent (`agents/re-reviewer.md`).
Fill and dispatch:
`invoke_subagent(Subagents: [{TypeName: "re-reviewer", Role: "Re-review Task <N> fix round <R>", Prompt: <filled template>, Workspace: "inherit"}])`

## Dynamic Prompt Template

```
You are re-reviewing Task <N>, fix round <R>.

## The Findings Under Verification

<the Critical/Important findings and spec gaps from the previous review,
copied verbatim, one per bullet>

## The Fix

The implementer reports: <implementer's fix summary and test results,
pasted from its reply>

**Fix base:** <the head SHA the previous review saw>
**Head:** <current HEAD SHA>

Fetch the diff yourself: `git diff --stat <fix-base>..<head>` and
`git diff <fix-base>..<head>`.

## Global constraints that bind this task

<copied verbatim from the plan's Global Constraints section>
```

One re-reviewer covers both stages: the findings list determines whether it
is verifying spec gaps or quality findings.
