<p align="center">
  <img src="docs/banner.png" alt="Superpowers for Antigravity" width="100%">
</p>

<p align="center">
  <strong>A complete software development methodology for your coding agent.</strong><br>
  Composable skills that trigger automatically — your agent just has Superpowers.
</p>

<p align="center">
  <a href="https://github.com/roundpilot/superpowers-antigravity#-installation"><img src="https://img.shields.io/badge/Install-Guide-blue?style=for-the-badge" alt="Install"></a>
  <a href="RELEASE-NOTES.md"><img src="https://img.shields.io/badge/Version-6.3.0-green?style=for-the-badge" alt="Version 6.3.0"></a>
  <a href="https://github.com/obra/superpowers"><img src="https://img.shields.io/badge/Fork%20of-obra%2Fsuperpowers-purple?style=for-the-badge" alt="Fork of obra/superpowers"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="MIT License"></a>
</p>

---

> **This is a fork of [obra/superpowers](https://github.com/obra/superpowers) rebuilt natively for [Google Antigravity](https://antigravity.google): the 2.0 app, the IDE and the CLI (`agy`).** If you need multi-platform support (Claude Code, Codex, Cursor, etc.), use the upstream repo instead.

---

## ✨ How It Works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do.

How much ceremony follows depends on what you asked for. It classifies the request out loud — a feasibility probe, a bounded change to code that already exists, or something architectural — and only the last of those earns a written spec, shown to you in chunks short enough to actually read and digest. The smaller paths get a couple of sentences in chat instead. What never scales down is the approval: nothing gets built until you say yes.

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasises true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY.

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for agents to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers. (See [Activation](#-activation) for how the loading works — and how to scope it if you don't want it everywhere.)

## 🔀 What's Different from Upstream?

The original superpowers supports 9+ platforms via a tool mapping abstraction layer — skills are written with Claude Code tool names, and per-platform reference files translate at runtime.

This fork **removes the abstraction entirely**. All skills use native Antigravity 2.0 tool names directly (`view_file`, `run_command`, `invoke_subagent`, `define_subagent`, etc.), eliminating translation overhead and making every skill read exactly as the agent will execute it.

<details>
<summary><strong>Why remove cross-platform support?</strong> (click to expand)</summary>

The abstraction layer costs tokens on every interaction, and those costs compound across a session:

1. **Tool mapping file loaded every session.** The upstream approach loads a ~500-token tool mapping reference into context at session start. Every turn carries this translation table. This fork eliminates it entirely.

2. **Agent reasoning overhead.** When a skill says "use the Bash tool," the agent must look up the mapping, reason about which native tool to call, and potentially make mistakes. When skills say `run_command` directly, there's zero translation cost.

3. **Platform-conditional branching in skills.** The upstream `using-superpowers` skill has separate instruction blocks for Claude Code, Copilot CLI, Gemini CLI, Codex, Antigravity 2.0, and "other environments." Only one applies.

4. **87 fewer files than upstream (as of v6.3.0 on both sides).** When agents explore the repo, fewer files means less noise in `list_dir` output and faster orientation.

5. **Leaner skills without platform detection.** No harness-detection or fallback branches inside skills — `using-git-worktrees` is 120 lines to upstream's 167 (as of v6.3.0). Shorter skills = less context consumed.

</details>

### Comparison Table

| Area | Upstream (obra/superpowers) | This fork |
|------|---------------------------|-----------| 
| **Platforms** | 9+ (Claude Code, Codex, Cursor, etc.) | Antigravity only (2.0 app, IDE, CLI) |
| **Tool names in skills** | Claude Code names + mapping files | Native Antigravity names |
| **Subagent dispatch** | `Task tool (general-purpose)` | Bundled custom agents + `invoke_subagent` |
| **Workspace isolation** | `git worktree` with fallback | Native `Workspace: "branch"` / `"inherit"` (`"share"` not recommended: its semantics are unverified) |
| **Task tracking** | `TodoWrite` tool | `task.md` artifacts |
| **Visual brainstorming** | Browser-based server | Native `generate_image` (no server needed) |
| **Plan formatting** | Plain markdown | Mermaid diagrams, file links, diff blocks, GitHub alerts |
| **Background tasks** | Not documented | `manage_task`, `send_message`, `schedule` (incl. cron) |
| **UI verification** | Not available | `browser-testing` skill with screenshot evidence |
| **Read-only subagents** | Full tool set for all | Bundled read-only reviewer agents (plus `TypeName: "research"` ad-hoc) |
| **Web research** | Not guided | `search_web` + `read_url_content` integrated |

### Core Enhancements

Beyond the platform port, this fork adds capabilities that don't exist upstream:

- 🎨 **`generate_image` in brainstorming** — native mockup generation with carousel comparisons
- 📐 **Rich plan formatting** — Mermaid architecture diagrams, clickable `file:///` links, diff blocks
- 🔄 **Async subagent coordination** — `manage_task` for builds, `send_message` mid-flight, `schedule` for timeouts
- 🌐 **Browser-testing skill** — evidence-before-assertions discipline for UI work
- 💰 **Token-saving subagents** — reviewers are read-only bundled agents (`TypeName: "research"` for ad-hoc review)
- ✅ **Automatic feedback loops** — `RequestFeedback: true` (in `ArtifactMetadata`) on design docs and plans
- 🔀 **Workspace mode guidance** — decision tables for `branch` and `inherit` per role; `share` is not recommended (semantics unverified)
- 🛡️ **Edit-time purity gate** — a `PreToolUse` hook blocks banned legacy vocabulary from entering this plugin's `skills/` before a write ever lands (opt-in for contributors: rename `hooks.example.json` → `hooks.json`; requires `bash` available to the hook runner)
- 🔍 **Web research integration** — `search_web` woven into debugging, brainstorming, and planning

## 🚀 The Workflow

```
 ┌─────────────┐     ┌──────────────┐     ┌───────────────┐     ┌──────────────────────────┐
 │ Brainstorm  │ ──▶ │ Write Plan   │ ──▶ │ Create Branch │ ──▶ │ Subagent-Driven Dev      │
 │             │     │              │     │               │     │  ┌────────┐ ┌──────────┐ │
 │ • Questions │     │ • Tasks      │     │ • Isolated    │     │  │Implement│▶│  Review  │ │
 │ • Mockups   │     │ • Diagrams   │     │ • Clean base  │     │  └────────┘ └──────────┘ │
 │ • Design    │     │ • Specs      │     │ • Tests pass  │     │       ↺ per task         │
 └─────────────┘     └──────────────┘     └───────────────┘     └──────────────────────────┘
                                                                             │
                                                                             ▼
                                                                ┌──────────────────────────┐
                                                                │   Finish Branch          │
                                                                │  • Final review          │
                                                                │  • Merge / PR / Keep     │
                                                                └──────────────────────────┘
```

1. **brainstorming** — Classifies the request (spike / bounded / architectural), then refines it through questions, explores alternatives, generates visual mockups
2. **using-git-worktrees** — Isolates the session on a feature branch; concurrent writing subagents get native `Workspace: "branch"`
3. **writing-plans** — Breaks work into bite-sized tasks with exact file paths and verification steps
4. **subagent-driven-development** or **executing-plans** — Activates with plan. Either dispatches a fresh subagent per task with a two-stage review after each (most thorough), or implements every task inline in the current session with one fresh review of the whole branch at the end (cheapest).
5. **test-driven-development** — RED-GREEN-REFACTOR: write failing test → minimal code → pass → commit
6. **requesting-code-review** — Reviews against plan, reports issues by severity
7. **finishing-a-development-branch** — Verifies tests, presents merge/PR/keep options

**Where each executor runs.** subagent-driven-development needs `invoke_subagent` and the plugin's bundled agents — documented for 2.0 and the CLI, not available in the IDE (it has no `invoke_subagent`). executing-plans runs on all three; its final review uses a subagent where one is available.

**Skills trigger automatically.** Mandatory workflows, not suggestions.

## 🩺 When Something Goes Wrong

Sometimes a session misbehaves: a skill fires when it shouldn't, stays silent when it should, or the agent ignores its plan, repeats work, or burns more tokens than you'd expect. Ask your coding agent to "figure out what went wrong with superpowers in this session" and it will invoke the **diagnosing-superpowers** skill. To examine an earlier session, name it: "figure out what went wrong with superpowers in session `<id>`".

The skill reads the session transcript, reports what happened with line-level evidence, and, if you want, packages a scrubbed bundle for a bug report.

You can also start it directly: `/diagnosing-superpowers` in the 2.0 app or `/superpowers:diagnosing-superpowers` in the CLI.

## Running long plans

Both executors run a plan to the end without pausing, but approval settings can still park a run on a prompt. What may wait: the read-only git commands the executors and reviewers run on every task (`git rev-parse`, `git rev-list`, `git merge-base`, `git diff`, `git log`, `git status`), the plan's test commands, `git add` and `git commit`, and — where edits need review — every file edit.

- **Allow rules per subcommand, never a blanket `command(git)`**, which also lets `git push` through — and a push is one of the stops a run asks you about. Allow `command(git rev-parse)`, `command(git rev-list)`, `command(git merge-base)`, `command(git diff)`, `command(git log)`, `command(git status)`, `command(git add)`, `command(git commit)` and the plan's test command.
- **2.0 on macOS/Linux, Default preset:** sandboxed commands already run without prompting, so `command(git add)`, `command(git commit)` and the test command matter most; under Request Review add the read-only rules too.
- **2.0 on Windows:** the Default preset reviews every command, so add the same rules. Enabling the sandbox is not the lever: a command that must run outside it still asks first.
- **CLI:** `request-review` (the default) prompts before shell commands, so add the same rules. On Windows shells use the `regex:` form, one token per regex: `command(regex:git (rev-parse|rev-list|merge-base|diff|log|status|add|commit).*)`. `default` mode also pauses on every file edit; `accept-edits` removes those pauses and subagents inherit it — it is your choice, and the plugin never sets it. `unsandboxed` rules are deprecated in favour of `command` rules. Headless runs (`agy -p`) soft-deny shell commands you have not granted, so grant them under `permissions.allow` first.
- **IDE:** add the same git subcommands and the test command to the terminal allowlist under Request Review. In strict mode the allowlist is ignored, so every command asks.
- **Least invasive:** answer the first prompt with "Yes, and always allow in this conversation" (CLI), or rely on 2.0 remembering an approval for the rest of the conversation. Each subagent runs in its own conversation; subagents inherit your allowed command prefixes, but whether a per-conversation approval reaches a subagent is not documented.
- **Remote Control** (2.0 and the CLI) lets you answer approvals and questions from another device and notifies you when an agent needs input. It is optional; the skills never name it.
- **`/goal` is not recommended for plan runs:** it runs "without intermediate pauses", which overrides the executors' stops and the finishing menu. The executors already run continuously.

When a subagent's commit approval times out — the CLI gives subagent interactions 60 seconds — the implementer reports `commit not made`, and the controller commits its reported files in your conversation, where no such limit applies.

## 📦 Installation

> **Already installed `obra/superpowers`?** In the CLI, upstream's install most likely uses the same plugin name, `superpowers`, so installing one replaces the other. Run `agy plugin uninstall superpowers` before installing this one. Upstream's install also brings its own session-start bootstrap. In the 2.0 app and the IDE, if a folder named `superpowers` already exists in `~/.gemini/config/plugins/`, move it out of that folder before cloning this one.

### Antigravity 2.0 app and Antigravity IDE

Both discover plugins in the same folders, so one clone serves both. Install globally unless you want superpowers in chosen projects only.

A workspace install (`.agents/plugins/superpowers`) is project-level. In a 2.0 Project conversation started in New Worktree Mode, check Customizations that superpowers is listed; if it is not, use the global install for those conversations.

#### macOS / Linux

**Global plugin** (available in all projects):
```bash
git clone https://github.com/roundpilot/superpowers-antigravity ~/.gemini/config/plugins/superpowers
```

**Workspace plugin** (project-level only):
```bash
git clone https://github.com/roundpilot/superpowers-antigravity .agents/plugins/superpowers
```

**Update later:**
```bash
cd ~/.gemini/config/plugins/superpowers && git pull
```

#### Windows (PowerShell)

**Global plugin** (available in all projects):
```powershell
git clone https://github.com/roundpilot/superpowers-antigravity "$env:USERPROFILE\.gemini\config\plugins\superpowers"
```

**Workspace plugin** (project-level only):
```powershell
git clone https://github.com/roundpilot/superpowers-antigravity .agents\plugins\superpowers
```

**Update later:**
```powershell
cd "$env:USERPROFILE\.gemini\config\plugins\superpowers"; git pull
```

#### Windows (WSL)

**2.0 app connected to a WSL distribution** (Application Settings): confirm in Settings > Customizations that superpowers is listed. If it is not, clone into `~/.gemini/config/plugins/superpowers` inside the WSL distribution.

If you run the **Windows Antigravity IDE** but your workspace is in **WSL**:

```bash
# Global plugin (installed on Windows side):
git clone https://github.com/roundpilot/superpowers-antigravity /mnt/c/Users/$USER/.gemini/config/plugins/superpowers

# Workspace plugin (inside your WSL workspace):
git clone https://github.com/roundpilot/superpowers-antigravity /path/to/your/wsl/project/.agents/plugins/superpowers
```

#### Manual installation for the 2.0 app and the IDE (no git required)

<details>
<summary>Download ZIP instead of cloning (click to expand)</summary>

**macOS / Linux:**
```bash
curl -L https://github.com/roundpilot/superpowers-antigravity/archive/refs/heads/main.zip -o superpowers.zip
unzip superpowers.zip
mkdir -p ~/.gemini/config/plugins
mv superpowers-antigravity-main ~/.gemini/config/plugins/superpowers
rm superpowers.zip
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://github.com/roundpilot/superpowers-antigravity/archive/refs/heads/main.zip" -OutFile superpowers.zip
Expand-Archive superpowers.zip -DestinationPath .
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.gemini\config\plugins"
Move-Item superpowers-antigravity-main "$env:USERPROFILE\.gemini\config\plugins\superpowers"
Remove-Item superpowers.zip
```

To update later, delete the `superpowers` folder and repeat the steps above.

</details>

#### Migrating a 2.0 app or IDE install from `roundpilot/superpowers`

If you previously installed from `roundpilot/superpowers`, update your remote:

```bash
cd ~/.gemini/config/plugins/superpowers
git remote set-url origin https://github.com/roundpilot/superpowers-antigravity.git
git pull
```

#### Troubleshooting

**If superpowers is listed but its skills are never followed,** the agent may not be allowed to read files outside your project: check the IDE's non-workspace file access and strict mode, or, in the 2.0 app on Windows, the project's outside-of-folder file access policy. A workspace install keeps the skills inside the project.

### Antigravity CLI (`agy`)

```bash
agy plugin install https://github.com/roundpilot/superpowers-antigravity
```

If the CLI rejects the URL, clone the repository and install from the folder (to update this way, run `git -C <dir> pull`, then install again):

```bash
git clone https://github.com/roundpilot/superpowers-antigravity <dir>
agy plugin install <dir>
```

Inside an `agy` session, `/plugin install <local-path>` does the same as `agy plugin install <dir>`.

- **List:** `agy plugin list`
- **Update:** run the same install command again. It replaces the installed copy, so any edits made inside the installed copy are lost.
- **Disable or enable:** `agy plugin disable superpowers` / `agy plugin enable superpowers`
- **Uninstall:** `agy plugin uninstall superpowers`

> The CLI keeps its own copy of installed plugins. If you also use the 2.0 app or the IDE, install for each. If `agy plugin list` already shows superpowers after you cloned for the app, skip the CLI install.

### ✅ Verify Installation

1. **Check the product's own view** (no model turn):
   - **2.0 app:** Settings > Customizations lists superpowers under Plugins and its 16 skills under Skills.
   - **IDE:** the … menu in the agent side panel > Customizations lists superpowers among the active plugin components, with its skills.
   - **CLI:** `agy plugin list` shows superpowers and its components; `agy -p "/skills" --output-format json` lists the skills without starting an agent turn.
2. **Slash command:** type `/using-superpowers` in the 2.0 app or `/superpowers:using-superpowers` in the CLI. The bootstrap loads for the session.
3. **Behaviour:** say "Let's make a react todo list". The brainstorming skill should trigger and ask design questions instead of writing code.

## 🔌 Activation

Once installed, the methodology loads itself — no per-session setup:

- **Automatic (default).** The plugin ships the using-superpowers bootstrap as an always-on rule (`rules/using-superpowers.md`), so it loads into every conversation with no setup. Individual skills then trigger on what you ask for: describe a feature and brainstorming starts, report a bug and systematic-debugging starts.
- **Scoped, if you don't want it everywhere.** In the 2.0 app and the IDE, install as a **workspace plugin** (`.agents/plugins/superpowers`) so only chosen projects get it. In the CLI, `agy plugin disable superpowers` turns it off and `agy plugin enable superpowers` turns it back on.

The always-loaded footprint is a single ~55-line bootstrap; individual skills are read only when they trigger.

## 📚 Skills Reference

### Testing & Verification
| Skill | Purpose |
|-------|---------|
| **test-driven-development** | RED-GREEN-REFACTOR cycle with the `writing-good-tests` reference (falsifiability rules + mutation check) |
| **browser-testing** | Evidence-before-assertions for UI work (screenshot → DOM inspect → embed proof) |

### Debugging
| Skill | Purpose |
|-------|---------|
| **systematic-debugging** | 4-phase root cause process with `search_web` for unfamiliar errors |
| **verification-before-completion** | Ensure it's actually fixed; cron schedules for long test suites |
| **diagnosing-superpowers** | Work out what went wrong in a session, with evidence; export a scrubbed bundle or file an issue |

### Collaboration
| Skill | Purpose |
|-------|---------|
| **brainstorming** | Three-path router (spike / bounded / architectural) so ceremony scales to the task; Socratic refinement with `generate_image` mockups and `search_web` for prior art |
| **writing-plans** | Detailed plans with Mermaid diagrams, rich formatting, `RequestFeedback`, and a `Spec:` pointer so the spec travels with the plan |
| **executing-plans** | Inline plan execution: one context, one final review |
| **dispatching-parallel-agents** | Concurrent workflows with `Workspace: "branch"` / `"inherit"` and monitoring |
| **requesting-code-review** | Bundled `code-reviewer` dispatches with severity classification (`research` for lightweight ad-hoc reviews) |
| **receiving-code-review** | Responding to feedback with technical rigor |
| **using-git-worktrees** | Workspace isolation with mode decision table |
| **finishing-a-development-branch** | Merge/PR decision workflow |
| **subagent-driven-development** | Fast iteration with two-stage task review and async coordination; resume-based fix loop with five-round cap; records rulings instead of stalling, and batches small same-shape tasks into one dispatch |

### Meta
| Skill | Purpose |
|-------|---------|
| **writing-skills** | Create new skills following best practices |
| **using-superpowers** | Introduction to the skills system |

## 🧭 Philosophy

- **Test-Driven Development** — Write tests first, always
- **Systematic over ad-hoc** — Process over guessing
- **Complexity reduction** — Simplicity as primary goal
- **Evidence over claims** — Verify before declaring success

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines, PR requirements, and quality standards.

## 📜 License

MIT License — see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgements

This project is a fork of [obra/superpowers](https://github.com/obra/superpowers). If Superpowers has helped you, consider [sponsoring the original project](https://github.com/sponsors/obra).
