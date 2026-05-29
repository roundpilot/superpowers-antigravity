# Superpowers for Antigravity 2.0

> \*\*This is a fork of \[obra/superpowers](https://github.com/obra/superpowers) ported to \[Google Antigravity 2.0](https://antigravity.google).\*\*
>
> All upstream skills, workflows, and prompt templates are preserved. This fork adds native Antigravity 2.0 support: a `plugin.json` manifest, a comprehensive tool mapping reference (`antigravity-tools.md`), workspace isolation via `invoke\_subagent` with `Workspace: "branch"`, and a full test suite.

Superpowers is a complete software development methodology for your coding agents, built on top of a set of composable skills and some initial instructions that make sure your agent uses them.

## What's different in this fork?

|Area|What changed|
|-|-|
|**Plugin manifest**|Added `plugin.json` for Antigravity 2.0 plugin discovery|
|**Tool mapping**|New `antigravity-tools.md` maps all 20 Antigravity tools from the generic Claude Code format used in skills|
|**Subagent dispatch**|Documents `invoke\_subagent` (baseline) and `define\_subagent` (optimization for multi-task plans)|
|**Workspace isolation**|`using-git-worktrees` recognizes `Workspace: "branch"` as a native worktree tool|
|**Bootstrap**|`using-superpowers` SKILL.md and `GEMINI.md` updated with Antigravity 2.0 entries|
|**Test suite**|Full `tests/antigravity/` directory with plugin discovery, skill triggering, subagent dispatch, and tool mapping validation tests|
|**Cross-platform**|All upstream prompt templates are **unmodified** — Claude Code, Codex, Copilot CLI, and Gemini CLI all work exactly as before|

## Quickstart

Give your agent Superpowers: [Antigravity 2.0](#antigravity-20), [Claude Code](#claude-code), [Codex CLI](#codex-cli), [Codex App](#codex-app), [Factory Droid](#factory-droid), [Gemini CLI](#gemini-cli), [OpenCode](#opencode), [Cursor](#cursor), [GitHub Copilot CLI](#github-copilot-cli).

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do.

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest.

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY.

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for Claude to be able to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.



## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring my opensource work](https://github.com/sponsors/obra).

Thanks!

* Jesse



## Installation

Installation differs by harness. If you use more than one, install Superpowers separately for each one.

### Antigravity 2.0

This is the primary target for this fork. Choose your platform below.

#### macOS / Linux

* **Global plugin** (available in all projects):

```bash
  git clone https://github.com/roundpilot/superpowers \~/.gemini/config/plugins/superpowers
  ```

* **Workspace plugin** (project-level only):

```bash
  git clone https://github.com/roundpilot/superpowers .agents/plugins/superpowers
  ```

* **Update later:**

```bash
  cd \~/.gemini/config/plugins/superpowers \&\& git pull
  ```

#### Windows (PowerShell)

* **Global plugin** (available in all projects):

```powershell
  git clone https://github.com/roundpilot/superpowers "$env:USERPROFILE\\.gemini\\config\\plugins\\superpowers"
  ```

* **Workspace plugin** (project-level only):

```powershell
  git clone https://github.com/roundpilot/superpowers .agents\\plugins\\superpowers
  ```

* **Update later:**

```powershell
  cd "$env:USERPROFILE\\.gemini\\config\\plugins\\superpowers"; git pull
  ```

#### Windows (WSL)

If you run Antigravity inside WSL, use the Linux paths.

If you run the **Windows Antigravity IDE** but your workspace is in **WSL**, the plugin scope determines the location:

* **Global plugin** (available in all projects, installed on Windows side):

  Clone the repository directly to your Windows user profile path:

  ```bash
  git clone https://github.com/roundpilot/superpowers /mnt/c/Users/$USER/.gemini/config/plugins/superpowers
  ```

* **Workspace plugin** (project-level only, installed inside your WSL workspace):

  Clone (or symlink) the repository into the project-level plugins folder inside your WSL workspace:

  ```bash
  git clone https://github.com/roundpilot/superpowers /path/to/your/wsl/project/.agents/plugins/superpowers
  ```



  #### Activation

  Once installed, Superpowers skills are available via the **`/using-superpowers`** slash command. Type `/using-superpowers` at the start of a session to activate the skill system. *(Note: If you are using the Antigravity IDE or Antigravity 2.0, restart the application or open a new chat session after installing to ensure the plugin is scanned and loaded).* The agent will load the bootstrap and tool mapping, then brainstorming, TDD, subagent-driven-development, and all other skills will trigger automatically for the rest of the session.



  #### Verify Installation

1. Start a new Antigravity session
2. Type `/using-superpowers`
3. Say "Let's make a react todo list"
4. The brainstorming skill should trigger automatically



   ### Claude Code

   Superpowers is available via the [official Claude plugin marketplace](https://claude.com/plugins/superpowers)

   #### Official Marketplace

* Install the plugin from Anthropic's official marketplace:

  ```bash
  /plugin install superpowers@claude-plugins-official
  ```

  #### Superpowers Marketplace

  The Superpowers marketplace provides Superpowers and some other related plugins for Claude Code.

* Register the marketplace:

  ```bash
  /plugin marketplace add obra/superpowers-marketplace
  ```

* Install the plugin from this marketplace:

  ```bash
  /plugin install superpowers@superpowers-marketplace
  ```

  ### Codex CLI

  Superpowers is available via the [official Codex plugin marketplace](https://github.com/openai/plugins).

* Open the plugin search interface:

  ```bash
  /plugins
  ```

* Search for Superpowers:

  ```bash
  superpowers
  ```

* Select `Install Plugin`.

  ### Codex App

  Superpowers is available via the [official Codex plugin marketplace](https://github.com/openai/plugins).

* In the Codex app, click on Plugins in the sidebar.
* You should see `Superpowers` in the Coding section.
* Click the `+` next to Superpowers and follow the prompts.

  ### Factory Droid

* Register the marketplace:

  ```bash
  droid plugin marketplace add https://github.com/obra/superpowers
  ```

* Install the plugin:

  ```bash
  droid plugin install superpowers@superpowers
  ```

  ### Gemini CLI

* Install the extension:

  ```bash
  gemini extensions install https://github.com/obra/superpowers
  ```

* Update later:

  ```bash
  gemini extensions update superpowers
  ```

  ### OpenCode

  OpenCode uses its own plugin install; install Superpowers separately even if you
already use it in another harness.

* Tell OpenCode:

  ```
  Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md
  ```

* Detailed docs: [docs/README.opencode.md](docs/README.opencode.md)

  ### Cursor

* In Cursor Agent chat, install from marketplace:

  ```text
  /add-plugin superpowers
  ```

* Or search for "superpowers" in the plugin marketplace.

  ### GitHub Copilot CLI

* Register the marketplace:

  ```bash
  copilot plugin marketplace add obra/superpowers-marketplace
  ```

* Install the plugin:

  ```bash
  copilot plugin install superpowers@superpowers-marketplace
  ```

  ## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves design document.
2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.
3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps.
4. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches fresh subagent per task with two-stage review (spec compliance, then code quality), or executes in batches with human checkpoints.
5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.
6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.
7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

   **The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

   ## What's Inside

   ### Skills Library

   **Testing**

* **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

  **Debugging**

* **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
* **verification-before-completion** - Ensure it's actually fixed

  **Collaboration**

* **brainstorming** - Socratic design refinement
* **writing-plans** - Detailed implementation plans
* **executing-plans** - Batch execution with checkpoints
* **dispatching-parallel-agents** - Concurrent subagent workflows
* **requesting-code-review** - Pre-review checklist
* **receiving-code-review** - Responding to feedback
* **using-git-worktrees** - Parallel development branches
* **finishing-a-development-branch** - Merge/PR decision workflow
* **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)

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

  The general contribution process for Superpowers is below. Keep in mind that we don't generally accept contributions of new skills and that any updates to skills must work across all of the coding agents we support.

1. Fork the repository
2. Switch to the 'dev' branch
3. Create a branch for your work
4. Follow the `writing-skills` skill for creating and testing new and modified skills
5. Submit a PR, being sure to fill in the pull request template.

   See `skills/writing-skills/SKILL.md` for the complete guide.

   ## Updating

   Superpowers updates are somewhat coding-agent dependent, but are often automatic.

   ## License

   MIT License - see LICENSE file for details

   ## Community

   Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

* **Discord**: [Join us](https://discord.gg/35wsABTejz) for community support, questions, and sharing what you're building with Superpowers
* **Issues**: https://github.com/obra/superpowers/issues
* **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions

