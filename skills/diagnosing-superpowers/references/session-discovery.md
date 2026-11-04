# Discover the session history

Resolve the session your human partner named using the tools and information
available in this environment. Your knowledge can suggest where to look; verify
the result against the actual history.

Use the harness's exposed session tools, configured storage, local help,
documentation, or bounded filesystem inspection. Measure files before reading
their content and follow context-safety.md. Inspect archives or indexes when the
environment points to them. A supplied usable path does not need another search.

Confirm identity using the available session id, working directory, timestamps,
and matching conversation content. Recency alone is not confirmation. Distinguish
the requested session from its children and unrelated candidates. Ask for a
missing identifying fact when the available evidence cannot distinguish them.

For each filesystem source, obtain its full absolute path from the environment,
with home-directory shorthand and variables expanded. Use that same path in the
case record and in the discovery answer you give your human partner.

Establish the record meanings needed for the requested investigation from
observed records or documentation. Distinguish human messages from injected
messages, tool results, and a parent agent's dispatch. Match tool calls to their
results. Establish usage-counter semantics before calculating totals. Do not
infer a format from another harness or turn a missing field into a zero.

Record the exact sources, relevant field meanings, supporting record locations,
associated sessions, rejected plausible candidates, and unresolved information
in the case file. Subsequent readers use that record rather than repeating
discovery. If history is missing, inaccessible, or ambiguous, state the specific
limitation and ask for the missing path, export, or identifying detail.

## On Antigravity

These notes are starting points, not conclusions. *Documented* means an Antigravity docs page or release note says it; *observed* means it was seen in one machine's 2.0 app store and must be confirmed against the records in front of you. Record what you confirmed, and how, in the case file. When a store path or a record's meaning is in doubt, also consult the built-in Antigravity Guide skill and record what it says as documentation.

### Stores

- A session is a conversation, and its id is the conversation's UUID. Its transcript is `<app_data_dir>/brain/<id>/.system_generated/logs/transcript.jsonl` (*documented*, https://antigravity.google/docs/hooks), where `<app_data_dir>` is `~/.gemini/antigravity` for the 2.0 app, `~/.gemini/antigravity-ide` for the IDE and `~/.gemini/antigravity-cli` for the CLI. A CLI docs example puts a CLI transcript under `~/.gemini/antigravity`, so for a CLI session check the CLI root first, then that one. Check every root whichever product you run in: the other products' sessions are on the same machine.
- Records can carry `truncated_fields` (*observed*). Look for a truncated value in the 2.0 app's `transcript_full.jsonl` beside the transcript (*observed*), under the same context-safety rules, and cite the file you read.
- Most IDE conversation directories hold no transcript (*observed*). A missing transcript was not written: cite the artifacts and their snapshots in `brain/<id>/` instead, and note the absence in coverage.
- `~/.gemini/antigravity-cli/cache/last_conversations.json` (*documented*) is a hint only, and it usually names the conversation you are running in.

### Identity

- This conversation: its artifacts live in its own `brain/<id>/` (*documented*), and artifact writes target it by absolute path (*observed*), so the directory holding this skill's task.md names this conversation. If task.md landed anywhere else, ask your partner for the id.
- Clones share a first prompt and early timestamps: `/fork`, importing a 2.0 conversation into the CLI, and switching custom agents each start a new conversation from an old one's history (*documented* for the CLI). A supplied id settles which one is meant; otherwise compare where they diverge and list the clones you rejected.
- Never resume or continue the diagnosed conversation or any of its subagents, and never `send_message` to them: a message wakes an idle agent (*documented*), which then writes to the transcript you are reading. Never kill them. Use `manage_subagents` only with Action `list`; stop your own readers with Action `kill` and their `ConversationIds`, never `kill_all`.

### Records (*observed*, 2.0 app)

