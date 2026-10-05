// PreToolUse purity gate for contributors to this repository (ESM, node >= 18; node:fs,
// node:path and node:url only). It runs the same law as the release gate,
// `bash tests/antigravity/test-skill-tool-purity.sh`, at edit time: the law is the data
// file tests/antigravity/purity-patterns.txt, read from beside this script.
//
// Policy: deny a file-tool write that puts banned vocabulary into one of this
// repository's guarded folders; allow only a write inside a workspacePaths entry or the
// artifactDirectoryPath, where the engine already allows; otherwise, errors included, ask.
//
// Why never `allow` anywhere else: `allow` is an approval ("Automatically allows the
// tool execution"), so returning it would skip the permission prompt for writes the
// engine would have asked about. `ask` is a well-formed decision that defers to the user
// and respects "Always Allow".
//
// Which repository: resolved from this script's own location (import.meta.url) and its
// git common directory, never from the payload. A directory is this repository when its
// path matches the script's root or its `.git` shares the script's common directory,
// which covers every checkout and linked worktree and never a foreign repository.
// workspacePaths is a membership test only: no member, no scan; absent, the script's own
// root alone; it never widens the scope. A relative TargetFile is joined to a single
// workspacePaths entry, else the hook asks; there is no cwd fallback.
//
// Contract (https://antigravity.google/docs/hooks, re-captured 2026-09-29; the 2.0 app,
// the CLI and the IDE share it):
//   stdin  (PreToolUse): {"toolCall": {"name": <str>, "args": {...}}, "stepIdx": <int>,
//     "conversationId", "workspacePaths": [<abs dir>, ...], "transcriptPath",
//     "artifactDirectoryPath", "modelName"}
//   stdout (PreToolUse): {"decision": "allow|deny|ask|force_ask|deny_unless_prior_grant",
//     "reason": <str, optional>}. This hook prints exactly one line: allow, deny or ask.
//   File-tool arguments: write_to_file -> TargetFile, CodeContent; replace_file_content ->
//     TargetFile, ReplacementContent; multi_replace_file_content -> TargetFile,
//     ReplacementChunks ("array of chunks", with no element fields documented).
//   Chunk keys, maintainer-observed on 2026-09-25 in 175 transcripts from the 2.0 app:
//     TargetContent, ReplacementContent, StartLine, EndLine, AllowMultiple on all 81
//     decodable chunks. Transcripts store ReplacementChunks as JSON text; whether the
//     payload carries an array or text is not observed, so both are read, and text that
//     does not parse is scanned raw.
//   Not documented: the hook command's working directory, its shell and its exit-code
//     semantics. The global entry therefore carries an absolute path, and this script
//     prints one well-formed line and exits 0 on every path, errors included.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const FILE_TOOLS = ['write_to_file', 'replace_file_content', 'multi_replace_file_content'];
// A guarded folder is found by the first of these segments whose prefix is this repository.
const ROOT_MARKERS = ['/skills/', '/agents/', '/rules/', '/.github/'];
const GATE = 'bash tests/antigravity/test-skill-tool-purity.sh';
const PATTERNS_REL = 'tests/antigravity/purity-patterns.txt';
const PATTERNS_URL = new URL('../tests/antigravity/purity-patterns.txt', import.meta.url);
const scriptRoot = path.resolve(fileURLToPath(new URL('..', import.meta.url)));
// NTFS and the default macOS volumes ignore case, so their path keys are lowercased.
const FOLD = process.platform === 'win32' || process.platform === 'darwin';
// A relative target is joined to the workspace only when its meaning does not depend on
// state this hook cannot see: not `~...` (a home directory) and not `X:name` (a
// per-drive working directory).
const UNPLACEABLE = /^(~([\\/]|$)|[A-Za-z]:(?![\\/]))/;

let emitted = false;
function emit(decision) {
    if (emitted) return;
    emitted = true;
    process.stdout.write(`${JSON.stringify(decision)}\n`);
}

function errorDecision(err) {
    const message = err && err.message ? err.message : String(err);
    return { decision: 'ask', reason: `purity gate error: ${message}` };
}

process.on('uncaughtException', (err) => emit(errorDecision(err)));
process.stdout.on('error', () => {});

function slashes(p) {
    return p.split('\\').join('/');
}

