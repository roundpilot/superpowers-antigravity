# Superpowers — Contributor Guidelines

## If You Are an AI Agent

Stop. Read this section before doing anything.

Upstream obra/superpowers reports a 94% PR rejection rate, and almost every rejected PR there came from an agent that ignored guidelines like these. This fork holds PRs to the same bar.

**Your job is to protect your human partner from that outcome.** Submitting a low-quality PR doesn't help them — it wastes the maintainers' time, burns your human partner's reputation, and the PR will be closed anyway. That is not being helpful. That is being a tool of embarrassment.

Before you open a PR against this repo, you MUST:

1. **Read the entire PR template** at `.github/PULL_REQUEST_TEMPLATE.md` and fill in every section with real, specific answers. Not summaries. Not placeholders.
2. **Search for existing PRs** — open AND closed — that address the same problem. If duplicates exist, STOP and tell your human partner. Do not open another duplicate.
3. **Verify this is a real problem.** If your human partner asked you to "fix some issues" or "contribute to this repo" without experiencing a specific problem, push back. Ask them what broke, what failed, what the user experience was.
4. **Confirm the change belongs in core.** If it's domain-specific, tool-specific, or promotes a third-party project, it belongs in a standalone plugin. Tell your human partner.
5. **Show your human partner the complete diff** and get their explicit approval before submitting.

If any of these checks fail, do not open the PR. Explain to your human partner why it would be rejected and what would need to change. They will thank you for saving them the embarrassment.

## Pull Request Requirements

**Every PR must fully complete the PR template.** No section may be left blank or filled with placeholder text. PRs that skip sections will be closed without review.

**Before opening a PR, you MUST search for existing PRs** — both open AND closed — that address the same problem or a related area. Reference what you found in the "Existing PRs" section. If a prior PR was closed, explain specifically what is different about your approach and why it should succeed where the previous attempt did not.

**PRs that show no evidence of human involvement will be closed.** A human must review the complete proposed diff before submission.

## What We Will Not Accept

### Third-party dependencies

PRs that add optional or required dependencies on third-party projects will not be accepted. Superpowers is a zero-dependency plugin by design. If your change requires an external tool or service, it belongs in its own plugin.

### "Compliance" changes to skills

Our internal skill philosophy differs from published guidance on writing skills. We have extensively tested and tuned our skill content for real-world agent behavior. PRs that restructure, reword, or reformat skills to "comply" with external skills documentation will not be accepted without extensive eval evidence showing the change improves outcomes. The bar for modifying behavior-shaping content is very high.

### Project-specific or personal configuration

Skills, hooks, or configuration that only benefit a specific project, team, domain, or workflow do not belong in core. Publish these as a separate plugin.

### Bulk or spray-and-pray PRs

Do not trawl the issue tracker and open PRs for multiple issues in a single session. Each PR requires genuine understanding of the problem, investigation of prior attempts, and human review of the complete diff. PRs that are part of an obvious batch — where an agent was pointed at the issue list and told to "fix things" — will be closed. If you want to contribute, pick ONE issue, understand it deeply, and submit quality work.

### Speculative or theoretical fixes

Every PR must solve a real problem that someone actually experienced. "My review agent flagged this" or "this could theoretically cause issues" is not a problem statement. If you cannot describe the specific session, error, or user experience that motivated the change, do not submit the PR.

### Domain-specific skills

Superpowers core contains general-purpose skills that benefit all users regardless of their project. Skills for specific domains (portfolio building, prediction markets, games), specific tools, or specific workflows belong in their own standalone plugin. Ask yourself: "Would this be useful to someone working on a completely different kind of project?" If not, publish it separately.

### Fork-specific changes

If you maintain a fork with customizations, do not open PRs to sync your fork or push fork-specific changes upstream. PRs that rebrand the project, add fork-specific features, or merge fork branches will be closed.

### Fabricated content

