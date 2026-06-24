#!/bin/bash
set -euo pipefail

# ProxyEnv Installer
# Installs the proxy environment auto-detection LaunchAgent.

SCRIPT_SRC="$(cd "$(dirname "$0")" && pwd)/proxy-env.sh"
SCRIPT_DST="$HOME/.local/bin/proxy-env"
PLIST_SRC="$(cd "$(dirname "$0")" && pwd)/com.user.proxy-env.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.user.proxy-env.plist"
LOG_FILE="/tmp/proxy-env.log"

echo "[1/3] Installing script to $SCRIPT_DST …"
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_SRC" "$SCRIPT_DST"
chmod +x "$SCRIPT_DST"

echo "[2/3] Installing LaunchAgent plist …"
mkdir -p "$HOME/Library/LaunchAgents"
sed "s|{{SCRIPT_PATH}}|$SCRIPT_DST|g; s|{{LOG_FILE}}|$LOG_FILE|g" "$PLIST_SRC" > "$PLIST_DST"

echo "[3/3] Loading LaunchAgent (unload first if exists) …"
launchctl bootout "gui/$(id -u)" "$PLIST_DST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"

echo "✓ ProxyEnv installed. Log: $LOG_FILE"
echo "  Check status: launchctl print gui/$(id -u)/com.user.proxy-env"
