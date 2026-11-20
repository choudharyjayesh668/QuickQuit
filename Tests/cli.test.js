'use strict';

// Unit tests for the quickquit command and the npm postinstall step.
// Run with: npm run test:cli
// Every system call is replaced by a fake, so these tests never build,
// install, launch, or remove anything, and they run on any operating system.

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

const { main, postinstall, VERSION } = require('../lib/quickquit.js');
const pkg = require('../package.json');

const ROOT = path.join(__dirname, '..');
const HOME = '/Users/tester';
const AGENT = `${HOME}/Library/LaunchAgents/local.quickquit.QuickQuit.plist`;

/** Builds fake dependencies that record what the code tried to do. */
function fakeDeps(overrides = {}) {
    const deps = {
        platform: 'darwin',
        uid: 501,
        env: {},
        homedir: HOME,
        out: [],
        err: [],
        runs: [],
        removed: [],
        existing: [],
        exitCodes: {},
        stdout: {},
        ...overrides,
    };
    deps.log = (message) => deps.out.push(message);
    deps.error = (message) => deps.err.push(message);
    deps.exists = (file) => deps.existing.includes(file);
    deps.makeTempDir = () => '/tmp/quickquit-build-test';
    deps.removeDir = (dir) => deps.removed.push(dir);
    deps.run = (command, args, options = {}) => {
        deps.runs.push({ command, args, options });
        const name = path.basename(args[0] && command === '/bin/bash' ? args[0] : command);
        return { status: deps.exitCodes[name] || 0, stdout: deps.stdout[name] || '' };
    };
    return deps;
}

function scriptsRun(deps) {
    return deps.runs.filter((run) => run.command === '/bin/bash')
        .map((run) => path.relative(ROOT, run.args[0]));
}

test('install runs scripts/install.sh with a temporary build folder and cleans it up', () => {
    const deps = fakeDeps({ env: { PATH: '/usr/bin' } });
    assert.equal(main(['install'], deps), 0);
    assert.deepEqual(scriptsRun(deps), [path.join('scripts', 'install.sh')]);
    assert.equal(deps.runs[0].options.env.QUICKQUIT_BUILD_DIR, '/tmp/quickquit-build-test');
    assert.equal(deps.runs[0].options.env.PATH, '/usr/bin');
    assert.deepEqual(deps.removed, ['/tmp/quickquit-build-test']);
    assert.match(deps.out.join('\n'), /quickquit uninstall/);
});

test('install reports failure, keeps the script exit code, and still cleans up', () => {
    const deps = fakeDeps({ exitCodes: { 'install.sh': 3 } });
    assert.equal(main(['install'], deps), 3);
    assert.match(deps.err.join('\n'), /was not set up/);
    assert.deepEqual(deps.removed, ['/tmp/quickquit-build-test']);
});

test('install refuses to run on an unsupported operating system', () => {
    for (const platform of ['linux', 'win32']) {
        const deps = fakeDeps({ platform });
        assert.equal(main(['install'], deps), 1);
        assert.match(deps.err.join('\n'), /only works on macOS/);
        assert.match(deps.err.join('\n'), new RegExp(platform));
        assert.equal(deps.runs.length, 0);
    }
});

test('install, uninstall, and status refuse to run as root', () => {
    for (const command of ['install', 'uninstall', 'status']) {
        const deps = fakeDeps({ uid: 0 });
        assert.equal(main([command], deps), 1);
        assert.match(deps.err.join('\n'), /root or with sudo/);
        assert.equal(deps.runs.length, 0);
    }
});

test('uninstall runs scripts/uninstall.sh and explains how to remove the command', () => {
    const deps = fakeDeps();
    assert.equal(main(['uninstall'], deps), 0);
    assert.deepEqual(scriptsRun(deps), [path.join('scripts', 'uninstall.sh')]);
    assert.match(deps.out.join('\n'), /npm uninstall -g quickquit/);
});

test('uninstall passes on a failing exit code', () => {
    const deps = fakeDeps({ exitCodes: { 'uninstall.sh': 1 } });
    assert.equal(main(['uninstall'], deps), 1);
});

test('status succeeds when the app is installed, loaded, and running', () => {
    const deps = fakeDeps({
        existing: ['/Applications/QuickQuit.app', AGENT],
        stdout: { plutil: '1.2.3\n' },
    });
    assert.equal(main(['status'], deps), 0);
    const output = deps.out.join('\n');
    assert.match(output, /\/Applications\/QuickQuit\.app \(version 1\.2\.3\)/);
    assert.match(output, /LaunchAgent: {2}loaded/);
    assert.match(output, /Running: {6}yes/);
    const launchctl = deps.runs.find((run) => run.command === '/bin/launchctl');
    assert.deepEqual(launchctl.args, ['print', 'gui/501/local.quickquit.QuickQuit']);
});

