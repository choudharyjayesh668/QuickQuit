#!/bin/bash
# Double-click this file to build QuickQuit, install it in Applications, and set
# macOS to start it at login and relaunch it whenever it exits.
# The work is done by scripts/install.sh.
cd "$(dirname "$0")" || exit 1

/bin/bash scripts/install.sh
status=$?

if [ "$status" -eq 0 ]; then
    echo "To turn off the automatic relaunch, double-click 'Uninstall QuickQuit.command'."
    echo
fi
echo "You can close this window."
exit "$status"
