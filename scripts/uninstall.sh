#!/bin/bash
# Stops QuickQuit's automatic start/relaunch and removes the app.
# Safe to run when QuickQuit is not installed. Never needs sudo.
#
# Used by "Uninstall QuickQuit.command" and by the npm package (quickquit uninstall).
set -uo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
    echo "QuickQuit only supports macOS. There is nothing to remove." >&2
    exit 1
fi
if [ "$(id -u)" -eq 0 ]; then
    echo "Do not uninstall QuickQuit as root or with sudo." >&2
    echo "Run the uninstaller again as the user who installed it." >&2
    exit 1
fi

LABEL="local.quickquit.QuickQuit"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null   # stops it and the auto-relaunch
rm -f "$AGENT"
killall QuickQuit 2>/dev/null
rm -rf "/Applications/QuickQuit.app" "$HOME/Applications/QuickQuit.app"
defaults delete "$LABEL" 2>/dev/null

for leftover in "$AGENT" "/Applications/QuickQuit.app" "$HOME/Applications/QuickQuit.app"; do
    if [ -e "$leftover" ]; then
        echo "Could not remove $leftover. Delete it by hand." >&2
        exit 1
    fi
done

echo "QuickQuit has been stopped and removed. It will no longer start at login."
