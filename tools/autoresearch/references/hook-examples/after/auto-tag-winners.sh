#!/usr/bin/env bash
# after hook: auto-tag git commits for winning experiments
# When a run is "kept" and metric improved over previous best, add a git tag.
set -euo pipefail

PAYLOAD=$(cat)
STATUS=$(echo "$PAYLOAD" | jq -r '.run_entry.status // ""')
CWD=$(echo "$PAYLOAD" | jq -r '.cwd // "."')
RUN=$(echo "$PAYLOAD" | jq -r '.run_entry.run // 0')
METRIC=$(echo "$PAYLOAD" | jq -r '.run_entry.metric // 0')
BEST=$(echo "$PAYLOAD" | jq -r '.session.best_metric // "null"')
DIRECTION=$(echo "$PAYLOAD" | jq -r '.session.direction // "lower"')
GOAL=$(echo "$PAYLOAD" | jq -r '.session.goal // ""' | tr ' ' '-')

if [[ "$STATUS" != "keep" ]]; then
  exit 0
fi

# Check if this is a new personal best
if [[ "$BEST" == "null" || "$BEST" == "$METRIC" ]]; then
  TAG="ar-${GOAL}-best-v${RUN}"
  cd "$CWD" && git tag -a "$TAG" -m "autoresearch best: $METRIC (run #$RUN)" 2>/dev/null || true
  echo "🏆 New best! Tagged as $TAG"
fi
