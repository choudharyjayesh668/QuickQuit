'use strict';

// npm runs this after installing the package (see "postinstall" in package.json).
// For a global install on macOS it builds, installs, and starts QuickQuit.
// For any other kind of install it does nothing.
process.exitCode = require('../lib/quickquit.js').postinstall();