- One JSON object per line: `step_index`, `source`, `type`, `status`, `created_at` (UTC), `content`, `tool_calls`, `thinking`, `truncated_fields`, `error`, `error_code`. `source` is `USER_EXPLICIT`, `MODEL` or `SYSTEM`; `SYSTEM` records have `type` `SYSTEM_MESSAGE`, `CONVERSATION_HISTORY`, `ERROR_MESSAGE` or `CHECKPOINT`. Establish from the records which `SYSTEM` type marks a compaction before counting one. `status` is `DONE`, `RUNNING` or `ERROR`.
- `USER_EXPLICIT` does not prove that your partner typed it. A subagent's opening prompt from its parent is likely recorded that way, and hook-injected steps, a Stop hook's reason, `schedule` prompts, messages from other agents, 2.0 scheduled tasks and sidecar messages add words too (*documented* channels; how each is recorded is not). A prompt the records do not establish as human goes under unresolved information.
- Skill use: a `view_file` call with `IsSkillFile: true` (*observed*), a read of a `SKILL.md`, or a slash command naming the skill in a human prompt. The always-on rule, and any context file the installed version still ships, is not an invocation.
- No usage field was seen: record usage counters as unavailable and take time from `created_at`. A CLI stream-json capture your partner already has adds usage (per step in `step_update`, cumulative in the final `result`), `duration_seconds` and `subagent_info` (*documented*); never start a run to make one. A dispatch's `Model` shows what was requested, not what ran.
- Absent means not recorded: CLI builds before 1.2.4 left failed steps out of the transcript. Compaction rewrites a live log, so record the line count and mtime when you read.

### Associated sessions

- Subagents are separate conversations. Each `INVOKE_SUBAGENT` result carries the child's `conversationId`, and `send_message` records name children as `Recipient` (*observed*); the child's transcript is under `brain/<child-id>/` in the same root. Recurse; nesting reaches ten levels (*documented*).
- Never pick children by mtime: that also finds unrelated conversations, including this diagnosis's own readers. List children the records do not confirm under unresolved information.

### Access

The stores, the install root and `~/.superpowers/` sit outside the project, and each product's default file scope differs. Get access in this order, without changing your partner's settings. Readers inherit your grants.

