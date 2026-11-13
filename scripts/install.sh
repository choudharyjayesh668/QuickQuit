#!/bin/bash
# Builds QuickQuit, installs it in Applications, starts it, and sets macOS to
# start it at login and relaunch it whenever it exits.
#
# Safe to run again: it stops the running copy, replaces the installed app, and
# rewrites the single LaunchAgent. Never needs sudo.
#
# Used by "Install QuickQuit.command" and by the npm package (quickquit install).
# Set QUICKQUIT_BUILD_DIR to build somewhere other than ./build.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "QuickQuit only supports macOS. Nothing was installed." >&2
    exit 1
fi
if [ "$(id -u)" -eq 0 ]; then
    echo "Do not install QuickQuit as root or with sudo." >&2
    echo "QuickQuit runs inside your own login session. Run the installer again as your normal user." >&2
    exit 1
fi

LABEL="local.quickquit.QuickQuit"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"
BUILD_DIR="${QUICKQUIT_BUILD_DIR:-$ROOT/build}"

QUICKQUIT_BUILD_DIR="$BUILD_DIR" /bin/bash "$ROOT/build.sh"

# Install system-wide when possible, otherwise for this user only.
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

# Remove the previous version. Also remove a copy left in the other Applications
# folder by an earlier install, so only one QuickQuit.app exists.
for dir in "/Applications" "$HOME/Applications"; do
    old="$dir/QuickQuit.app"
    [ -e "$old" ] || continue
    if rm -rf "$old" 2>/dev/null; then continue; fi
    if [ "$dir" = "$DEST" ]; then
        echo "Could not replace $old. Check its permissions and try again." >&2
        exit 1
    fi
    echo "Warning: could not remove the old copy at $old. Delete it by hand." >&2
done
cp -R "$BUILD_DIR/QuickQuit.app" "$DEST/"

# LaunchAgent: start at login (RunAtLoad) and relaunch after any exit (KeepAlive).
# ThrottleInterval keeps launchd from restarting it more than once every 10 seconds.
# Writing the file again replaces the previous agent, so there is only ever one.
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

launchctl enable "$DOMAIN/$LABEL" 2>/dev/null || true   # in case it was disabled earlier
# Loads the agent now, which starts QuickQuit.
if ! launchctl bootstrap "$DOMAIN" "$AGENT"; then
    echo >&2
    echo "QuickQuit was copied to $DEST, but macOS could not load its LaunchAgent." >&2
    echo "This step needs a logged-in desktop session; it does not work over SSH." >&2
    echo "Log in at the Mac's screen and run the installer again." >&2
    exit 1
fi

# Give launchd up to 5 seconds to start the app.
for _ in $(seq 1 50); do
    pgrep -x QuickQuit >/dev/null && break
    sleep 0.1
done

echo
if pgrep -x QuickQuit >/dev/null; then
    echo "QuickQuit is installed in $DEST and running (look for it in the Dock)."
else
    echo "QuickQuit is installed in $DEST, but it has not started yet."
    echo "Check System Settings → General → Login Items and allow QuickQuit in the background."
fi
echo "It starts automatically when you log in and reopens itself if it quits."
echo "  Control+Shift+Q  asks your open apps to quit"
echo
echo "If you previously added QuickQuit to System Settings → General → Login Items"
echo "(under \"Open at Login\"), remove it there — it's no longer needed."
