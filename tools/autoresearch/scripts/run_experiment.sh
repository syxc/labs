#!/usr/bin/env bash
# run_experiment — execute command, time it, capture output, parse METRIC lines
# Usage: run_experiment.sh <command> [timeout_seconds] [checks_timeout_seconds]
# Outputs JSON to stdout
set -euo pipefail

COMMAND="$1"
TIMEOUT="${2:-600}"
CHECKS_TIMEOUT="${3:-300}"

WORKDIR="${AR_WORKDIR:-.}"

# ---- Run the main experiment ----------------------------------------------

START_NS=$(python3 -c 'import time; print(int(time.time() * 1e9))' 2>/dev/null || echo 0)
TMPLOG=$(mktemp "${TMPDIR:-/tmp}/ar-run-$$-XXXXXX.log")
EXIT_CODE=0
CRASHED=false
TIMED_OUT=false

if timeout "$TIMEOUT" bash -c "cd '$WORKDIR' && $COMMAND" > "$TMPLOG" 2>&1; then
  EXIT_CODE=0
else
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 124 || $EXIT_CODE -eq 137 ]]; then
    TIMED_OUT=true
    EXIT_CODE=124
  fi
fi

END_NS=$(python3 -c 'import time; print(int(time.time() * 1e9))' 2>/dev/null || echo 0)
DURATION_SEC=$(python3 -c "print(round(($END_NS - $START_NS) / 1e9, 3))" 2>/dev/null || echo "0")

# Determine pass/crash
if $TIMED_OUT; then
  PASSED=false
  CRASHED=false
elif [[ $EXIT_CODE -eq 0 ]]; then
  PASSED=true
  CRASHED=false
else
  PASSED=false
  if [[ $EXIT_CODE -gt 128 ]]; then
    CRASHED=true
  else
    CRASHED=false
  fi
fi

# Read output
RAW_OUTPUT=$(cat "$TMPLOG")
TAIL_OUTPUT=$(echo "$RAW_OUTPUT" | tail -40 | head -c 4096)

# Parse METRIC lines — use grep || true to avoid pipefail on no match
METRIC_LINES=$(echo "$RAW_OUTPUT" | { grep "^METRIC " || true; })
if [[ -n "$METRIC_LINES" ]]; then
  PARSED_METRICS=$(echo "$METRIC_LINES" | while IFS= read -r line; do
    name=$(echo "$line" | sed -E 's/^METRIC ([^=]+)=.*/\1/')
    value=$(echo "$line" | sed -E 's/^METRIC [^=]+=(.*)/\1/')
    if [[ "$value" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
      echo "$name:$value"
    fi
  done | jq -Rn '[inputs | split(":") | {(.[0]): (.[1] | tonumber)}] | add // {}')
else
  PARSED_METRICS="{}"
fi

# ---- Checks (if checks.sh exists) -----------------------------------------

CHECKS_PASS=null
CHECKS_TIMED_OUT=false
CHECKS_OUTPUT=""
CHECKS_DURATION=0

CHECKS_FILE="$WORKDIR/autoresearch.checks.sh"
if [[ -f "$CHECKS_FILE" && -x "$CHECKS_FILE" ]]; then
  if $PASSED && ! $TIMED_OUT; then
    CHECKS_LOG=$(mktemp "${TMPDIR:-/tmp}/ar-checks-$$-XXXXXX.log")
    CHECKS_START=$(python3 -c 'import time; print(int(time.time() * 1e9))' 2>/dev/null || echo 0)

    if timeout "$CHECKS_TIMEOUT" bash "$CHECKS_FILE" > "$CHECKS_LOG" 2>&1; then
      CHECKS_PASS=true
    else
      CHECK_EXIT=$?
      if [[ $CHECK_EXIT -eq 124 || $CHECK_EXIT -eq 137 ]]; then
        CHECKS_TIMED_OUT=true
      fi
      CHECKS_PASS=false
    fi

    CHECKS_END=$(python3 -c 'import time; print(int(time.time() * 1e9))' 2>/dev/null || echo 0)
    CHECKS_DURATION=$(python3 -c "print(round(($CHECKS_END - $CHECKS_START) / 1e9, 3))" 2>/dev/null || echo "0")
    CHECKS_OUTPUT=$(tail -80 "$CHECKS_LOG" 2>/dev/null || echo "")
    rm -f "$CHECKS_LOG"
  fi
fi

# ---- Cleanup + Output -----------------------------------------------------

rm -f "$TMPLOG"

jq -n \
  --arg command "$COMMAND" \
  --argjson exitCode "$EXIT_CODE" \
  --argjson durationSeconds "$DURATION_SEC" \
  --argjson passed "$PASSED" \
  --argjson crashed "$CRASHED" \
  --argjson timedOut "$TIMED_OUT" \
  --arg tailOutput "$TAIL_OUTPUT" \
  --argjson parsedMetrics "$PARSED_METRICS" \
  --argjson checksPass "$CHECKS_PASS" \
  --argjson checksTimedOut "$CHECKS_TIMED_OUT" \
  --arg checksOutput "$CHECKS_OUTPUT" \
  --argjson checksDuration "$CHECKS_DURATION" \
  '{
    command: $command,
    exitCode: $exitCode,
    durationSeconds: $durationSeconds,
    passed: $passed,
    crashed: $crashed,
    timedOut: $timedOut,
    tailOutput: $tailOutput,
    parsedMetrics: $parsedMetrics,
    checksPass: $checksPass,
    checksTimedOut: $checksTimedOut,
    checksOutput: $checksOutput,
    checksDuration: $checksDuration
  }'
