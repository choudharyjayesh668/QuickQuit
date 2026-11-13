// Unit tests for the quit policy. Run with ./test.sh.
// Plain Swift with no test framework, so it works with Apple Command Line Tools
// alone (XCTest needs full Xcode). These tests never quit any real app.
import AppKit

let ownPID: pid_t = 100
let ownBundleID = "local.quickquit.QuickQuit"
var failures = 0

@MainActor
func expect(_ actual: Bool, _ expected: Bool, _ name: String, line: UInt = #line) {
    if actual == expected {
        print("ok    \(name)")
    } else {
        failures += 1
        print("FAIL  \(name) (Tests/main.swift:\(line)): expected \(expected), got \(actual)")
    }
}

/// Describes another running app as seen by an installed QuickQuit.
func asks(_ policy: NSApplication.ActivationPolicy, pid: pid_t = 200, bundleID: String?) -> Bool {
    shouldAskToQuit(activationPolicy: policy,
                    processIdentifier: pid,
                    bundleIdentifier: bundleID,
                    ownProcessIdentifier: ownPID,
                    ownBundleIdentifier: ownBundleID)
}

expect(asks(.regular, bundleID: "com.apple.Safari"), true,
       "regular Dock app is asked to quit")
expect(asks(.regular, bundleID: nil), true,
       "regular app without a bundle identifier is asked to quit")
expect(asks(.accessory, bundleID: "com.example.menubar"), false,
       "menu bar (accessory) app is left alone")
expect(asks(.prohibited, bundleID: "com.example.helper"), false,
       "background-only app is left alone")
expect(asks(.regular, pid: ownPID, bundleID: ownBundleID), false,
       "QuickQuit never asks itself to quit")
expect(asks(.regular, pid: ownPID, bundleID: "com.example.other"), false,
       "own process is skipped even if the bundle identifier differs")
expect(asks(.regular, pid: 300, bundleID: ownBundleID), false,
       "another running copy of QuickQuit is left alone")

for bundleID in ["com.apple.finder", "com.apple.loginwindow", "com.apple.dock",
                 "com.apple.systemuiserver"] {
    expect(excludedBundleIDs.contains(bundleID), true, "\(bundleID) is on the exclusion list")
    expect(asks(.regular, bundleID: bundleID), false, "\(bundleID) is never asked to quit")
}

// When QuickQuit runs as a bare executable it has no bundle identifier. Apps
// that also have none are then indistinguishable from another copy and skipped.
expect(shouldAskToQuit(activationPolicy: .regular, processIdentifier: 200,
                       bundleIdentifier: nil, ownProcessIdentifier: ownPID,
                       ownBundleIdentifier: nil), false,
       "unbundled QuickQuit skips apps that have no bundle identifier")
expect(shouldAskToQuit(activationPolicy: .regular, processIdentifier: 200,
                       bundleIdentifier: "com.apple.Safari", ownProcessIdentifier: ownPID,
                       ownBundleIdentifier: nil), true,
       "unbundled QuickQuit still asks regular bundled apps to quit")

if failures > 0 {
    print("\n\(failures) test(s) failed")
    exit(1)
}
print("\nAll tests passed")
