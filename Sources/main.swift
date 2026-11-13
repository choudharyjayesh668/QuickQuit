// QuickQuit — press Control+Shift+Q to ask all regular apps to quit.
import AppKit
import Carbon.HIToolbox

/// Passed by the LaunchAgent (see the installer) so we know launchd started us.
let launchedByAgent = CommandLine.arguments.contains("--launch-agent")

@MainActor
func quitOtherApps() {
    let me = NSRunningApplication.current
    for app in NSWorkspace.shared.runningApplications {
        // Which apps qualify is decided in QuitPolicy.swift.
        guard shouldAskToQuit(activationPolicy: app.activationPolicy,
                              processIdentifier: app.processIdentifier,
                              bundleIdentifier: app.bundleIdentifier,
                              ownProcessIdentifier: me.processIdentifier,
                              ownBundleIdentifier: me.bundleIdentifier)
        else { continue }
        // Graceful quit: same as choosing "Quit" in the app. Apps with
        // unsaved work show their usual save prompt. Never force-quit.
        app.terminate()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerInstalled = false
    private var retryTimer: Timer?
    private var terminateObserver: NSObjectProtocol?

    /// Remembered across relaunches so a failing shortcut alerts only once,
    /// not every time macOS restarts QuickQuit.
    private let alertShownKey = "ShortcutErrorAlertShown"

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()

        // Avoid two copies fighting over the shortcut (e.g. if QuickQuit is also
        // listed in Login Items). A copy started by the LaunchAgent waits and takes
        // over when the other exits; any other extra copy just exits quietly.
        if let other = otherRunningCopy() {
            if launchedByAgent {
                waitForExit(of: other)
            } else {
                other.activate()
                NSApp.terminate(nil)
            }
            return
        }
        setUpShortcut()
    }

    private func otherRunningCopy() -> NSRunningApplication? {
        let me = NSRunningApplication.current
        guard let id = me.bundleIdentifier else { return nil }
        return NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .first { $0.processIdentifier != me.processIdentifier }
    }

    private func waitForExit(of other: NSRunningApplication) {
        let pid = other.processIdentifier
        terminateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            guard app?.processIdentifier == pid else { return }
            MainActor.assumeIsolated {
                guard let self else { return }
                if let obs = self.terminateObserver {
                    NSWorkspace.shared.notificationCenter.removeObserver(obs)
                    self.terminateObserver = nil
                }
                self.setUpShortcut()
            }
        }
        if other.isTerminated { setUpShortcut() } // it exited before we started watching
    }

    /// Registers the shortcut. On failure: alert once (ever, until it works again),
    /// stay running, and quietly retry. Never exits, so launchd never restarts us
    /// because of this and there is no alert/restart loop.
    private func setUpShortcut() {
        guard hotKeyRef == nil else { return }
        if let error = registerHotKey() {
            if !UserDefaults.standard.bool(forKey: alertShownKey) {
                UserDefaults.standard.set(true, forKey: alertShownKey)
                showError(error)
            }
            if retryTimer == nil {
                retryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                    MainActor.assumeIsolated { self.setUpShortcut() }
                }
            }
        } else {
            retryTimer?.invalidate()
            retryTimer = nil
            UserDefaults.standard.removeObject(forKey: alertShownKey)
        }
    }

    private func showError(_ error: String) {
        let alert = NSAlert()
        alert.messageText = "QuickQuit couldn’t set up Control+Shift+Q"
        alert.informativeText = error
            + "\n\nQuickQuit will keep running and try again every 30 seconds. "
            + "Quit the other app that uses this shortcut and it will start working. "
            + "This message won’t be shown again."
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    /// Minimal menu so Command+Q quits QuickQuit when it is the active app.
    private func buildMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit QuickQuit",
                        action: #selector(NSApplication.terminate(_:)),
                        keyEquivalent: "q")
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        let main = NSMenu()
        main.addItem(appItem)
        NSApp.mainMenu = main
    }

    /// Registers the global hotkey. Returns an error message on failure.
    private func registerHotKey() -> String? {
        if !handlerInstalled {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                     eventKind: UInt32(kEventHotKeyPressed))
            let installStatus = InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
                MainActor.assumeIsolated { quitOtherApps() }
                return noErr
            }, 1, &spec, nil, nil)
            guard installStatus == noErr else {
                return "macOS returned error \(installStatus) while preparing the shortcut."
            }
            handlerInstalled = true
        }

        let id = EventHotKeyID(signature: OSType(0x5151_5554), id: 1) // 'QQUT'
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_Q),
                                         UInt32(controlKey | shiftKey),
                                         id, GetApplicationEventTarget(), 0, &hotKeyRef)
        switch status {
        case noErr:
            return nil
        case OSStatus(eventHotKeyExistsErr):
            hotKeyRef = nil
            return "Another app is already using Control+Shift+Q."
        default:
            hotKeyRef = nil
            return "macOS returned error \(status) while registering the shortcut."
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
