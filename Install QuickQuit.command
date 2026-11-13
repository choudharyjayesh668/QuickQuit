#!/bin/bash
# Double-click this file to build QuickQuit, install it in Applications, and set
# macOS to start it at login and relaunch it whenever it exits.
set -euo pipefail
cd "$(dirname "$0")"

LABEL="local.quickquit.QuickQuit"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

./build.sh

DEST="/Applications"
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"

# Stop an older copy: unload the agent first so launchd doesn't relaunch it.
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
# bootout can return before launchd has finished unloading the agent. Wait for
# it (up to 5 seconds) so the bootstrap below does not fail on a reinstall.
for _ in $(seq 1 50); do
    launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1 || break
    sleep 0.1
done
if killall QuickQuit 2>/dev/null; then sleep 1; fi

rm -rf "$DEST/QuickQuit.app"
cp -R build/QuickQuit.app "$DEST/"

# LaunchAgent: start at login (RunAtLoad) and relaunch after any exit (KeepAlive).
# ThrottleInterval keeps launchd from restarting it more than once every 10 seconds.
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DEST/QuickQuit.app/Contents/MacOS/QuickQuit</string>
        <string>--launch-agent</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>ThrottleInterval</key><integer>10</integer>
    <key>LimitLoadToSessionType</key><string>Aqua</string>
    <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
PLIST

launchctl enable "$DOMAIN/$LABEL"          # in case it was disabled earlier
launchctl bootstrap "$DOMAIN" "$AGENT"     # loads it now and starts QuickQuit

echo
echo "QuickQuit is installed in $DEST and running (look for it in the Dock)."
echo "It starts automatically when you log in and reopens itself if it quits."
echo "  Control+Shift+Q  asks your open apps to quit"
echo
echo "If you previously added QuickQuit to System Settings → General → Login Items"
echo "(under \"Open at Login\"), remove it there — it's no longer needed."
echo "To turn off the automatic relaunch, double-click 'Uninstall QuickQuit.command'."
echo
echo "You can close this window."
