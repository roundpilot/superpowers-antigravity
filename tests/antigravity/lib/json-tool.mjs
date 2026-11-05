// json-tool.mjs: the one place the bash tests read or build JSON, so no test needs jq
// or python. ESM, node >= 18, built-ins only.
//
//   node tests/antigravity/lib/json-tool.mjs <command> [args...]
//
// `commands` maps a command name to (argv: string[]) => number, the exit code. An
// unknown command prints `json-tool: unknown command <name>` to stderr and exits 2.
// Later tasks add entries to this table.
import fs from 'node:fs';
import os from 'node:os';
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

// get: the value at a dot path (integer segments index arrays), raw if a string; exit 1 if unreadable or absent, 2 on usage.
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

const TRANSCRIPT_USAGE =
    'usage: json-tool.mjs transcript --product 2.0|ide|cli (--id <uuid> | --token <text>) ' +
    '--view tool-calls|skill-reads|subagents [--root <dir>] [--field <key>]';

function transcriptRoots(product, home) {
    const g = (name) => path.join(home, '.gemini', name);
    if (product === '2.0') return [g('antigravity')];
    if (product === 'ide') return [g('antigravity-ide')];
    return [g('antigravity-cli'), g('antigravity')];
}

const transcriptFile = (root, id) => path.join(root, 'brain', id, '.system_generated', 'logs', 'transcript.jsonl');

// firstUserContent: the content of a transcript's first USER_EXPLICIT record, read chunk by chunk.
function firstUserContent(file) {
    let fd;
    try {
        fd = fs.openSync(file, 'r');
    } catch {
        return undefined;
    }
    try {
        const buf = Buffer.alloc(65536);
        let carry = '';
        for (;;) {
            const n = fs.readSync(fd, buf, 0, buf.length, null);
            if (n === 0) break;
            const parts = (carry + buf.toString('utf8', 0, n)).split('\n');
            carry = parts.pop();
            for (const line of parts) {
                const rec = parseRecord(line);
                if (rec && rec.source === 'USER_EXPLICIT') return String(rec.content);
            }
        }
        const rec = parseRecord(carry);
        if (rec && rec.source === 'USER_EXPLICIT') return String(rec.content);
    } finally {
        fs.closeSync(fd);
    }
    return undefined;
}

function parseRecord(line) {
    const t = line.trim();
    if (t === '' || t[0] !== '{') return undefined;
    try {
        return JSON.parse(t);
    } catch {
        return undefined;
    }
}

// decodeArgs: every value of a tool call's args is a JSON-encoded string; kept as is when it does not parse.
function decodeArgs(args) {
    let obj = args;
    if (typeof obj === 'string') {
        try {
            obj = JSON.parse(obj);
        } catch {
            return {};
        }
    }
    if (obj === null || typeof obj !== 'object' || Array.isArray(obj)) return {};
    const out = {};
    for (const k of Object.keys(obj)) {
        const v = obj[k];
        if (typeof v === 'string') {
            try {
                out[k] = JSON.parse(v);
            } catch {
                out[k] = v;
            }
        } else {
            out[k] = v;
        }
    }
    return out;
}

function findConversationIds(value, out) {
    if (Array.isArray(value)) value.forEach((v) => findConversationIds(v, out));
    else if (value !== null && typeof value === 'object') {
        for (const k of Object.keys(value)) {
            if (k === 'conversationId' && typeof value[k] === 'string') out.push(value[k]);
            else findConversationIds(value[k], out);
        }
    }
}

