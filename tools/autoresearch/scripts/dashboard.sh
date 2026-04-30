#!/usr/bin/env bash
# dashboard.sh — render the experiment dashboard as ASCII table
# Usage: dashboard.sh [max_rows=6]
# Reads from $AR_WORKDIR/autoresearch.jsonl
set -euo pipefail

MAX_ROWS="${1:-6}"
AR_WORKDIR="${AR_WORKDIR:-.}"
AR_JSONL="$AR_WORKDIR/autoresearch.jsonl"

if [[ ! -f "$AR_JSONL" ]]; then
  echo "No experiments yet (autoresearch.jsonl not found)"
  exit 0
fi

# ---- Parse state ----------------------------------------------------------

HEADER=$(jq -s 'map(select(.type == "config")) | last // {}' "$AR_JSONL")
NAME=$(echo "$HEADER" | jq -r '.name // "unnamed"')
METRIC_NAME=$(echo "$HEADER" | jq -r '.metric_name // "metric"')
METRIC_UNIT=$(echo "$HEADER" | jq -r '.metric_unit // ""')
DIRECTION=$(echo "$HEADER" | jq -r '.direction // "lower"')
CURRENT_SEGMENT=$(echo "$HEADER" | jq -r '.segment // 0')

# All runs in current segment
RUNS=$(jq -s --argjson seg "$CURRENT_SEGMENT" '
  [.[] | select(.type == "run" and .segment == $seg)]
' "$AR_JSONL")

TOTAL=$(echo "$RUNS" | jq 'length')
KEPT=$(echo "$RUNS" | jq '[.[] | select(.status == "keep")] | length')
DISCARDED=$(echo "$RUNS" | jq '[.[] | select(.status == "discard")] | length')
CRASHED=$(echo "$RUNS" | jq '[.[] | select(.status == "crash")] | length')
CHECKS_FAILED=$(echo "$RUNS" | jq '[.[] | select(.status == "checks_failed")] | length')

BASELINE_METRIC=$(echo "$RUNS" | jq -r '.[0].metric // "null"')
BEST=$(echo "$RUNS" | jq '
  [.[] | select(.status == "keep" and .metric > 0)]
  | if length == 0 then null else ('"$(if [[ "$DIRECTION" == "lower" ]]; then echo "min_by(.metric)"; else echo "max_by(.metric)"; fi)"'.metric) end
')

# Confidence
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"
CONF=$(bash "$SCRIPT_DIR/confidence.sh" "$AR_JSONL" "$CURRENT_SEGMENT" "$DIRECTION" 2>/dev/null || echo "null")

# ---- Render ---------------------------------------------------------------

echo "🔬 autoresearch: $NAME"
echo "────────────────────────────────────────────────────────────"
echo "Runs: $TOTAL  |  $KEPT kept  |  $DISCARDED discarded  |  $CRASHED crashed  |  $CHECKS_FAILED checks_failed"
echo "Baseline: ★ $METRIC_NAME = $(printf '%.2f' "$BASELINE_METRIC" 2>/dev/null || echo "$BASELINE_METRIC")$METRIC_UNIT  (run #1)"

if [[ "$BEST" != "null" ]]; then
  DELTA_PCT=""
  if [[ "$BASELINE_METRIC" != "null" && "$BASELINE_METRIC" != "0" ]]; then
    DELTA_PCT=$(python3 -c "print(f'{($BEST - $BASELINE_METRIC) / $BASELINE_METRIC * 100:+.1f}%')" 2>/dev/null || echo "")
  fi
  echo "Best:    ★ $METRIC_NAME = $(printf '%.2f' "$BEST" 2>/dev/null || echo "$BEST")$METRIC_UNIT  $DELTA_PCT"
fi

if [[ "$CONF" != "null" ]]; then
  CONF_SCORE=$(printf '%.1f' "$CONF" 2>/dev/null || echo "$CONF")
  if (( $(echo "$CONF >= 2.0" | bc -l) )); then
    echo "Confidence: ${CONF_SCORE}× ✅ (real improvement)"
  elif (( $(echo "$CONF >= 1.0" | bc -l) )); then
    echo "Confidence: ${CONF_SCORE}× ⚠️  (within noise — consider re-running)"
  else
    echo "Confidence: ${CONF_SCORE}× ❌ (< noise floor)"
  fi
fi

echo ""
echo "---- Recent Runs ----"
printf "%-4s %-8s %-12s %-10s %s\n" "#" "commit" "metric" "status" "description"
echo "────────────────────────────────────────────────────────────"

# Show last N runs
echo "$RUNS" | jq -r '
  .[] |
  [ (.run | tostring),
    (.commit // "-"),
    ((.metric | tostring) + "'"$METRIC_UNIT"'"),
    .status,
    (.description // "")
  ] | @tsv
' | tail -"$MAX_ROWS" | while IFS=$'\t' read -r run commit metric status desc; do
  printf "%-4s %-8s %-12s %-10s %s\n" "$run" "$commit" "$metric" "$status" "${desc:0:60}"
done

echo ""

# Ideas if they exist
if [[ -f "$AR_WORKDIR/autoresearch.ideas.md" ]]; then
  echo "---- Ideas Backlog ----"
  cat "$AR_WORKDIR/autoresearch.ideas.md"
  echo ""
fi
