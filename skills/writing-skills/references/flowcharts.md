# Flowcharts in Skills

Part of superpowers:writing-skills.

## Flowchart Usage

```dot
digraph when_flowchart {
    "Need to show information?" [shape=diamond];
    "Decision where I might go wrong?" [shape=diamond];
    "Use markdown" [shape=box];
    "Small inline flowchart" [shape=box];

    "Need to show information?" -> "Decision where I might go wrong?" [label="yes"];
    "Decision where I might go wrong?" -> "Small inline flowchart" [label="yes"];
    "Decision where I might go wrong?" -> "Use markdown" [label="no"];
}
```

**Use flowcharts ONLY for:**
- Non-obvious decision points
- Process loops where you might stop too early
- "When to use A vs B" decisions

**Never use flowcharts for:**
- Reference material → Tables, lists
- Code examples → Markdown blocks
- Linear instructions → Numbered lists
- Labels without semantic meaning (step1, helper2)

See `graphviz-conventions.dot` in this directory for graphviz style rules.

**Visualizing for your human partner:** Use `render-graphs.js` in the writing-skills directory to render a skill's flowcharts to SVG, run from there:
```bash
node ./render-graphs.js ../some-skill           # Each diagram separately
node ./render-graphs.js ../some-skill --combine # All diagrams in one SVG
```

Run it through `run_command` with `Cwd` set to this skill's directory, giving the target skill's
absolute path when it is not a sibling of this one. It needs Graphviz (`dot`) on PATH and writes
the SVGs to the target's `diagrams/` directory. In a sandboxed session this skill's directory may
be invisible to commands: ask for read access to it (`ask_permission` with `Action: "read_file"`),
and run outside the sandbox only as a last resort, with your human partner's approval.
