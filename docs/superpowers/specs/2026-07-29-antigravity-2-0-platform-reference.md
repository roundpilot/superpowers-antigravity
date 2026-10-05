# Antigravity 2.0 Platform Reference — Tool Schemas & Subagent Model
**SUPERSEDED 2026-09-25** by `2026-09-25-antigravity-platform-reference.md`, which is now the fork's ground truth. This file is frozen, unchanged since commit 53e969d (2026-08-24) apart from this line, so that `ref:NN` line citations stay valid. Its errors are listed in the successor's §14.
> Captured 2026-07-29 from the official Antigravity 2.0 documentation (provided by the maintainer). This is the fork's **ground truth** for what the platform actually supports. Every tool invocation example under `skills/` must match these schemas exactly; every capability claim must be supported here. Where the older `2026-06-10-gap-analysis.md` conflicts with this document, this document wins.

**Provenance:** the `Subagents` array shape, `define_subagent`, `manage_task`, `schedule`, and the `ArtifactMetadata` params below come from the maintainer's 2026-07-29 capture and are absent from the public documentation pages as of 2026-07-30 — treat those specific shapes as maintainer-sourced, not independently corroborated against a public page.

## Tools

### File and directory operations

| Tool | Arguments |
|---|---|
| `view_file` | `AbsolutePath`, `StartLine`?, `EndLine`?, `IsSkillFile`? |
| `write_to_file` | `TargetFile`, `Overwrite`, `CodeContent`, `Description`, `IsArtifact`?, `ArtifactMetadata`? |
| `replace_file_content` | `TargetFile`, `Instruction`, `Description`, `AllowMultiple`, `TargetContent`, `ReplacementContent`, `StartLine`, `EndLine`, `TargetLintErrorIds`? |
| `multi_replace_file_content` | `TargetFile`, `Instruction`, `Description`, `ReplacementChunks` (array), `TargetLintErrorIds`?, `ArtifactMetadata`? |
| `list_dir` | `DirectoryPath` |
| `find_by_name` | `SearchDirectory`, `Pattern`, `Type`?, `Excludes`?, `Extensions`?, `FullPath`?, `MaxDepth`? |

**Trap:** `write_to_file` has **no** top-level `ArtifactType` or `RequestFeedback` argument. Artifact typing and metadata belong inside the `ArtifactMetadata` object.

### Search and research

| Tool | Arguments |
|---|---|
| `grep_search` | `SearchPath`, `Query`, `IsRegex`?, `CaseInsensitive`?, `Includes`?, `MatchPerLine`? |
| `search_web` | `query`, `domain`? |
| `read_url_content` | `Url` |

### System and execution

| Tool | Arguments |
|---|---|
| `run_command` | `CommandLine`, `Cwd`, `WaitMsBeforeAsync`, `RunPersistent`?, `RequestedTerminalID`? |
| `manage_task` | `Action` (`'list'`\|`'kill'`\|`'status'`\|`'send_input'`), `TaskId`?, `Input`? |
| `schedule` | `DurationSeconds`?, `CronExpression`?, `MaxIterations`?, `Prompt` |
| `list_permissions` | (none) |
| `ask_permission` | `Action`, `Target`, `Reason` |

**Trap:** `ask_permission` requests **additional scoped permissions** (resource-access grants; sibling of `list_permissions`). It is not a user-confirmation dialog for destructive actions.

`Action` takes one of seven values: `read_file`, `write_file`, `read_url`, `execute_url`, `command`, `mcp`, `all`. Evaluation precedence when grants conflict: Deny > Ask > Allow.

### Agent collaboration

| Tool | Arguments |
|---|---|
| `invoke_subagent` | `Subagents` — **an ARRAY** of specs `{Prompt, Role, TypeName, Workspace?}` |
| `define_subagent` | `name`, `description`, `system_prompt`, `enable_mcp_tools`?, `enable_write_tools`?, `enable_subagent_tools`? |
| `send_message` | `Recipient`, `Message` |
| `manage_subagents` | `Action` (`'list'`\|`'kill'`\|`'kill_all'`), `ConversationIds`? |

**Traps:** a single dispatch is still `Subagents: [{...}]` with one element — there is no bare named-parameter form. `define_subagent` has **no** `model`, `tools`, or `Workspace` argument: workspace is chosen per invocation; model tier is set only in custom-agent `.md` frontmatter.

