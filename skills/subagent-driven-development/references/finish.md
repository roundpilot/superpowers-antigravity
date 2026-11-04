# Finish

Before you delete anything, collect every ledger line containing `Ruling:` —
preflight rulings, parked findings, breaker adjudications, all of them — into
your final message under "Rulings I made", in the order you made them, each
with what it costs if wrong. The list is exhaustive: if the ledger holds a
ruling, the list holds it. That list, and the walkthrough artifact that
copies it, are the only places the decisions you took on your human
partner's behalf reach them — they read it and rework whatever you got
wrong. A ruling that dies with the workspace was a decision made in secret.

Then, still before you delete anything, write the walkthrough: `write_to_file` as an artifact — with your other artifacts, never into the repository — with `IsArtifact: true` and, in `ArtifactMetadata`, `ArtifactType: "walkthrough"`, `RequestFeedback: false` and `UserFacing: true`. It holds what was built (one line per task, from the ledger's completion lines), how the final review ran (the bundled reviewer or a `self` subagent) and what the final review and its fix wave fixed, and the list above, copied verbatim; embed screenshots or recordings and link key changed files where they help. It asks for nothing: superpowers:finishing-a-development-branch presents the choices.

When the final whole-branch review is clean and its fixes are merged,
delete this plan's workspace — the git history is the record now. Sibling
directories belong to other plans; leave them alone.

Then hand off to **superpowers:finishing-a-development-branch** to complete
the branch.
