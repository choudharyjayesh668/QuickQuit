#!/bin/bash
# Compiles and runs the Swift unit tests in Tests/ against the quit policy.
# Needs only Apple Command Line Tools. Does not launch QuickQuit or quit any app.
# The test binary goes to ./build, or to QUICKQUIT_BUILD_DIR if that is set.
set -euo pipefail
cd "$(dirname "$0")"

BUILD_DIR="${QUICKQUIT_BUILD_DIR:-build}"
mkdir -p "$BUILD_DIR"
# shellcheck disable=SC2086  # SWIFTFLAGS is intentionally split into words
swiftc -swift-version 6 ${SWIFTFLAGS:-} Sources/QuitPolicy.swift Tests/main.swift \
    -o "$BUILD_DIR/QuickQuitTests"
"$BUILD_DIR/QuickQuitTests"