// transcript: views over one conversation's transcript.jsonl (see tests/antigravity/README.md).
function transcript(argv) {
    const opt = {};
    for (let i = 0; i < argv.length; i++) {
        const flag = argv[i];
        if (!['--product', '--id', '--token', '--view', '--root', '--field'].includes(flag)) {
            return usage(TRANSCRIPT_USAGE, `unknown flag ${flag}`);
        }
        if (i + 1 >= argv.length) return usage(TRANSCRIPT_USAGE, `${flag} needs a value`);
        opt[flag.slice(2)] = argv[++i];
    }
    if (!['2.0', 'ide', 'cli'].includes(opt.product)) return usage(TRANSCRIPT_USAGE, 'transcript needs --product 2.0|ide|cli');
    if ((opt.id === undefined) === (opt.token === undefined)) return usage(TRANSCRIPT_USAGE, 'transcript needs one of --id, --token');
    if (!['tool-calls', 'skill-reads', 'subagents'].includes(opt.view)) return usage(TRANSCRIPT_USAGE, 'transcript needs --view tool-calls|skill-reads|subagents');
    const fail = (message, code = 1) => {
        process.stderr.write(`json-tool: transcript: ${message}\n`);
        return code;
    };

    const home = process.env.SP_TRANSCRIPT_HOME || os.homedir();
    const roots = transcriptRoots(opt.product, home);
    const label = opt.id !== undefined ? opt.id : opt.token;
    const missing = () => fail(`no transcript for ${label}`);

    let file;
    if (opt.id !== undefined) {
        file = roots.map((r) => transcriptFile(r, opt.id)).find((f) => fs.existsSync(f));
    } else {
        const ids = new Set();
        for (const r of roots) {
            let dirs = [];
            try {
                dirs = fs.readdirSync(path.join(r, 'brain'));
            } catch { /* no brain folder in this root */ }
            for (const d of dirs) {
                const f = transcriptFile(r, d);
                if (ids.has(d) || !fs.existsSync(f)) continue;
                const content = firstUserContent(f);
                if (content !== undefined && content.includes(opt.token)) {
                    ids.add(d);
                    if (file === undefined) file = f;
                }
            }
        }
        if (ids.size > 1) return fail(`token matches ${ids.size} conversations`);
    }
    if (file === undefined) return missing();

    const records = fs.readFileSync(file, 'utf8').split('\n').map(parseRecord).filter(Boolean);
    if (!records.some((r) => Array.isArray(r.tool_calls))) return fail('transcript schema not recognised');

    const norm = (p) => p.replace(/\\/g, '/');
    const win = process.platform === 'win32';
    const key = (p) => (win ? p.toLowerCase() : p);
    const under = (p, dir) => key(p) === key(dir) || key(p).startsWith(`${key(dir)}/`);
    const rootDir = opt.root === undefined ? undefined : norm(path.resolve(opt.root));
    const homeDir = norm(path.resolve(home));
    const fmt = (p) => {
        if (typeof p !== 'string') return null;
        const n = norm(p);
        if (rootDir !== undefined && under(n, rootDir)) return `.${n.slice(rootDir.length)}`;
        if (under(n, homeDir)) return `~${n.slice(homeDir.length)}`;
        return n;
    };

    const calls = [];
    for (const r of records) {
        if (!Array.isArray(r.tool_calls)) continue;
        for (const c of r.tool_calls) {
            if (c && typeof c.name === 'string') calls.push({ name: c.name, args: decodeArgs(c.args) });
        }
    }

    const items = [];
    if (opt.view === 'tool-calls') {
        for (const c of calls) {
            const p = c.args.AbsolutePath ?? c.args.TargetFile ?? c.args.Cwd;
            items.push({ shown: { name: c.name, path: fmt(p) }, args: c.args });
        }
    } else if (opt.view === 'skill-reads') {
        for (const c of calls) {
            const p = c.args.AbsolutePath;
            if (c.name !== 'view_file' || typeof p !== 'string' || !/\/SKILL\.md$/.test(norm(p))) continue;
            const shown = { skill: norm(p).split('/').slice(-2)[0], path: fmt(p), IsSkillFile: c.args.IsSkillFile };
            items.push({ shown, args: shown });
        }
    } else {
        for (const c of calls) {
            if (c.name !== 'invoke_subagent') continue;
            let list = c.args.Subagents;
            if (typeof list === 'string') {
                try {
                    list = JSON.parse(list);
                } catch {
                    list = [];
                }
            }
            for (const s of Array.isArray(list) ? list : []) {
                const shown = { TypeName: s.TypeName, Workspace: s.Workspace, Model: s.Model };
                items.push({ shown, args: shown });
            }
        }
        for (const r of records) {
            if (typeof r.type !== 'string' || !r.type.includes('INVOKE_SUBAGENT')) continue;
            let content = r.content;
            if (typeof content === 'string') {
                try {
                    content = JSON.parse(content);
                } catch {
                    content = {};
                }
            }
            const ids = [];
            findConversationIds(content, ids);
            for (const child of ids) items.push({ shown: { child }, args: { child } });
        }
    }

    for (const item of items) {
        if (opt.field === undefined) {
            process.stdout.write(`${JSON.stringify(item.shown)}\n`);
        } else if (item.args[opt.field] !== undefined) {
            process.stdout.write(`${printField(item.args[opt.field])}\n`);
        }
    }
    return 0;
}

export const commands = {
    transcript,
    payload,
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