// key(p): the form two paths are compared in. Resolve, backslashes to `/`; win32 strips a
// leading `X:` (a UNC path keeps its host) and lowercases; darwin lowercases; Linux is exact.
function key(p) {
    let k = slashes(path.resolve(p));
    if (process.platform === 'win32') k = k.replace(/^[A-Za-z]:/, '');
    return FOLD ? k.toLowerCase() : k;
}

// gitCommonDir(dir): the git common directory of the checkout at dir, or null. A `.git`
// directory is its own common directory; a `.git` file reading `gitdir: X` names a linked
// worktree's directory X, whose `commondir` file points at the common one (two levels up
// when that file is absent).
function gitCommonDir(dir) {
    try {
        const dotGit = path.join(dir, '.git');
        const st = fs.statSync(dotGit);
        if (st.isDirectory()) return path.resolve(dotGit);
        if (!st.isFile()) return null;
        const m = /^gitdir:\s*(.+?)\s*$/m.exec(fs.readFileSync(dotGit, 'utf8'));
        if (!m) return null;
        const gitDir = path.resolve(dir, m[1]);
        try {
            const common = fs.readFileSync(path.join(gitDir, 'commondir'), 'utf8').trim();
            if (common) return path.resolve(gitDir, common);
        } catch {
            // no commondir file: fall through to the two-levels-up rule
        }
        return path.resolve(gitDir, '..', '..');
    } catch {
        return null;
    }
}

let anchor;
function getAnchor() {
    if (!anchor) {
        const common = gitCommonDir(scriptRoot);
        anchor = { root: key(scriptRoot), common: common === null ? null : key(common) };
    }
    return anchor;
}

// belongsToThisRepo(dir): is dir a checkout or worktree of the repository this script is in?
function belongsToThisRepo(dir) {
    const a = getAnchor();
    if (key(dir) === a.root) return true;
    if (a.common === null) return false;
    const common = gitCommonDir(dir);
    return common !== null && key(common) === a.common;
}

// loadGroups(): the purity law, one entry per row of purity-patterns.txt.
function loadGroups() {
    const text = fs.readFileSync(PATTERNS_URL, 'utf8');
    const groups = [];
    let row = 0;
    for (const raw of text.split('\n')) {
        const line = raw.replace(/\r/g, '');
        if (line === '' || line.startsWith('#')) continue;
        row += 1;
        const f = line.split('\t');
        if (f.length !== 5 || f[0] === '' || f[1] === '' || f[2] === '') {
            throw new Error(`malformed row ${row} in ${PATTERNS_REL}`);
        }
        groups.push({
            group: f[0],
            paths: f[1].split(',').map((s) => s.trim()).filter(Boolean),
            re: new RegExp(f[2], 'm'),
        });
    }
    if (groups.length === 0) throw new Error(`no rows in ${PATTERNS_REL}`);
    return groups;
}

function appliesTo(group, relKey) {
    return group.paths.some((p) => {
        const q = FOLD ? p.toLowerCase() : p;
        return relKey === q || relKey.startsWith(`${q}/`);
    });
}

function isUnder(abs, base) {
    const a = key(abs);
    const b = key(base);
    return a === b || a.startsWith(b.endsWith('/') ? b : `${b}/`);
}

// workspacePaths: null when absent, else its string entries.
function workspaceEntries(value) {
    if (value === undefined || value === null) return null;
    if (!Array.isArray(value)) throw new Error('workspacePaths is not an array');
    return value.filter((w) => typeof w === 'string' && w !== '');
}

// The text blobs a write carries, besides its path.
function contents(args) {
    const out = [];
    if (typeof args.CodeContent === 'string') out.push(args.CodeContent);
    if (typeof args.ReplacementContent === 'string') out.push(args.ReplacementContent);
    const chunks = args.ReplacementChunks;
    if (chunks !== undefined && chunks !== null) {
        let v = chunks;
        if (typeof v === 'string') {
            try {
                v = JSON.parse(v);
            } catch {
                v = null;
                out.push(chunks);
            }
        }
        if (v !== null) {
            for (const item of Array.isArray(v) ? v : [v]) {
                if (typeof item === 'string') out.push(item);
                else if (item && typeof item === 'object' && typeof item.ReplacementContent === 'string') {
                    out.push(item.ReplacementContent);
                }
            }
        }
    }
    return out;
}

