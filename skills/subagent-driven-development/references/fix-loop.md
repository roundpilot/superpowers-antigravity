# The Fix Loop

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
problem. Kill it (`manage_subagents`, ledgering the kill as Setup says), dispatch a fresh implementer one tier up (Model Selection)
whose Prompt carries: the task text, the open findings, and this framing:
"A prior implementer attempted this task [N] times; you own it now."
followed by the prior implementer's last report. The task's commits are
already on the working branch, so it continues from them. Its first action
is `git status`: a killed implementer can leave uncommitted edits, which it
builds on or reports — it never discards them.

**Round counting is shared per task, across both stages.** After each
round, append to the ledger:
`Task <N>: fix round <R>/5 (<stage>: <X> addressed, <Y> open — <one-liners>; commits <a7>..<b7>)`

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
