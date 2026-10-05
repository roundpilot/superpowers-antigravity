# Antigravity Platform Reference — 2.0 app, IDE and CLI

## §0 Using this reference

This file is the fork's ground truth for what Antigravity supports (R2). It covers three products: the Antigravity 2.0 app, the Antigravity IDE and the Antigravity CLI (`agy`). It succeeds `2026-07-29-antigravity-2-0-platform-reference.md`, which stays frozen so that its `ref:NN` line citations keep resolving; that file's errors are listed in §14. Cite this file as `ref §n.m`. Sections are never renumbered: new material is appended as subsections.

Sources:

- **Docs.** Every page at `https://antigravity.google/docs/<page>`, captured on 2026-09-25 (Markdown, text and raw HTML) and again on 2026-09-29 (Markdown; it adds the new pages `marketplace` and `changelog`, and revisions of others, among them `plugins`, `slash-commands` and `cli/features`). Line numbers in labels are those of the 2026-09-29 Markdown capture of the page.
- **Product tabs.** Read from the `tab-panel-N` ranges of the 2026-09-25 raw HTML; for a page first captured on 2026-09-29, from the Markdown panel order (§0.2).
- **Changelog.** The official changelog, to 2.0 2.18.1 (2026-09-28), CLI 1.2.11 (2026-09-25) and IDE 2.5.5, plus the dated blog posts.
- **Maintainer observations.** On-disk session data, hook logs, live-check runs, directory listings and docs-site fetches. The records themselves stay outside the repository; this file carries their durable facts, labelled `[MO …]` (maintainer instruction).

Every fact carries a label (§0.1). §0.2 says which product a docs sentence covers, §0.3 how far a skill may rely on a fact, §0.4 what happens when sources disagree, and §0.5 summarises every capability per product.

### §0.1 Evidence classes and labels

Labels are `[D <products> <page>:<lines>]`, `[CL <product> <version>]` or `[CL blog <date> <products|unscoped>]`, `[MO <product> <bound> <date> <how>]` and `[U]` with its sub-tags.

