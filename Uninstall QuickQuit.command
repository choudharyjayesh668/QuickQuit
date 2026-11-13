#!/bin/bash
# Double-click this file to stop QuickQuit's automatic start/relaunch and remove it.
set -uo pipefail

LABEL="local.quickquit.QuickQuit"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null   # stops it and the auto-relaunch
rm -f "$AGENT"
killall QuickQuit 2>/dev/null
rm -rf "/Applications/QuickQuit.app" "$HOME/Applications/QuickQuit.app"
defaults delete "$LABEL" 2>/dev/null

echo "QuickQuit has been stopped and removed. It will no longer start at login."
echo "You can close this window."