1. In the turn that dispatches readers, before the dispatch, request each directory outside the project that you will cite or hand to a reader: `ask_permission({Action: "read_file", Target: "<abs dir>", Reason: "read-only diagnosis of session <id>"})`. These are `brain/<id>/` of the diagnosed conversation and of each child, and `<install root>/skills/`. With no id yet, or for step 7, request the store's `brain/` root, or ask your partner for the id. Grants come first because a permission card raised inside a subagent can time out while nobody answers it (after 60 seconds on the CLI).
2. If the request is rejected, the first read raises a permission card: ask your partner to approve the directory, not the single file.
3. If access is refused (non-workspace access off, or the IDE's strict mode), say so, and ask for a copy inside the project or for the diagnosis to run from another Antigravity product on this machine.

Before dispatch, measure every session file (rule 1 of `references/context-safety.md`) and write its lines over 100,000 characters under the Sessions table as `Long lines: <path> — <line>:<length>, …` (or `none`). Where your partner's settings require approval for every command, say before dispatch that each reader will ask: allow rules reach readers, and on Windows a command line that cannot be split into words runs without approval only under a rule that matches the whole line.

### Case workspace

- Key the case workspace by the diagnosed session's id. Before creating `~/.superpowers/diagnosing-superpowers/<session-id>/`, request it: `ask_permission(Action: "write_file", Target: "<absolute case dir>", Reason: "case workspace for this diagnosis")`. Then write `case.md` there with `write_to_file`.
- If a directory is missing, create each level with the shell's own command and retry.
- If the grant is refused or the directory cannot be written, use `<project root>/.superpowers/diagnosing-superpowers/<session-id>/`. First, if `<project root>/.superpowers/.gitignore` is missing, create it with `write_to_file` containing the single line `*`, and tell your partner that the case sits inside the project folder: git ignores it, but anything else that copies the folder does not. If neither location can be written, ask your partner for a directory.
- Write the path you used on the case file's `Case workspace:` line.

### Report

- Write `report.md` with `write_to_file`, adding `IsArtifact: true` and `ArtifactMetadata` `{ArtifactType: "other", UserFacing: true, RequestFeedback: false}` so that it opens as a document your partner can read. If the write is refused with those arguments, or the file is not at the path afterwards, write it again without them. Either way, give the path and show it. Approval never rides on the artifact.

### Approvals

- An approval is your partner's own answer. If you would be settling an archive, issue or comment question yourself because nobody can answer, the answer is "do not archive" or "do not file": leave the text in the case workspace and stop.

### Dispatch

- Readers get `Workspace: "inherit"` and absolute paths: the case file, their prompt files, `references/context-safety.md` for every `session-analyst`, and `references/redaction-policy.md` for the scrub and the scrub audit. The scrub and the audit also get every BUNDLE file listed by absolute path, with "report any difference between that list and what you find". Each prompt file's return format governs. Set no per-dispatch `Model`.
- Step 3 is one `invoke_subagent` call with one entry per dimension: `{TypeName: "session-analyst", Role: "<dimension> analyst", Workspace: "inherit", Prompt: "CASE: <abs case.md>. Read <abs analyst-common.md>, then <abs <dimension>.md>. Context-safety rules: <abs context-safety.md>. RANGE: <optional>."}`. A dimension split by turn range adds entries. Step 7's matchers are one call with one `session-analyst` entry per candidate, given `prompts/similar-session.md`.
- The scrub is `bundle-scrubber` with `prompts/scrub.md`, BUNDLE, PUBLIC_REPOS and PROPRIETARY. Each audit round is a fresh `session-analyst` with `prompts/scrub-audit.md`, never `bundle-scrubber`.
- When an audit returns MISSED, send the list to the same scrubber: `send_message(Recipient: <scrubber conversationId>, Message: <MISSED list>)`. It wakes with its replacement map still in context (*documented*). If `manage_subagents` (Action `list`) shows it killed or in error, dispatch a fresh `bundle-scrubber` with the current `scrub-log.md`, told to number each category after the highest placeholder in that log, and say in the scrub log and the report that one value may now carry two placeholders.
- If a reader reports that it cannot read a file, `send_message` that file's text to the reader; dispatch it again only if it was killed or errored. When readers cannot measure a session file, analyze those dimensions yourself, one at a time under the same rules, and say so in report §8.
- If `invoke_subagent` rejects a TypeName, retry it once as `superpowers:<name>`. If that is rejected too, read `<install root>/agents/<name>.md` and dispatch TypeName `self` with the file's body ahead of the prompt; such a reader is read-only only because that body says so. With no subagent tool, no agent file, or `self` rejected, analyze the dimensions yourself, one at a time. Note each fallback in report §8, for example `session-analyst: self subagent (bundled agent unavailable)`.

### Similar-session candidates

- Scan every root under Stores. Exclude this conversation and every reader it dispatched (their ids are in your dispatch results). Flag clones of the diagnosed session, which match it trivially.

### Environment

- Install root, the directory that contains `skills/`: for this run, the absolute path of this skill's `SKILL.md` as your own `view_file` read it; else a path in the content a slash command expanded; else write `install root: unknown (skill loaded by slash command)`. For the diagnosed session, any `view_file` `AbsolutePath` (read `\` as `/`) ending in `/skills/<name>/SKILL.md`; `IsSkillFile: true` only confirms it (*observed*). Write both into the case file's install-root line, and say so if they differ.
- Version: `version` in `<install root>/plugin.json`, else in `<install root>/package.json`, plus the git sha if the install is a checkout. Hash skill files with `sha1sum`, `shasum` or `Get-FileHash -Algorithm SHA1`.
- Other plugins: beside the install root and in the project's `.agents/plugins/`. MCP servers: `~/.gemini/config/mcp_config.json` and `.agents/mcp_config.json`. Hooks: `~/.gemini/config/hooks.json`, `.agents/hooks.json`, each plugin's `hooks.json` and, for the CLI, `~/.gemini/antigravity-cli/settings.json`. Custom agents: `.agents/agents/` and `~/.gemini/config/agents/`; flag any named like an agent the plugin bundles, which may run in its place. Skills: `.agents/skills/`, legacy `.agent/skills/`, `~/.gemini/config/skills/`, legacy `~/.gemini/antigravity/skills/` and, for the CLI, `~/.gemini/antigravity-cli/skills/` (all *documented*).
- Instruction files, with paths and byte sizes: `AGENTS.md` and `GEMINI.md`, and their `.agents/` forms, at every level from the files the session touched up to the project root; `.agents/rules/` and `.agents/rules.json`; both names in `~/.gemini/` and `~/.gemini/config/`; `~/.gemini/config/rules/`; for the CLI, `~/.gemini/antigravity-cli/rules/`; and the rule and context files the installed superpowers ships. A directory's files load only when a file below it is read, so presence is not loading; a rule file over 24,000 bytes is truncated (*documented*).
- Product version: from the product's own version display. `agy plugin list` and `agy agents --output-format json` observe CLI sessions only. Never run `agy -p` to take inventory: it creates a conversation in the store you are reading.
