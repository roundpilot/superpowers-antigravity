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

## §7 Hooks

The hooks page is tabbed only for locations and toggles; its schema and contract are shared (§0.2).

### §7.1 Locations and toggles

- Workspace `.agents/hooks.json` in the workspace root, and global `~/.gemini/config/hooks.json`, on all three products [D 2.0 hooks:13-14; D CLI hooks:24-25; D IDE hooks:40-41].
- CLI only: also `~/.gemini/antigravity-cli/settings.json`, and a plugin-level `hooks.json` [D CLI hooks:25-26].
- The plugin tree lists `hooks.json` for all products [D shared plugins:13, :82] (X7).
- Toggles:
  - 2.0: Settings > Customizations > Hooks [D 2.0 hooks:16];
  - IDE: … > Customizations > Hooks in the agent side panel [D IDE hooks:43];
  - CLI: `/hooks` for inspection [D CLI hooks:28-32];
  - `"enabled": false` in the file disables a hook without removing it [D shared hooks:93].
- The workspace `.agents/settings.json` hooks location in the 2026-07-29 reference, line 104, was never documented. 2.0 2.17.0's "no longer read" concerns repository customization settings, not hooks [CL 2.0 2.17.0].

### §7.2 Schema

- The file maps hook names to events [D shared hooks:47-87]. Tool events take `matcher` plus a `hooks` list; PreInvocation, PostInvocation and Stop take a list of handlers directly [D shared hooks:121].
- Handler fields: `type` (only `command`), `command`, and `timeout`, which defaults to 30 seconds [D shared hooks:186-190].

### §7.3 Events and contract

- Five events: PreToolUse, PostToolUse, PreInvocation, PostInvocation and Stop [D shared hooks:102-108]. The matcher is a regex for the tool events, `""` or `"*"` matches all tools [D shared hooks:114], and it is ignored for the others [D shared hooks:121].
- Hooks read JSON on stdin and write JSON on stdout [D shared hooks:194].
- Common input fields: `conversationId`, `workspacePaths` (it can hold several roots), `transcriptPath`, `artifactDirectoryPath` and `modelName` [D shared hooks:196-212].
- PreToolUse input: `toolCall.name`, `toolCall.args` and `stepIdx` [D shared hooks:226-229]. Decisions: `allow`, `deny`, `ask`, `force_ask` and `deny_unless_prior_grant`, plus `reason` and `permissionOverrides` [D shared hooks:236-243]. `allow` "Automatically allows the tool execution" [D shared hooks:237], so an allowing PreToolUse hook would also skip the permission prompt [I].
- PostToolUse input: `toolCall` (`name` and `args`), `stepIdx` and `error`; it returns `{}` [D shared hooks:288-295].
- PreInvocation receives `invocationNum` and `initialNumSteps` and may return `injectSteps` (`toolCall`, `userMessage` or `ephemeralMessage`) [D shared hooks:333-349].
- PostInvocation may also return `terminationBehavior` [D shared hooks:383-393].
- Stop receives `fullyIdle` and `terminationReason`, and returns `decision: "continue"` with a `reason` to keep the agent running [D shared hooks:415-430].

### §7.4 Changelog behaviours

- Hooks run before the built-in termination checks [CL CLI 1.1.10].
- Stop-hook loops are bounded [CL CLI 1.1.9; CL 2.0 2.6.0].
- Configurations that could never run are rejected at load time [CL 2.0 2.6.0].
- A failing hook "is now reported as an error and the conversation continues" [CL 2.0 2.12.0]. What that means for the gated tool call is unstated.
- Workspace hooks were fixed to load after a folder is trusted [CL CLI 1.1.1]; that trust gates loading is an inference [I].
- Empty decision strings returned by pre-tool hooks are handled safely instead of failing [CL CLI 1.0.16].
- `/hooks` writes to the shared `~/.gemini/config/hooks.json`, not a CLI-private file [CL CLI 1.0.8].
- Plugin hooks appear in `/hooks` [CL CLI 1.2.3].
- `hooks.json` was silently dropped under customization budget truncation, now fixed [CL CLI 1.2.4].
- Agent `hooks:` front matter [CL 2.0 2.17.0] (§3.8).

### §7.5 Precedence

"workspace-specific hooks … taking precedence if it exists" [CL blog 2026-05-19 unscoped]. It counts as `[U]` for eligibility, and the docs are silent.

### §7.6 Undocumented runtime

Unverified on every product [U] until LC6 and LC6 S1-l:

- the shell, the working directory, exit-code semantics, and what an unrunnable handler does;
- whether `${extensionPath}` expands in `hooks.json` (CLI 1.0.7's fix concerns variables in plugins generally [CL CLI 1.0.7], so its reach here is an inference [I]);
- what an empty stdout from a hook does: a third-party report says it denies every call the matcher covers [TP cmux #5358] (the 2026-07-29 reference, line 106).

Observed so far:

- A hook Antigravity cannot run (the v6.2.0 gate where `bash` is missing) fails closed and blocks file writes [MO 2.0 ≤2.10.0 2026-08-03 v6.2.1 release note] (re-observe: 2.6.0, 2.12.0).
- What `toolCall.args` holds is documented only as "Arguments passed to the tool call" [D shared hooks:228]. A structure-only read of 175 2.0 transcripts recorded the argument forms, not the hook payload [MO 2.0 ≤2.10.0 2026-08-25 structure probe]:
  - 62 `multi_replace_file_content` calls, the newest on 2026-07-31; every one of the 81 decodable chunks has exactly `TargetContent`, `ReplacementContent`, `StartLine`, `EndLine` and `AllowMultiple`; 28 of the 62 chunk arrays do not parse, 18 of them in records with `truncated_fields`;
  - transcript `args` store string values JSON-encoded and other values as JSON text, so `ReplacementChunks` is recorded as text. Whether the hook payload carries an array or text is not observed, so a hook accepts both;
  - `TargetFile` forms across 637 file-tool calls: `X:\` 359, `x:\` 91, `x:/` 17, `\\wsl…` UNC 148, POSIX-absolute 21, relative 1. That the hook payload uses the same forms is an inference [I].

### §7.7 Corrections

The 2026-07-29 reference's hook errors (lines 102-108) are listed in §14.

## §8 Artifacts, planning and review

- Documented kinds: Implementation Plans, code diffs, architecture diagrams, images and browser recordings [D 2.0/CLI artifacts:3]; on the IDE, "rich markdown plans, code diff views, architecture diagrams, images, and browser recordings" [D IDE ide/overview:41-43]. Walkthroughs [D unscoped walkthrough:3].
- "Task lists" as an artifact category appear only in the 2025-11-18 launch blog [CL blog 2025-11-18 unscoped]. No docs page and no changelog entry mentions `task.md`.
- `ArtifactType: "task"` was used 21 times [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; upstream's claim corroborates it [TP upstream v6.4.1 `references/antigravity-tools.md`].
- Location:
  - The artifact directory is `artifactDirectoryPath` [D shared hooks:211]. That it equals `<app_data_dir>/brain/<conversationId>` is an inference from the payload example [I from D shared hooks:263].
  - The IDE's app-data directory "contains artifacts, knowledge items, and configuration files" [D IDE settings:256]; 2.0's, on Windows, "contains Artifacts, Knowledge Items" [D 2.0 agent-settings:35].
  - Observed: in 199 of 217 `ArtifactMetadata` writes the agent itself passed an absolute path under `brain/<id>/`; 18 writes targeted workspace paths [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]. `task.md`, `implementation_plan.md` and `walkthrough.md` sit there with `.metadata.json` and `.resolved.N`.
  - Whether a bare `TargetFile` is routed to the artifact directory is unverified on every product [U] (§0.5 row 8b; LC5 S1-g).
  - Whether the agent is told its artifact directory is unverified [U]; on 2.0 it evidently knew it [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
  - Artifacts in subdirectories now appear in the list [CL 2.0 2.11.0; CL CLI 1.1.15].
  - Scratch files are hidden unless marked user-facing [CL 2.0 2.13.0], so `task.md` is never written under `scratch/` [I].
- HTML and generative-UI artifacts [CL 2.0 2.11.0].
- Knowledge Items: 2.0 [D 2.0 agent-settings:35], IDE [D IDE settings:256]. The IDE's records include a `KNOWLEDGE_ARTIFACTS` type [MO IDE ? 2026-09-25 transcript probe].
- Task Groups:
  - The agent manages them in planning mode [D unscoped tools:3]; no documented tool creates them (§2.1a).
  - Planning Mode "organizes its work in task groups" [D unscoped artifact-review:5].
  - Teamwork keeps plan and progress artifacts [D 2.0/CLI teamwork:82-86].
- `/plan` and plan mode:
  - `/plan` drafts an Implementation Plan artifact for review on 2.0 and the CLI [D 2.0/CLI slash-commands:3, :84-93; D 2.0/CLI plan:3]. The IDE is named on no `/plan` page; the untabbed implementation-plan page mentions `/plan` without naming a product [D unscoped implementation-plan:7].
  - CLI modes are `default`, `accept-edits` and `plan` [D CLI cli/modes:16-18]. Plan mode prepends the `/plan` prefix and uses read-only tools [D CLI cli/modes:85].
  - The partner selects the mode: Shift+Tab or `--mode=plan` on the CLI [D CLI cli/modes:26, :82], Planning or Fast at the start of a conversation [D unscoped artifact-review:3-6].
  - Plan Review Policy governs `/plan` on 2.0 [CL 2.0 2.17.0].
  - Headless runs proceed through plan review automatically [CL CLI 1.1.28].
- Review setting per product (X6):
  - 2.0: "Plan Review Policy", with three behaviours: review every plan, review only when the agent judges it worthwhile, or skip review [CL 2.0 2.17.0]. The artifact-review page still names two options [D unscoped artifact-review:8-29].
  - CLI: `artifactReviewPolicy`, whose values are `asks-for-review`, `agent-decides` and `always-proceed`, and which also gates code files [D CLI settings:152-155]. The CLI's artifact picker approves or rejects per file and takes line comments [D CLI cli/artifacts:18-56, :144-151].
  - IDE: the policy exists; strict mode sets it to "Request Review", and "the agent always prompts for confirmation before acting on plans laid out in artifacts" [D IDE settings:270-276]. The IDE's Review Changes pane takes comments on diffs "just like with artifacts" [D IDE ide/review-changes-editor:3-7]. The non-strict values, Request Review or Always Proceed "When working in Planning Mode", come only from the unscoped artifact-review page [D unscoped artifact-review:8-29].
- CLI write approval: `y` approves one file, Shift+A approves all pending files [D CLI cli/artifacts:51, :53], and `accept-edits` approves writes automatically [D CLI cli/modes:17]. The approval is consent to write, not a review verdict [I]. Whether a repository-path artifact appears in `/artifact` is open (LC5 5a); CLI 1.2.2's fix hints that the review trigger is keyed to the app-data path [CL CLI 1.2.2].

## §9 Permissions, sandbox and settings

- macOS and Linux (2.0): the presets are Default, Request Review and Turbo. Under Default and Request Review the agent reads and writes the workspace (and, under Default, temp directories) and "needs approval for anything else" [D 2.0 agent-settings:13-15; D 2.0 permissions:26-38].
- Windows (2.0) keeps the older settings [D 2.0 agent-settings:21-44; D 2.0 permissions:137-253]:
  - Terminal Command Auto Execution;
  - Agent Non-Workspace File Access. By default the app-data directory `~/.gemini/antigravity/` is accessible [D 2.0 agent-settings:35];
  - Terminal Sandbox Mode.
- IDE [D IDE settings:241-283]:
  - terminal command auto execution: Request Review or Always Proceed [D IDE settings:245-250];
  - agent non-workspace file access. By default the app-data directory `~/.gemini/antigravity-ide/` is accessible [D IDE settings:252-257];
  - strict mode: terminal, browser JavaScript and artifact review set to "Request Review" [D IDE settings:270-276]; "Respect .gitignore" [D IDE settings:282]; "Workspace isolation" disables access outside the workspace [D IDE settings:283].
- These boundaries can block skill reads: the IDE's default non-workspace access, IDE strict mode (`.gitignore`, workspace isolation) and 2.0's Windows outside-of-folder file access policy [D IDE settings:252-257, :282-283; D 2.0 settings:50]. Their effect on plugin skill reads is unverified [U] until LC2 2e.
- File and network sandboxing on Windows [CL 2.0 2.15.1]. WSL [CL 2.0 2.16.0].
- Rule namespaces:
  - `read_file` and `write_file` default to "Ask (Allowed in workspace)";
  - `read_url`, `execute_url`, `command` and `mcp`;
  - `unsandboxed` (X5) [D 2.0 permissions:44-49, :159-165]. The CLI lists the same namespaces, `unsandboxed` included [D CLI permissions:283-291].
- Precedence is Deny > Ask > Allow [D 2.0 permissions:24, :153; D CLI permissions:271].
- Exact-match fallback: command or process substitution, fd or network redirections, and (on Windows) commands that cannot be split into words fall back to Ask. Simple file redirects prefix-match normally [D 2.0 permissions:57-59, :173-175; D CLI permissions:308].
- Windows command matching: a command line that cannot be split into separate words needs a full-line match, else Ask [D 2.0 permissions:173; D CLI permissions:308]. To match a command and its subcommands, the Windows CLI needs `regex:` rules [D CLI permissions:308].
- The hooks page still calls `run_command` "a bash command" [D shared hooks:153], and the shell on Windows is undocumented [U] (§2.2).
- Windows paths are normalised by stripping the drive letter and using forward slashes [D 2.0 permissions:71, :187; D CLI permissions:304].
- Sandbox mounts: paths granted under `read_file` mount read-only inside the sandbox, and `write_file` grants mount read-write [D 2.0 sandbox:54, :102; D CLI sandbox:152]. A command run outside the sandbox runs "on your host with full privileges" [D 2.0 sandbox:41, :96]. The `ask_permission` Action `read_file` is observed on 2.0 [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- Edit tools prompt for files in `.git`, `.env` and `.vscode` under the Default and Request Review presets [CL 2.0 2.18.1].
- CLI settings:
  - `allowNonWorkspaceAccess` is off by default [D CLI settings:157];
  - outside-workspace access is read-only [CL CLI 1.1.14].
- The project option was renamed "Inherit Global" [CL 2.0 2.14.0] (X11).

## §10 Transcripts and session data

- Path per product: `<app_data_dir>/brain/<conversationId>/.system_generated/logs/transcript.jsonl` under `~/.gemini/antigravity` (2.0), `~/.gemini/antigravity-cli` (CLI) and `~/.gemini/antigravity-ide` (IDE) [D shared hooks:204-208]. The CLI root is disputed (X2). A documented path does not prove the file is written (X18).
- The status line and hooks receive the path as `transcript_path` / `transcriptPath` [D CLI cli/statusline:43; D shared hooks:204].
- CLI resume cache: `~/.gemini/antigravity-cli/cache/last_conversations.json` maps each workspace directory to its most recent conversation id [D CLI cli/commands/resume:97-98]. It is only a hint, and usually names the current conversation [I].
- Identifiers (§1): the session id is the conversation UUID, and the status line's `session_id` is an alias of `conversation_id` [D CLI cli/statusline:41]; `artifactDirectoryPath` is `brain/<id>` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- Record schema [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]:
  - fields: `step_index`, `source` (`USER_EXPLICIT`, `MODEL`, `SYSTEM`), `type` (including `SYSTEM_MESSAGE`, `CONVERSATION_HISTORY`, `ERROR_MESSAGE`, `CHECKPOINT`), `status` (`DONE`, `RUNNING`, `ERROR`), `created_at`, `content`, `tool_calls`, `thinking`, `truncated_fields`, `error` and `error_code`;
  - no token, usage or cost field;
  - `transcript_full.jsonl` and `logs/chunks/` sit alongside it; diagnosing looks for the values that `truncated_fields` names in 2.0's `transcript_full.jsonl`.
- Only 1 of 33 IDE conversation directories has a transcript [MO IDE ? 2026-09-25 directory listing] (X18). Where it is missing, the artifacts and snapshots in `brain/<id>/` are what remains.
- Linkage [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]:
  - `INVOKE_SUBAGENT` results carry the child `conversationId` (96 of 96);
  - `send_message.Recipient` carries child ids;
  - a child's opening prompt is likely recorded as `USER_EXPLICIT` (open until LC7), so `source` alone cannot tell a human prompt from an injected one.
- Nesting reaches ten levels below the primary agent [D 2.0 subagents:123], so a search for children recurses that deep.
- `IsSkillFile: true` appears on `view_file` skill reads [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- Clones of a CLI conversation come from `/fork` [D CLI cli/conversations:19-40], from importing a 2.0 conversation [D CLI cli/commands/resume:54-63] and from switching agents inside a conversation, which forks it [D CLI cli/commands/agents:43].
- A message to an idle agent wakes it [D 2.0 subagents:118], with its prior context [D 2.0 subagents:103-104].
- Headless stream linkage and timing (CLI):
  - `subagent_info` lists each child's `type_name`, `role`, `conversation_id`, `log_uri` and `workspace_uris` [D CLI cli/headless:191];
  - steps carry `duration_seconds` and per-step `usage` [D CLI cli/headless:178-179];
  - the `result` event's `usage`, `num_turns` and `duration_seconds` are cumulative over the session [D CLI cli/headless:301-308].
- Token usage:
  - CLI headless: the `usage` object in `json` output and the `result` event, and per-step `usage` in `stream-json` [D CLI cli/headless:65-70, :87, :179, :218-222];
  - CLI interactive: the status-line payload's `context_window` (`total_input_tokens`, `total_output_tokens`, `context_window_size`, `used_percentage`, …) [D CLI cli/statusline:47; D CLI cli/features:119]. It reaches the partner's status-line script, not the agent;
  - CLI `/usage` shows model quotas [D CLI cli/commands/usage:26];
  - 2.0 transcripts carry none [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; the IDE is unverified [U];
  - these are CLI-only (T3) sources for diagnosing's cost questions.
- Caveats:
  - terminal `ERROR` steps were omitted from `transcript.jsonl` before CLI 1.2.4 [CL CLI 1.2.4];
  - compaction rewrites the log, and appends during that rewrite could corrupt it before CLI 1.1.13 [CL CLI 1.1.13];
  - a missing record means "not recorded", never "did not happen" [I].
- Access for a diagnosis:
  - `~/.superpowers/` is outside every product's default file scope [D 2.0 agent-settings:13-14, :35; D IDE settings:256; D CLI settings:157];
  - a subagent's interaction card times out after 60 seconds on the CLI [CL CLI 1.0.2], so grants come before a dispatch;
  - Windows command lines that cannot be split into words need whole-line rules [D 2.0 permissions:173] (§9);
  - observed `ask_permission` Actions are in §2.2.
- A report artifact with `ArtifactMetadata` `{ArtifactType: "other", UserFacing: true, RequestFeedback: false}` uses only observed keys and an observed `ArtifactType` value [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- The environment inventory reads the documented locations: plugins (§6), MCP servers in `~/.gemini/config/mcp_config.json` and `.agents/mcp_config.json` [D CLI mcp:63-64; D IDE mcp:89], hooks (§7.1), custom agents (§3.6), skills (§4) and rule files (§5). A directory's rule files load only when a file below it is read, so presence is not loading [D shared rules:15].
- The built-in `antigravity_guide` skill is a documented cross-check on all three products [CL CLI 1.0.10; CL 2.0 2.2.1; CL IDE 2.5.2] (§4).
- Requirements on the test documents and diagnosing's `session-discovery.md` (S1.11):
  - they cite the hooks page for the transcript path and its three roots;
  - they label record fields maintainer-observed;
  - they find a transcript by the `conversation_id` of `result` or `step_update` (not `init`), CLI root first (X2);
  - they read a missing file as "not written".

## §11 Slash commands, modes and headless runs

- The catalogue covers 2.0 and the CLI [D 2.0/CLI slash-commands:3, :29-40, :223-228]:
  - `/goal` "without intermediate pauses" [D 2.0/CLI slash-commands:33];
  - `/plan`, `/grill-me` and `/learn` (X10);
  - `/plugin` (§6);
  - `/schedule`, `/browser` and `/btw`;
  - `/boost` and `/teamwork-preview`, on paid plans [D 2.0/CLI slash-commands:31-32] (the 2026-07-29 reference's "Ultra plan exclusive" is corrected in §14).
- Plugin slash commands show their plugin name in the 2.0 `/` menu [CL 2.0 2.18.1].
- CLI interactive:
  - `/diff` with VCS, Turn and Commit modes, and line comments that steer the agent [D CLI cli/commands/diff:7, :27];
  - `/tasks` [D CLI subagents:200-212];
  - `/fork` (alias `/branch`) and `/resume` [D CLI cli/conversations:19-40];
  - `/codesearch` [D CLI cli/commands/codesearch:3-7];
  - the status line [D CLI cli/statusline:3];
  - the `/context` panel [CL CLI 1.1.14].
- Headless (CLI):
  - output formats `text`, `json` and `stream-json` [D CLI cli/headless:28-36];
  - `usage` token counts, and `--json-schema` with `structured_output` [D CLI cli/headless:65-70, :85-87, :89-126];
  - `--input-format stream-json` keeps one conversation across turns, with one `result` per turn [D CLI cli/headless:243-247];
  - `--continue` and `--conversation <id>` [D CLI cli/headless:229];
  - `permission_mode` in `init` [D CLI cli/headless:157];
  - a tool that needs an approval it cannot obtain is soft-denied: the run continues and exits 0 [D CLI cli/headless:445];
  - `--dangerously-skip-permissions` [D CLI cli/headless:461-467];
  - exit codes [D CLI cli/headless:469-471];
  - `--print-timeout` (X3).
- Changelog additions for headless runs:
  - plan review auto-proceeds under `agy -p` [CL CLI 1.1.28];
  - the agent settles choices itself where it would otherwise ask [CL CLI 1.1.12];
  - persisted settings, artifact review included, are honoured [CL CLI 1.1.4];
  - refused actions are reported as `denied_actions` [CL CLI 1.1.27];
  - a run that ends on a model or agent error prints `AGY_ERROR` on stderr and exits 3 [CL CLI 1.2.6, 1.2.10];
  - `agy agents|models --output-format json` [CL CLI 1.1.12];
  - background commands in headless runs [CL CLI 1.2.6].
- Skills carry no headless clause (D7). Under `agy -p` the agent may settle the plan gate's method question itself [CL CLI 1.1.12], a recorded gap against upstream's C7. Exception: at diagnosing's archive, issue and comment gates, a self-settled answer means "do not".
- Remote Control:
  - it drives a session from another device, where questions and approvals can be answered [D 2.0 remote-control:23; D CLI remote-control:103];
  - 2.0 push notifications when agents need input [CL 2.0 2.9.1];
  - the CLI's `--remote-control` [CL CLI 1.2.6].
- Timers and notices: `schedule` one-shot timers pace status checks, and a subagent that sets a timer and ends its turn goes Idle (S3.5). Completion notices [CL CLI 1.2.5] and a `schedule` early-termination condition [CL CLI 1.1.12] are CLI changelog facts, unverified on 2.0 and the IDE (LC4 S1-j); no skill relies on them (register B14).

## §13 Contradictions

Each entry names both sides, the interim rule that binds every section until the decider reports, and the decider (§0.4). Each interim rule is safe under both sides.

| X | Topic | Side A | Side B | Interim rule | Decider |
|---|---|---|---|---|---|
| X1 | CLI plugin store root | `~/.gemini/antigravity-cli/plugins/<plugin_name>/` [D CLI plugins:166; D CLI skills:127] | install to the shared `~/.gemini/config/` [CL CLI 1.0.2]; the CLI also loads plugins placed directly in `~/.gemini/config/plugins` [CL CLI 1.2.11] | Never hard-code the CLI plugin root; diagnosing derives it from the loaded SKILL.md. | LC8 S1-i |
| X2 | CLI transcript root | `~/.gemini/antigravity-cli` [D CLI hooks:34; D CLI cli/commands/resume:97] | the example path `~/.gemini/antigravity/brain/…` [D CLI cli/statusline:73] | Use a supplied `transcriptPath`, else probe the CLI root, then `~/.gemini/antigravity`. | LC7 |
| X3 | Headless timeout default | `--print-timeout` default `5m` [D CLI cli/headless:499, :519] | "from 5 minutes to unlimited" [CL CLI 1.2.6] | Not relied on; tests pass `--print-timeout`. | none |
| X4 | `@path` in rule files | `@filename` "Does **not** inline" [D shared rules:103] | inlining with `@path/to/file` [CL 2.0 2.11.0] | Only `@[label](path)` includes. | LC2 |
| X5 | `unsandboxed` rules | documented for 2.0 on Windows [D 2.0 permissions:164] and for the CLI [D CLI sandbox:154-204] | deprecated, migrate to `command` [CL CLI 1.2.2] | Never suggest `unsandboxed` rules or request the `unsandboxed` Action. | LC1 |
| X6 | Review-policy name and values | "Artifact Review Policy", two options [D unscoped artifact-review:8-29] | "Plan Review Policy", three options [CL 2.0 2.17.0]; CLI `artifactReviewPolicy` with three values [D CLI settings:152-155]; IDE strict mode's "Artifact review" [D IDE settings:276] | Describe behaviour, never labels. | LC5 |
| X7 | Plugin-level `hooks.json` | plugin level listed only in the CLI tab [D CLI hooks:26] | `hooks.json` in the shared component list [D shared plugins:13, :82] | No plugin-level `hooks.json`. | LC6 |
| X8 | IDE custom agents and `invoke_subagent` | `invoke_subagent` and `agents/` in shared lists [D shared hooks:166; D shared plugins:17]; "Agent & Parallel Subagents" [D IDE ide/overview:33] | the `subagents` page has no IDE tab (§0.2); `/docs/ide/subagents` returned 404 [MO docs ? 2026-09-25 page fetch]; "IDE following shortly", a vendor promise [CL blog 2026-08-12 2.0/CLI] | "Unverified on the IDE; detect at runtime." | LC1, LC3 |
| X9 | `/browser` as the only entry point | "invoked exclusively via the `/browser` slash command" [D 2.0 subagents:22] | "research, browser and teamwork assistants work again" [CL 2.0 2.6.0]; the IDE Browser Subagent works "as needed" [D IDE ide/browser:9] | `/browser` on 2.0 and the CLI; the IDE may delegate; never name `browser_*` tools. | LC1 S1-a |
| X10 | `/learn` output | `.antigravity/rules.md` [D 2.0/CLI slash-commands:134] | `.agents/rules/*.md` [D shared rules:9-19] | Not relied on. | none |
| X11 | Project permission option | "Inherit General" [D 2.0 agent-settings:17] | "Inherit Global" [CL 2.0 2.14.0] | Not relied on. | none |
| X12 | Over-budget rules | the per-file cap truncates; over budget, the largest rules are demoted to pointers [D shared rules:132-133] | "instead of being cut short" [CL 2.0 2.17.0]; "cutting oversized rules on newline boundaries" [CL CLI 1.2.7] | Shipped rules stay far below 24,000 bytes. | LC2 |
| X13 | Legacy search tools | listed [D shared hooks:137-145]; `grep_search` named as a read-only plan-mode tool [D CLI cli/modes:85] | retired from the default baseline [CL CLI 1.2.7] | R13 (§16.4). | LC1, LC8 |
| X14 | Removed CLI commands | `/fast` and `/planning` listed [D CLI cli/reference:23, :34] | "removed in `1.1.0`" [D CLI cli/modes:131] | Not relied on. | none |
| X15 | Model catalogue | no 3.5 Flash [D unscoped models:9-15] | `--model gemini-3.5-flash-medium` example [D CLI cli/headless:430]; "Gemini 3.5 Flash (High)" in the status-line example [D CLI cli/statusline:75] | Skills and tests never name model slugs (`Model` values are tiers); tests read `AGY_TEST_MODEL`. | none |
| X16 | Default agent inheritance | inherit by default [CL CLI 1.1.25] | 2.0's opt-in reading, "can now reuse … using a single `inheritCustomizations` setting" [CL 2.0 2.9.1] | Nothing depends on default inheritance. | LC3 |
| X17 | Reading back a backgrounded command | `manage_task`: "Interact with background tasks", with `Action: "status"` [D shared hooks:155-156]; the CLI's `/tasks` lists "direct shell commands" [D CLI subagents:202]; list and kill for custom agents [CL CLI 1.1.13]; named completion notifications [CL CLI 1.2.5] | on 2.0 the agent read backgrounded commands with the undocumented `command_status {CommandId, OutputCharacterCount, WaitDurationSeconds}` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; `manage_task` `status` was also called, on targets the probe did not record | Name only `manage_task` (`command_status` only if S3.5's all-products 3k row passes); foreground first; an unreadable result never passes. | LC4 S1-j |
| X18 | IDE transcript presence | `transcriptPath` is "the persistent `transcript.jsonl` conversation logs", with an IDE root [D shared hooks:204-208] | 1 of 33 IDE conversation directories has a transcript [MO IDE ? 2026-09-25 directory listing] | A missing IDE transcript never means "nothing happened"; use the partner's account plus the artifacts. | LC7 S1-h |

Where a section cites a numbered contradiction that overlaps an X entry, the X entry's interim rule binds.

## §14 Corrections to the 2026-07-29 reference

Each entry gives the line of the 2026-07-29 reference, what it said, and the corrected fact with its label. That file stays frozen (§0), so its errors are corrected here.

- Line 5 — the maintainer-sourced shapes (`Subagents`, `define_subagent`, `manage_task`, `schedule`) are now documented [D shared hooks:155-158, :166-169]. The inner keys of `ArtifactMetadata` are maintainer-observed [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].
- Line 13 — `view_file` gained page and resolution arguments [CL 2.0 2.11.0].
- Lines 17-18 and 26 — the legacy trio: X13 and R13.
- Line 42 — `all` becomes [U-ms]; `unsandboxed` is observed as an `ask_permission` Action [MO 2.0 ≤2.10.0 2026-08-25 transcript probe] (T4, X5).
- Lines 53 and 124 — the `Model` key moves from "unconfirmed" to accepted, effect unverified [MO 2.0 ≤2.10.0 2026-08-25 transcript probe] (§3.10).
- Line 64 — the claim that `/browser` is the only way in: X9. `self`'s "same toolset" is now documented [D 2.0 subagents:23] and matters for #2059 (§3.9).
- Line 65 — `share` semantics are unverified [U].
- Lines 67 and 69 — `Error` is a CLI panel state [D CLI subagents:173]. Line 69's claims that Error is surfaced by `manage_subagents` `list` and cannot be resumed are [U-ms].
- Lines 70-71 — JSONL transcripts that other agents can read are documented [D 2.0 subagents:111, :119]; the path, which the old file does not give, is now documented [D shared hooks:204-208].
- Line 83 — plugin agents are documented on 2.0 [D 2.0 subagents:37]; the IDE is ambiguous (X8).
- Line 85 — the frontmatter list omits the changelog-only keys (§3.8).
- Line 91 — Agent Non-Workspace File Access is documented for 2.0 on Windows [D 2.0 agent-settings:35] and for the IDE [D IDE settings:252-257]; on 2.0 macOS and Linux the presets govern it [D 2.0 agent-settings:13-15].
- Line 92 — the review policy was renamed on 2.0 [CL 2.0 2.17.0] (X6); the IDE's policy exists [D IDE settings:270-276].
- Line 98 — the `task` kind is observed [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]; task lists appear in the 2025 launch blog only [CL blog 2025-11-18 unscoped].
- Lines 102-108 — five errors:
  - two hook events instead of five [D shared hooks:102-108];
  - a `settings.json` location that was never documented (§7.1);
  - four decisions instead of five [D shared hooks:236-241];
  - "ships `hooks.json`", when from v6.2.1 the plugin root carried only `hooks.example.json`;
  - the `$PWD` fallback, which commit 2bc50a6 (2026-07-31) removed.
- Line 116 — teamwork is available on paid plans [D 2.0/CLI teamwork:7], not "Ultra plan exclusive".
- Lines 118-122 — slash invocation is documented on 2.0 and the CLI [D 2.0 skills:117; D CLI skills:131]. The "IDE" observation is relabelled 2.0 (probable) [MO 2.0 (probable) ? 2026-07-30 slash palette], and the "(CLI)" observation becomes [U-ms 2026-07-30]. "Gemini 3.5 Flash" is no longer listed [D unscoped models:9-15] (X15).

## §15 Live checks

Eight live checks decide this release's gated choices. §15.0 says how they run and how results are recorded; §15.n holds live check LCn: its protocol, what the 2026-09-25 on-disk probe had already answered, the sub-questions the design sections added, and one result line per product.

### §15.0 Running and recording

The protocols below are those registered on 2026-09-25 (maintainer instruction), verbatim except native-read substitutions (R6).

- **Instrument.** The probe's hook logger (`zz-log`, S8.1) is installed in the throwaway probe workspace's `.agents/hooks.json`: PostToolUse with matcher `""`, PreInvocation and Stop entries, each running `node "<absolute path>/hook.mjs" <tag>`, which logs the payload, cwd and shell and prints `{}` (Stop prints the allowing decision). There is no PreToolUse logger: a PreToolUse `allow` "Automatically allows the tool execution" [D shared hooks:237] and would mask the permission behaviour being probed. The CLI tool list comes from `init.tools` [D CLI cli/headless:162]. Without hooks, a product falls back to self-report plus transcripts.
- **Results.** Each answer becomes an `[MO <product> <version> <date> LCn]` fact in its §, updating §0.5, §13 and the revision log. The product's result line then reads `LCn: <product> done <date>`. A leg that was not run reads "not run" and is never inferred (R10).
- **Installs.** Probe plugins are workspace installs: `.agents/plugins/<probe>/` on 2.0 and the IDE, and `agy plugin install <path>` on the CLI, uninstalled after the leg. The exceptions are the real clone, switched to the probe branch and back, and S1-i's global placement, removed after the leg. Probe-branch commits need the maintainer's go-ahead (D16).
- **Order.** LC6 S1-l; LC1; LC2; LC3, LC4, LC5 and LC7; LC8 and the CLI legs after the 2.0 and IDE collection; the remaining LC6 legs while a hook ships or remains the contributor gate (it does: S7.2). The core probe (IDE, then 2.0) and the CLI legs run before Phase 2 (D2); every gated row has a default.

### §15.1 LC1 — Tool-schema dump

**Protocol:**

1. **Tool-schema dump (2.0, IDE, CLI; about 5 minutes each).** In a fresh conversation, ask: "Print verbatim the parameter schemas you were given for write_to_file, multi_replace_file_content, ask_permission, schedule, invoke_subagent, ask_question, view_file, run_command, manage_task; then list every tool name you have." Report per surface:
   - the ArtifactMetadata fields and kinds (task, implementation plan, walkthrough, RequestFeedback);
   - the ask_permission Action values;
   - any schedule early-termination parameter;
   - the invoke_subagent Workspace values and result fields;
   - whether view_file has StartPage, EndPage and MediaResolution;
   - how run_command describes its shell;
   - whether ask_question supports write-in answers;
   - whether invoke_subagent exists on the IDE;
   - whether list_dir, grep_search, find_by_name and code_search are present.

   Unblocks: the task-artifact trio, both schedule items, the read-grant items, view_file pages, write-in, the legacy-search trio, both IDE-subagent items, and part of tools-artifact-edit-tool-choice. Record the answers as maintainer-observed, not documented.

**Answered before the probe:** 2.0: the `ArtifactMetadata` keys and `ArtifactType` values; the `ask_permission` Actions seen (`write_file`, `read_file`, `unsandboxed`); the `schedule` keys seen (`DurationSeconds`, `Prompt`); the `invoke_subagent` spec keys, including `Model` (accepted) and `Workspace` (`inherit`, `branch`); the child `conversationId` in results; the `ask_question` array form (first element); `define_subagent`'s three flags accepted; `command_status` exists; the legacy trio was last used before CLI 1.2.7 [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].

**Sub-questions:**

- **S1-a** Can the main agent reach the browser subagent without the partner typing `/browser`? (X9)
- **S1-b** Record the full tool list per product for §2.1b and R13: from `init.tools` on the CLI; on 2.0 and the IDE from the model's list, labelled self-report until a logged call corroborates each name.
- **S1-k** Pass one unknown inner `ArtifactMetadata` key on each product and record whether it is ignored, rejected with an error the agent can act on, or hangs (T2's per-product note, §0.3).
- **1a** Per product: the `ArtifactType` values, the `ask_permission` Actions, `manage_task` status output and `command_status` (S5).
- S6's legs: `invoke_subagent` on the IDE (S6.1); the `ask_permission` Actions on the IDE and the CLI, and `list_permissions` output around a grant (S6.5); both issue URLs per product, and whether their three fields survive conversion (S6.7).

**Result:**

LC1: 2.0 not run

LC1: IDE not run

LC1: CLI not run

### §15.2 LC2 — Bootstrap probe

**Protocol:**

2. **Bootstrap probe (2.0, IDE, CLI).** On a scratch branch:
   - Add `trigger: always_on` and `description:` to rules/using-superpowers.md.
   - Add rules/zz-probe.md with `trigger: always_on` and the body `@[probe](../skills/zz-probe/PROBE.md)`. PROBE.md has frontmatter and a unique token.
   - Install one clone at ~/.gemini/config/plugins/superpowers for 2.0 and the IDE, and use `agy plugin install <path>` for the CLI.
   - Before and after the change, open Customizations > Rules, Skills and Agents (on the CLI: `agy plugin list` and `/context`).
   - Ask: "Without reading files, quote the token and the first Red Flags row, and say how many times the using-superpowers text is in your context."
   - Type `/using-superpowers` and `/superpowers:using-superpowers`.

   Report:
   - whether the rule is listed, which trigger is shown, and whether it can be set to Manual;
   - whether the token is present, and whether PROBE.md's frontmatter leaked;
   - whether the bootstrap appears once or twice;
   - which slash forms resolve;
   - the skill and agent counts;
   - the directory agy created.

   Unblocks all of the boot rule, delivery, README, slash-command and verify-step items.

**Answered before the probe:** 2.0: only that plugin skills load from `~/.gemini/config/plugins/superpowers/skills/` with `IsSkillFile` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].

**Sub-questions:**

- **S1-c** On the IDE specifically, does `/using-superpowers` resolve (§4)?
- **2a** The listing and the slash forms.
- **2b** Legacy files removed, plus "Reply with the single word OK." with no SKILL.md read.
- **2c** The workspace walk.
- **2d** 2.0 Projects: Local, New Worktree (for S4.1) and two folders.
- **2e** File access.
- **2f** CLI variants S (skills), R (+rules), L (+legacy) and RL, compared by `usage.input_tokens`: R−S ≈ E (rule bytes ÷ 4), L−S ≈ 20, E or 0 (pointer, inlined or ignored), RL−S ≈ 2E (double).
- **2g** An unshipped count of SKILL.md re-reads in 2.0 transcripts, before and after release.

S2.16 defines the markers the agent lists and the CLI's answer schema.

**Result:**

LC2: 2.0 not run

LC2: IDE not run

LC2: CLI not run

### §15.3 LC3 — Bundled-agent probe

**Protocol:**

3. **Bundled-agent probe (2.0 and CLI; one attempt on the IDE).** From a Flash session, and once from a Claude Opus 4.6 session, dispatch two subagents in one call:
   - `spec-reviewer` as shipped;
   - a scratch `zz-pro` agent with `model: pro`, `inheritCustomizations: false`, `skills: [../skills/test-driven-development]` and `hidden: true`.

   Ask each to report its model, whether the using-superpowers rule or the probe token is in its context, its tool list, and whether it can load TDD. Then add `<ws>/.agents/agents/spec-reviewer.md` with a marker line and redispatch. Report:
   - the model per card or `subagent_info`;
   - inheritance with and without the key;
   - whether manage_task appears without being listed;
   - whether the `skills:` path resolved;
   - which spec-reviewer ran (precedence);
   - whether `hidden` takes effect;
   - the TypeName form in `agy agents --output-format json`;
   - whether the IDE resolves the TypeName at all.

   Unblocks: P1 for all final-reviewer and tier items, name collision, every inheritCustomizations item, and allowlist exclusivity (add one variant with `excludeDefaultComponents`).

**Answered before the probe:** 2.0 dispatches the bare TypeNames `implementer`, `spec-reviewer` and `code-reviewer` and the built-ins `research` and `self` [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].

**Sub-questions:**

- **S1-d** Dispatch built-in `research` and record its tool list.
- **S1-e** For every bundled role, record whether `invoke_subagent`, `define_subagent` or `send_message` appears without being listed, and what the default built-in toolset holds (3i). This is the §3.9 re-open trigger.
- **3a** Model per subagent: from a Gemini Flash session and from a Claude Opus 4.6 session, on 2.0 and the CLI, a PreInvocation hook logs each child's `modelName` (S3.3).
- **3b** Inheritance defaults: with no key set, are the using-superpowers rule, the skill catalog, a probe token, the plugin's `GEMINI.md` bootstrap (while it ships) and the project's `AGENTS.md`/`GEMINI.md` and `.agents/rules/*.md` in a bundled agent's context, on 2.0 and the CLI?
- **3c** `inheritCustomizations: false` and `true`: is the value accepted as a YAML boolean, and does the agent keep its `tools:`? With `false`, are the plugin rule, the skill catalog and the plugin `GEMINI.md` bootstrap gone while the project's rule files and the user's MCP servers still arrive? With `true`, do skills and rules arrive where 3b showed none?
- **3d** Does `manage_task` appear in a bundled agent that does not list it, and does listing it error (S3.5)?
- **3e** Precedence: which agent runs for TypeName `spec-reviewer` when `<ws>/.agents/agents/spec-reviewer.md` exists, and for `code-reviewer` when `~/.gemini/config/agents/code-reviewer/agent.md` exists? On the CLI it counts only on 1.2.11 or later (§3.6).
- **3f** `hidden: true`: does it drop the agent from the `/agents` picker and the planner roster, and does dispatch by TypeName still resolve?
- **3g** The TypeName form, bare or `superpowers:`-prefixed, from `agy agents --output-format json` and from a stream-json dispatch's `subagent_info.subagents[].type_name` (with LC8).
- **3h** Does the IDE resolve a bundled TypeName at all?
- **3i** For `code-reviewer`, the effective tool list with and without `excludeDefaultComponents: true`.
- **3j** The `define_subagent` registration toolset is known for 2.0 to 2026-07-08 (§2.2) [MO 2.0 ≤2.10.0 2026-07-08 registration read]. No skill step uses the tool (D6), so no leg runs it.
- **3k** Whether `command_status` is in each product's tool list, from LC1's list (S3.5's all-products row).
- **3a-M** The `Model` key: 3a's hook, dispatching `implementer` with `Model` `"flash"`, `"pro"` and `"inherit"`, records each child's `modelName` (D5).
- **O1** Offline, over existing 2.0 transcripts: for each `INVOKE_SUBAGENT` with TypeName `implementer`, follow the child `conversationId` and count `view_file` records with `IsSkillFile: true`, by skill folder. It answers part of 3b for 2.0.
- **P4** On 2.0 and the CLI, a plugin agent that lists `invoke_subagent` dispatches `implementer`, resumes it with `send_message` and returns a relayable final message (S3.10).
- S6's legs: 3h with `session-analyst` per product: it resolves, a sandboxed `run_command` measures a transcript after the parent's grant, and `send_message` resumes it with its context (S6.4); 3d: `manage_task` reaches `session-analyst` (S6.6).

**Result:**

LC3: 2.0 not run

LC3: IDE not run

LC3: CLI not run

### §15.4 LC4 — Workspace and commit probe

**Protocol:**

4. **Workspace and commit probe (2.0 and CLI, with the usual sandbox settings).** Dispatch `implementer` with Workspace "branch". Its task: commit a file, background `sleep 90` and check it with manage_task, then set a 60-second schedule and end its turn. Then dispatch a second implementer with Workspace "inherit". Report:
   - the branch worktree path and branch name, and whether its base equals the parent's HEAD;
   - whether the parent's `git branch --list` shows the branch;
   - whether `git commit` succeeded, prompted or failed;
   - what the dispatch result shows the model (conversation_id, workspace_uris);
   - whether the parent got an Idle result before the timer fired;
   - whether a completion notice arrived without polling;
   - whether the inherit commit landed on the controller's branch;
   - whether the branch survives `manage_subagents` kill;
   - whether any approval from the subagent timed out after about 60 seconds.

   Unblocks: the integration versus inherit decision and its dependents, the git-commit sandbox items, the async trio, and the completion-notice item.

**Answered before the probe:** 2.0: `Workspace` `branch` and `inherit` are both used [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].

**Sub-questions:**

- **S1-f** A third dispatch with `Workspace: "share"`: its path, lifetime and git state.
- **S1-j** On all three products: background a 90-second command with a short `WaitMsBeforeAsync`, then record whether `manage_task` `Action: "status"` returns its output and exit status, and whether a completion notice arrives without polling (X17).
- **S1-m** On the CLI and the IDE: after an implementer goes Idle, `send_message` it a request to repeat its report; record whether it wakes with its context (§0.5 row 45).
- S4's step: repeat the `inherit` implementer's commit after the controller obtained an `ask_permission` grant for running `git commit` outside the sandbox, in two legs: macOS or Linux (2.0 or the CLI), and Windows 2.0 with Enable Sandbox Mode on and Proceed in Sandbox (S4.7).

**Result:**

LC4: 2.0 not run

LC4: IDE not run

LC4: CLI not run

### §15.5 LC5 — Gate probe

**Protocol:**

5. **Gate probe (2.0 under each of the three Plan Review Policy values, the IDE, CLI default mode, and one `agy -p` run).** Have the agent:
   - write docs/superpowers/plans/zz.md as an implementation-plan artifact with `RequestFeedback`;
   - write `.superpowers/sdd/zz/progress.md` into a directory that does not exist yet;
   - write a task.md artifact and a walkthrough;
   - make one ask_question call with two questions.

   Respond with Proceed, then Review plus an inline comment, then Cancel. Report:
   - whether the header appears and the turn pauses;
   - the exact text the agent receives for Proceed, a comment, a CLI reject and Cancel;
   - whether the method question is still asked after Proceed;
   - whether missing parent directories were created;
   - where task.md landed, and whether the walkthrough is filed as an artifact or a scratch file;
   - whether both questions rendered, and whether a write-in field appears on 2.0 and the IDE;
   - the exact 2.0 policy labels;
   - what `-p` returned.

   Unblocks all of the plan-gate, method-choice, headless, bookkeeping and walkthrough items.

**Answered before the probe:** in 199 of 217 `ArtifactMetadata` writes on 2.0 the agent passed an absolute `brain/<id>/` path itself; 18 targeted workspace paths [MO 2.0 ≤2.10.0 2026-08-25 transcript probe].

**Sub-questions:**

- **S1-g** On all three products, 2.0 included: write `task.md` with `IsArtifact` and a bare `TargetFile`, and compare the logged `TargetFile` with the payload's `artifactDirectoryPath` and with where the file lands (§0.5 rows 8a, 8b).
- S4's step: the IDE leg repeated once with strict mode on, reading back the ledger and a `task.md` artifact (S4.2).
- **5a** The header and the pause, per setting and product.
- **5b** The signals received per partner action and per CLI approval.
- **5c** Whether an edit re-save reopens review.
- **5d** A question or execution after Proceed (`implementation_plan`, then `other`).
- **5e** Fast Mode.
- **5f** CLI `task.md` prompts.
- **5g** Skills under `/plan` and `agy --mode=plan`, and whether the plan file is writable.
- **5h** The output of `agy -p`.
- S6's legs: an `agy -p` leg (S6.1, S6.7); parent-directory creation, and an `"other"` artifact written outside `brain/<id>/` and the project (S6.3).

**Result:**

LC5: 2.0 not run

LC5: IDE not run

LC5: CLI not run

### §15.6 LC6 — Windows shell and hook runtime probe

**Protocol:**

6. **Windows shell and hook runtime probe (2.0, IDE, CLI).** In the fork repo, add a tracked `.agents/hooks.json` with three entries:
   - a PreToolUse hook running `node ./hooks/zz-probe.mjs`, which logs cwd, ComSpec/SHELL and stdin, then allows;
   - one entry pointing at a missing command;
   - one entry with `enabled: false`.

   Also add a `trigger: glob` rule on `skills/**`. Then:
   - write skills/zz/SKILL.md;
   - run `echo $PSVersionTable.PSVersion; where.exe bash jq node`, plus one command with `> out 2>&1`, with `Cwd` set to the parent directory;
   - toggle the hook in Customizations > Hooks (CLI: `/hooks`);
   - repeat from a Workspace "branch" implementer;
   - install the repo at `<ws>/.agents/plugins/superpowers`.

   Report:
   - whether the hook fires, its cwd and shell, and the raw TargetFile form;
   - whether the missing-command hook denies, allows, or is rejected at load;
   - which shell run_command used, and whether it reports exit codes;
   - whether `Cwd` was honoured and whether the redirect prompted;
   - whether the toggle rewrote the tracked file;
   - whether the glob rule activates, and whether it leaks through the workspace install.

   Unblocks all hooks and purity items and P2.

**Answered before the probe:** nothing.

**Sub-questions:**

- **S1-l** (runs first) In a throwaway workspace, does the probe logger fire under `node`, from which cwd and shell, and does its payload carry the documented fields?
- **6a** Sandbox reads of the plugin directory, with and without a grant (S5.11).
- S6's legs: on Windows, per product, the shell, exit codes, prompting under no rule, a `command(powershell)` prefix rule and a full-line `regex:` rule, and the `powershell -NoProfile -Command` wrapper (S6.6).

**Result:**

LC6: 2.0 not run

LC6: IDE not run

LC6: CLI not run

### §15.7 LC7 — Transcript and permission probe

**Protocol:**

7. **Transcript and permission probe for diagnosing (all three surfaces).** On each surface, run one short conversation that dispatches a subagent. Then, from a new 2.0 conversation, list `~/.gemini/antigravity*/brain/`, view the first two lines of the other surfaces' transcript.jsonl, read its end with `view_file`, or count its lines with run_command running `node -e "console.log(require('fs').readFileSync(process.argv[1],'utf8').split('\n').length)" <path>`, dispatch a subagent to do the same, and read and write `~/.superpowers/zz/`. Report:
   - the CLI transcript root;
   - whether the brain/<id> directory name equals the conversation ID shown in the app or `/resume`;
   - which record and field carry the child conversation ID;
   - the `source` value for a human prompt versus a subagent message;
   - whether IsSkillFile appears on skill reads;
   - for each access: silent, prompt card, or refused, and whether the subagent inherited the grant.

   Unblocks the diag discovery, linkage, grant, case-folder, injected-message and activation items, plus session-analyst and hooks-transcript-path-c13.

**Answered before the probe:** 2.0: the `brain/<id>/.system_generated/logs/transcript.jsonl` layout, plus `transcript_full.jsonl` and chunks; child linkage through the `INVOKE_SUBAGENT` `conversationId` and `send_message.Recipient`; `source` cannot tell a human prompt from an injected one; `IsSkillFile` on skill reads; no token fields [MO 2.0 ≤2.10.0 2026-08-25 transcript probe]. IDE: 1 transcript in 33 directories [MO IDE ? 2026-09-25 directory listing].

**Sub-questions:**

- **S1-h** Does a new IDE conversation write the file that its logged `transcriptPath` names (X18)?
- S6's legs: on all three products, the CLI root, the 2.15–2.17 record schema, the directory name against the displayed id, `source` for a human prompt against a dispatch, injected channels, and `task.md` landing in `brain/<id>/` (S6.2); the `~/.superpowers/zz/` leg and an `ask_permission` `write_file` request on the IDE and the CLI (S6.3); a subagent reads `prompts/stumbles.md` under the install root, and (informational) file search under a `*` `.gitignore` (S6.4); the access half (S6.5).

**Result:**

LC7: 2.0 not run

LC7: IDE not run

LC7: CLI not run

### §15.8 LC8 — CLI tooling

**Protocol:**

8. **CLI tooling, scripted.** Run:
   - `agy plugin install <path>` twice, and once with a `/tree/<branch>` URL;
   - `agy plugin list`;
   - `agy -p "/skills" --output-format json`;
   - `agy -p "/hooks" --output-format json` from the repo root, both trusted and untrusted;
   - `agy agents --output-format json`;
   - `agy -p "hi" --output-format stream-json`, reading `init.tools`;
   - `agy -p "/superpowers:using-superpowers" --output-format stream-json`.

   Report:
   - the install directory, whether a reinstall replaces cleanly, and whether the branch URL works;
   - whether package.json is staged into the install;
   - whether skills are namespaced;
   - whether the workspace hook is listed;
   - the agent names;
   - whether `init.tools` has the legacy search tools, `code_search` and `ask_question`;
   - whether the slash expansion applied the skill;
   - whether any print-mode slash command created a brain/<id> directory.

   Unblocks the CLI discovery test, update/pin, manifest, hooks introspection, roster test, env-inventory and plugin-discovery items.

**Answered before the probe:** nothing (`agy` was not installed on 2026-09-25).

**Sub-questions:**

- **S1-i** Does the CLI discover a plugin placed only in `~/.gemini/config/plugins/`, with no `agy plugin install` (X1)?

**Result:**

LC8: CLI not run

## §16 Standing rules

The rules every change follows. R1–R5 are the decision register's standing rules 1–5; R12 and R13 are new in this release.

### §16.1 R1–R11

- **R1 — Charter.** Antigravity only.
- **R2 — Documented capabilities.** Refined by the labelled evidence model (§16.2).
- **R3 — Verbatim port or recorded divergence.**
- **R4 — The purity gate is the release gate.**
- **R5 — No implementer-facing handoff files.**
- **R6 — Shell neutrality.**
- **R7 — Tiers come from agent frontmatter.** Refined by D5.
- **R8 — Git hygiene.** No `Co-Authored-By`; upstream read through `refs/upstream-tags/*`.
- **R9 — Additive delivery.** See §16.5.
- **R10 — Honest verification.** An unrun check reads "not run".
- **R11 — Rulings, not stalls.**

### §16.2 R2 refined

**R2 refined (2026-09-25).** Every fact carries a §0.1 label; a skill relies on it only at its §0.3 tier, maintainer-observed facts included; prose asserts no absence without documented, changelog or maintainer-observed evidence. A per-dispatch `Model` key counts only once LC3's model leg proves it (D5).

### §16.3 R12 — Rule-walk hygiene

**R12 — Rule-walk hygiene.** Nothing tracked in this repo may be a file that Antigravity's directory-scoped rule walk, or its project-subdirectory customization discovery, would load for a workspace-install user. The only exceptions are the entries on the layout test's allowlist, each naming the spec section that owns it.

Concretely:
- **Rule files.** No `AGENTS.md` or `GEMINI.md` at any depth, in any letter case. The root `GEMINI.md` is allowed while S2.3 keeps it.
- **`.agents/` and `.agent/`.** No `AGENTS.md`, `GEMINI.md`, `rules/` or `rules.json` inside any such directory at any depth. The only tracked paths under a `.agents/` directory may be the repo-root `.agents/hooks.json` (S7.2's contributor entry, shipped disabled) and, only if Live check 6(e) shows it absent from workspace installs (D14), `.agents/skills/contributing-to-superpowers/SKILL.md`. Hooks are documented only at the workspace root, the global file and the plugin level [D hooks:13, :24-26, :40], so a nested copy is not expected to load [I]; it ships disabled either way (S7.3 check 3).
- **Discovery files.** No `skills.json`, `agents.json` or `rules.json` at any depth (S2.4; D15).
- **Contributor guidance** for agents goes in CONTRIBUTING.md, which is never auto-loaded, or in a snippet contributors copy into their own `~/.gemini/config/rules/`.

First application: upstream's root `AGENTS.md` (C16) stays out, because the walk would load it into every workspace-install user's context [D shared rules:15].

### §16.4 R13 — Native tool naming

R13: skill and rule prose names only ref §2.1b tools, including in tool-call examples; arguments follow ref §0 tiers (D-shared unconditional, `[CL]`/`[MO]`-only T2/T3). For the trio, `code_search`, `command_status`, `manage_inbox`, `read_resource` and `browser_*` it uses upstream's action wording. Agent `tools:` allowlists are exempt (S7.5 checks them against §2.1a). S7.1 alone enforces R13: its `non-baseline-tools` group lists those names, and check 6 tests against `known-tools.txt`.

### §16.5 Delivery

Additive delivery: the `rules/` bootstrap ships alongside `gemini-extension.json` and `GEMINI.md` until Live check 2's CLI leg confirms the rule channel; then both are retired (S2.3). The plugin ships no `hooks.json` and no `mcp_config.json`. The repository's disabled `.agents/hooks.json` and the global-hook entry in CONTRIBUTING are contributor-only tools (S7.2, S7.3).

### §16.6 Decision record changes

Decision record changes of this release (id — old — new — part). The ids are rows of the maintainer's decision register, which stays outside the repository (D3).

- register A2 — native tool names, no mapping layer — refined by R13: skill and rule prose names only ref §2.1b baseline tools — S1
- register A4 — OPEN: bootstrap may load twice — closes under outcome A; under B/C records the CLI double-load and any leg-2c walk cost; copy count measured (K2, CLI T5) — S2, S8
- register A5 — line 24 reverted to "todo" — line 24 uses a `task.md` artifact (D15) — S5
- register A7 — manual bumps, ad-hoc JSON check — manual bumps reaffirmed; equality checked by the packaging test — S2, S8
- register A8 — `docs/testing.md` documents removed test trees — closed by S7.9's rewrite — S7
- register B2 — plan handoff offers SDD only — removed; C3's Subagent-driven/Native choice — S5
- register B4 — four bundled agents — seven (nine with S3.4's fallback variants) — S3
- register B6 — no SDD scripts, no file handoff — refined: plan-range handoff for in-repo, non-ignored plans, still no handoff files — S4
- register B9 — #2059 skip, reason only in a gitignored ledger — skip stands; reasoning in ref §3.9; `self` residual accepted — S1, S3
- register B12 — final-review fix range on the fixer's branch — retired (kept only under variant B or both-fail) — S4
- register B13 — tier set in agent frontmatter only — per-task tier by the `Model` key if 3a-M proves it, else variant TypeNames — S3
- register B15 — OPEN: reviewers read-only by prose only — closed by S3.2 — S3
- register C5 — `RequestFeedback: true` with the comment loop — kept for specs and plans (request after the self-review; only the partner approves); revised to `RequestFeedback: false` at both executors' walkthrough — S4, S5
- register §F, v6.4.1 row (upstream C16, root `AGENTS.md`; with C21) — excluded by charter — C16 also excluded for a native reason (the rule walk); C21 not ported (A7); the legacy files listed as not ported only under outcome A — S2, S8
- register D1 — `Workspace: "branch"` for subagents — refined: implementers on `inherit`; shell-neutral Step 0 and Step 2; `share` not recommended — S4
- register D4 — keep the `MAIN_ROOT` `cd` — the `cd` becomes a placeholder, plus `Cwd` — S5
- register E1 — personal-skill location — per-product paths; upstream's multi-harness hunk stays rejected — S5
- register E7 — executing-plans says "user" — resolved: "your human partner" — S4
- register E8 — render-graphs node guard, never run — runs with Graphviz installed (D13); closed — S7, S8
- register E11 — `/using-superpowers` observed "on the IDE" — relabelled "2.0 (probable)"; CLI form unverified — S2
- register E12 — specs and plans untracked; reference tracked — evidence stays outside the repo; durable facts in the platform reference — S1
- register E13 — `$schema` not applied, no reason recorded — keep `plugin.json` `version` as a recorded schema exception; no `$schema` — S2
- register §2 item 6 — `inheritCustomizations` in no tracked file — closed by ref §3.9 — S1, S3
- register §3 rule 2 — only documented capabilities ("no model argument" trap) — refined: labelled evidence model, maintainer-observed facts allowed by tier; the `Model` key only if 3a-M proves it (D5) — S1, S3
- register §3 rule 9 — additive delivery — reversed for the bootstrap under outcome A only — S2
- register §3 R12, R13 — none — added after rule 11 (rule-walk hygiene; native tool naming) — S1, S2
- register §6.1 — B9's reasons only in a gitignored ledger — closed by ref §3.9; probe facts go to the reference — S1, S8
- register §6.5 — release notes wrong twice — closed by S8.5's Fixes line — S8
- register §6 items 6 and 7 — stale `.gitattributes`/`docs/testing.md`; purity gate misses newer harness names and `references/` links — closed by S7.10, S7.1 and S7.9 — S7

## Revision log

- 2026-10-05 — §0–§6 — created from the 2026-09-25 and 2026-09-29 docs captures and the changelog to 2.0 2.18.1 and CLI 1.2.11; IDE U cells re-checked; 2026-07-29 reference frozen — maintainer instruction
- 2026-10-05 — §7–§11, §13–§16 — added; live checks not run — maintainer instruction
