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

const HOOKS_CONFIG_USAGE = 'usage: json-tool.mjs hooks-config <file|->';

// hooks-config: one line per hook handler of a hooks.json, read from a file or, for `-`,
// from stdin:
//   <entry><TAB><event><TAB><enabled><TAB><command>
// An entry maps an event name to a list. The list holds matcher groups,
// {"matcher": ..., "hooks": [<handler>, ...]}, or, for the events without a matcher,
// handlers directly (docs/hooks "Schema and File Format"); both forms are read, and a
// group that also carries its own `command` yields that handler too. Any key but
// `enabled` whose value is an array is an event, so an event added later cannot hide a
// handler. <enabled> is `true`, `false`, or `absent` for an entry without the key. A
// handler without a string command prints an empty command. TAB, LF and CR inside a
// field print as \t, \n and \r so a line always has four fields.
// Exit 1 on an unreadable or unparseable file or a document that is not the shape above,
// with the reason on stderr; 2 on a usage error.
function hooksConfig(argv) {
    if (argv.length !== 1) return usage(HOOKS_CONFIG_USAGE, 'hooks-config takes one argument');
    const source = argv[0];
    const fail = (message) => {
        process.stderr.write(`json-tool: hooks-config: ${message}\n`);
        return 1;
    };

    let text;
    try {
        text = fs.readFileSync(source === '-' ? 0 : source, 'utf8');
    } catch (err) {
        return fail(`cannot read ${source === '-' ? 'stdin' : source}: ${err.message}`);
    }
    let doc;
    try {
        doc = JSON.parse(text.replace(/^﻿/, ''));
    } catch (err) {
        return fail(`not JSON: ${err.message}`);
    }
    const isObject = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);
    if (!isObject(doc)) return fail('the document is not an object of entries');

    const field = (value) =>
        String(value).replace(/\t/g, '\\t').replace(/\n/g, '\\n').replace(/\r/g, '\\r');
    const lines = [];
    for (const entry of Object.keys(doc)) {
        const body = doc[entry];
        if (!isObject(body)) return fail(`entry ${JSON.stringify(entry)} is not an object`);
        let enabled = 'absent';
        if (Object.prototype.hasOwnProperty.call(body, 'enabled')) {
            if (typeof body.enabled !== 'boolean') {
                return fail(`entry ${JSON.stringify(entry)}: "enabled" is not a boolean`);
            }
            enabled = String(body.enabled);
        }
        for (const event of Object.keys(body)) {
            if (event === 'enabled' || !Array.isArray(body[event])) continue;
            const emit = (handler) => {
                if (!isObject(handler)) {
                    return fail(`entry ${JSON.stringify(entry)}, event ${event}: a handler is not an object`);
                }
                const command = typeof handler.command === 'string' ? handler.command : '';
                lines.push([entry, event, enabled, command].map(field).join('\t'));
                return 0;
            };
            for (const item of body[event]) {
                if (!isObject(item)) {
                    return fail(`entry ${JSON.stringify(entry)}, event ${event}: a list item is not an object`);
                }
                const grouped = Array.isArray(item.hooks);
                if (grouped) {
                    for (const handler of item.hooks) {
                        if (emit(handler) !== 0) return 1;
                    }
                }
                if (!grouped || typeof item.command === 'string') {
                    if (emit(item) !== 0) return 1;
                }
            }
        }
    }
    if (lines.length > 0) process.stdout.write(`${lines.join('\n')}\n`);
    return 0;
}

const KEYS_USAGE = 'usage: json-tool.mjs keys <file>';
const GET_USAGE = 'usage: json-tool.mjs get <file> <dot.path>';

// loadJson: read and parse a JSON file (a leading BOM is ignored). Returns {doc} or
// {error}, the reason for stderr.
function loadJson(file) {
    let text;
    try {
        text = fs.readFileSync(file, 'utf8');
    } catch (err) {
        return { error: `cannot read ${file}: ${err.message}` };
    }
    try {
        return { doc: JSON.parse(text.replace(/^﻿/, '')) };
    } catch (err) {
        return { error: `${file} is not JSON: ${err.message}` };
    }
}

// keys: the top-level keys of a JSON object file, one per line, in document order.
// Exit 1, with the reason on stderr, if the file cannot be read, does not parse or is not
// an object; 2 on a usage error.
function keys(argv) {
    if (argv.length !== 1) return usage(KEYS_USAGE, 'keys takes one argument');
    const loaded = loadJson(argv[0]);
    if (loaded.error !== undefined) {
        process.stderr.write(`json-tool: keys: ${loaded.error}\n`);
        return 1;
    }
    const doc = loaded.doc;
    if (doc === null || typeof doc !== 'object' || Array.isArray(doc)) {
        process.stderr.write(`json-tool: keys: ${argv[0]} is not a JSON object\n`);
        return 1;
    }
    const names = Object.keys(doc);
    if (names.length > 0) process.stdout.write(`${names.join('\n')}\n`);
    return 0;
}

// get: the value at a dot path of a JSON file, followed by one newline. A string prints
// raw; anything else prints as JSON.stringify gives it. The path splits on `.`: a segment
// indexes an array when it is a canonical non-negative integer, else it is an own key of an
// object (so a key that itself holds a dot cannot be addressed). Exit 1, with the reason
// on stderr, if the file cannot be read, does not parse or has no such path; 2 on a usage
// error.
function get(argv) {
    if (argv.length !== 2) return usage(GET_USAGE, 'get takes two arguments');
    const [file, dotPath] = argv;
    const loaded = loadJson(file);
    if (loaded.error !== undefined) {
        process.stderr.write(`json-tool: get: ${loaded.error}\n`);
        return 1;
    }
    let value = loaded.doc;
    for (const segment of dotPath.split('.')) {
        if (Array.isArray(value)) {
            const index = /^(0|[1-9][0-9]*)$/.test(segment) ? Number(segment) : -1;
            if (index < 0 || index >= value.length) value = undefined;
            else value = value[index];
        } else if (
            value !== null &&
            typeof value === 'object' &&
            Object.prototype.hasOwnProperty.call(value, segment)
        ) {
            value = value[segment];
        } else {
            value = undefined;
        }
        if (value === undefined) {
            process.stderr.write(`json-tool: get: ${file} has no ${dotPath}\n`);
            return 1;
        }
    }
    process.stdout.write(`${typeof value === 'string' ? value : JSON.stringify(value)}\n`);
    return 0;
}

export const commands = { payload, 'hooks-config': hooksConfig, keys, get };

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