// Positions of marker in norm, found without case on the platforms that fold case.
function markerPositions(norm, marker) {
    const want = FOLD ? marker.toLowerCase() : marker;
    const found = [];
    for (let i = 0; i + want.length <= norm.length; i++) {
        const seg = norm.slice(i, i + want.length);
        if ((FOLD ? seg.toLowerCase() : seg) === want) found.push(i);
    }
    return found;
}

// The first guarded-folder segment of abs whose prefix is this repository: the target
// relative to that root, as written and in key form; or null.
function findRoot(abs) {
    const norm = slashes(abs);
    const at = [];
    for (const marker of ROOT_MARKERS) at.push(...markerPositions(norm, marker));
    at.sort((a, b) => a - b);
    for (const i of at) {
        // The `/` after the prefix keeps `C:` from meaning "the working directory of C:".
        if (belongsToThisRepo(path.resolve(`${norm.slice(0, i)}/`))) {
            const rel = norm.slice(i + 1);
            return { rel, relKey: FOLD ? rel.toLowerCase() : rel };
        }
    }
    return null;
}

function ask(reason) {
    return { decision: 'ask', reason };
}

function decide(payload) {
    const call = payload && typeof payload === 'object' ? payload.toolCall : undefined;
    if (!call || typeof call !== 'object' || typeof call.name !== 'string') {
        throw new Error('the payload has no toolCall.name');
    }
    // 1. Not one of the three file tools.
    if (!FILE_TOOLS.includes(call.name)) {
        return ask(`purity gate: ${call.name} is not a file tool; deferring to you`);
    }
    // 2. The arguments this hook needs.
    const args = call.args;
    if (!args || typeof args !== 'object' || Array.isArray(args)) throw new Error('toolCall.args is missing');
    const target = args.TargetFile;
    if (typeof target !== 'string' || target === '') throw new Error('toolCall.args.TargetFile is missing');
    const workspaces = workspaceEntries(payload.workspacePaths);
    // 3. Place the target.
    let abs;
    if (path.isAbsolute(target)) {
        abs = path.resolve(target);
    } else if (
        workspaces !== null && workspaces.length === 1 &&
        path.isAbsolute(workspaces[0]) && !UNPLACEABLE.test(target)
    ) {
        abs = path.resolve(workspaces[0], target);
    } else {
        return ask(`purity gate: cannot place relative path ${target}; deferring to you`);
    }
    // 4. Membership: some workspace is this repository (the script's own root alone when
    // workspacePaths is absent).
    const member = workspaces === null ||
        workspaces.some((w) => path.isAbsolute(w) && belongsToThisRepo(path.resolve(w)));
    // 5. A member: scan a write under a guarded folder of this repository.
    if (member) {
        const hit = findRoot(abs);
        if (hit) {
            const text = [hit.rel, ...contents(args)].join('\n');
            for (const g of loadGroups()) {
                if (!appliesTo(g, hit.relKey)) continue;
                const m = g.re.exec(text);
                if (m) {
                    return {
                        decision: 'deny',
                        reason: `Purity gate (${g.group}): '${m[0]}' is banned in ${hit.rel}. ` +
                            `Same law as the release gate, ${GATE} (patterns: ${PATTERNS_REL}).`,
                    };
                }
            }
        }
    }
    // 6. At or under a workspace or the artifact directory: the engine allows it anyway.
    const bases = [...(workspaces || []), payload.artifactDirectoryPath]
        .filter((b) => typeof b === 'string' && b !== '' && path.isAbsolute(b));
    if (bases.some((b) => isUnder(abs, b))) return { decision: 'allow' };
    // 7. Everything else defers to the user.
    return ask(`purity gate: ${target} is outside the workspace; deferring to you`);
}

// The entry CONTRIBUTING has contributors add to ~/.gemini/config/hooks.json.
function globalEntry() {
    return {
        'superpowers-purity-gate': {
            PreToolUse: [
                {
                    matcher: FILE_TOOLS.join('|'),
                    hooks: [
                        {
                            type: 'command',
                            command: `node "${slashes(scriptRoot)}/hooks/purity-check.mjs"`,
                            timeout: 10,
                        },
                    ],
                },
            ],
        },
    };
}

function main() {
    try {
        if (process.argv.includes('--print-global-entry')) {
            process.stdout.write(`${JSON.stringify(globalEntry(), null, 2)}\n`);
            return;
        }
        const raw = fs.readFileSync(0, 'utf8').replace(/^\uFEFF/, '');
        emit(decide(JSON.parse(raw)));
    } catch (err) {
        emit(errorDecision(err));
    }
}

main();
