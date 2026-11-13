// QuitPolicy — decides which running apps QuickQuit asks to quit.
// Kept free of side effects so it can be unit-tested (see Tests/main.swift).
import AppKit

/// Apps that are never asked to quit (besides QuickQuit itself).
let excludedBundleIDs: Set<String> = [
    "com.apple.finder",     // quitting Finder disrupts the desktop/session
    "com.apple.loginwindow",
    "com.apple.dock",
    "com.apple.systemuiserver",
]

/// Returns true if the described running app should be asked to quit.
/// The `own…` arguments describe the running QuickQuit process itself.
func shouldAskToQuit(
    activationPolicy: NSApplication.ActivationPolicy,
    processIdentifier: pid_t,
    bundleIdentifier: String?,
    ownProcessIdentifier: pid_t,
    ownBundleIdentifier: String?
) -> Bool {
    // Only normal user-facing apps (those that appear in the Dock).
    activationPolicy == .regular
        && processIdentifier != ownProcessIdentifier
        && bundleIdentifier != ownBundleIdentifier // any other QuickQuit copy
        && !excludedBundleIDs.contains(bundleIdentifier ?? "")
}
