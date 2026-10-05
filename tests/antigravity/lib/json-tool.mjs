// json-tool.mjs: the one place the bash tests read or build JSON, so no test needs jq
// or python. ESM, node >= 18, built-ins only.
//
//   node tests/antigravity/lib/json-tool.mjs <command> [args...]
//
// `commands` maps a command name to (argv: string[]) => number, the exit code. An
// unknown command prints `json-tool: unknown command <name>` to stderr and exits 2.
// Later tasks add entries to this table.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PAYLOAD_USAGE =
    'usage: json-tool.mjs payload --tool <name> --target <path> [--workspace <dir>]... ' +
    '[--code <text>] [--replacement <text>] [--chunks <json>] [--chunks-text <text>] ' +
    '[--artifact-dir <dir>]';

function usage(text, message) {
    if (message) process.stderr.write(`json-tool: ${message}\n`);
    process.stderr.write(`${text}\n`);
    return 2;
}

// payload: one PreToolUse fixture line for the purity hook,
//   {"toolCall":{"name","args":{"TargetFile",...}},"stepIdx":0,"conversationId":"zz-fixture"}
// workspacePaths and artifactDirectoryPath appear only when their flags are given.
function payload(argv) {
    const VALUE_FLAGS = [
        '--tool', '--target', '--workspace', '--code', '--replacement',
        '--chunks', '--chunks-text', '--artifact-dir',
    ];
    let tool;
    let target;
    let code;
    let replacement;
    let chunks;
    let artifactDir;
    const workspaces = [];
    for (let i = 0; i < argv.length; i++) {
        const flag = argv[i];
        if (!VALUE_FLAGS.includes(flag)) return usage(PAYLOAD_USAGE, `unknown flag ${flag}`);
        if (i + 1 >= argv.length) return usage(PAYLOAD_USAGE, `${flag} needs a value`);
        const value = argv[++i];
        if (flag === '--tool') tool = value;
        else if (flag === '--target') target = value;
        else if (flag === '--workspace') workspaces.push(value);
        else if (flag === '--code') code = value;
        else if (flag === '--replacement') replacement = value;
        else if (flag === '--artifact-dir') artifactDir = value;
        else if (flag === '--chunks-text') chunks = value;
        else {
            try {
                chunks = JSON.parse(value);
            } catch (err) {
                return usage(PAYLOAD_USAGE, `--chunks is not JSON: ${err.message}`);
            }
        }
    }
    if (tool === undefined) return usage(PAYLOAD_USAGE, 'payload needs --tool');
    if (target === undefined) return usage(PAYLOAD_USAGE, 'payload needs --target');

    const args = { TargetFile: target };
    if (code !== undefined) args.CodeContent = code;
    if (replacement !== undefined) args.ReplacementContent = replacement;
    if (chunks !== undefined) args.ReplacementChunks = chunks;
    const out = {
        toolCall: { name: tool, args },
        stepIdx: 0,
        conversationId: 'zz-fixture',
    };
    if (workspaces.length > 0) out.workspacePaths = workspaces;
    if (artifactDir !== undefined) out.artifactDirectoryPath = artifactDir;
    process.stdout.write(`${JSON.stringify(out)}\n`);
    return 0;
}

export const commands = { payload };

function isMain() {
    try {
        return (
            fs.realpathSync(path.resolve(process.argv[1])) ===
            fs.realpathSync(fileURLToPath(import.meta.url))
        );
    } catch {
        return false;
    }
}

if (isMain()) {
    const name = process.argv[2];
    if (name === undefined) {
        process.exitCode = usage(`usage: json-tool.mjs <command> [args...]  (commands: ${Object.keys(commands).join(', ')})`);
    } else if (!Object.prototype.hasOwnProperty.call(commands, name)) {
        process.stderr.write(`json-tool: unknown command ${name}\n`);
        process.exitCode = 2;
    } else {
        process.exitCode = commands[name](process.argv.slice(3));
    }
}
