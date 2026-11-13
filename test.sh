#!/bin/bash
# Compiles and runs the unit tests in Tests/ against the quit policy.
# Needs only Apple Command Line Tools. Does not launch QuickQuit or quit any app.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p build
# shellcheck disable=SC2086  # SWIFTFLAGS is intentionally split into words
swiftc -swift-version 6 ${SWIFTFLAGS:-} Sources/QuitPolicy.swift Tests/main.swift \
    -o build/QuickQuitTests
./build/QuickQuitTests
