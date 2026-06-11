# Superpowers — Antigravity 2.0 Edition

> **This is a fork of [obra/superpowers](https://github.com/obra/superpowers) rebuilt natively for [Google Antigravity 2.0](https://antigravity.google).**

Superpowers is a complete software development methodology for your coding agents, built on top of composable skills that trigger automatically. Your agent just has Superpowers.

## What's different from upstream?

The original superpowers supports 9+ platforms (Claude Code, Codex, Cursor, Gemini CLI, OpenCode, Copilot CLI, Factory Droid, etc.) via a tool mapping abstraction layer — skills are written with Claude Code tool names, and per-platform reference files translate at runtime.

This fork **removes the abstraction entirely**. All skills use native Antigravity 2.0 tool names directly (`view_file`, `run_command`, `invoke_subagent`, `define_subagent`, etc.), eliminating the translation overhead and making every skill read exactly as the agent will execute it.

### Why remove cross-platform support?

The abstraction layer costs tokens on every interaction, and those costs compound across a session:

1. **Tool mapping file loaded every session.** The upstream approach loads a ~500-token tool mapping reference (`antigravity-tools.md`) into context via `GEMINI.md` at session start. Every turn carries this translation table. This fork eliminates it entirely — `GEMINI.md` is now a single line.

2. **Agent reasoning overhead.** When a skill says "use the Bash tool," the agent must look up the mapping, reason about which native tool to call, and potentially make mistakes. When skills say `run_command` directly, there's zero translation cost — the agent reads the exact tool name it will invoke.

3. **Platform-conditional branching in skills.** The upstream `using-superpowers` skill has separate instruction blocks for Claude Code, Copilot CLI, Gemini CLI, Codex, Antigravity 2.0, and "other environments." The agent reads all of them every time the skill loads, but only one applies. This fork has a single Antigravity paragraph.

4. **86 fewer files in the project.** When agents explore the repo (during brainstorming, debugging, or planning), fewer files means less noise in `list_dir` output and faster orientation. Platform manifests, hook scripts, brainstorm server code, and legacy test suites are all gone.

5. **Smaller, focused skills.** Skills like `using-git-worktrees` went from ~216 lines (with harness detection, `git worktree` fallback, submodule guards) to ~55 lines. Shorter skills mean less context consumed when loaded, and less ambiguity about which code path to follow.

The trade-off is clear: if you use Antigravity 2.0, this fork gives you leaner skills, faster agent orientation, and zero translation overhead. If you need Claude Code, Codex, or other platforms, use the upstream [obra/superpowers](https://github.com/obra/superpowers).

| Area | Upstream (obra/superpowers) | This fork |
|------|---------------------------|-----------|
| **Platforms** | 9+ (Claude Code, Codex, Cursor, Gemini CLI, etc.) | Antigravity 2.0 only |
| **Tool names in skills** | Claude Code names + per-platform mapping files | Native Antigravity names throughout |
| **Subagent dispatch** | `Task tool (general-purpose)` with prompt template | `invoke_subagent` / `define_subagent` directly |
| **Workspace isolation** | `git worktree` with harness detection fallback | Native `Workspace: "branch"` / `"share"` / `"inherit"` |
| **Task tracking** | `TodoWrite` tool | `task.md` artifacts with `RequestFeedback` |
| **Visual brainstorming** | Browser-based server with consent gate | Native `generate_image` (no server, no consent) |
| **Plan formatting** | Plain markdown | Mermaid diagrams, file links, diff blocks, GitHub alerts |
| **Background tasks** | Not documented | `manage_task`, `send_message`, `schedule` (incl. cron) |
| **UI verification** | Not available | `browser-testing` skill with screenshot evidence |
| **Read-only subagents** | All subagents get full tool set | `TypeName: "research"` for reviewers (smaller context) |
| **Web research** | Not guided | `search_web` + `read_url_content` integrated into debugging, brainstorming, planning |
| **Hooks & bootstrap** | SessionStart hooks, `.claude-plugin/`, `.codex-plugin/`, etc. | `plugin.json` + `GEMINI.md` only |
| **Test suite** | `tests/claude-code/`, `tests/opencode/`, etc. | `tests/antigravity/` with purity validation |
| **Files removed** | — | 86 legacy platform files deleted |

### Core enhancements over upstream

Beyond the platform port, this fork adds capabilities that don't exist in the upstream repo:

* **`generate_image` in brainstorming** — native mockup generation with carousel comparisons, no browser server needed
* **Rich plan formatting** — Mermaid architecture diagrams, clickable `file:///` links, diff blocks, and GitHub alerts in implementation plans
* **Walkthrough artifacts** — `executing-plans` generates a `walkthrough.md` artifact with file links and test results before finishing
* **Async subagent coordination** — `manage_task` for long-running builds, `send_message` for mid-flight questions, `schedule` for timeout protection
* **Browser-testing skill** — evidence-before-assertions discipline for UI work (screenshot → DOM inspect → embed proof)
* **Token-saving subagents** — reviewers and explorers use `TypeName: "research"` (read-only, smaller context window) instead of full `"self"` clones
* **Automatic feedback loops** — `RequestFeedback: true` on design docs, plans, and walkthroughs eliminates the extra "please review" turn
* **Workspace mode guidance** — decision tables across skills for choosing `branch`, `inherit`, or `share` per subagent role
* **Web research integration** — `search_web` and `read_url_content` woven into debugging (unfamiliar errors), brainstorming (existing solutions), and planning (API docs)
* **Cron-based verification** — recurring `schedule` timers for long-running test suites instead of blocking the orchestrator
* **Slash command recommendations** — skills suggest `/grill-me`, `/goal`, `/browser` where appropriate

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do.

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest.

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY.

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for agents to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.

## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring the original project's opensource work](https://github.com/sponsors/obra).

## Installation

### macOS / Linux

* **Global plugin** (available in all projects):

```bash
git clone https://github.com/roundpilot/superpowers-antigravity ~/.gemini/config/plugins/superpowers
```

* **Workspace plugin** (project-level only):

```bash
git clone https://github.com/roundpilot/superpowers-antigravity .agents/plugins/superpowers
```

* **Update later:**

```bash
cd ~/.gemini/config/plugins/superpowers && git pull
```

### Windows (PowerShell)

* **Global plugin** (available in all projects):

```powershell
git clone https://github.com/roundpilot/superpowers-antigravity "$env:USERPROFILE\.gemini\config\plugins\superpowers"
```

* **Workspace plugin** (project-level only):

```powershell
git clone https://github.com/roundpilot/superpowers-antigravity .agents\plugins\superpowers
```

* **Update later:**

```powershell
cd "$env:USERPROFILE\.gemini\config\plugins\superpowers"; git pull
```

### Windows (WSL)

If you run Antigravity inside WSL, use the Linux paths above.

If you run the **Windows Antigravity IDE** but your workspace is in **WSL**, the plugin scope determines the location:

* **Global plugin** (installed on Windows side):

```bash
git clone https://github.com/roundpilot/superpowers-antigravity /mnt/c/Users/$USER/.gemini/config/plugins/superpowers
```

* **Workspace plugin** (inside your WSL workspace):

```bash
git clone https://github.com/roundpilot/superpowers-antigravity /path/to/your/wsl/project/.agents/plugins/superpowers
```

### Manual Installation (no git required)

If you don't have git installed, you can download and extract the ZIP directly from GitHub.

**macOS / Linux:**

```bash
# Download
curl -L https://github.com/roundpilot/superpowers-antigravity/archive/refs/heads/main.zip -o superpowers.zip

# Extract to global plugin directory
unzip superpowers.zip
mkdir -p ~/.gemini/config/plugins
mv superpowers-antigravity-main ~/.gemini/config/plugins/superpowers

# Clean up
rm superpowers.zip
```

**Windows (PowerShell):**

```powershell
# Download
Invoke-WebRequest -Uri "https://github.com/roundpilot/superpowers-antigravity/archive/refs/heads/main.zip" -OutFile superpowers.zip

# Extract to global plugin directory
Expand-Archive superpowers.zip -DestinationPath .
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.gemini\config\plugins"
Move-Item superpowers-antigravity-main "$env:USERPROFILE\.gemini\config\plugins\superpowers"

# Clean up
Remove-Item superpowers.zip
```

To update later, delete the `superpowers` folder and repeat the steps above.

### Activation

Once installed, Superpowers skills are available via the `/using-superpowers` slash command in Antigravity 2.0 and Antigravity IDE. For the Antigravity CLI, the command is `/superpowers:using-superpowers`. Type the appropriate command at the start of a session to activate the skill system. (Note: If you have Antigravity open during install, restart the application to ensure the plugin is scanned and loaded). The agent will load the bootstrap and tool mapping, then brainstorming, TDD, subagent-driven-development, and all other skills will trigger automatically for the rest of the session.

```
/using-superpowers
```

```
/superpowers:using-superpowers
```

### Migrating from `roundpilot/superpowers`

If you previously installed from `roundpilot/superpowers`, update your remote:

```bash
cd ~/.gemini/config/plugins/superpowers
git remote set-url origin https://github.com/roundpilot/superpowers-antigravity.git
git pull
```

On Windows (PowerShell):

```powershell
cd "$env:USERPROFILE\.gemini\config\plugins\superpowers"
git remote set-url origin https://github.com/roundpilot/superpowers-antigravity.git
git pull
```

### Verify Installation

1. Start a new Antigravity session
2. Type `/using-superpowers` (or `/superpowers:using-superpowers` if using the Antigravity CLI)
3. Say "Let's make a react todo list"
4. The brainstorming skill should trigger automatically

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Uses `generate_image` for visual mockups and comparisons. Saves design document.
2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace via `invoke_subagent` with `Workspace: "branch"`, runs project setup, verifies clean test baseline.
3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps. Plans include Mermaid architecture diagrams and rich formatting.
4. **subagent-driven-development** - Activates with plan. Uses `define_subagent` to set up implementer, spec-reviewer, and code-reviewer types, then dispatches fresh subagent per task with two-stage review. Uses `manage_task` for long-running operations and `schedule` for timeout protection.
5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.
6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.
7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard) via `ask_question`, cleans up workspace.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## What's Inside

### Skills Library

**Testing & Verification**

* **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)
* **browser-testing** - Evidence-before-assertions for UI work (screenshot, DOM inspect, embed proof)

