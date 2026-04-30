#!/usr/bin/env bash
# Confidence score computation using Median Absolute Deviation (MAD)
# Usage: confidence.sh <jsonl_path> <segment> <direction>
# Output: float or "null"
set -euo pipefail

JSONL="${1:-}"
SEGMENT="${2:-0}"
DIRECTION="${3:-lower}"

if [[ ! -f "$JSONL" ]]; then
  echo "null"
  exit 0
fi

# Extract metric values for current segment, excluding zero-metric runs (crashes)
VALUES=$(jq -s --argjson seg "$SEGMENT" -r '
  [.[] | select(.type == "run" and .segment == $seg and .metric > 0)]
  | [.[].metric]
' "$JSONL")

COUNT=$(echo "$VALUES" | jq 'length')
if [[ "$COUNT" -lt 3 ]]; then
  echo "null"
  exit 0
fi

# Compute MAD
STATS=$(echo "$VALUES" | jq '
  sort as $sorted |
  ($sorted | length) as $n |
  (if $n % 2 == 1 then
    $sorted[($n - 1) / 2]
  else
    ($sorted[$n/2 - 1] + $sorted[$n/2]) / 2
  end) as $median |
  ($sorted | map(. - $median | abs) | sort) as $deviations |
  ($deviations | length) as $dn |
  (if $dn % 2 == 1 then
    $deviations[($dn - 1) / 2]
  else
    ($deviations[$dn/2 - 1] + $deviations[$dn/2]) / 2
  end) as $mad |
  {median: $median, mad: $mad}
')

MAD=$(echo "$STATS" | jq -r '.mad')

if [[ "$MAD" == "0" || "$MAD" == "null" ]]; then
  echo "null"
  exit 0
fi

# Get baseline (first run's metric)
BASELINE=$(jq -s --argjson seg "$SEGMENT" -r '
  [.[] | select(.type == "run" and .segment == $seg)]
  | if length > 0 then .[0].metric else null end
' "$JSONL")

if [[ "$BASELINE" == "null" ]]; then
  echo "null"
  exit 0
fi

# Get best kept metric
if [[ "$DIRECTION" == "lower" ]]; then
  BEST=$(jq -s --argjson seg "$SEGMENT" -r '
    [.[] | select(.type == "run" and .status == "keep" and .segment == $seg and .metric > 0)]
    | if length > 0 then min_by(.metric).metric else null end
  ' "$JSONL")
else
  BEST=$(jq -s --argjson seg "$SEGMENT" -r '
    [.[] | select(.type == "run" and .status == "keep" and .segment == $seg and .metric > 0)]
    | if length > 0 then max_by(.metric).metric else null end
  ' "$JSONL")
fi

if [[ "$BEST" == "null" || "$BEST" == "$BASELINE" ]]; then
  echo "null"
  exit 0
fi

# Confidence = |best - baseline| / MAD
echo "$BEST $BASELINE $MAD" | awk '{delta = ($1 > $2 ? $1 - $2 : $2 - $1); printf "%.4f", delta / $3}'