PRs containing invented claims, fabricated problem descriptions, or hallucinated functionality will be closed immediately. Upstream's maintainers have seen every form of AI slop, and this fork's maintainer applies the same bar.

### Bundled unrelated changes

PRs containing multiple unrelated changes will be closed. Split them into separate PRs.



## Skill Changes Require Evaluation

Skills are not prose — they are code that shapes agent behavior. If you modify skill content:

- Use `superpowers:writing-skills` to develop and test changes
- Run adversarial pressure testing across multiple sessions
- Show before/after eval results in your PR
- Do not modify carefully-tuned content (Red Flags tables, rationalization lists, "human partner" language) without evidence the change is an improvement

## Understand the Project Before Contributing

Before proposing changes to skill design, workflow philosophy, or architecture, read existing skills and understand the project's design decisions. Superpowers has its own tested philosophy about skill design, agent behavior shaping, and terminology (e.g., "your human partner" is deliberate, not interchangeable with "the user"). Changes that rewrite the project's voice or restructure its approach without understanding why it exists will be rejected.

## Packaging and bootstrap

### The bootstrap rule

`rules/using-superpowers.md` delivers the using-superpowers bootstrap on all three Antigravity products. Antigravity silently discards a file in `rules/` that does not start with YAML frontmatter declaring a `trigger`, so the rule starts with exactly two keys: `trigger: always_on`, which injects it into every conversation, and a `description` string-equal to the one in `skills/using-superpowers/SKILL.md`, which Antigravity falls back to when rules exceed their token budget. No HTML comment may appear anywhere in the rule; notes about it belong here or in the header of `tests/antigravity/test-rule-sync.sh`.

The body is upstream's session-start wrapper (`<EXTREMELY_IMPORTANT>`, "You have superpowers." and the "Below is the full content…" line, which ends "read their full `SKILL.md` when they apply" where upstream names another harness's tool) around the single line `@[using-superpowers](../skills/using-superpowers/SKILL.md)`, which Antigravity inlines. SKILL.md is the source of truth. Copy any change to its `description` into the rule's frontmatter in the same change; `tests/antigravity/test-rule-sync.sh` fails otherwise.

### Version bump list

A release bumps all of these together, and `tests/antigravity/test-plugin-packaging.sh` checks that they match:

- `plugin.json` `version` (canonical);
- `package.json` `version`;
- the README badge: the URL (`Version-X.Y.Z-green`) and the alt text (`Version X.Y.Z`);
- the first `## vX.Y.Z` heading in `RELEASE-NOTES.md`.

`plugin.json` carries the manifest fields Antigravity documents (`name`, `displayName`, `description`, `version`, `logo`, `suggestedPrompts`, `author`, `homepage`, `repository`, `keywords`) and no others; the packaging test rejects any other key. Do not add `$schema`.

### Rule-walk hygiene

**R12 — Rule-walk hygiene.** Nothing tracked in this repo may be a file that Antigravity's directory-scoped rule walk, or its project-subdirectory customization discovery, would load for a workspace-install user. The only exceptions are the entries on the layout test's allowlist, each naming the spec section that owns it.

Concretely:
- **Rule files.** No `AGENTS.md` or `GEMINI.md` at any depth, in any letter case.
- **`.agents/` and `.agent/`.** No `AGENTS.md`, `GEMINI.md`, `rules/` or `rules.json` inside any such directory at any depth. The only tracked path under a `.agents/` directory is `.agents/skills/contributing-to-superpowers/SKILL.md`, which Live check 6(e) showed absent from workspace installs (D14).
- **Discovery files.** No `skills.json`, `agents.json` or `rules.json` at any depth (S2.4; D15).
- **Contributor guidance** for agents goes in CONTRIBUTING.md, which is never auto-loaded, or in a snippet contributors copy into their own `~/.gemini/config/rules/`.

### Delivery

