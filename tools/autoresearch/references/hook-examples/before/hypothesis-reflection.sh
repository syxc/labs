#!/usr/bin/env bash
# before hook: reflect on last run's hypothesis and suggest next direction
# Reads JSON payload from stdin. Outputs steer message to stdout.
set -euo pipefail

PAYLOAD=$(cat)
LAST_RUN=$(echo "$PAYLOAD" | jq -r '.last_run // null')
CWD=$(echo "$PAYLOAD" | jq -r '.cwd // "."')
NEXT_RUN=$(echo "$PAYLOAD" | jq -r '.next_run // 1')

if [[ "$LAST_RUN" == "null" ]]; then
  echo "Starting fresh experiment session. Read the source code deeply before forming hypotheses."
  exit 0
fi

STATUS=$(echo "$LAST_RUN" | jq -r '.status // "unknown"')
DESC=$(echo "$LAST_RUN" | jq -r '.description // ""')
ASI_HYPOTHESIS=$(echo "$LAST_RUN" | jq -r '.asi.hypothesis // ""')
ASI_LEARNED=$(echo "$LAST_RUN" | jq -r '.asi.learned // ""')
ASI_NEXT=$(echo "$LAST_RUN" | jq -r '.asi.next_focus // ""')

echo "## Hypothesis Reflection (Run #$NEXT_RUN)"
echo "Last run status: **$STATUS**"
echo ""

if [[ -n "$ASI_HYPOTHESIS" ]]; then
  echo "Last hypothesis: $ASI_HYPOTHESIS"
fi

if [[ -n "$ASI_LEARNED" ]]; then
  echo "Learned: $ASI_LEARNED"
fi

if [[ -n "$ASI_NEXT" ]]; then
  echo "Next focus: $ASI_NEXT"
fi

# Check for thrashing patterns in recent runs
if [[ -f "$CWD/autoresearch.jsonl" ]]; then
  RECENT=$(tail -20 "$CWD/autoresearch.jsonl" | grep -v '"type":"config"' | grep -v '"type":"hook"' | tail -5)
  DISCARD_COUNT=$(echo "$RECENT" | grep -c '"status":"discard"' || echo 0)
  if [[ $DISCARD_COUNT -ge 4 ]]; then
    echo "⚠️  4+ consecutive discards in recent runs. Consider a fundamentally different approach."
  fi
fi

echo ""
echo "Before making changes, ask yourself: Is this a genuinely new direction or a variation on something already tried?"
