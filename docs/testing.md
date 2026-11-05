# Testing Superpowers-Antigravity

This fork tests its skills, agents, bootstrap rule and packaging with one runner, from the repository root in Git Bash:

    bash tests/run-tests.sh [--live] [--live-extra]

From PowerShell, run `& "$env:ProgramFiles\Git\bin\bash.exe" tests/run-tests.sh`. The default run covers the gate and unit tiers and needs only bash and node 18 or later. The live tiers also need `agy`, signed in. `tests/antigravity/README.md` gives the exit codes, the tier rules, the live-test environment and the transcript tier.

| Test | Tier | Checks |
|---|---|---|
| `tests/antigravity/test-skill-tool-purity.sh` | gate | the purity law in `purity-patterns.txt` over `skills/`, `agents/`, `rules/` and `.github/`; tool names against `known-tools.txt`; bundled scripts invoked through their interpreter |
| `tests/antigravity/test-plugin-layout.sh` | gate | nothing tracked that the rule walk, plugin discovery or a hook file could load for users (R12) |
| `tests/antigravity/test-release-notes-bullets.sh` | gate | the newest release-notes entry keeps bullets short; a "used by" row in the platform reference names a shipped skill |
| `tests/antigravity/test-agent-frontmatter.sh` | gate | bundled agents' frontmatter keys, tools, roles and cross-file rules |
| `tests/antigravity/test-purity-hook.sh` | gate | `hooks/purity-check.mjs` decisions on fixture payloads, Windows path forms included |
| `tests/antigravity/test-rule-sync.sh` | gate | `rules/using-superpowers.md` frontmatter, wrapper and body |
| `tests/antigravity/test-plugin-packaging.sh` | gate | manifests, versions, skill names, README rows, issue-template labels |
| `tests/antigravity/test-execution-skills.sh` | gate | the execution skills' workspace, ledger and shell-neutrality text |
| `tests/diagnosing-superpowers/test-skill-structure.sh` | gate | diagnosing-superpowers' structure, word budget, agent names and leak patterns |
| `tests/skill-size/test-skill-size.sh` | gate | no SKILL.md body reaches the 24 KB limit |
| `tests/skill-layout/test-no-dev-files-in-skills.sh` | gate | no skill directory ships files meant for developing the skill |
| `tests/writing-skills/test-render-graphs.sh` | unit | `render-graphs.js`; the render assertions need Graphviz |
| `tests/systematic-debugging/test-find-polluter.sh` | unit | `find-polluter.sh` |
| `tests/antigravity/test-plugin-discovery.sh` | live | the working tree's 16 skills and every bundled agent listed by `agy` |
| `tests/antigravity/test-tool-roster.sh` | live | every baseline tool the skills name is in the CLI's tool list |
| `tests/antigravity/test-bundled-dispatch.sh` | live | the bundled `final-reviewer` resolves |
| `tests/antigravity/test-skill-triggering/run-all.sh` | live | natural prompts make the agent read the matching skill |
| `tests/antigravity/test-subagent-dispatch.sh` | live | subagent-driven development dispatches an implementer and both reviewers on a two-task plan |
| `tests/antigravity/test-inline-execution.sh` | live | executing-plans runs the same plan inline, without per-task dispatch |
| `tests/antigravity/test-worktree-workspace.sh` | live | workspace isolation follows the shipped workspace variant |
| `tests/antigravity/test-spec-gate-stream.sh` | live | a headless brainstorming run stops at the spec review |
| `tests/antigravity/test-hooks-introspection.sh` | live-extra | `agy` lists the contributor hook entry only where it is enabled |