### Interaction and media

| Tool | Arguments |
|---|---|
| `ask_question` | `questions` — array of `{question, options, is_multi_select}` |
| `generate_image` | `Prompt`, `ImageName`, `ImagePaths`? |

## Subagent model

- **Built-ins:** `research` (codebase research, file navigation, structural exploration), `self` (clone of the calling agent — same system instructions and toolset), `browser` (sandboxed browser testing, invoked **exclusively via the `/browser` slash command** — not via `invoke_subagent`).
- **Workspace options:** `inherit` (same workspace) | `branch` (isolated git worktree, auto-cleaned when the subagent is killed) | `share` (shared directory storage).
- **Context isolation:** subagents start with a clean slate — no parent conversation history. Parents retain full access to subagent workspaces, including isolated worktrees.
- **Lifecycle:** `Running` → `Idle` → `Killed`, plus a terminal `Error` state reachable from `Running` (CLI naming: `running`/`done`/`error`/`killed`).
  - **Idle:** task complete, result message sent to parent, execution paused. **An idle subagent automatically re-awakens to Running upon receiving a message, and retains all context from its prior turns.** "Resume" is a supported, documented pattern.
  - **Error:** terminal failure, distinct from Idle — surfaced by `manage_subagents` `Action: "list"`. Cannot be resumed; treat like Killed (dispatch a fresh subagent with the task text and last known state).
  - **Killed:** permanent; cannot be re-awoken. Worktrees auto-cleaned; transcripts remain readable as JSONL.
- **Communication:** agents message each other by unique agent conversation ID (`send_message`); routing to parent, subagents, or peers whose ID is known. Agents can read each other's conversation transcripts.
- **Nesting limit:** maximum depth 10 below the primary agent, strictly enforced.
- **Permissions:** subagents inherit the parent's allowed command prefixes, file read/write scopes, and sandbox settings. Tool authorizations bubble up to the main UI/subagent panel.

## Custom subagents (`.md`)

Discovery locations:

| Scope | Path |
|---|---|
| Workspace | `.agents/agents/<name>.md` or `.agents/agents/<name>/agent.md` |
| Global | `~/.gemini/config/agents/<name>.md` (or `.../agents/<name>/agent.md`) |
| Plugin | `plugins/<plugin_name>/agents/` — CLI-documented; IDE discovery unverified |

Frontmatter properties: `name` (required), `description` (required — used by the planner for delegation), `tools` (string[] — **exact names; a misspelled tool name may hang the subagent**), `mainAgent` (default true), `subagent` (default true), `model` (`inherit`\|`flash`\|`pro`), `commandExecutionPolicy` (`off`\|`auto`\|`eager`\|`sandbox`), `mcpServers`, `skills`/`plugins`. The Markdown body after the frontmatter is the system prompt.

## Agent settings

Fetched 2026-07-30 to verify two setting names referenced in `skills/brainstorming/SKILL.md` and `skills/subagent-driven-development/SKILL.md` weren't fabricated.

- **Agent Non-Workspace File Access** — confirmed verbatim on `https://antigravity.google/docs/agent-settings` (the FETCH-FIRST target for this check): *"Allows the agent to view and edit files outside of the active project folders."* Default: restricted to project folders and `~/.gemini/antigravity/`. Guidance: *"Enable non-workspace access with caution"* (potential exposure of sensitive local data).
- **Artifact Review Policy** — **not** spelled out on `/docs/agent-settings` itself (that page only links out to "[Artifact Review](/docs/artifact-review)" without naming the setting or its values). Confirmed instead via that linked page, `https://antigravity.google/docs/artifact-review`, which names both the setting (**Artifact Review Policy**) and a value, **Request Review (Recommended)**: *"The agent always halts and requests your explicit approval before proceeding with proposed changes."* Both skill files' existing prose ("Artifact Review Policy is set to Request Review") already matches this and needed no wording change — recorded here as the corroborating source since the primary FETCH-FIRST page alone didn't carry it.

## Artifacts

Structured deliverables (implementation plans, code diffs, architecture diagrams, images/screenshots, browser recordings) generated mainly in Planning Mode, reviewed in the desktop sidebar/review pane or the CLI's keyboard-driven review panel. Support inline feedback and steering at milestones before the agent modifies files.

