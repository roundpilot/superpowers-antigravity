<!--
BEFORE SUBMITTING: Read every word of this template. PRs that leave
sections blank, contain multiple unrelated changes, or show no evidence
of human involvement will be closed without review.
-->

## Who is submitting this PR? (required)
<!-- Who are you, and what did your human partner ask you to do? As close
     to their words as you can get. If you wrote this PR by hand with no
     agent, say so. -->

## Human-authored summary (required, under 200 words)
<!-- A human writes this section, in their own words: why this PR exists
     and what they checked before approving it. If an agent is submitting,
     that means your human partner, not you. -->

## What problem are you trying to solve?
<!-- Describe the specific problem you encountered. If this was a session
     issue, include: what you were doing, what went wrong, the model's
     exact failure mode, and ideally a transcript or session log.

     "Improving" something is not a problem statement. What broke? What
     failed? What was the user experience that motivated this? -->

## What does this PR change?
<!-- 1-3 sentences. What, not why — the "why" belongs above. -->

## Is this change appropriate for the core library?
<!-- Superpowers core contains general-purpose skills and infrastructure
     that benefit all users. Ask yourself:

     - Would this be useful to someone working on a completely different
       kind of project than yours?
     - Is this project-specific, team-specific, or tool-specific?
     - Does this integrate or promote a third-party service?

     If your change is a new skill for a specific domain, workflow tool,
     or third-party integration, it belongs in its own plugin — not here.
     See the plugin development docs for how to publish it separately. -->

## What alternatives did you consider?
<!-- What other approaches did you try or evaluate before landing on this
     one? Why were they worse? If you didn't consider alternatives, say so
     — but know that's a red flag. -->

## Does this PR contain multiple unrelated changes?
<!-- If yes: stop. Split it into separate PRs. Bundled PRs will be closed.
     If you believe the changes are related, explain the dependency. -->

## Existing PRs
- [ ] I have reviewed all open AND closed PRs for duplicates or prior art
- Related PRs: <!-- #number, #number, or "none found" -->

<!-- If a related closed PR exists, explain what's different about your
     approach and why it should succeed where the other didn't. -->

## Environment tested

| Antigravity product (2.0 app / IDE / CLI) | Antigravity version | Model | Model version/ID |
|-------------------------------------------|---------------------|-------|------------------|
|                                           |                     |       |                  |

## Tested on Antigravity (required if this PR changes skills, rules, agents or packaging)

<!-- On each Antigravity product your change affects, open a clean conversation
     and send exactly "Let's make a react todo list". A working install reads
     the brainstorming skill before writing any file.

     CLI: run `agy -p "Let's make a react todo list" --output-format stream-json`
     and paste the `view_file` tool_info line whose AbsolutePath ends in
     brainstorming/SKILL.md.

     2.0 app and IDE: say, or attach a screenshot showing, that the
     conversation read brainstorming/SKILL.md before it wrote any file.

     This fork supports Antigravity only; support for other agents belongs upstream. -->

## Evaluation
- What was the initial prompt you (or your human partner) used to start
  the session that led to this change?
- How many eval sessions did you run AFTER making the change?
- How did outcomes change compared to before the change?

<!-- "It works" is not evaluation. Describe the before/after difference
     you observed across multiple sessions. -->

## Rigor

- [ ] If this is a skills change: I used `superpowers:writing-skills` and
      completed adversarial pressure testing (paste results below)
- [ ] This change was tested adversarially, not just on the happy path
- [ ] I did not modify carefully-tuned content (Red Flags table,
      rationalizations, "human partner" language) without extensive evals
      showing the change is an improvement

<!-- If you changed wording in skills that shape agent behavior, show your
     eval methodology and results. These are not prose — they are code. -->

## Human review
- [ ] A human has reviewed the COMPLETE proposed diff before submission

<!--
STOP. If the checkbox above is not checked, do not submit this PR.

PRs will be closed without review if they:
- Show no evidence of human involvement
- Contain multiple unrelated changes
- Promote or integrate third-party services or tools
- Submit project-specific or personal configuration as core changes
- Leave required sections blank or use placeholder text
- Modify behavior-shaping content without eval evidence
-->