**Debugging**

* **systematic-debugging** - 4-phase root cause process with `search_web` for unfamiliar errors and `grep_search` for codebase patterns
* **verification-before-completion** - Ensure it's actually fixed; cron schedules for long test suites

**Collaboration**

* **brainstorming** - Socratic design refinement with `generate_image` mockups, `research` subagents for exploration, `search_web` for prior art
* **writing-plans** - Detailed implementation plans with Mermaid diagrams, rich formatting, `RequestFeedback` on artifacts
* **executing-plans** - Inline plan execution with walkthrough generation (for non-subagent environments)
* **dispatching-parallel-agents** - Concurrent subagent workflows with `Workspace: "share"` and `manage_subagents` monitoring
* **requesting-code-review** - `TypeName: "research"` reviewers with GitHub alert severity classification
* **receiving-code-review** - Responding to feedback
* **using-git-worktrees** - Workspace isolation with mode decision table (`branch`/`inherit`/`share`)
* **finishing-a-development-branch** - Merge/PR decision workflow with `ask_permission` for destructive operations
* **subagent-driven-development** - Fast iteration with two-stage review, `manage_task` for async ops, `schedule` cron for timeouts

**Meta**

* **writing-skills** - Create new skills following best practices (includes testing methodology)
* **using-superpowers** - Introduction to the skills system

## Philosophy

* **Test-Driven Development** - Write tests first, always
* **Systematic over ad-hoc** - Process over guessing
* **Complexity reduction** - Simplicity as primary goal
* **Evidence over claims** - Verify before declaring success

Read [the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines, PR requirements, and quality standards.

## License

MIT License - see LICENSE file for details

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

* **Discord**: [Join us](https://discord.gg/35wsABTejz) for community support, questions, and sharing what you're building with Superpowers
* **Issues**: https://github.com/obra/superpowers/issues
* **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions
