#!/bin/bash
# Double-click this file to stop QuickQuit's automatic start/relaunch and remove it.
# The work is done by scripts/uninstall.sh.
cd "$(dirname "$0")" || exit 1

/bin/bash scripts/uninstall.sh
status=$?

echo "You can close this window."
exit "$status"
