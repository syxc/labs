#!/usr/bin/env bash
# after hook: send macOS notification on new best metric
set -euo pipefail

PAYLOAD=$(cat)
STATUS=$(echo "$PAYLOAD" | jq -r '.run_entry.status // ""')
METRIC=$(echo "$PAYLOAD" | jq -r '.run_entry.metric // 0')
BEST=$(echo "$PAYLOAD" | jq -r '.session.best_metric // "null"')
DIRECTION=$(echo "$PAYLOAD" | jq -r '.session.direction // "lower"')
METRIC_NAME=$(echo "$PAYLOAD" | jq -r '.session.metric_name // "metric"')
GOAL=$(echo "$PAYLOAD" | jq -r '.session.goal // ""')
RUN=$(echo "$PAYLOAD" | jq -r '.run_entry.run // 0')

if [[ "$STATUS" != "keep" ]]; then
  exit 0
fi

IS_NEW_BEST=false
if [[ "$BEST" == "null" ]]; then
  IS_NEW_BEST=true
elif [[ "$DIRECTION" == "lower" && $(echo "$METRIC < $BEST" | bc -l) -eq 1 ]]; then
  IS_NEW_BEST=true
elif [[ "$DIRECTION" == "higher" && $(echo "$METRIC > $BEST" | bc -l) -eq 1 ]]; then
  IS_NEW_BEST=true
fi

if $IS_NEW_BEST; then
  DELTA=""
  if [[ "$BEST" != "null" && "$BEST" != "0" ]]; then
    DELTA=$(python3 -c "print(f'{($METRIC - $BEST) / $BEST * 100:+.1f}%')" 2>/dev/null || echo "")
  fi
  osascript -e "display notification \"Run #$RUN: $METRIC $DELTA\" with title \"Autoresearch: $GOAL\" subtitle \"New Best!\""
fi
