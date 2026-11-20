'use strict';

// The quickquit command and the npm postinstall step.
//
// This file only decides what to run and reports the result. The actual
// installing and removing is done by scripts/install.sh and
// scripts/uninstall.sh, the same scripts the double-click installers use.
// Everything that touches the system goes through `deps`, so the tests in
// Tests/cli.test.js can run without installing anything.

const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const ROOT = path.join(__dirname, '..');
const { version: VERSION } = require('../package.json');
const LABEL = 'local.quickquit.QuickQuit';

const USAGE = `QuickQuit ${VERSION}
Press Control+Shift+Q to ask your open Dock apps to quit. Nothing is force-quit.

Usage:
  quickquit install     Build QuickQuit, put it in Applications, start it, and
                        set it to start at login. Safe to run again.
  quickquit uninstall   Stop QuickQuit and remove the app and its LaunchAgent.
  quickquit status      Show whether QuickQuit is installed and running.
  quickquit --version   Print the version of this package.
  quickquit --help      Show this help.
`;

function defaultDeps() {
    return {
        platform: process.platform,
        uid: typeof process.getuid === 'function' ? process.getuid() : -1,
        env: process.env,
        homedir: os.homedir(),
        log: (message) => console.log(message),
        error: (message) => console.error(message),
        exists: (file) => fs.existsSync(file),
        makeTempDir: () => fs.mkdtempSync(path.join(os.tmpdir(), 'quickquit-build-')),
        removeDir: (dir) => fs.rmSync(dir, { recursive: true, force: true }),
        run(command, args, options = {}) {
            const result = spawnSync(command, args, {
                stdio: options.capture ? ['ignore', 'pipe', 'pipe'] : 'inherit',
                env: options.env || process.env,
                encoding: 'utf8',
            });
            return {
                status: result.status === null ? 1 : result.status,
                stdout: result.stdout || '',
            };
        },
    };
}

/** Returns why QuickQuit cannot be set up here, or null if it can. */
function unsupportedReason(deps) {
    if (deps.platform !== 'darwin') {
        return `QuickQuit only works on macOS. This system is "${deps.platform}", so nothing was installed.`;
    }
    if (deps.uid === 0) {
        return 'QuickQuit must not be set up as root or with sudo, because it runs inside your own '
            + 'login session.\nRun this as your normal user instead:  quickquit install';
    }
    return null;
}

function install(deps) {
    const reason = unsupportedReason(deps);
    if (reason) {
        deps.error(reason);
        return 1;
    }
    // Build in a temporary folder: the package folder may not be writable.
    const buildDir = deps.makeTempDir();
    try {
        const result = deps.run('/bin/bash', [path.join(ROOT, 'scripts', 'install.sh')], {
            env: { ...deps.env, QUICKQUIT_BUILD_DIR: buildDir },
        });
        if (result.status !== 0) {
            deps.error('\nQuickQuit was not set up. Fix the problem shown above, then try again.');
            return result.status;
        }
        deps.log('To remove QuickQuit later, run:  quickquit uninstall');
        return 0;
    } finally {
        deps.removeDir(buildDir);
    }
}

function uninstall(deps) {
    const reason = unsupportedReason(deps);
    if (reason) {
        deps.error(reason);
        return 1;
    }
    const result = deps.run('/bin/bash', [path.join(ROOT, 'scripts', 'uninstall.sh')]);
    if (result.status !== 0) {
        return result.status;
    }
    deps.log('The quickquit command is still installed. To remove it too, run:  '
        + 'npm uninstall -g quickquit');
    return 0;
}

/** Prints what is installed. Returns 0 only if QuickQuit is installed, loaded, and running. */
function status(deps) {
    const reason = unsupportedReason(deps);
    if (reason) {
        deps.error(reason);
        return 1;
    }
    const apps = ['/Applications', path.join(deps.homedir, 'Applications')]
        .map((dir) => path.join(dir, 'QuickQuit.app'))
        .filter((app) => deps.exists(app));
    const agentFile = path.join(deps.homedir, 'Library', 'LaunchAgents', `${LABEL}.plist`);
    const agentLoaded = deps.run('/bin/launchctl', ['print', `gui/${deps.uid}/${LABEL}`],
        { capture: true }).status === 0;
    const running = deps.run('/usr/bin/pgrep', ['-x', 'QuickQuit'], { capture: true }).status === 0;

    if (apps.length === 0) {
        deps.log('App:          not installed');
    }
    for (const app of apps) {
        const plist = path.join(app, 'Contents', 'Info.plist');
        const version = deps.run('/usr/bin/plutil',
            ['-extract', 'CFBundleShortVersionString', 'raw', '-o', '-', plist],
            { capture: true }).stdout.trim() || 'unknown';
        deps.log(`App:          ${app} (version ${version})`);
    }
    if (agentLoaded) {
        deps.log('LaunchAgent:  loaded (starts at login, reopens after it exits)');
    } else if (deps.exists(agentFile)) {
        deps.log('LaunchAgent:  present but not loaded');
    } else {
        deps.log('LaunchAgent:  not installed');
    }
    deps.log(`Running:      ${running ? 'yes' : 'no'}`);

    const ok = apps.length > 0 && agentLoaded && running;
    if (!ok) {
        deps.log('\nTo set up or repair QuickQuit, run:  quickquit install');
    }
    return ok ? 0 : 1;
}

/** The quickquit command. Returns the process exit code. */
function main(argv, deps = defaultDeps()) {
    const command = argv[0];
    switch (command) {
        case 'install':
            return install(deps);
        case 'uninstall':
            return uninstall(deps);
        case 'status':
            return status(deps);
        case '--version':
        case '-v':
            deps.log(VERSION);
            return 0;
        case undefined:
        case 'help':
        case '--help':
        case '-h':
            deps.log(USAGE);
            return 0;
        default:
            deps.error(`Unknown command: ${command}\n\n${USAGE}`);
            return 2;
    }
}

/**
 * Runs after npm installs the package. Sets QuickQuit up only for a global
 * install (npm install -g). Returns the process exit code; a non-zero code makes
 * npm report the install as failed and show the messages printed here.
 */
function postinstall(deps = defaultDeps()) {
    if (deps.env.QUICKQUIT_SKIP_POSTINSTALL === '1') {
        deps.log('QuickQuit: automatic setup skipped because QUICKQUIT_SKIP_POSTINSTALL=1. '
            + 'To set it up, run:  quickquit install');
        return 0;
    }
    if (deps.env.npm_config_global !== 'true') {
        deps.log('QuickQuit: this is not a global install (npm install -g), so the app was not '
            + 'set up. To set it up, run:  npx quickquit install');
        return 0;
    }
    if (deps.platform !== 'darwin') {
        deps.error(unsupportedReason(deps));
        return 1;
    }
    if (deps.uid === 0) {
        // npm was run with sudo. Do not fail: the command is still useful.
        deps.log('QuickQuit: installed with sudo, so the app was not set up automatically. '
            + 'To set it up, run this as your normal user:  quickquit install');
        return 0;
    }
    const code = install(deps);
    if (code !== 0) {
        deps.error('After fixing it, run:  npm install -g quickquit');
    }
    return code;
}

module.exports = { main, postinstall, unsupportedReason, VERSION, LABEL };