test('status finds a copy in the user Applications folder', () => {
    const deps = fakeDeps({ existing: [`${HOME}/Applications/QuickQuit.app`, AGENT] });
    assert.equal(main(['status'], deps), 0);
    assert.match(deps.out.join('\n'), /\/Users\/tester\/Applications\/QuickQuit\.app/);
});

test('status fails and suggests a fix when nothing is installed', () => {
    const deps = fakeDeps({ exitCodes: { launchctl: 113, pgrep: 1 } });
    assert.equal(main(['status'], deps), 1);
    const output = deps.out.join('\n');
    assert.match(output, /App: {10}not installed/);
    assert.match(output, /LaunchAgent: {2}not installed/);
    assert.match(output, /Running: {6}no/);
    assert.match(output, /quickquit install/);
});

test('status fails when the app is installed but not running', () => {
    const deps = fakeDeps({
        existing: ['/Applications/QuickQuit.app', AGENT],
        exitCodes: { launchctl: 113, pgrep: 1 },
    });
    assert.equal(main(['status'], deps), 1);
    assert.match(deps.out.join('\n'), /present but not loaded/);
});

test('help, version, and unknown commands', () => {
    for (const args of [[], ['help'], ['--help'], ['-h']]) {
        const deps = fakeDeps();
        assert.equal(main(args, deps), 0);
        assert.match(deps.out.join('\n'), /quickquit install/);
    }
    const version = fakeDeps();
    assert.equal(main(['--version'], version), 0);
    assert.deepEqual(version.out, [VERSION]);

    const unknown = fakeDeps();
    assert.equal(main(['explode'], unknown), 2);
    assert.match(unknown.err.join('\n'), /Unknown command: explode/);
    assert.equal(unknown.runs.length, 0);
});

test('postinstall sets QuickQuit up for a global install on macOS', () => {
    const deps = fakeDeps({ env: { npm_config_global: 'true' } });
    assert.equal(postinstall(deps), 0);
    assert.deepEqual(scriptsRun(deps), [path.join('scripts', 'install.sh')]);
});

test('postinstall does nothing for a local (non-global) install', () => {
    const deps = fakeDeps({ env: {} });
    assert.equal(postinstall(deps), 0);
    assert.equal(deps.runs.length, 0);
    assert.match(deps.out.join('\n'), /not a global install/);
});

test('postinstall can be switched off with QUICKQUIT_SKIP_POSTINSTALL=1', () => {
    const deps = fakeDeps({ env: { npm_config_global: 'true', QUICKQUIT_SKIP_POSTINSTALL: '1' } });
    assert.equal(postinstall(deps), 0);
    assert.equal(deps.runs.length, 0);
});

test('postinstall fails with a clear message on an unsupported operating system', () => {
    const deps = fakeDeps({ platform: 'linux', env: { npm_config_global: 'true' } });
    assert.equal(postinstall(deps), 1);
    assert.match(deps.err.join('\n'), /only works on macOS/);
    assert.equal(deps.runs.length, 0);
});

test('postinstall skips setup without failing when npm runs as root', () => {
    const deps = fakeDeps({ uid: 0, env: { npm_config_global: 'true' } });
    assert.equal(postinstall(deps), 0);
    assert.equal(deps.runs.length, 0);
    assert.match(deps.out.join('\n'), /as your normal user/);
});

test('postinstall fails the npm install when setup fails', () => {
    const deps = fakeDeps({
        env: { npm_config_global: 'true' },
        exitCodes: { 'install.sh': 1 },
    });
    assert.equal(postinstall(deps), 1);
    assert.match(deps.err.join('\n'), /npm install -g quickquit/);
});

test('package.json is ready to publish and points at files that exist', () => {
    assert.equal(pkg.name, 'quickquit');
    assert.match(pkg.version, /^\d+\.\d+\.\d+$/);
    assert.equal(pkg.private, undefined);
    assert.deepEqual(pkg.os, ['darwin']);
    assert.equal(pkg.license, 'MIT');
    assert.equal(pkg.scripts.postinstall, 'node scripts/postinstall.js');
    assert.ok(fs.existsSync(path.join(ROOT, pkg.bin.quickquit)));
    for (const entry of pkg.files) {
        assert.ok(fs.existsSync(path.join(ROOT, entry)), `${entry} is listed in "files"`);
    }
    for (const needed of ['scripts/install.sh', 'scripts/uninstall.sh', 'scripts/postinstall.js',
        'build.sh', 'Sources/main.swift', 'Sources/QuitPolicy.swift']) {
        assert.ok(fs.existsSync(path.join(ROOT, needed)), `${needed} exists`);
        assert.ok(pkg.files.some((entry) => needed === entry || needed.startsWith(entry)),
            `${needed} is covered by "files"`);
    }
});
