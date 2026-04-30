#!/usr/bin/env bash
# after hook: append structured learnings to a journal file
set -euo pipefail

PAYLOAD=$(cat)
CWD=$(echo "$PAYLOAD" | jq -r '.cwd // "."')
RUN=$(echo "$PAYLOAD" | jq -r '.run_entry.run // 0')
STATUS=$(echo "$PAYLOAD" | jq -r '.run_entry.status // ""')
DESC=$(echo "$PAYLOAD" | jq -r '.run_entry.description // ""')
METRIC=$(echo "$PAYLOAD" | jq -r '.run_entry.metric // 0')
ASI_LEARNED=$(echo "$PAYLOAD" | jq -r '.run_entry.asi.learned // ""')
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

JOURNAL="$CWD/autoresearch.learnings.md"

if [[ ! -f "$JOURNAL" ]]; then
  echo "# Autoresearch Learnings" > "$JOURNAL"
  echo "" >> "$JOURNAL"
  echo "| Run | Status | Metric | Learning |" >> "$JOURNAL"
  echo "|-----|--------|--------|----------|" >> "$JOURNAL"
fi

if [[ -n "$ASI_LEARNED" && "$STATUS" == "discard" ]]; then
  echo "| $RUN | $STATUS | $METRIC | $ASI_LEARNED |" >> "$JOURNAL"
fi
