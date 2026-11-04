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

const STREAM_USAGE = 'usage: json-tool.mjs stream init-tools|text|tool-calls [name]|subagents|result [--field <key>]  (stdin)';

// jsonLines: the JSON objects with an `event` key among the lines of a text; others are skipped.
function jsonLines(text) {
    const out = [];
    for (const line of text.split(/\r?\n/)) {
        const t = line.trim();
        if (t === '' || t[0] !== '{') continue;
        try {
            const obj = JSON.parse(t);
            if (obj !== null && typeof obj === 'object' && typeof obj.event === 'string') out.push(obj);
        } catch { /* not JSON: skipped */ }
    }
    return out;
}

const printField = (value) => (typeof value === 'string' ? value : JSON.stringify(value));

// sameDir: a file URI and a directory resolve, through fileURLToPath and path.resolve, to one path.
function sameDir(uri, cwd) {
    try {
        let a = path.resolve(fileURLToPath(uri));
        let b = path.resolve(cwd);
        if (process.platform === 'win32') {
            a = a.toLowerCase();
            b = b.toLowerCase();
        }
        return a === b;
    } catch {
        return false;
    }
}

// stream: views over an `agy --output-format stream-json` capture on stdin.
function stream(argv) {
    const view = argv[0];
    const rest = argv.slice(1);
    if (!['init-tools', 'text', 'tool-calls', 'subagents', 'result'].includes(view)) {
        return usage(STREAM_USAGE, `unknown view ${view}`);
    }
    let field;
    let name;
    for (let i = 0; i < rest.length; i++) {
        if (rest[i] === '--field') {
            if (i + 1 >= rest.length) return usage(STREAM_USAGE, '--field needs a value');
            field = rest[++i];
        } else if (view === 'tool-calls' && name === undefined) {
            name = rest[i];
        } else {
            return usage(STREAM_USAGE, `unexpected argument ${rest[i]}`);
        }
    }
    let input = '';
    try {
        input = fs.readFileSync(0, 'utf8');
    } catch { /* an empty stdin reads as no events */ }
    const events = jsonLines(input);
    const out = (line) => process.stdout.write(`${line}\n`);
    const init = events.find((e) => e.event === 'init');

    if (view === 'init-tools') {
        if (!init) {
            process.stderr.write('json-tool: stream: no init event\n');
            return 1;
        }
        for (const tool of (init.init && init.init.tools) || []) out(tool);
        return 0;
    }

    if (view === 'result') {
        const last = events.filter((e) => e.event === 'result').pop();
        let obj = {};
        if (last) {
            const r = last.result || {};
            obj = {
                status: r.status,
                conversation_id: r.conversation_id,
                denied_actions: Array.isArray(r.denied_actions) ? r.denied_actions : [],
            };
        }
        if (field !== undefined) {
            if (obj[field] !== undefined) out(printField(obj[field]));
        } else {
            out(JSON.stringify(obj));
        }
        return 0;
    }

    // steps: step_update payloads keyed by conversation_id + step_index, merged in arrival
    // order so the last update wins per key; first-seen order is kept.
    const steps = new Map();
    for (const e of events) {
        if (e.event !== 'step_update' || !e.step_update) continue;
        const u = e.step_update;
        const key = `${u.conversation_id}#${u.step_index}`;
        const cur = steps.get(key) || { text: '' };
        const { text_delta: delta, ...others } = u;
        Object.assign(cur, others);
        if (typeof delta === 'string') cur.text += delta;
        steps.set(key, cur);
    }

    if (view === 'text') {
        const parts = [...steps.values()].filter((s) => s.step_type === 'agent_response' && s.text !== '').map((s) => s.text);
        out(parts.join('\n'));
        return 0;
    }

    if (view === 'tool-calls') {
        for (const s of steps.values()) {
            if (s.step_type !== 'tool' || !s.tool_info || typeof s.tool_info !== 'object') continue;
            if (name !== undefined && s.tool_info.name !== name) continue;
            const params = s.tool_info.parameters === undefined ? {} : s.tool_info.parameters;
            if (field !== undefined) {
                if (params !== null && typeof params === 'object' && Object.prototype.hasOwnProperty.call(params, field)) {
                    out(printField(params[field]));
                }
            } else {
                out(JSON.stringify({ name: s.tool_info.name, parameters: params }));
            }
        }
        return 0;
    }

    const cwd = init && init.init ? init.init.cwd : undefined;
    for (const s of steps.values()) {
        const list = s.subagent_info && Array.isArray(s.subagent_info.subagents) ? s.subagent_info.subagents : [];
        for (const sub of list) {
            const uris = Array.isArray(sub.workspace_uris) ? sub.workspace_uris : [];
            const item = {
                type_name: sub.type_name,
                role: sub.role,
                conversation_id: sub.conversation_id,
                workspace_uris: uris,
                init_cwd: cwd === undefined ? null : path.resolve(cwd),
                at_init_cwd: cwd !== undefined && uris.every((u) => sameDir(u, cwd)),
            };
            if (field !== undefined) {
                if (item[field] !== undefined) out(printField(item[field]));
            } else {
                out(JSON.stringify(item));
            }
        }
    }
    return 0;
}

const NAMES_USAGE = 'usage: json-tool.mjs skills-json|agents-json <file|->';

// collectNames: every string under a `name` key at any depth, recursing into strings that
// parse as JSON; unique, in input order.
function collectNames(value, seen) {
    if (typeof value === 'string') {
        const t = value.trim();
        if (t[0] === '{' || t[0] === '[') {
            try {
                collectNames(JSON.parse(t), seen);
            } catch { /* plain text */ }
        }
    } else if (Array.isArray(value)) {
        for (const v of value) collectNames(v, seen);
    } else if (value !== null && typeof value === 'object') {
        for (const k of Object.keys(value)) {
            if (k === 'name' && typeof value[k] === 'string') seen.add(value[k]);
            else collectNames(value[k], seen);
        }
    }
}

// namesJson: the names listed in `agy ... --output-format json`, for skills-json and agents-json.
function namesJson(argv) {
    if (argv.length !== 1) return usage(NAMES_USAGE, 'takes one argument');
    let text;
    try {
        text = fs.readFileSync(argv[0] === '-' ? 0 : argv[0], 'utf8');
    } catch (err) {
        process.stderr.write(`json-tool: cannot read ${argv[0]}: ${err.message}\n`);
        return 1;
    }
    text = text.replace(/^﻿/, '');
    const seen = new Set();
    try {
        collectNames(JSON.parse(text), seen);
    } catch {
        for (const line of text.split(/\r?\n/)) collectNames(line, seen);
    }
    if (seen.size === 0) {
        process.stderr.write('json-tool: no names found\n');
        return 1;
    }
    process.stdout.write(`${[...seen].join('\n')}\n`);
    return 0;
}

export const commands = {
    payload,
    'hooks-config': hooksConfig,
    keys,
    get,
    stream,
    'skills-json': namesJson,
    'agents-json': namesJson,
};

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
