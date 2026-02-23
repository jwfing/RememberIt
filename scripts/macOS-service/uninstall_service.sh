#!/bin/bash
#
# Uninstall myknowledge launchd service
#

set -e

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/dev.jwfing.myknowledge.plist"

echo "=== Uninstalling myknowledge service ==="

# Stop and unload (also clean up old split services if they exist)
launchctl unload "$PLIST" 2>/dev/null && echo "Unloaded: myknowledge" || echo "Service not loaded"
launchctl unload "$PLIST_DIR/dev.jwfing.myknowledge.api.plist" 2>/dev/null || true
launchctl unload "$PLIST_DIR/dev.jwfing.myknowledge.mcp.plist" 2>/dev/null || true

# Remove plist files
rm -f "$PLIST"
rm -f "$PLIST_DIR/dev.jwfing.myknowledge.api.plist"
rm -f "$PLIST_DIR/dev.jwfing.myknowledge.mcp.plist"

echo ""
echo "Service removed. Log files retained at ~/Library/Logs/myknowledge/"
echo "To also remove logs: rm -rf ~/Library/Logs/myknowledge"