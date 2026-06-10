# Core Enhancements & Browser-Testing — Design Spec

> Approved design for 4 sub-projects that upgrade Superpowers to leverage native Antigravity 2.0 capabilities.

## Approach

**Incremental Skill Patches + One New Skill (Approach A):** Make targeted edits to 3 existing skills and create 1 new skill. Each change is independently testable and committable. No shared abstraction layers — each skill uses native Antigravity tools directly, consistent with v6.0.0 philosophy.

**Implementation constraint:** Each skill change follows writing-skills TDD cycle (RED-GREEN-REFACTOR with subagent pressure scenarios).

---

## Sub-project 1: Visual Brainstorming Enhancement

**File:** `skills/brainstorming/SKILL.md`

### Problem

The checklist step 2 still says "Offer visual companion" with a consent flow designed for the old browser-based server. With native `generate_image`, there's no browser to open — consent isn't needed. The visual companion section (lines 149-162) already references `generate_image` but lacks practical guidance.

### Changes

1. **Remove the consent gate from checklist step 2.** Replace "Offer visual companion (if topic will involve visual questions)" with a simpler decision: "Assess whether upcoming questions have visual aspects." No separate message, no consent — just a note that `generate_image` is available for visual questions.

2. **Expand the Visual Companion section** with practical guidance:
   - When to generate a single mockup vs. multiple comparison mockups
   - How to embed generated images in artifacts (carousels for A/B comparisons)
   - Prompting tips for `generate_image` (be specific about layout, style, content)

3. **Remove any remaining reference** to the deleted `visual-companion.md` file.

### What stays the same

- The overall brainstorming checklist flow (9 steps)
- The per-question decision logic (visual vs. text)
- The hard gate on implementation before design approval
- All other sections remain untouched

---

## Sub-project 2: Rich Artifacts Upgrade

**Files:** `skills/writing-plans/SKILL.md`, `skills/executing-plans/SKILL.md` (new in workspace)

### Problem

- writing-plans doesn't mention Mermaid diagrams, rich artifact formatting, or the typed artifact system
- executing-plans only exists in the installed plugin, not in the workspace, and contains legacy multi-platform references ("Claude Code or Codex")
- Neither skill generates proper walkthrough artifacts after completion

### Changes to writing-plans

1. **Add Mermaid architecture diagram** as a required element in the Plan Document Header. After the `Architecture:` text description, the plan should include a Mermaid diagram showing component relationships and data flow.

2. **Add rich artifact formatting guidance:** Instruct agents to use:
   - Diff blocks for code changes
   - File links (`[file](file:///path)`) for all file references
   - GitHub alerts (`> [!IMPORTANT]`) for critical requirements

3. **No structural changes** to the task format, self-review process, or execution handoff.

### Changes to executing-plans

1. **Add to workspace** — copy from installed plugin and update.

2. **Remove legacy multi-platform reference** on line 14 ("Claude Code or Codex") — replace with just recommending SDD when subagents are available, without naming specific platforms.

3. **Add walkthrough artifact generation:** After completing all tasks (Step 3), before invoking `finishing-a-development-branch`, generate a `walkthrough.md` artifact summarizing what was implemented, what was tested, and embedding any relevant screenshots or recordings.

### What stays the same

- writing-plans task structure (bite-sized steps, TDD, file paths)
- writing-plans self-review checklist
- executing-plans 3-step process flow (load/review → execute → complete)
- All cross-references to other skills

---

## Sub-project 3: Asynchronous Subagents (SDD Enhancement)

**File:** `skills/subagent-driven-development/SKILL.md`

### Problem

SDD dispatches one implementer at a time, blocks on each, then dispatches reviewers sequentially. Long-running builds/tests block the coordinator. No guidance on inter-agent communication beyond dispatch-and-wait.

### Changes

