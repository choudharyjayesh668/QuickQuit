#!/usr/bin/env node
'use strict';

process.exitCode = require('../lib/quickquit.js').main(process.argv.slice(2));
