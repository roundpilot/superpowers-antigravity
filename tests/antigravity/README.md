# Superpowers-Antigravity Test Suite

Tests for this fork's skills, agents, bootstrap rule and packaging on Antigravity: the 2.0 app, the IDE and the CLI (`agy`). Run them through `tests/run-tests.sh`; each test also runs on its own as `bash <path>`.

## Prerequisites

- **bash:** Git Bash on Windows. From PowerShell or cmd, bare `bash` is often WSL, and the runner refuses to run the gate there against a Windows checkout.
- **node 18 or later:** every JSON read goes through `tests/antigravity/lib/json-tool.mjs`. No `jq` or `python` is needed.
- **Graphviz** (`dot` on `PATH`) for the render assertions in `tests/writing-skills/test-render-graphs.sh`.
- **agy**, signed in, for the live tiers only.

## Exit codes and tiers

Every test exits `0` PASS, `1` FAIL or `77` SKIP; any other code counts as FAIL. A SKIP is never a pass. `[N/A]` marks a single fixture that does not apply on this platform, never a whole test.

| Tier | Runs | Tests |
|---|---|---|
| gate | always; anything but PASS fails the run | `test-skill-tool-purity.sh`, `test-plugin-layout.sh`, `test-agent-frontmatter.sh`, `test-purity-hook.sh`, `test-rule-sync.sh`, `test-plugin-packaging.sh`, `test-execution-skills.sh`, `tests/diagnosing-superpowers/test-skill-structure.sh`, `tests/skill-size/test-skill-size.sh`, `tests/skill-layout/test-no-dev-files-in-skills.sh` |
| unit | always | `tests/writing-skills/test-render-graphs.sh`, `tests/systematic-debugging/test-find-polluter.sh` |
| live | `--live` | `test-plugin-discovery.sh`, `test-tool-roster.sh`, `test-bundled-dispatch.sh`, `test-skill-triggering/run-all.sh`, `test-subagent-dispatch.sh`, `test-inline-execution.sh`, `test-worktree-workspace.sh`, `test-spec-gate-stream.sh` |
| live-extra | `--live-extra` | `test-hooks-introspection.sh` (CLI only) |

`bash tests/run-tests.sh` exits `1` on any FAIL or any gate test that did not pass, `2` ("INCOMPLETE") when a requested test was skipped, and `0` otherwise. Every `test-*.sh` belongs to exactly one tier, except the library `test-helpers.sh`; the runner fails on a test it does not know.

## Live tiers

The live tests run `agy` headless with `--output-format stream-json`, an explicit `--print-timeout` and `--dangerously-skip-permissions`. They read tool calls, subagent dispatches and the final `result` from the stream, never from transcripts. A run that ends without a result, on an infrastructure error (`AGY_ERROR`, exit 3), at the print timeout, cancelled, or with denied actions is a SKIP. `ERROR`, `INVALID` and `WAITING` are FAILs. `AGY_TEST_MODEL` and `AGY_TEST_EFFORT` pass `--model` and `--effort` to every run.

The live tests exercise the superpowers that `agy` has installed, and SKIP when none is. `test-plugin-discovery.sh` is the exception, because it certifies the working tree. It SKIPs over an existing install. With `SUPERPOWERS_AGY_INSTALL=1` and no install, it runs `agy plugin install <native path of this repository>` and uninstalls on exit. Never symlink the repository into a plugin folder. After editing a skill, `/skills reload` refreshes a running `agy` session.

Headless runs and the review gates: a `-p` run that starts in brainstorming stops at the spec review message, because the agent's turn ends there. A run that reaches writing-plans does not stop at the plan: `-p` proceeds through plan review automatically (CLI 1.1.28), and the agent settles the execution-method question itself (CLI 1.1.12). To stop at the plan, say so in the prompt; to make the method your choice rather than the agent's, name it in the prompt. The trigger tests check skill loading only. `test-spec-gate-stream.sh` observes the spec gate over `--input-format stream-json`.

## Transcript tier

`bash tests/run-tests.sh --transcript <product>:<conversation id> --scenario <scenario>` applies the live assertions to a session you ran yourself. This matters most on the 2.0 app, which has no headless mode. `<product>` is `2.0`, `ide` or `cli`. Use `<product>:token:<text>` to find the conversation whose first message contains `<text>` instead of giving an id.

| Scenario | Passes when |
|---|---|
| `trigger:<skill>` | the session read `skills/<skill>/SKILL.md` (from under `--install-root <dir>` when given) and read no skill from a `zz-` copy |
| `sdd` | it dispatched an implementer, `spec-reviewer` and `code-reviewer`; with `--project <dir>`, the project gained two commits and `npm test` passes |
| `inline` | it read executing-plans' `SKILL.md` and dispatched no implementer or per-task reviewer; `--project` as for `sdd` |
| `worktree` | with `--project <dir>`, the project shows the isolation `WORKSPACE_VARIANT` expects, as in `test-worktree-workspace.sh` |

Create the project with `bash tests/antigravity/lib/fixture-plan-project.sh <dir>`, open it, and paste the prompt that `bash tests/antigravity/lib/fixture-plan-project.sh --print-prompt sdd|inline|worktree` prints. The trigger scenarios use the prompts in `test-skill-triggering/prompts/`.

A conversation's transcript is `<app_data_dir>/brain/<conversationId>/.system_generated/logs/transcript.jsonl`. `<app_data_dir>` is `~/.gemini/antigravity` for the 2.0 app, `~/.gemini/antigravity-ide` for the IDE and `~/.gemini/antigravity-cli` for the CLI (https://antigravity.google/docs/hooks). A CLI example in the docs places a CLI transcript under the 2.0 root, so `cli` looks in its own root first and the 2.0 root second. Always look a transcript up by its id, never by modification time. For a headless run, take the id from the `conversation_id` of the `result` or `step_update` payloads, not from the `init` event. The record fields are maintainer-observed, not documented. If no record carries tool calls, the tier fails with "transcript schema not recognised". A missing transcript means it was not written on that product, so `ide` and `cli` report SKIP. `skills/diagnosing-superpowers/references/session-discovery.md` is where the rest of this fork's transcript knowledge lives.

Observed root: `ide` transcripts were found under `~/.gemini/antigravity-ide` [MO IDE 2.5.5, Live check 7], and the tier looks there first. A missing `ide` transcript fails instead of skipping.

Observed root: `cli` transcripts were found under `~/.gemini/antigravity-cli` [MO CLI 1.2.17, Live check 7], and the tier looks there first. A missing `cli` transcript fails instead of skipping.
