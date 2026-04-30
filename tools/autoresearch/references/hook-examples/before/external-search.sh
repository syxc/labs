#!/usr/bin/env bash
# before hook: search for related optimization approaches online
# Uses duckduckgo via lynx or curl. Configure SEARCH_QUERY_TEMPLATE below.
set -euo pipefail

SEARCH_QUERY_TEMPLATE="optimize {goal} performance techniques"

PAYLOAD=$(cat)
GOAL=$(echo "$PAYLOAD" | jq -r '.session.goal // ""')
BEST=$(echo "$PAYLOAD" | jq -r '.session.best_metric // "null"')

if [[ -z "$GOAL" || "$GOAL" == "null" ]]; then
  exit 0
fi

QUERY=$(echo "$SEARCH_QUERY_TEMPLATE" | sed "s/{goal}/$GOAL/g")

# Check if we have web access (optional — exits silently if no tools)
if ! command -v curl &>/dev/null; then
  exit 0
fi

# Only search every 10 runs to avoid noise
NEXT_RUN=$(echo "$PAYLOAD" | jq -r '.next_run // 0')
if [[ $((NEXT_RUN % 10)) -ne 0 ]]; then
  exit 0
fi

echo "## External Research (Run #$NEXT_RUN)"
echo "Searching for: $QUERY"
echo ""
echo "Remember: external advice is contextual — validate against your specific workload."
