#!/bin/sh
# Restore rtk-shim snapshot to ~/.newmax/rtk-shim/. Existing → .bak.<ts>
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.newmax/rtk-shim"

[ -d "$HERE/snapshot/rtk-shim" ] || { echo "snapshot missing" >&2; exit 1; }

if [ -d "$TARGET" ]; then
  BAK="$TARGET.bak.$(date +%Y%m%d_%H%M%S)"; mv "$TARGET" "$BAK"
  echo "backed up → $BAK"
fi

mkdir -p "$HOME/.newmax"
tar -C "$HERE/snapshot" -cf - rtk-shim | tar -C "$HOME/.newmax" -xf -
chmod +x "$TARGET/_dispatch"
echo "installed → $TARGET"
echo "merge shell-config/{zshenv,zprofile}.sh into dotfiles, then verify:"
echo "  CLAUDE_CONFIG_DIR=\$HOME/.newmax \"$TARGET/ls\" /tmp"