| Class | Tag | What counts | Example |
|---|---|---|---|
| Documented | `[D]` | A sentence on a current `antigravity.google/docs` page, 2026-09-25 capture or later | `[D shared hooks:204-208]` |
| Changelog-only | `[CL]` | An official changelog entry or a dated blog post, not on any docs page | `[CL CLI 1.2.7]`, `[CL blog 2026-05-19 unscoped]` |
| Maintainer-observed | `[MO]` | Seen by the maintainer: on-disk session data, a hook log, a live check, a directory listing, a docs-site fetch or a UI observation. It always carries the product, a version bound and a date | `[MO 2.0 ≤2.10.0 2026-08-25 transcript probe]` |
| Unverified | `[U]`, with sub-tags `[TP]` (a third-party claim, upstream's included), `[I]` (an inference or analogy) and `[U-ms]` (maintainer-sourced, undated or product-less) | Anything else | `[TP upstream v6.4.1]`, `[I]` |

**Self-report.** A live-check answer that is the model's own statement (for example "print the schemas you were given") is written `[MO <product> <bound> <date> LCn self-report]`. It counts as `[U]` for tiers until an observed call (a hook-log line or a transcript record) or the CLI's `init.tools` corroborates it; then it is relabelled `[MO … LCn]`.

**Grammar.**

- `[D <products> <page>:<lines>]`: `<products>` is `2.0`, `CLI`, `IDE`, a combination such as `2.0/CLI`, `shared` or `unscoped` (§0.2). `<page>` is the URL path after `https://antigravity.google/docs/` (`rules`, `cli/headless`, `migration/workflows-to-skills`). `<lines>` are lines of the 2026-09-29 Markdown capture, for example `12-14` or `12-14, :20`.
- `[CL <product> <version>]`: `<product>` is the changelog panel the entry sits in (`2.0`, `CLI`, `IDE` or `SDK`). A blog post is `[CL blog <date> <products named|unscoped>]`.
- `[MO <product> <bound> <date> <how>]`: `<bound>` is a version bound such as `≤2.10.0`, or `?` when the version is unknown. The product `docs` marks a fetch of the docs site, and `(probable)` after the product marks a product that was inferred rather than recorded. `<how>` names the method: `transcript probe`, `registration read`, `directory listing`, `slash palette`, `LC3` and so on.
- `[U …]`, `[TP …]`, `[I …]` and `[U-ms …]` name their origin where one exists.
- Several sources join with `; ` inside one label.
- A bare `[MO]` in older text (the design spec, the 2026-07-29 reference) means `[MO 2.0 ≤2.10.0 2026-08-25 transcript probe]`: the 2.0 app's on-disk sessions, version 2.10.0 or earlier, newest 2026-08-25.

### §0.2 Product attribution

These rules decide which product a `[D]` sentence covers.

- **Tabs.** A sentence inside a product tab covers that product only. Tab membership comes from the raw HTML, because the Markdown capture flattens the tabs into one stream; for `marketplace`, first captured on 2026-09-29, it comes from the Markdown panel order.
- **Untabbed text** covers every product that has a tab on the same page. On the three-tab pages it is labelled `shared`; on two-tab pages it is cited as the pair, `2.0/CLI`.
- **`subagents` has no shared body.** Everything from "Invoking Subagents" to "Multi-agent orchestrators" (:8-151) is the 2.0 tab: workspace modes, built-ins, the frontmatter table, the lifecycle, messaging, nesting and permission inheritance. Everything from "Asynchronous execution model" to "Keyboard ergonomics" (:153-230) is the CLI tab. The CLI tab links the frontmatter specification (:189). `permissions`, `projects`, `sandbox` and `settings` are likewise fully tabbed.
- **Badges and product sentences override tabs.** `slash-commands` names only 2.0 and the CLI (:3, :225-228), so it is cited `2.0/CLI`.
- **Product sections.** `ide/*` pages cover the IDE, and `cli/*` pages cover the CLI.
- **Unscoped pages.** An untabbed page with no product statement (`artifact-review`, `walkthrough`, `tools` (the Task Groups page), `migration/workflows-to-skills`, `models`, `sidecars`) is `[D unscoped …]`. It is cited, but it counts as `[U]` on every product.
- **Changelog.** An entry covers only its own panel: 2.0, CLI, IDE or SDK. SDK entries never count, because the SDK is a library and not a target product.
- **Blog.** A blog sentence covers only the products it names. An unscoped blog sentence ("Antigravity now supports …") is `[CL blog <date> unscoped]` and counts as `[U]`, like `[D unscoped]`. A post that predates a product cannot cover it: the 2025-11-18 launch post predates the 2.0 app and the CLI.
- **Inference.** A fact inferred from a "Fixed …" entry (for example the `/<plugin>:<skill>` form implied by CLI 1.2.7's double-prefix fix) is `[I]`, not `[CL]`.
- **Promises.** A vendor promise ("the IDE following shortly") is `[U]`.

Tab map (lines of the 2026-09-29 capture):

| Page | 2.0 tab | CLI tab | IDE tab | Untabbed text |
|---|---|---|---|---|
| `getting-started` | 9-77 | 79-148 | 150-161 | `shared` |
| `hooks` | 9-16 | 18-34 | 36-43 | `shared` (1-7, from 45) |
| `mcp` | 31-48 | 50-70 | 72-89 | `shared` (1-29, from 95) |
| `plugins` | 92-111 | 113-174 | 176-182 | `shared` (1-90) |
| `rules` | 143-152 | 154-160 | 162-171 ("IDE & Extensions") | `shared` (1-141) |
| `settings` | 9-71 | 73-239 | 241-315 | none |
| `skills` | 102-117 | 119-143 | 145-154 | `shared` (1-100) |
| `artifacts` | 14-16 | 18-20 | — | `2.0/CLI` |
| `boost` | 73-76 | 79-85 | — | `2.0/CLI` |
| `marketplace` | 12-44 | 46-155 | — | `2.0/CLI` (1-10) |
| `teamwork` | 121-127 | 129-137 | — | `2.0/CLI` |
| `permissions` | 8-253 | 255-356 | — | none |
| `projects` | 8-47 | 50-87 | — | none |
| `sandbox` | 8-110 | 112-204 | — | none |
| `subagents` | 8-151 | 153-230 | — | none |

### §0.3 Reliance tiers

The tier is decided from the three product cells of the coverage matrix (§0.5), across all three cells and never per product: a capability evidenced on two products and detected at runtime on the third is T3.

| Tier | Condition | How a skill may use it |
|---|---|---|
| **T1** Sole mechanism | `[D]`, `[CL]` or `[MO]` on all three products, and no open contradiction the wording does not survive | Unconditionally |
| **T2** Unconditional enhancement | Evidence on at least one product. It is an optional argument or key on a T1 tool or file, a product that ignores it still leaves every step correct, and no gate depends on its effect | Unconditionally, without depending on the effect (for example, `RequestFeedback` never replaces the `ask_question` approval). How a product that does not know the key reacts is recorded per product: on the CLI a schema-validation failure is returned to the agent to self-correct [CL CLI 1.2.4]; on 2.0 and the IDE it is unverified until LC1 S1-k |
| **T3** Product-named extra | Evidence on at least one product | Only with the product named in the skill text, and only with a stated fallback that is itself T1. Runtime detection ("if the TypeName does not resolve …") counts as naming |
| **T4** Reference-only | Only `[U]` evidence, or SDK-only, or plan-tier-gated (paid or preview), or deprecated on any product | Never as a mechanism. It may appear in this reference and in live-check gates |

- Agent frontmatter keys (`agents/*.md`) with `[CL]` evidence only ship, as T2, once LC3 shows that the products lacking evidence ignore them. Until then they are not shipped (S3.1).
- Skill prose never asserts an absence unless `[D]`, `[CL]` or `[MO]` states it. Docs absence is not behaviour absence, in either direction.

### §0.4 Conflicts, precedence and decay

- **Conflicts.** Two sources that disagree get a §13 contradiction entry. The entry names both sides, the interim rule every section follows meanwhile, and the live check that decides it.
- **Dated against undated.** Docs pages are undated and the changelog is dated. A newer `[CL]` entry that contradicts a docs sentence is probable current behaviour, not settled: skill prose must work under both readings, or be gated.
- **Observation.** An `[MO]` fact settles its product at its version and date. If it disagrees with `[D]` or `[CL]`, that is also a §13 entry; a documented path or file that `[MO]` finds missing is such a disagreement (X18).
- **Decay.** An `[MO]` fact older than a later changelog entry for the same feature on the same product is marked `(re-observe: <version>)` in §0.5 and at the fact. It keeps its tier until it is contradicted, and the next live check covering that feature re-observes it. Examples: `ArtifactMetadata.UserFacing` was observed on 2.0 no later than 2.10.0, and 2.0 2.13.0 changed how user-facing scratch files display; the v6.2.1 hook "fails closed" note (2026-08-03) predates 2.0 2.6.0 (load-time rejection) and 2.12.0 (failing hooks no longer end the session).
- **Placement.** Each fact sits in the § for its feature, with its label inline. §0.5 holds the matrix. Nothing is labelled only in a table footnote.
- **Maintenance.** This file is edited in place. Each new fact enters with a label and a revision-log line, and live-check results enter as `[MO]` facts (§15). A superseded fact is never deleted silently: it moves to §14, with the fact that replaces it. The next complete re-capture of the docs yields the next dated successor, and this file is then frozen the same way.

### §0.5 Coverage matrix

Each row has a 2.0, a CLI and an IDE cell, a skill use and a decider. Row numbers are stable: a split row takes a letter and new rows are appended. When a check is not run its cells stay as they are and its result reads "not run" (R10); no tier removes a 2.0 mechanism without a named fallback. Cell codes:

- `D` = documented on that product's tab or page;
- `D·s` = documented in a shared untabbed section;
- `CL x.y.z` = changelog entry;
- `MO` = maintainer-observed (2.0 ≤2.10.0, newest session 2026-08-25, unless a date is given);
- `U` = unverified;
- `X#` = contradiction entry (§13);
- `—` = not applicable.

A cell cites its source in short form: the page and lines of the 2026-09-29 capture, with the column's product unless another is named.

| # | Capability | 2.0 | CLI | IDE | Skill use | Decider |
|---|---|---|---|---|---|---|
| 1 | Documented tool names and their documented arguments (§2.1a): `view_file`, `write_to_file`, `replace_file_content`, `multi_replace_file_content`, `list_dir`, `find_by_name`, `grep_search`, `search_web`, `read_url_content`, `run_command`, `manage_task`, `schedule`, `list_permissions`, `ask_permission`, `invoke_subagent`, `define_subagent`, `send_message`, `manage_subagents`, `ask_question`, `generate_image` | D·s hooks:123-180 | D·s | D·s | T1 as names; the prose baseline (§2.1b) excludes row 2 | — |
| 2 | `list_dir`, `find_by_name` and `grep_search` in the default toolset | D·s listed; MO last used 2026-08-25 | CL 1.2.7 retired from the default baseline; kept if listed in `tools:` | D·s listed | T4 in skill and rule prose (R13); allowed in agent `tools:` | LC1, LC8 |
| 3 | `code_search` | U | D cli/modes:85 (name only) | U | T4 | LC1, LC8 |
| 4 | `command_status` | MO | U | U | T4 (S3.5's gated row) | LC1 (S3 3k) |
| 5 | `view_file` `StartPage`, `EndPage`, `MediaResolution` | CL 2.11.0 | U | U | T3 | LC1 |
| 6 | `IsSkillFile: true` on skill reads | D·s (argument name only); MO (semantics) | U | U | Reference-only (diagnosing evidence) | LC7 |
| 7 | `ArtifactMetadata` inner keys: `ArtifactType` (`task`, `implementation_plan`, `walkthrough`, `other`), `RequestFeedback`, `Summary`, `UserFacing` | MO (re-observe: 2.13.0) | U | U | T2; no gate depends on the effect | LC1, LC5, LC1 S1-k |
| 8a | The agent writes artifacts to an explicit path in its own artifact directory | MO: in 199 of 217 `ArtifactMetadata` writes the agent itself passed an absolute `brain/<id>/` path; 18 targeted workspace paths | U | U; D settings:256 (the app-data directory "contains artifacts") | T3 | LC5 S1-g |
| 8b | A bare `TargetFile` with `IsArtifact` is routed to the artifact directory | U (the probe classified the path the agent passed, not routing) | U | U | T4: skills never rely on routing | LC5 S1-g |
| 9 | `invoke_subagent` `Workspace` values `inherit`/`branch` | D 2.0 subagents:12; MO both used; CL 2.18.1 | argument D·s hooks:167; `branch` worktrees CL 1.1.26; `inherit` U; CL 1.2.10 | argument D·s; values U | T3 (the argument is D·s; the values are named with a runtime fallback) | LC1, LC4 |
| 10 | `Workspace: "share"` semantics | D 2.0 subagents:12, the phrase "share directory storage" only | U | U | T4 | LC4 S1-f |
| 11 | `invoke_subagent` spec key `Model` | MO accepted (`inherit`, `flash`); effect unverified | U | U | T4; T2 once LC3's model leg (3a-M) shows each child's `modelName` following `flash` and `pro` on every product dispatched (D5) | LC3 |
| 12 | Child conversation id visible to the parent | MO (`INVOKE_SUBAGENT` results, 96/96) | D cli/headless:191 `subagent_info.conversation_id` (print mode) | U | T3; row 46 is the listing route | LC7 |
| 13 | Plugin `agents/` discovered; bundled TypeNames dispatched by bare name | D 2.0 subagents:37; MO `implementer`, `spec-reviewer`, `code-reviewer` | D cli/commands/agents:68; CL 1.0.1; the TypeName form is U (CL 1.1.24's de-duplication suggests no prefix) | X8 | T3 (runtime detection; S3.7's resolution chain) | LC3, LC8 |
| 14 | Documented agent keys: `name`, `description`, `tools`, `mainAgent`, `subagent`, `model`, `commandExecutionPolicy`, `mcpServers`, `skills`/`plugins` | D 2.0 subagents:45-53 | D CLI subagents:189 (by link) | U | T3 as a file format; a product that does not load agents falls to S3.7's chain | LC3 |
| 15 | Changelog-only agent keys (§3.8) | CL | CL | U | Not shipped until LC3 (S3.1) | LC3 |
| 16 | Built-ins `research` and `self` | D 2.0 subagents:21-23; MO both used | `self` CL 1.1.22; `research` U | U | T3 (`research` for exploration only; never called read-only; `self` last in S3.7's chain) | LC3 |
| 17 | `/browser` as the only entry point to the browser subagent | D 2.0 subagents:22, against CL 2.6.0 (X9) | `/browser` D slash-commands:39, :180-187 (2.0 and CLI); "exclusively" U, since the CLI tab does not repeat it | — (D ide/browser:9: the Browser Subagent works "as needed") | T3 per product | LC1 S1-a |
| 18 | Plugin `skills/` discovery | D·s plugins:14-16; MO reads from `~/.gemini/config/plugins/superpowers/skills/` | D skills:127 | D·s | T1 | — |
| 19 | Skill slash invocation | D skills:117 `/<skill-name>`; bare plugin-skill names MO 2.0 (probable) 2026-07-30 (re-observe: 2.18.1), recorded as "IDE" (§14) | D skills:131; `/<plugin>:<skill>` U-ms 2026-07-30 (product and machine unconfirmed) plus I (CL 1.2.7) | D unscoped migration/workflows-to-skills:201 (`/<name>` for workspace and global skills, not plugin skills); IDE workflows `/workflow-name` D ide/workflows:7; plugin skills U | T3 per product | LC2 S1-c, LC8 |
| 20 | Headless skill expansion, `agy -p "/<skill> …"` | — | CL 1.1.9 (un-namespaced example) | — | T3 (tests) | LC8 |
| 21 | Directory-scoped rule walk | D·s rules:13-19 | D·s | D·s | Fact behind R12 | — |
| 22 | Rule frontmatter required; invalid rules silently discarded | D·s rules:37-41 (worded for `.agents/rules`) | D·s | D·s | Fact (S2.1) | LC2 |
| 23 | `@[label](path)` inlines; `@filename` does not | D·s rules:98-103 | D·s | D·s | T1 (not used today; S2.2 gates its adoption) | LC2 |
| 24 | `@path` inlines | CL 2.11.0 (X4) | U | U | T4 | LC2 |
| 25 | Plugin `rules/` activated automatically | D·s component; activation U | D rules:160 | D·s component; activation U | Per S2.1's gate | LC2, LC8 |
| 26 | A plugin-level `hooks.json` loads | D·s plugins:13, :82 (X7) | D hooks:26 | D·s (X7) | The fork ships none at the plugin root | LC6 |
| 27 | Workspace `.agents/hooks.json` and global `~/.gemini/config/hooks.json` | D hooks:13-14 | D hooks:24-25; loading after folder trust CL 1.1.1 | D hooks:40-41 | T1 (existence; contributor gate only, S7.2) | — |
| 28 | Hook runtime: shell, cwd, exit codes, what a failure does | U; "fails closed" MO product unrecorded, 2026-08-03 (v6.2.1 release note) (re-observe: 2.0 2.6.0, 2.12.0) | U | U | T4 | LC6, LC6 S1-l |
| 29a | Transcript path `<app_data_dir>/brain/<id>/.system_generated/logs/transcript.jsonl` | D·s hooks:204-208 | D·s, against the statusline example (X2) | D·s | T1 as a path; never as proof that the file exists | — |
| 29b | The transcript file is actually written | MO (175 of 221 conversation directories) | U (X2; not observed before `agy` was installed) | X18: MO 1 of 33 directories has one | T3: diagnosing names the product and falls back to the partner's account plus the conversation's artifacts | LC7 S1-h |
| 30 | Transcript record fields; token usage | Fields MO; no token, usage or cost field MO | Token usage D cli/headless:65-70, :87, :179 (print mode) and D cli/statusline:47 (`context_window`, delivered to the partner's status-line script); quota D cli/commands/usage:26 | U | T3 (diagnosing notes, labelled) | LC7 |
| 31 | Plugin install root | D plugins:110-111; MO clone at `~/.gemini/config/plugins/superpowers` | D plugins:166, against CL 1.0.2 (X1); CL 1.2.11 | D plugins:180-181; MO `~/.gemini/antigravity-ide/plugins/` holds a Google plugin (2026-09-25 listing) | Never hard-coded in skills | LC8 S1-i, CLI C2 |
| 32 | `plugin.json` with the out-of-schema `version` key loads | MO (the d558e20 clone loads) | U (`name` required, `additionalProperties: false`) | U | recorded schema exception (D15) | LC8 |
| 33 | `ask_question` `questions` array shape | D·s hooks:177-178; MO array form accepted (the probe recorded the first element only) | D·s | D·s | T1 (shape); multi-question rendering open | LC5 |
| 34 | `ask_question` write-in answers | U | CL 1.2.7, CL 1.1.12 | U | T3 | LC1, LC5 |
| 35a | `ask_permission` `Action` strings `write_file`, `read_file` | MO | U (only the rule namespaces are D) | U | T3 | LC1 |
| 35b | `ask_permission` `Action: "unsandboxed"` | MO | deprecated as a rule namespace CL 1.2.2 (X5) | U | T4 (deprecated on one product) | LC1 |
| 36 | Plan and artifact review policy | CL 2.17.0 "Plan Review Policy" (3 values), against D unscoped artifact-review:14, :24 (2 values) (X6) | D settings:152-155 `artifactReviewPolicy` | D settings:270-276: strict mode sets "Artifact review" to "Request Review", so the policy exists; its other labels are not quoted (X6) | Describe behaviour, not setting labels | LC5 |
| 37 | `/plan` and the Implementation Plan artifact | D slash-commands:84-93 | D; plan mode D cli/modes | Plans as artifacts D ide/overview:41-43; `/plan` U | T3 | LC5 |
| 38 | `/goal`, `/grill-me`, `/learn`, `/schedule`, `/btw` | D slash-commands:29-40 | D | U | T3 | LC2 |
| 39 | `/boost` and `/teamwork-preview` | D (paid plans) | D (paid plans) | — | T4 (plan-tier-gated) | — |
| 40 | Subagent interaction timeout (60 s) | U | CL 1.0.2 | U | Risk note only | LC4 |
| 41 | Remote Control answers questions and approvals remotely | CL 2.9.1; D remote-control:23 | CL 1.2.0 and 1.2.6; D remote-control:103 | U | T3 | — |
| 42 | Windows shell used by `run_command` | D permissions:173 (PowerShell or Command Prompt possible; default undocumented) | D permissions:308; CL 1.0.10 concerns bash mode and may or may not apply to `run_command` [I] | U | R6 | LC6 |
| 43 | A backgrounded `run_command` is read back with `manage_task` `Action: "status"` | tool D·s hooks:155-156; X17 (MO `command_status` did this job) | tool D·s; `/tasks` lists "direct shell commands" D CLI subagents:202; list and kill CL 1.1.13; completion notifications CL 1.2.5 | tool D·s; addressing a run U | T3: secondary to a foreground wait with a long enough `WaitMsBeforeAsync` (S3.5, S4 EP-11), which is T1 | LC4 S1-j |
| 44 | `send_message` to a conversation id | tool D·s hooks:170-171; routing D 2.0 subagents:115-117; MO `Recipient` carries child ids | tool D·s; routing U; partner-side `@<subagent>` CL 1.2.9 | tool D·s; routing U | T3 for agent-to-agent delivery | LC4 S1-m |
| 45 | An Idle subagent re-awakens on a message with its context retained | D 2.0 subagents:103-104, :118 | U | U | T3. Used by SDD fix rounds 1-3 (register B7) and S4's "ask it to repeat the report". Fallback, T1: dispatch a fresh subagent with the task text (S4 already does this for Killed and for rounds 4-5) | LC4 S1-m |
| 46 | `manage_subagents` `list`/`kill`/`kill_all` with `ConversationIds` | D·s hooks:172-173; MO all three actions | D·s | D·s | T1 (tool and actions); what `list` returns is U | LC4 |
| 47 | `define_subagent` with `enable_write_tools`, `enable_mcp_tools`, `enable_subagent_tools` | D·s hooks:168-169; MO used; base registration toolset MO 2026-07-08 (registration read) | D·s | D·s | T1 as a tool; no skill step uses it (D6) | LC1, LC3 S1-e (S3 3j) |
| 48 | Nesting limit of 10 levels | D 2.0 subagents:123 | U | U | Risk note only | — |
| 49 | Subagents inherit the parent's command prefixes, file scopes and sandbox settings; requests bubble up | D 2.0 subagents:129-131 | bubbling D CLI subagents:220-230 (Alt+J, Ctrl+K); scopes U | U | T3 (S6.5's grants before fan-out) | LC7 |
| 50 | Agents can read each other's transcripts | D 2.0 subagents:119 | U | U | T3 (diagnosing) | LC7 |
| 51 | Non-workspace file access; the app-data directory readable by default | Windows: D agent-settings:35; macOS and Linux presets need approval outside workspace and temp D agent-settings:13-14 | `allowNonWorkspaceAccess` off D settings:157; outside reads become read-only CL 1.1.14 | D settings:252-257; strict mode disables outside access D settings:283 | T3. No pre-emptive `ask_permission` for the main agent's own file-tool reads, where the access itself prompts; a pre-emptive grant only where no card can reach the partner in time, that is before a subagent fan-out (S6.5, row 49) and for a sandbox mount of a directory that sandboxed commands must see (S5.11) | LC7 |
| 52 | Marketplace, the /plugin manager and cross-surface sync | D marketplace:12-44; CL 2.18.1 | D marketplace:46-149; D plugins:113-129 | U | README names /plugin install <local-path> for the CLI (S2.10); no skill mechanism | CLI C2 |

**Binding verdicts**

- **T1:** documented tool names; plugin `skills/`; the transcript path (as a path, never as proof the file exists); `ask_question` arrays; `manage_subagents` actions; foreground `run_command` waits; `@[label](path)` includes and the workspace/global `hooks.json` locations (existence).
- **T2:** `ArtifactMetadata` inner keys; the `Model` key once LC3's model leg shows each child's `modelName` following `flash` and `pro` on every product dispatched (S3 3a-M); until then T4, and S3.4's variant files ship (D5).
- **T3:** `Workspace` `inherit`/`branch` (S4 uses `inherit`, D4); bundled agents via S3.7's chain; `research` for exploration, never called read-only; explicit artifact paths; slash forms and `/plan`; Idle re-awakening and `send_message` by conversation id (fallback: fresh dispatch); the child conversation id; `manage_task` status (secondary to the foreground wait); `ask_question` write-in; the `ask_permission` read/write Actions; non-workspace access (pre-emptive `ask_permission` grants only before a subagent fan-out or a sandbox mount).
- **T4:** bare-`TargetFile` routing, `share`, `@path`, hook runtime, `unsandboxed`, `/boost`, `/teamwork-preview`.
- `plugin.json` keeps `version` as a recorded schema exception.

## §1 Products, roots and identifiers

- Target products: the Antigravity 2.0 app (Desktop and Web [D 2.0/CLI slash-commands:227]), the IDE and the CLI (`agy`).
- Covered releases: 2.0 to 2.18.1 (2026-09-28), CLI to 1.2.11 (2026-09-25), IDE to 2.5.5.
- Out of target:
  - the SDK, a library, whose facts are never mechanisms;
  - IDE extensions (VS Code, Visual Studio, JetBrains, Zed and Xcode). They are recorded only where a tab reads "IDE & Extensions" [D shared rules:141].
- `<app_data_dir>` [D 2.0 hooks:16; D CLI hooks:34; D IDE hooks:43; D shared hooks:204-208]:
  - 2.0: `~/.gemini/antigravity`;
  - CLI: `~/.gemini/antigravity-cli`;
  - IDE: `~/.gemini/antigravity-ide`.
- The shared config directory `~/.gemini/config/` holds `hooks.json`, `plugins/`, `skills/`, `agents/` and `rules/` [D 2.0 hooks:14; D CLI hooks:25; D IDE hooks:41; D 2.0 plugins:111; D IDE plugins:181; D 2.0 skills:109; D IDE skills:152; D 2.0 subagents:36; D CLI subagents:185; D shared rules:26].
- CLI-only locations: `~/.gemini/antigravity-cli/settings.json`, `skills/`, `rules/`, `plugins/` and `cache/last_conversations.json` [D CLI hooks:25; D CLI skills:126; D CLI rules:159; D CLI plugins:166; D CLI cli/commands/resume:97].
- Identifiers:
  - Hooks receive the conversation id as `conversationId` [D shared hooks:202].
  - The session id is the conversation UUID: the CLI's status-line `session_id` is an alias of `conversation_id` [D CLI cli/statusline:41]. The hook field `artifactDirectoryPath` [D shared hooks:211] is `brain/<id>` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
  - Headless `result` and every `step_update` carry `conversation_id`; `init` does not [D CLI cli/headless:79, :159-166, :172].
  - A `brain/<id>` directory name equals the child `conversationId` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- Per-project settings load from `<project>/.gemini/config.json`, and `.agents/settings.json` is no longer read [CL 2.0 2.17.0] (the `personal_customization_dir` note, S7.10).
- Observed directories, listed 2026-09-25, before `agy` was installed:
  - `~/.gemini/antigravity-ide/plugins/` holds one Google plugin [MO IDE ? 2026-09-25 directory listing];
  - `~/.gemini/config/` holds `projects/`, `sidecars/` and `global_workflows/` [MO 2.0/IDE ? 2026-09-25 directory listing];
  - `~/.gemini/antigravity-cli` did not exist [MO CLI ? 2026-09-25 directory listing].

## §2 Tools

Two lists (§2.1a, §2.1b), the per-product deltas (§2.2) and the traps (§2.3). §2.1a equals the `baseline` plus `retired` classes of `tests/antigravity/known-tools.txt`, which the agent lint (S7.5) and the purity gate's check 6 read; §2.1b equals its `baseline` class. A change to either list changes that file in the same commit.

### §2.1a Documented tools

Every tool on the Supported Tools list of the hooks page [D shared hooks:123-180], the legacy trio included, with its documented arguments.

| Tool | Documented arguments | Label |
|---|---|---|
| `view_file` | `AbsolutePath`, `StartLine` (optional), `EndLine` (optional), `IsSkillFile` (optional) | [D shared hooks:129-130] |
| `write_to_file` | `TargetFile`, `Overwrite`, `CodeContent`, `Description`, `IsArtifact` (optional), `ArtifactMetadata` (optional) | [D shared hooks:131-132] |
| `replace_file_content` | `TargetFile`, `Instruction`, `Description`, `AllowMultiple`, `TargetContent`, `ReplacementContent`, `StartLine`, `EndLine`, `TargetLintErrorIds` (optional) | [D shared hooks:133-134] |
| `multi_replace_file_content` | `TargetFile`, `Instruction`, `Description`, `ReplacementChunks` (array of chunks), `TargetLintErrorIds` (optional), `ArtifactMetadata` (optional) | [D shared hooks:135-136] |
| `list_dir` | `DirectoryPath` | [D shared hooks:137-138]; retired from the CLI default toolset; kept when listed in `tools:` [CL CLI 1.2.7] |
| `find_by_name` | `SearchDirectory`, `Pattern`, `Type` (optional), `Excludes` (optional), `Extensions` (optional), `FullPath` (optional), `MaxDepth` (optional) | [D shared hooks:139-140]; retired from the CLI default toolset; kept when listed in `tools:` [CL CLI 1.2.7] |
| `grep_search` | `SearchPath`, `Query`, `IsRegex` (optional), `CaseInsensitive` (optional), `Includes` (optional), `MatchPerLine` (optional) | [D shared hooks:144-145]; retired from the CLI default toolset; kept when listed in `tools:` [CL CLI 1.2.7] |
| `search_web` | `query`, `domain` (optional) | [D shared hooks:146-147] |
| `read_url_content` | `Url` | [D shared hooks:148-149] |
| `run_command` | `CommandLine`, `Cwd`, `WaitMsBeforeAsync`, `RunPersistent` (optional), `RequestedTerminalID` (optional) | [D shared hooks:153-154] |
| `manage_task` | `Action` (`list`, `kill`, `status`, `send_input`), `TaskId` (optional), `Input` (optional) | [D shared hooks:155-156] |
| `schedule` | `DurationSeconds` (optional), `CronExpression` (optional), `MaxIterations` (optional), `Prompt` | [D shared hooks:157-158] |
| `list_permissions` | none | [D shared hooks:159-160] |
| `ask_permission` | `Action`, `Target`, `Reason` | [D shared hooks:161-162] |
| `invoke_subagent` | `Subagents` (array of specs with `Prompt`, `Role`, `TypeName`, `Workspace` (optional)) | [D shared hooks:166-167] |
| `define_subagent` | `name`, `description`, `system_prompt`, `enable_mcp_tools` (optional), `enable_write_tools` (optional), `enable_subagent_tools` (optional) | [D shared hooks:168-169] |
| `send_message` | `Recipient`, `Message` | [D shared hooks:170-171] |
| `manage_subagents` | `Action` (`list`, `kill`, `kill_all`), `ConversationIds` (optional) | [D shared hooks:172-173] |
| `ask_question` | `questions` (array of questions with `question`, `options`, `is_multi_select`) | [D shared hooks:177-178] |
| `generate_image` | `Prompt`, `ImageName`, `ImagePaths` (optional) | [D shared hooks:179-180] |

### §2.1b Prose baseline

§2.1a minus the `retired` class (`list_dir`, `find_by_name` and `grep_search` [CL CLI 1.2.7]), plus any name that LC1 or LC8 records in the default toolset of all three products (S3.5's `command_status` row is the model; S7.1 then moves the name to `baseline`). Skill and rule prose names only these tools (R13).

| Tool | Label |
|---|---|
| `view_file` | [D shared hooks:129-130] |
| `write_to_file` | [D shared hooks:131-132] |
| `replace_file_content` | [D shared hooks:133-134] |
| `multi_replace_file_content` | [D shared hooks:135-136] |
| `search_web` | [D shared hooks:146-147] |
| `read_url_content` | [D shared hooks:148-149] |
| `run_command` | [D shared hooks:153-154] |
| `manage_task` | [D shared hooks:155-156] |
| `schedule` | [D shared hooks:157-158] |
| `list_permissions` | [D shared hooks:159-160] |
| `ask_permission` | [D shared hooks:161-162] |
| `invoke_subagent` | [D shared hooks:166-167] |
| `define_subagent` | [D shared hooks:168-169] |
| `send_message` | [D shared hooks:170-171] |
| `manage_subagents` | [D shared hooks:172-173] |
| `ask_question` | [D shared hooks:177-178] |
| `generate_image` | [D shared hooks:179-180] |

### §2.2 Per-product deltas

- `view_file`: `StartPage`, `EndPage` and `MediaResolution` [CL 2.0 2.11.0]. `IsSkillFile: true` is set on skill reads [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; the argument itself is documented [D shared hooks:130].
- `ArtifactMetadata`, observed on 2.0 in sessions up to 2026-08-25:
  - its inner keys `ArtifactType` (`task`, `implementation_plan`, `walkthrough`, `other`), `RequestFeedback`, `Summary` and `UserFacing` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe] (re-observe: 2.13.0);
  - it is accepted on all three edit tools, `replace_file_content` included [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; the docs list it only on `write_to_file` and `multi_replace_file_content` [D shared hooks:132, :136];
  - `IsArtifact` exists on `write_to_file` only [D shared hooks:132];
  - upstream maps its task list to `ArtifactMetadata.ArtifactType: "task"` [TP upstream v6.4.1 `references/antigravity-tools.md`]. This corroborates the observation and proves nothing further.
- `run_command`:
  - Arguments `CommandLine`, `Cwd`, `WaitMsBeforeAsync`, `RunPersistent` and `RequestedTerminalID` [D shared hooks:153-154]. The docs say "Propose a bash command".
  - On Windows, commands may run under PowerShell or Command Prompt [D 2.0 permissions:173; D CLI permissions:308]. The default shell for `run_command` is undocumented [U].
  - On Windows, a command line that cannot be split into separate words needs a full-line match, else the request falls back to Ask [D 2.0 permissions:173; D CLI permissions:308].
  - CLI 1.0.10's "defaulted shell resolution to PowerShell" is worded for bash mode, a term no docs page defines; whether it applies to `run_command` is an inference either way [CL CLI 1.0.10].
  - A command still running after `WaitMsBeforeAsync` continues in the background (X17 for how it is read back).
- `schedule`:
  - Arguments `DurationSeconds`, `CronExpression` and `MaxIterations` (all optional) and `Prompt` [D shared hooks:157-158].
  - Numeric typing of `DurationSeconds` and `MaxIterations` [CL CLI 1.1.10].
  - An "early-termination condition" is mentioned [CL CLI 1.1.12]; its parameter is undocumented [U].
  - Only `{DurationSeconds, Prompt}` has been observed [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- `manage_task` and background commands:
  - `manage_task` is the documented tool for background tasks [D shared hooks:155-156]. It is available to declarative agents that have not opted out of fundamental components [CL CLI 1.1.13].
  - Background tasks keep their names in completion notifications and task lists [CL CLI 1.2.5]. The CLI's completion notices [CL CLI 1.2.5, 1.1.13] have undocumented agent-facing semantics.
- `ask_permission`:
  - Observed `Action` values are `write_file`, `read_file` and `unsandboxed` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
  - The permission rule namespaces are documented [D 2.0 permissions:44-49, :159-165].
  - `all` is maintainer-sourced only: the 2026-07-29 reference, line 42, lists it from the maintainer's 2026-07-29 capture, and it is on no docs page and was never observed [U-ms]. It stays listed with that tag.
- `ask_question`:
  - Its shape is the documented `questions` array [D shared hooks:177-178], whose array form was observed accepted [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
  - Write-in answers are documented only for the CLI [CL CLI 1.0.3, 1.1.12, 1.2.7].
  - Cancel is documented for 2.0 [CL 2.0 2.13.0].
- `invoke_subagent`: the `Model` spec key is accepted [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; the result carries the child `conversationId` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; in headless output `subagent_info` has `type_name`, `role`, `conversation_id`, `log_uri` and `workspace_uris` [D CLI cli/headless:191].
- `define_subagent`: `name`, `description`, `system_prompt`, and the optional `enable_mcp_tools`, `enable_write_tools` and `enable_subagent_tools` [D shared hooks:168-169; MO 2.0 ≤2.10.0 2026-08-25 transcript probe]. The flags' effects and defaults are undocumented [U]. On 2.0, registrations are stored per conversation under `brain/<id>/.agents/agents/<name>/agent.json`, with `hidden: true`; the base tool set is `send_message`, `find_by_name`, `grep_search`, `view_file`, `list_dir`, `read_url_content`, `search_web` and `schedule`, and a larger set adds the three write tools, `run_command` and `manage_task` [MO 2.0 ≤2.10.0 2026-07-08 registration read]. That the larger set is what `enable_write_tools: true` yields is an inference [I].
- Legacy `list_dir`, `find_by_name` and `grep_search` were retired from the CLI's default baseline, and stay available to agents that list them in `tools` [CL CLI 1.2.7]. They are still listed on the hooks page (X13). 2.0 and the IDE have no retirement entry.
- Tools not on the documented list:
  - `command_status {CommandId, OutputCharacterCount, WaitDurationSeconds}`, observed on 2.0 and undocumented [MO 2.0 ≤2.10.0 2026-08-25 transcript probe];
  - `manage_inbox` [CL CLI 1.1.13];
  - `code_search` [D CLI cli/modes:85];
  - `read_resource` (MCP) [CL CLI 1.1.16];
  - `browser_*` names [U]. The only source is the matcher regex example [D shared hooks:117].

### §2.3 Traps

- `Subagents` is always an array.
- Artifact typing lives inside `ArtifactMetadata`, never at the top level.
- `ask_permission` requests scoped permissions. It is not a confirmation dialog.
- `define_subagent` takes no `model`, `tools` or `Workspace` argument; its capability switches are the three `enable_*` flags [D shared hooks:169].
- A misspelled name in `tools:` may hang the subagent [D 2.0 subagents:55].

## §3 Subagents and custom agents

The `subagents` page is tabbed throughout (§0.2): its 2.0 tab documents the dispatch model, and its CLI tab the panels and Markdown agents.

### §3.1 Workspace modes

- The `Workspace` argument is optional [D shared hooks:167].
- `inherit`: "the same workspace as its parent". Writes land in the parent's checkout, and there is no read-only property [D 2.0 subagents:12].
- `branch`: an isolated Git worktree [D 2.0 subagents:12], created under `.system_generated/worktrees` [CL CLI 1.1.26].
- Subagent worktrees live under the app data directory's `worktrees/`, no longer in conversation directories or treated as artifacts [CL CLI 1.2.10; CL 2.0 2.18.1].
- `share`: documented only as "share directory storage". Its path, lifetime and git state are unverified [U] (LC4 S1-f).
- Parents keep full access to their subagents' workspaces, including worktrees [D 2.0 subagents:130].
- Killing a subagent cleans up its worktrees [D 2.0 subagents:110]. So branch results must be integrated before the kill [I].
- Parallel `inherit` subagents that each commit share one checkout and race on `.git/index.lock` [I].
- The CLI tab does not repeat the workspace sentence.

### §3.2 Built-in subagents

- `research`, `browser` and `self` [D 2.0 subagents:21-23]. `self` is "a direct clone of the calling agent, sharing identical system instructions and toolsets" [D 2.0 subagents:23].
- `research` has no documented toolset and no read-only property.
- Its CLI availability is unverified [U]. `self` exists on the CLI [CL CLI 1.1.22].
- Upstream calls `research` "read-only" [TP upstream v6.4.1]. That is not evidence either way.

### §3.3 Lifecycle and communication

- Running, Idle, Killed; re-awakening; context retained [D 2.0 subagents:90-111].
- CLI panel states: running, done, killed, error [D CLI subagents:173].
- Stopping a parent stops nested subagents [CL 2.0 2.6.0].
- Live subagent cards [CL 2.0 2.16.0].
- `send_message` routing by conversation id, auto-wake and shared transcripts [D 2.0 subagents:115-119]. The tool itself is shared [D shared hooks:170-171].
- `@<subagent> <message>` from the partner [CL CLI 1.2.9]. `/btw` [D 2.0/CLI slash-commands:40].
- `manage_subagents` lists and kills by `ConversationIds` [D shared hooks:172-173; MO 2.0 ≤2.10.0 2026-08-25 transcript probe].

### §3.4 Nesting

- Maximum depth 10 [D 2.0 subagents:123].
- `/boost` and teamwork run nested hierarchies [D 2.0/CLI boost:29-43; D 2.0/CLI teamwork:26-35].
- Agents that list `invoke_subagent` in `tools` receive the roster [CL CLI 1.2.5].
- P4 (a plugin agent dispatches, resumes and relays `implementer`; S3.10): not run.

### §3.5 Permissions and timeouts

- Subagents inherit command prefixes, file scopes and sandbox settings, and permission requests bubble up [D 2.0 subagents:129-131]. On the CLI, subagent approvals surface to the partner through Alt+J and Ctrl+K [D CLI subagents:216-230].
- The default 60-second interaction timeout applies to subagents [CL CLI 1.0.2].
- Approvals are remembered for the conversation [CL 2.0 2.5.0; CL CLI 1.1.9].

### §3.6 Discovery and TypeNames

- Discovery locations: workspace, global and `plugins/<plugin_name>/agents/` [D 2.0 subagents:35-37].
- CLI: workspace and global [D CLI subagents:182-185]; plugin agents [D CLI cli/commands/agents:68; CL CLI 1.0.1].
- Project custom agents in `.agents/agents/` are found in Desktop-created workspaces, trusted workspaces, `--agent` and headless runs [CL CLI 1.2.11], so probe 3e and E9 count only on CLI 1.2.11 or later.
- IDE: ambiguous, not undocumented (X8).
- Bundled agents are documented on 2.0 and the CLI, unverified on the IDE.
- Bare bundled TypeNames resolve on 2.0 [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- The CLI TypeName form is unverified [U]. Same-name agents are de-duplicated across plugins [CL CLI 1.1.24], which suggests there is no prefix [I].

### §3.7 Documented frontmatter

The documented keys, with their defaults [D 2.0 subagents:45-53; D CLI subagents:189]:

| Key | Type | Default |
|---|---|---|
| `name` | string | required |
| `description` | string | required |
| `tools` | string[] | `[]` |
| `mainAgent` | boolean | `true` |
| `subagent` | boolean | `true` |
| `model` | string (`inherit`, `flash` or `pro`) | `inherit` |
| `commandExecutionPolicy` | string (`off`, `auto`, `eager` or `sandbox`) | `sandbox` |
| `mcpServers` | object[] | `[]` |
| `skills` / `plugins` | string[] | `[]` |

### §3.8 Keys beyond the docs table

Each changelog-only agent key, with its product and version (S3.1 decides which keys ship):

| Key | Source | What it says |
|---|---|---|
| `inheritCustomizations` | [CL 2.0 2.9.1; CL CLI 1.1.14] | Adoption of skills, rules, plugins, subagents and MCP servers (2.0: skills, rules and subagents) |
| Default inheritance | [CL CLI 1.1.25] | Markdown agents inherit ambient skills, rules and subagents by default. There is no 2.0 counterpart (X16) |
| `rules:` | [CL 2.0 2.11.0; CL CLI 1.1.15] | Names rule files "instead of inheriting your whole rule tree" |
| `agents:` | [CL CLI 1.1.27] | Declares dependent subagents; path rules as for `skills:`: workspace-relative, absolute, agent-relative |
| `excludeDefaultComponents` | [CL CLI 1.2.1]; 2.0 describes the capability without naming a key [CL 2.0 2.15.0] | Drops default prompt sections and built-in tools. So custom agents otherwise receive a default built-in toolset whose contents are undocumented |
| `hooks:` | [CL 2.0 2.17.0] | Per-agent hook files |
| `hidden`, `inheritMcp` | [CL CLI 1.1.6] | Named only |
| `inherit_user` | [CL CLI 1.1.14] | Named in a fix only |
| `permissionMode: acceptEdits` | [CL blog 2026-08-12 2.0/CLI] | Blog only |

`inheritCustomizations` governs "skills, rules, plugins, subagents, and MCP servers" [CL CLI 1.1.14], not `tools:` (§3.9).

### §3.9 Inheritance does not grant tools

Tools are the explicit list [D 2.0 subagents:47]; `inheritCustomizations` adopts skills, rules, plugins, subagents and MCP servers [CL CLI 1.1.14] (2.0: skills, rules, subagents [CL 2.0 2.9.1]); neither list includes built-in tools; CLI Markdown agents inherit ambient skills, rules and subagents by default [CL CLI 1.1.25]; rosters reach only agents listing `invoke_subagent` [CL CLI 1.2.5]; the default toolset is `[U]`, and its one documented member, `manage_task`, cannot dispatch; `self` shares its caller's tools [D 2.0 subagents:23]. Hence [I, pending LC3 S1-e] no bundled agent can open a review seat but `self` can, so `self` is the last subagent step: bare TypeName, `superpowers:` TypeName, `self`, then the consumer's own path, each fallback ledgered (D6). Skipped in v6.3.0; reversed in d58690c and reverted in 1f9860d (2026-08-24): "this is a native port, the skip stands" (maintainer instruction). Accepted residuals (D15): a duplicated review seat via `self` (cost, not correctness); a bundled agent reached by the bootstrap rule reviews inline at worst (`<SUBAGENT-STOP>`). Re-open if LC3 S1-e or S3 3i finds an unlisted dispatch tool, a skill uses `self` earlier, or a changelog adds dispatch tools to the defaults.

**Gate.** LC3 S1-e. Default: keep the skip. Fallback: d58690c's Task 8 verbatim at its placements (three reviewer blocks, `implementer.md`, both SDD hunks; placement-only divergence), plus the reviewer block in `final-reviewer.md` and the implementer block in any S3.4 variants (`session-analyst`, `bundle-scrubber`: none); record it in §3.9 and weigh `excludeDefaultComponents`.

### §3.10 Models

- `model` is `inherit`, `flash` or `pro` [D 2.0 subagents:50].
- With `inherit`, a subagent whose parent has no model falls back to the fast tier [CL CLI 1.1.16].
- What `flash` and `pro` map to is undocumented.
- No per-invocation override is documented (R7). The `invoke_subagent` spec key `Model` is accepted [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; effect unverified (R7, D5).
- `/model <name> <prompt>` is a one-shot for the main agent only [CL CLI 1.1.27].
- Arbitrary model targets per subagent, independent of the root agent, exist only in the SDK [CL SDK 0.1.18]. The product mechanism is the `model` frontmatter key.
- Current models: Gemini 3.8, 3.7 and 3.6 Flash, Gemini 3.1 Pro, Claude Sonnet 4.6 and Opus 4.6, and GPT-OSS-120b [D unscoped models:9-15]. Skills never name model slugs (X15).

## §4 Skills

- Anatomy (`scripts/`, `examples/`, `resources/`), frontmatter (`name` optional and defaulting to the folder name; `description` required) and progressive disclosure [D shared skills:23-29, :59-60, :70-72].
- Bundled scripts are documented. How their paths and working directory resolve is unverified [U]. The docs advise to "encourage the agent to run them with `--help` first" [D shared skills:88].
- Locations per product:

  | Scope | 2.0 | CLI | IDE |
  |---|---|---|---|
  | Workspace | `.agents/skills/<skill-folder>/` [D 2.0 skills:108] | `.agents/skills/<skill-folder>/` [D CLI skills:125] | `.agents/skills/<skill-folder>/` [D IDE skills:151] |
  | Global (personal) | `~/.gemini/config/skills/<skill-folder>/` [D 2.0 skills:109] | `~/.gemini/antigravity-cli/skills/<skill-folder>/` [D CLI skills:126] | `~/.gemini/config/skills/<skill-folder>/`, and the legacy `~/.gemini/antigravity/skills/` [D IDE skills:152] |
  | Plugin | a plugin's `skills/` [D shared plugins:14-16, :78] | `~/.gemini/antigravity-cli/plugins/<name>/skills/` [D CLI skills:127] | a plugin's `skills/` [D shared plugins:14-16, :78] |

  The legacy workspace `.agent/skills` is still read [D shared skills:17].
- Skill frontmatter:
  - `name` defaults to the folder name [D shared skills:59];
  - `disable-slash-command` [CL CLI 1.1.12];
  - `metadata.icon` [CL CLI 1.1.20]; 2.0's icon source is unstated.
- Slash invocation:
  - 2.0: `/<skill-name>` [D 2.0 skills:117]. The palette resolves bare plugin-skill names and shows descriptions truncated to about one line [MO 2.0 (probable) ? 2026-07-30 slash palette] (re-observe: 2.18.1). The 2026-07-29 reference, line 122, recorded this observation as "IDE"; it was made in the 2.0 app (§14).
  - CLI: automatic slash conversion [D CLI skills:131]. The plugin form `/<plugin>:<skill>` [U-ms 2026-07-30]: the 2026-07-29 reference, line 120, gives it, but its product and machine are unconfirmed, since `agy` was not installed and no `~/.gemini/antigravity-cli` existed on the maintainer machine. CLI 1.2.7's fix for double-prefixed plugin skill commands implies it [I from CL CLI 1.2.7], and plugins are "namespaced bundles" [D CLI cli/features:5].
  - IDE: `/<name>` for workspace and global skills [D unscoped migration/workflows-to-skills:201]; IDE workflows use `/workflow-name` [D IDE ide/workflows:7]; plugin skills are unverified [U].
  - Headless: `agy -p "/<skill> …"` resolves the skill [CL CLI 1.1.9], shown only with an un-namespaced example. `--disable-slash-commands` opts out.
  - Whether slash-expanded skill content shows the agent a file path is unverified [U] until Live check 7(b).
- Other skill features:
  - print-mode `/skills` [CL CLI 1.1.11];
  - `/skills reload` [CL CLI 1.2.4];
  - `skills.json`, `agents.json` and `rules.json` are discovered in project subdirectories [CL 2.0 2.11.0].
- `view_file` accepts `IsSkillFile` [D shared hooks:130], and it is set on skill reads [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- Markdown agents inherit ambient rules by default [CL CLI 1.1.25], and an agent's `rules:` key replaces the rule tree [CL CLI 1.1.15] (§3.8).
- Built-in skills:
  - `antigravity_guide` [CL CLI 1.0.10; CL 2.0 2.2.1; CL IDE 2.5.2];
  - `migrate-workflows` [CL CLI 1.1.22]; `/migrate-workflows` on the IDE [D IDE ide/workflows:5].
- Workflows are deprecated and retire on 2026-11-01 [D unscoped migration/workflows-to-skills:7], and skills take precedence over same-named workflows [D unscoped migration/workflows-to-skills:205].

## §5 Rules

- Sources and precedence: rules are cumulative, and the more specific directory rules win conflicts [D shared rules:11].
- The directory-scoped walk [D shared rules:13-19]:
  - `<dir>/AGENTS.md`, `<dir>/GEMINI.md`, `<dir>/.agents/AGENTS.md`, `<dir>/.agents/GEMINI.md`, `<dir>/.agents/rules/*.md` and the legacy `<dir>/.agent/rules/*.md`;
  - the walk runs at every level from the file read up to the workspace root;
  - for a plugin installed at `<ws>/.agents/plugins/superpowers/`, every tracked file of that kind in the plugin's tree is in the walk [I from D shared rules:15]. This includes a plugin-root `GEMINI.md`, and it is why agent-facing files are banned from the repository (S2.7, R12);
  - whether the walk runs for files outside the workspace (global installs) is unverified [U].
- The scan of `.agents/rules/` is flat [D shared rules:30].
- Frontmatter:
  - It is required in `rules/` files, and a missing frontmatter or an invalid `trigger` means the rule is silently discarded [D shared rules:37-41], worded for `.agents/rules/*.md`.
  - Triggers are `always_on`, `model_decision`, `glob` and `manual` [D shared rules:47, :55]; `always_on` injects the full content on every turn [D shared rules:75].
  - `description` is required for `model_decision`, and serves as the fallback for over-budget `always_on` rules [D shared rules:56].
- Includes and limits:
  - `@[label](path)` inlines the file, resolves relative to the rule file and strips frontmatter. `@filename` does not inline [D shared rules:98-103]. Includes work in `AGENTS.md`, `GEMINI.md` and `.agents/rules/*.md` [D shared rules:98].
  - Bare `@path` inlining is contested: 2.0 2.11.0 says `@path/to/file` inlines [CL 2.0 2.11.0], and the rules page says `@filename` does not (X4).
  - `@` has no documented meaning inside a skill: writing-skills' "force-loads" (`skills/writing-skills/SKILL.md:288-290`) describes another harness's `@` links.
  - `.agents/rules.json` supports `inherits`, `entries`, `include_only` and `exclude` [D shared rules:114-126].
  - Limits: 24,000 bytes per file after includes, and a 20,000-token budget in which the largest rules are demoted to `- <path>: <description>` [D shared rules:132-133]. The budget is also stated in 2.0 2.17.0 and CLI 1.2.7 [CL 2.0 2.17.0; CL CLI 1.2.7]; the CLI entry says it covers "user and workspace rules" (X12).
  - The 2.0 token-usage breakdown shows rules and other customizations as separate bars against their own budgets, and flags rules or customizations that were left out or included by path only after going over budget [CL 2.0 2.18.1].
- `rules.json` files:
  - `.agents/rules.json` [D shared rules:114-126];
  - a plugin top-level `rules.json` [CL CLI 1.1.15];
  - `skills.json`, `agents.json` and `rules.json` in project subdirectories [CL 2.0 2.11.0].
- Locations by product:
  - global standalone files (no frontmatter, always active) `~/.gemini/AGENTS.md`, `~/.gemini/GEMINI.md`, `~/.gemini/config/AGENTS.md` and `~/.gemini/config/GEMINI.md`, and modular global rules (frontmatter required) in `~/.gemini/config/rules/*.md` [D shared rules:25-26];
  - workspace and global rule locations per product [D 2.0 rules:151-152; D CLI rules:158-160; D IDE rules:170-171]; the CLI adds `~/.gemini/antigravity-cli/rules/*.md` [D CLI rules:159];
  - plugin rules are activated automatically [D CLI rules:160]. On 2.0 and the IDE activation is unverified [U], although `rules/` is a documented plugin component [D shared plugins:19, :80].
- Agent `rules:` key: §3.8.
- `/learn` output location: X10.

## §6 Plugins

- Tree and components: `plugin.json`, `mcp_config.json`, `hooks.json`, `skills/`, `agents/` and `rules/` [D shared plugins:9-21, :76-82].
- Manifest schema [D shared plugins:39, :52-71]:
  - `name` is required on the CLI and optional on 2.0 and the IDE;
  - the pattern is `^[a-zA-Z0-9-_]+$`, with `additionalProperties: false`;
  - the `$schema` URL returned 404 on 2026-09-25 [MO docs ? 2026-09-25 schema URL fetch].
- `plugin.json` keeps `version` outside the published schema: a recorded schema exception, with no `$schema` (D15).
- Installation by product:
  - 2.0 and the IDE: `.agents/plugins/` for a workspace (it "activates only when working in that project") or `~/.gemini/config/plugins/` [D 2.0 plugins:110-111; D IDE plugins:180-181].
  - CLI: `agy plugin list|install|enable|disable|uninstall`, with staging at `~/.gemini/antigravity-cli/plugins/<plugin_name>/` [D CLI plugins:131-167]. This conflicts with CLI 1.0.2, which names the shared `~/.gemini/config/` [CL CLI 1.0.2] (X1).
  - The CLI also loads plugins placed directly in `~/.gemini/config/plugins` [CL CLI 1.2.11].
  - CLI: `agy plugin import gemini` converts Gemini CLI extensions [D CLI cli/gcli-migration:3, :26].
  - A `~/.gemini/antigravity-ide/plugins/` directory has been observed locally [MO IDE ? 2026-09-25 directory listing].
- Marketplace, the `/plugin` manager and cross-surface sync: plugins install from a Marketplace; the `/plugin` manager (`install <plugin>@<marketplace>`, `install <local-path>`, `list`, `enable`, `disable`, `uninstall`) manages them; and plugins installed in 2.0 appear in the CLI's Installed tab [D 2.0/CLI marketplace:7; D CLI marketplace:121-129; D CLI plugins:113-129; CL 2.0 2.18.1]. 2.0 lists them in the Customizations tab's Marketplace and Installed views [D 2.0 plugins:92-104].
- Changelog-only features:
  - install from GitHub subpaths with branch resolution [CL CLI 1.0.7];
  - `${extensionPath}` resolution [CL CLI 1.0.7];
  - clean reinstall [CL CLI 1.1.28];
  - plugin import copies the entire plugin directory [CL CLI 1.0.14];
  - plugin MCP servers namespaced [CL CLI 1.2.2];
  - enablement lives only in `config.json` [CL CLI 1.1.11];
  - a marketplace cache [CL CLI 1.2.7];
  - directory entries in `skills.json`, `rules.json`, `agents.json` and `plugins.json` load only their direct children [CL CLI 1.2.10].
- A third-party porting guide claims that `agy` keeps a declared `contextFileName` and strips undeclared files [TP].
- Sidecars: `plugins/<pluginName>/sidecars/` and `builtin: schedule` [D unscoped sidecars:11, :37].
- Projects: "Reusable skills, MCPs, and hooks are managed globally" under the Project model, and New Worktree Mode isolates concurrent agents [D 2.0 projects:20, :47]. How that interacts with workspace plugin and hook installs is unverified [U] until leg 2d.
- This fork is installed on the maintainer's 2.0 as a git clone at `~/.gemini/config/plugins/superpowers` (d558e20) whose `plugin.json` carries `version`, and its skills load [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].

## Revision log

- 2026-10-05 — §0–§6 — created from the 2026-09-25 and 2026-09-29 docs captures and the changelog to 2.0 2.18.1 and CLI 1.2.11; IDE U cells re-checked; 2026-07-29 reference frozen — maintainer instruction