1. **New section: "Background Task Management"** — teach the coordinator to use `manage_task` for long-running operations:
   - Use `run_command` with a short `WaitMsBeforeAsync` for builds/tests expected to take >30 seconds
   - Use `manage_task` with `status` to check on completion
   - Don't poll in a loop — the system notifies automatically when tasks finish
   - Use `manage_task` with `kill` to terminate stuck processes

2. **New section: "Agent Communication"** — add `send_message` guidance:
   - Use `send_message` to provide additional context to a running implementer (instead of re-dispatching)
   - Use `send_message` to answer implementer questions mid-flight
   - The existing pattern of "re-dispatch with context" is still valid for NEEDS_CONTEXT, but `send_message` is preferred when the subagent is still running

3. **New section: "Timeout Protection"** — use `schedule` as a safety net:
   - When dispatching an implementer for a complex task, set a one-shot timer
   - If the implementer hasn't reported back within a reasonable window (recommend 5 minutes for standard tasks, 10 for complex ones), the timer fires and the coordinator can check status or intervene

### What stays the same

- Core sequential dispatch pattern (one implementer at a time)
- Subagent type definitions (implementer, spec-reviewer, code-reviewer)
- Two-stage review process (spec compliance then code quality)
- Handling implementer status (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED)
- All red flags and anti-patterns
- Model selection guidance

---

## Sub-project 4: Browser-Testing Skill (NEW)

**New file:** `skills/browser-testing/SKILL.md`

### Purpose

A new discipline-enforcing skill that teaches agents to verify UI/frontend work using Antigravity's browser automation, rather than claiming UI is correct without visual evidence.

### Frontmatter

```yaml
name: browser-testing
description: Use when completing frontend or UI work that needs visual verification, before claiming the UI is correct
```

### Structure

1. **Overview:** Core principle — never claim UI work is correct without visual evidence. Browser automation makes verification fast and produces artifacts for the user.

2. **When to Use** (flowchart): "Did you just implement UI/frontend changes?" → yes → "Use browser-testing"

3. **The Process:**
   - Navigate to the page under test using browser automation
   - Take a screenshot of the current state
   - Inspect DOM elements to verify structure matches expectations
   - Record a walkthrough of the key user flow (if multi-step)
   - Embed screenshots/recordings in a walkthrough artifact

4. **Quick Reference** table mapping verification needs to browser tools:
   - Visual appearance → screenshot
   - DOM structure → inspect elements
   - User flow → recording
   - Responsive layout → screenshot at different viewports

5. **Common Mistakes:**
   - Not waiting for page load before screenshots
   - Checking wrong viewport size
   - Forgetting to embed evidence in artifacts
   - Taking screenshots without inspecting DOM (visual-only verification is fragile)

6. **Integration:**
   - Reference `verification-before-completion` — browser-testing is a specialized form of verification for UI work
   - Reference `test-driven-development` — browser tests complement unit tests, not replace them

---

## Implementation Order

1. Sub-project 1 (brainstorming visual enhancement) — smallest change, minimal risk
2. Sub-project 2 (rich artifacts) — moderate change, adds executing-plans to workspace
3. Sub-project 3 (SDD async) — additive sections, no existing behavior changes
4. Sub-project 4 (browser-testing) — new skill, most testing needed

Each sub-project follows the writing-skills TDD cycle independently:
- RED: baseline test with subagent pressure scenario
- GREEN: write/edit the skill
- REFACTOR: close loopholes found during testing

## Verification Plan

For each sub-project:
1. **RED phase:** Dispatch a subagent with a scenario that exercises the skill's domain WITHOUT the skill loaded. Document baseline behavior.
2. **GREEN phase:** Apply the skill change. Re-run the same scenario WITH the skill. Verify compliance.
3. **REFACTOR phase:** Identify new rationalizations. Add counters. Re-test.
4. **Word count check:** `wc -w skills/<skill>/SKILL.md` — ensure token efficiency targets are met.