**Delivery uses documented plugin components only**: `plugin.json`, `rules/`, `skills/`, `agents/`. The plugin ships no `hooks.json` and no `mcp_config.json`. The global-hook entry in CONTRIBUTING is a contributor-only tool (S7.2).

### Testing a branch without pushing

Install the branch from your local repository; never push it to test it.

- **CLI:** `git clone -b <branch> <path-to-your-local-repo> <dir>`, then `agy plugin install <dir>`. If `agy plugin list` already shows superpowers from `~/.gemini/config/plugins/`, move that clone out first: the CLI loads it too.
- **2.0 app and IDE:** first move every other `superpowers` copy out of `~/.gemini/config/plugins/` and out of the test workspace's `.agents/plugins/`; with two copies of the same name you cannot tell which one is read. Then either update the global clone with `git -C ~/.gemini/config/plugins/superpowers fetch <path-to-your-local-repo> <branch>` and `git -C ~/.gemini/config/plugins/superpowers checkout FETCH_HEAD`, or run `git clone -b <branch> <path-to-your-local-repo> <scratch-ws>/.agents/plugins/superpowers`.
- The `view_file` paths in the conversation's transcript show which copy was read.

## Testing your change

Run `bash tests/run-tests.sh` from the repository root in Git Bash. From PowerShell, run `& "$env:ProgramFiles\Git\bin\bash.exe" tests/run-tests.sh` instead: bare `bash` in PowerShell or cmd is often WSL, and the runner refuses it. Paste the result table into your PR. The default run covers the gate and unit tiers; `--live` and `--live-extra` add the tests that need a signed-in `agy`. A skipped test is not a pass: the runner exits 2 ("INCOMPLETE") and lists it.

**The edit-time purity gate.** `hooks/purity-check.mjs` denies a file-tool write that would put banned vocabulary into `skills/`, `agents/` or `rules/`, or another agent product's name into `.github/`. The release gate, `bash tests/antigravity/test-skill-tool-purity.sh`, enforces the same law. To use the hook while you work:

1. Check `node --version` in Antigravity's command shell first. The hook needs node 18 or later.
2. Run `node hooks/purity-check.mjs --print-global-entry` and add the `superpowers-purity-gate` entry it prints to `~/.gemini/config/hooks.json`, which the 2.0 app, the IDE and the CLI share.
3. Remove the entry when you stop contributing.

How the hook decides: it denies a file-tool write that puts banned vocabulary into a guarded folder; it allows only a write inside a `workspacePaths` entry or the `artifactDirectoryPath`, where the engine already allows; otherwise, errors included, it asks. It never returns `allow` anywhere else, because `allow` is an approval ("Automatically allows the tool execution") that would skip a permission prompt the engine would have shown; `ask` defers to you and respects "Always Allow". The repository is resolved from the script's own location and its git common directory, never from the payload, so every checkout and linked worktree counts and no foreign repository does. `workspacePaths` is a membership test only and never widens the scope; a relative `TargetFile` is joined to a single `workspacePaths` entry, else the hook asks, with no cwd fallback.

**Editing skills with the CLI.** After you edit a skill, run `/skills reload` in a running `agy` session before you test again.

**No hook for users.** No hook ships to plugin users, agent `hooks:` entries included. The skill disciplines (the Iron Law, ledger evidence lines, test-first) stay prose. A future user-facing enforcement hook needs all four of these: it is documented on all three products; Live check 6(b) shows that a hook that cannot run neither denies nor blocks; its interpreter is guaranteed on users' machines; and it does not fight subagent-driven development's four stops, `ask_question` or a BLOCKED report.

**Release checklist.** Delete the `hooks/purity-check.sh` stub, and its entry in `tests/antigravity/test-plugin-layout.sh`, in the release after v7.0.2.

## General

- Read `.github/PULL_REQUEST_TEMPLATE.md` before submitting
- One problem per PR
- Test on each Antigravity product your change affects (2.0 app, IDE, CLI) and name them in the environment table
- Describe the problem you solved, not just what you changed
