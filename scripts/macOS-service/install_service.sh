#!/bin/bash
#
# Install myknowledge as a macOS launchd service
#
# Usage:
#   ./scripts/install_service.sh
#
# After installation:
#   Start:  launchctl load ~/Library/LaunchAgents/dev.jwfing.myknowledge.plist
#   Stop:   launchctl unload ~/Library/LaunchAgents/dev.jwfing.myknowledge.plist
#   Logs:   tail -f ~/Library/Logs/myknowledge/server.log
#   Status: launchctl list | grep myknowledge
#

set -e

# ── Locate project path ──
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PYTHON_BIN="$(which python3)"

PLIST_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/myknowledge"
ENV_FILE="$PROJECT_DIR/.env"

echo "=== myknowledge Service Installer ==="
echo ""
echo "Project:  $PROJECT_DIR"
echo "Python:   $PYTHON_BIN"
echo ""

# ── Pre-flight checks ──
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo "Run 'cp .env.example .env' and fill in your config first."
    exit 1
fi

# Ensure directories exist
mkdir -p "$PLIST_DIR" "$LOG_DIR"

# ── Read port from .env (for display) ──
API_PORT=$(grep -E '^API_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "6789")
API_PORT="${API_PORT:-6789}"

# ── Generate plist ──
PLIST="$PLIST_DIR/dev.jwfing.myknowledge.plist"
cat > "$PLIST" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dev.jwfing.myknowledge</string>

    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_BIN</string>
        <string>-m</string>
        <string>myknowledge</string>
        <string>serve</string>
    </array>

    <key>WorkingDirectory</key>
    <string>$PROJECT_DIR</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PYTHONPATH</key>
        <string>$PROJECT_DIR/src</string>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>ThrottleInterval</key>
    <integer>5</integer>

    <key>StandardOutPath</key>
    <string>$LOG_DIR/server.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/server.error.log</string>
</dict>
</plist>
PLIST

echo "Created: $PLIST"

# ── Load service ──
echo ""
echo "Loading service..."

# Unload old services if they exist
launchctl unload "$PLIST_DIR/dev.jwfing.myknowledge.api.plist" 2>/dev/null || true
launchctl unload "$PLIST_DIR/dev.jwfing.myknowledge.mcp.plist" 2>/dev/null || true
launchctl unload "$PLIST" 2>/dev/null || true

# Clean up old plist files
rm -f "$PLIST_DIR/dev.jwfing.myknowledge.api.plist"
rm -f "$PLIST_DIR/dev.jwfing.myknowledge.mcp.plist"

launchctl load "$PLIST"

echo ""
echo "=== Installation complete ==="
echo ""
echo "Server: http://localhost:$API_PORT  (dev.jwfing.myknowledge)"
echo "  API: http://localhost:$API_PORT/api/v1/*"
echo "  MCP: http://localhost:$API_PORT/mcp"
echo ""
echo "Commands:"
echo "  Status    launchctl list | grep myknowledge"
echo "  Stop      launchctl unload ~/Library/LaunchAgents/dev.jwfing.myknowledge.plist"
echo "  Restart   launchctl kickstart -k gui/\$(id -u)/dev.jwfing.myknowledge"
echo "  Logs      tail -f ~/Library/Logs/myknowledge/server.log"
echo "  Uninstall ./scripts/uninstall_service.sh"