These five are the publicly documented kinds. Skills also write `task.md` progress-tracking artifacts through `ArtifactMetadata`; a `task` kind is not confirmed on any public page — treat it as unverified until corroborated.

## Hooks

Antigravity supports `PreToolUse` and `PostToolUse` hook matchers over the documented tool names above (these are Antigravity hooks, unrelated to the deleted Claude Code `hooks/` directory).

**Locations:** a plugin's own `hooks.json` at the plugin root (confirmed — both `/docs/plugins` and `/docs/cli/plugins` show it in the plugin directory tree; this fork's hook lives here). Hooks can also be configured inside the user's own `settings.json`, which — mirroring the custom-subagent discovery scopes above — exists at workspace (`.agents/`) and global (`~/.gemini/config/`) scope; the docs state this split without itemizing per-scope precedence.

**PreToolUse contract** (confirmed via Task 5's fetch of `/docs/hooks` and `/docs/ide/hooks`): stdin is `{"toolCall": {"name": <tool>, "args": {...}}, ...}`; stdout is `{"decision": "allow|deny|ask|force_ask", "reason"?, "permissionOverrides"?}` — hooks can deny a call outright, not just request confirmation. Malformed or empty stdout is NOT a safe implicit allow: third-party evidence (not on either official page) shows it denies every call the matcher covers instead. Exit-code semantics and the hook command's working directory remain undocumented.

**In use:** the fork ships `hooks.json` at the plugin root with one `PreToolUse` matcher (`write_to_file|replace_file_content|multi_replace_file_content` → `hooks/purity-check.sh`) that denies writes introducing banned vocabulary into the plugin's own `skills/` tree (resolved from the hook script's own on-disk location, so a foreign project's `skills/` writes always pass through untouched) — the same law `tests/antigravity/test-skill-tool-purity.sh` enforces, now caught at edit time. The PreToolUse stdin payload's `workspacePaths[0]` is used as the join base for a relative `TargetFile`, falling back to the hook process's own `$PWD` if the payload doesn't carry it.

## Sidecars

Auto-managed background processes a plugin can ship, declared via a `sidecar.json` manifest — plugin-shippable, with per-user enablement (the user opts in rather than it running unconditionally). Evaluated for this fork; not used — no bundled process currently needs one.

## Multi-agent teamwork

`/teamwork-preview` (Ultra plan exclusive, preview): managed multi-agent framework with built-in error recovery, automatic retries, and task coordination.

## Slash commands (maintainer-observed)

The documented slash surface covers workflows (`/workflow-name`) and built-ins (`/browser`, `/teamwork-preview`). **Maintainer-observed 2026-07-30:** the palette also resolves skills — `/using-superpowers` (IDE) and `/superpowers:using-superpowers` (CLI) load the skill for the session. Undocumented but confirmed working in practice; treat as a supported-in-fact entry point. (Supersedes the 2026-07-30 audit's C3 finding, which inferred non-function from documentation absence — its adversarial verifier never ran.)

**Screenshot-confirmed (maintainer, 2026-07-30):** the IDE slash palette lists this plugin's skills by bare name with their frontmatter descriptions (truncated to ~1 line — front-loaded "Use when..." wording is what survives), alongside built-ins (`/goal`, `/schedule`, `/browser`, `/grill-me`, `/teamwork-preview`, `/learn`) — so **plugin-nested `skills/` discovery in the IDE is CONFIRMED**, and skills are slash-invocable without a plugin prefix in the IDE. Also observed: a `/learn` built-in ("Reflect on recent successes or corrections to capture reusable skills or rules") — native skill/rule capture, previously unrecorded; model selector shows "Gemini 3.5 Flash (Medium)", corroborating the CLI's `gemini-3.5-flash-medium` slug pattern and tier naming.

**Re-verified 2026-08-03** (prompted by a third-party review asserting `invoke_subagent` specs accept a `Model` field with an `inherit|flash_lite|flash|pro` enum): the live `/docs/hooks` Supported Tools listing still shows the `Subagents` spec as `Prompt`, `Role`, `TypeName`, `Workspace?` — no Model field; "flash_lite" appears nowhere on the page. The claim is unconfirmed against any documented surface. Definitive oracle if it matters: one live dispatch carrying `Model: "flash"` in a spec item — the slash-command lesson (docs absence ≠ behavior absence) cuts both ways, but skill text follows documented + observed behavior, not third-party assertion.
