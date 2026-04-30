#!/usr/bin/env bash
# autoresearch jsonl helpers — read/write/query the experiment log
set -euo pipefail

# Path helpers (caller sets AR_WORKDIR or we use cwd)
AR_WORKDIR="${AR_WORKDIR:-.}"
AR_JSONL="$AR_WORKDIR/autoresearch.jsonl"
AR_CONFIG="$AR_WORKDIR/autoresearch.config.json"
_AR_SCRIPT_DIR="${_AR_SCRIPT_DIR:-}"
if [[ -z "$_AR_SCRIPT_DIR" ]]; then
  _AR_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || _AR_SCRIPT_DIR="$HOME/.claude/skills/autoresearch/scripts"
fi

# ---- Read helpers ---------------------------------------------------------

jsonl_header() {
  # Return the last config entry as JSON
  if [[ ! -f "$AR_JSONL" ]]; then
    echo 'null'
    return
  fi
  local last
  last=$(grep '"type":"config"' "$AR_JSONL" | tail -1 2>/dev/null || echo 'null')
  if [[ -z "$last" ]]; then
    echo 'null'
  else
    echo "$last"
  fi
}

jsonl_all_entries() {
  if [[ ! -f "$AR_JSONL" ]]; then
    echo '[]'
    return
  fi
  jq -s '.' "$AR_JSONL" 2>/dev/null || echo '[]'
}

jsonl_last_run() {
  # Return the last run entry as JSON (not config, not hook)
  if [[ ! -f "$AR_JSONL" ]]; then
    echo 'null'
    return
  fi
  local last
  last=$(grep -v '"type":"config"' "$AR_JSONL" | grep -v '"type":"hook"' | tail -1 2>/dev/null || echo 'null')
  if [[ -z "$last" ]]; then
    echo 'null'
  else
    echo "$last"
  fi
}

jsonl_run_count() {
  if [[ ! -f "$AR_JSONL" ]]; then echo 0; return; fi
  grep -v '"type":"config"' "$AR_JSONL" | grep -v '"type":"hook"' | wc -l | tr -d ' '
}

jsonl_current_segment() {
  local header
  header=$(jsonl_header)
  if [[ "$header" == "null" ]]; then echo 0; return; fi
  echo "$header" | jq -r '.segment // 0'
}

# ---- Write helpers --------------------------------------------------------

jsonl_append() {
  local json="$1"
  echo "$json" >> "$AR_JSONL"
}

jsonl_init_config() {
  local name="$1"
  local metric_name="$2"
  local metric_unit="${3:-}"
  local direction="${4:-lower}"

  local segment=0
  local existing
  existing=$(jsonl_header)
  if [[ "$existing" != "null" ]]; then
    segment=$(echo "$existing" | jq -r '.segment // 0')
    segment=$((segment + 1))
  fi

  jsonl_append "$(jq -nc \
    --arg name "$name" \
    --arg metric_name "$metric_name" \
    --arg metric_unit "$metric_unit" \
    --arg direction "$direction" \
    --argjson segment "$segment" \
    '{type: "config", name: $name, metric_name: $metric_name, metric_unit: $metric_unit, direction: $direction, segment: $segment, timestamp: (now | floor)}')"

  echo "$segment"
}

jsonl_log_run() {
  local run_num="$1"
  local commit_hash="$2"
  local run_status="$3"
  local metric_val="$4"
  local desc="$5"
  local seg="$6"
  local metrics="{}"
  local asi="{}"
  local confidence="null"
  if [[ -n "${7-}" ]]; then metrics="$7"; fi
  if [[ -n "${8-}" ]]; then asi="$8"; fi
  if [[ -n "${9-}" ]]; then confidence="$9"; fi

  jsonl_append "$(jq -nc \
    --argjson run "$run_num" \
    --arg commit "$commit_hash" \
    --arg status "$run_status" \
    --argjson metric "$metric_val" \
    --arg description "$desc" \
    --argjson segment "$seg" \
    --argjson metrics "$metrics" \
    --argjson asi "$asi" \
    --argjson confidence "$confidence" \
    '{type: "run", run: $run, commit: $commit, status: $status, metric: $metric, description: $description, segment: $segment, timestamp: (now | floor), metrics: $metrics, asi: $asi, confidence: $confidence}')"
}

jsonl_log_hook() {
  local event="$1"
  local exit_code="$2"
  local timed_out="$3"
  local stdout_size="$4"
  local stderr_size="$5"

  jsonl_append "$(jq -nc \
    --arg event "$event" \
    --argjson exit_code "$exit_code" \
    --argjson timed_out "$timed_out" \
    --argjson stdout_size "$stdout_size" \
    --argjson stderr_size "$stderr_size" \
    '{type: "hook", event: $event, exit_code: $exit_code, timed_out: $timed_out, stdout_size: $stdout_size, stderr_size: $stderr_size, timestamp: (now | floor)}')"
}

# ---- Query helpers --------------------------------------------------------

get_session_baseline() {
  # First run's metric in current segment
  local segment="${1:-0}"
  if [[ ! -f "$AR_JSONL" ]]; then echo "null"; return; fi
  jq -s --argjson seg "$segment" '
    [.[] | select(.type == "run" and .segment == $seg)]
    | if length > 0 then .[0].metric else null end
  ' "$AR_JSONL"
}

get_best_metric() {
  local segment="${1:-0}"
  if [[ ! -f "$AR_JSONL" ]]; then echo "null"; return; fi
  local direction
  direction=$(jsonl_header | jq -r '.direction // "lower"')
  jq -s --argjson seg "$segment" --arg dir "$direction" '
    [.[] | select(.type == "run" and .status == "keep" and .segment == $seg and .metric > 0)]
    | if length == 0 then null
      elif $dir == "lower" then (min_by(.metric).metric)
      else (max_by(.metric).metric) end
  ' "$AR_JSONL"
}

get_confidence() {
  local segment="${1:-0}"
  local direction
  direction=$(jsonl_header | jq -r '.direction // "lower"')
  if [[ ! -f "$AR_JSONL" ]]; then echo "null"; return; fi
  bash "$_AR_SCRIPT_DIR/confidence.sh" "$AR_JSONL" "$segment" "$direction"
}

# ---- Config helpers -------------------------------------------------------

read_max_iterations() {
  if [[ -f "$AR_CONFIG" ]]; then
    jq -r '.maxIterations // empty' "$AR_CONFIG" 2>/dev/null || echo ""
  fi
}

read_working_dir() {
  if [[ -f "$AR_CONFIG" ]]; then
    jq -r '.workingDir // empty' "$AR_CONFIG" 2>/dev/null || echo ""
  fi
}
