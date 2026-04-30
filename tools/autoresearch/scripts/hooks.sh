#!/usr/bin/env bash
# hooks.sh — fire before/after iteration hooks for autoresearch
# Usage: hooks.sh <stage:before|after> <workdir> <payload_json>
# Outputs steer message to stdout (empty = silent)
set -euo pipefail

STAGE="$1"
WORKDIR="$2"
PAYLOAD="$3"

HOOK_FILE="$WORKDIR/autoresearch.hooks/$STAGE.sh"
HOOK_DIR="$WORKDIR/autoresearch.hooks"

# No hook file, no problem
if [[ ! -f "$HOOK_FILE" ]]; then
  exit 0
fi

if [[ ! -x "$HOOK_FILE" ]]; then
  exit 0
fi

# Run hook with timeout (30s), capture output
HOOK_LOG=$(mktemp /tmp/autoresearch-hook-$$-XXXXXX.log 2>/dev/null || mktemp /tmp/ar-hook-$$-${RANDOM}.log)
HOOK_INPUT=$(mktemp /tmp/autoresearch-hook-input-$$-XXXXXX.json 2>/dev/null || mktemp /tmp/ar-hook-in-$$-${RANDOM}.json)
echo "$PAYLOAD" > "$HOOK_INPUT"
EXIT_CODE=0
TIMED_OUT=false

if timeout 30 bash -c "cd '$WORKDIR' && '$HOOK_FILE' < '$HOOK_INPUT'" > "$HOOK_LOG" 2>&1; then
  EXIT_CODE=0
else
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 124 || $EXIT_CODE -eq 137 ]]; then
    TIMED_OUT=true
  fi
fi

# Read stdout (cap at 8KB)
STDOUT_SIZE=$(wc -c < "$HOOK_LOG" | tr -d ' ')
STDERR_SIZE=0

# Truncate to 8KB
if [[ $STDOUT_SIZE -gt 8192 ]]; then
  truncate -s 8192 "$HOOK_LOG"
  STDOUT_SIZE=8192
fi

# Log hook entry if jsonl helpers available
JSONL="$WORKDIR/autoresearch.jsonl"
if [[ -f "$JSONL" ]]; then
  jq -n \
    --arg event "$STAGE" \
    --argjson exit_code "$EXIT_CODE" \
    --argjson timed_out "$TIMED_OUT" \
    --argjson stdout_size "$STDOUT_SIZE" \
    --argjson stderr_size 0 \
    '{type: "hook", event: $event, exit_code: $exit_code, timed_out: $timed_out, stdout_size: $stdout_size, stderr_size: $stderr_size, timestamp: (now | floor)}' >> "$JSONL"
fi

# Output steer message
if $TIMED_OUT; then
  echo "[autoresearch hooks] WARNING: $STAGE hook timed out (30s)"
elif [[ $EXIT_CODE -ne 0 ]]; then
  echo "[autoresearch hooks] ERROR: $STAGE hook exited with code $EXIT_CODE"
else
  cat "$HOOK_LOG"
fi

rm -f "$HOOK_LOG" "$HOOK_INPUT"
