# Antigravity 2.0 Test Suite

Testing Superpowers skills on the Antigravity 2.0 platform (Google DeepMind's agentic coding assistant).

## Overview

This test suite validates that Superpowers skills work correctly on Antigravity 2.0, covering:

- **Plugin discovery** — Verifies Antigravity loads the superpowers plugin and exposes skills
- **Skill triggering** — Tests that naive prompts trigger the correct skill (reuses prompts from `tests/skill-triggering/prompts/`)
- **Subagent dispatch** — Validates the `subagent-driven-development` workflow using `invoke_subagent`
- **Tool mapping accuracy** — Static validation that `antigravity-tools.md` references only valid tools
- **Workspace isolation** — Confirms worktree/branch workspace guidance works

## Prerequisites

1. **Antigravity CLI** (`agy`) must be installed and available on `$PATH`
2. **Superpowers plugin** must be symlinked or copied into `~/.gemini/config/plugins/superpowers/`
3. **bash** 4.0+ with standard GNU utils (`grep`, `sed`, `timeout`, `jq`)

### Plugin Installation

```bash
# Symlink from repo root:
ln -sfn "$(pwd)" ~/.gemini/config/plugins/superpowers
```

## How to Run Tests

### All skill-triggering tests

```bash
cd tests/antigravity/test-skill-triggering
./run-all.sh
```

### Individual skill-triggering test

```bash
cd tests/antigravity/test-skill-triggering
./run-test.sh systematic-debugging ../../../tests/skill-triggering/prompts/systematic-debugging.txt
```

### Plugin discovery

```bash
cd tests/antigravity
./test-plugin-discovery.sh
```

### Subagent dispatch

```bash
cd tests/antigravity
./test-subagent-dispatch.sh
```

### Tool mapping accuracy (static, no agy required)

```bash
cd tests/antigravity
./test-tool-mapping-accuracy.sh
```

### Workspace isolation

```bash
cd tests/antigravity
./test-worktree-workspace.sh
```

## Session Transcript Format

Antigravity 2.0 stores session transcripts as **JSONL** files at:

```
~/.gemini/antigravity/brain/<conversation-id>/.system_generated/logs/transcript.jsonl
```

Each line is a JSON object with these key fields:

| Field | Description |
|-------|-------------|
| `step_index` | Sequential index of the step in the trajectory |
| `source` | Origin of the action: `USER_EXPLICIT`, `MODEL`, `SYSTEM` |
| `type` | Step type: `USER_INPUT`, `PLANNER_RESPONSE`, `VIEW_FILE`, etc. |
| `status` | Outcome: `DONE`, `ERROR` |
| `content` | Text content (user request or model response) |
| `tool_calls` | Array of tool invocations with their arguments |

### Example transcript entry

```json
{
  "step_index": 5,
  "source": "MODEL",
  "type": "PLANNER_RESPONSE",
  "status": "DONE",
  "content": "I'll use the subagent-driven-development skill...",
  "tool_calls": [
    {
      "name": "invoke_subagent",
      "arguments": {
        "TypeName": "self",
        "Role": "Implementer",
        "Prompt": "Implement Task 1..."
      }
    }
  ]
}
```

### Finding transcripts

```bash
# Find recent transcripts (last 60 minutes)
find ~/.gemini/antigravity/brain -name "transcript.jsonl" -mmin -60

# Search for specific tool calls in a transcript
grep '"invoke_subagent"' ~/.gemini/antigravity/brain/<id>/.system_generated/logs/transcript.jsonl
```

## Differences from Claude Code Testing

| Aspect | Claude Code | Antigravity 2.0 |
|--------|-------------|-----------------|
| **CLI command** | `claude` | `agy` |
| **Headless flag** | `-p` | `--print` |
| **Transcript location** | `~/.claude/projects/<dir>/<session>.jsonl` | `~/.gemini/antigravity/brain/<id>/.system_generated/logs/transcript.jsonl` |
| **Transcript format** | Flat JSONL with `type: "assistant"/"user"` | Structured JSONL with `step_index`, `source`, `type`, `status` |
| **Tool invocation field** | `"name":"Skill"` with `"skill":"..."` | Tool name directly in `tool_calls[].name` (e.g., `invoke_subagent`, `view_file`) |
| **Subagent dispatch** | `Task` / `Agent` tool | `invoke_subagent` tool |
| **Task tracking** | `TodoWrite` tool | `write_to_file` creating `task.md` artifact |
| **Skill invocation** | Explicit `Skill` tool call | Skills auto-load from plugins; look for `view_file` on `SKILL.md` |
| **Plugin loading** | `--plugin-dir` flag | Plugins in `~/.gemini/config/plugins/` |
| **Permission bypass** | `--permission-mode bypassPermissions` | Not needed (Antigravity handles permissions differently) |
| **Stream output** | `--output-format stream-json` | `--print` (plain text output) |

## Troubleshooting

### `agy` command not found

Ensure the Antigravity CLI is installed and on your `$PATH`:

```bash
which agy
```

If not installed, the test scripts will detect this and print a helpful error message.

### Plugin not loading

1. Check the plugin symlink exists:
   ```bash
   ls -la ~/.gemini/config/plugins/superpowers/
   ```
2. Verify `plugin.json` is present in the plugin directory
3. Look for plugin loading errors in Antigravity output

### Skills not triggering

- Skills auto-load in Antigravity; there's no explicit `Skill` tool call to grep for
- Instead, look for evidence the skill was read (`view_file` on `SKILL.md`) or skill name mentions in output
- Check that the plugin directory structure is correct: `skills/<skill-name>/SKILL.md`

### Transcript not found

Antigravity stores transcripts under `~/.gemini/antigravity/brain/`. Each conversation gets a UUID directory:

```bash
# List recent conversations
ls -lt ~/.gemini/antigravity/brain/ | head -10

# Find transcript files
find ~/.gemini/antigravity/brain -name "transcript.jsonl" -mmin -60
```

### Test timeouts

- Default timeout is 300 seconds (5 minutes) for simple tests
- Subagent dispatch tests use 1800 seconds (30 minutes)
- Increase via the timeout parameter if needed
- Check for network issues if Antigravity is slow to respond
