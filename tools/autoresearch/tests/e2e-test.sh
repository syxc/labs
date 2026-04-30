#!/usr/bin/env bash
# e2e-test.sh — End-to-end test for autoresearch skill
# Tests: init, log, run_experiment, confidence, dashboard, hooks, crash handling, git operations
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$SCRIPT_DIR/.."
TESTDIR=$(mktemp -d /tmp/ar-e2e-test-XXXXXX)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass=0
fail=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo -e "  ${GREEN}PASS${NC} $label"
    pass=$((pass+1))
  else
    echo -e "  ${RED}FAIL${NC} $label: expected='$expected', got='$actual'"
    fail=$((fail+1))
  fi
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo -e "  ${GREEN}PASS${NC} $label"
    pass=$((pass+1))
  else
    echo -e "  ${RED}FAIL${NC} $label: '$needle' not found in output"
    fail=$((fail+1))
  fi
}

assert_gt() {
  local label="$1" actual="$2" threshold="$3"
  if echo "$actual > $threshold" | bc -l | grep -q 1; then
    echo -e "  ${GREEN}PASS${NC} $label ($actual > $threshold)"
    pass=$((pass+1))
  else
    echo -e "  ${RED}FAIL${NC} $label: $actual not > $threshold"
    fail=$((fail+1))
  fi
}

cleanup() {
  rm -rf "$TESTDIR"
}
trap cleanup EXIT

echo "=== Autoresearch E2E Test ==="
echo "Test dir: $TESTDIR"
echo ""

# ---- Setup mock project ----
cat > "$TESTDIR/bench.sh" << 'SH'
#!/bin/bash
echo "METRIC total_ms=42.5"
SH
chmod +x "$TESTDIR/bench.sh"

# Crash version
cat > "$TESTDIR/bench-crash.sh" << 'SH'
#!/bin/bash
echo "some output"
exit 1
SH
chmod +x "$TESTDIR/bench-crash.sh"

cd "$TESTDIR"
git init -q && git add -A && git commit -qm "initial" && git checkout -qb ar/test

# ---- Source helpers ----
export AR_WORKDIR="$TESTDIR"
export _AR_SCRIPT_DIR="$SKILL_DIR/scripts"
source "$_AR_SCRIPT_DIR/jsonl.sh"

# ===========================
echo -e "${YELLOW}[1/8] Init config${NC}"
# ===========================
S=$(jsonl_init_config "e2e test" "total_ms" "ms" "lower")
assert_eq "segment is 0" "0" "$S"

HEADER=$(jsonl_header)
assert_eq "config name" "e2e test" "$(echo "$HEADER" | jq -r '.name')"
assert_eq "metric_name" "total_ms" "$(echo "$HEADER" | jq -r '.metric_name')"
assert_eq "direction" "lower" "$(echo "$HEADER" | jq -r '.direction')"

# ===========================
echo -e "${YELLOW}[2/8] Run experiment (pass)${NC}"
# ===========================
RESULT=$(AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/run_experiment.sh" "./bench.sh" 10)
assert_eq "passed" "true" "$(echo "$RESULT" | jq -r '.passed')"
assert_eq "crashed" "false" "$(echo "$RESULT" | jq -r '.crashed')"
assert_eq "exitCode" "0" "$(echo "$RESULT" | jq -r '.exitCode')"
assert_eq "parsedMetrics.total_ms" "42.5" "$(echo "$RESULT" | jq -r '.parsedMetrics.total_ms')"

# ===========================
echo -e "${YELLOW}[3/8] Log runs + query${NC}"
# ===========================
COMMIT=$(git rev-parse --short HEAD)
jsonl_log_run 1 "$COMMIT" "keep" "42.5" "Baseline" "$S" '{"compile_us":4200}' '{"hypothesis":"baseline"}'
jsonl_log_run 2 "$COMMIT" "discard" "44.1" "Bad idea" "$S" '{"compile_us":4500}' '{"hypothesis":"bad","learned":"worse"}'
jsonl_log_run 3 "$COMMIT" "keep" "33.5" "Good idea" "$S" '{"compile_us":4100}' '{"hypothesis":"good"}'
jsonl_log_run 4 "$COMMIT" "crash" "0" "Crashed" "$S" '{}' '{"hypothesis":"N/A"}'
jsonl_log_run 5 "$COMMIT" "keep" "28.1" "Best so far" "$S" '{"compile_us":4050}' '{"hypothesis":"cache"}'

assert_eq "run count" "5" "$(jsonl_run_count)"
assert_eq "baseline" "42.5" "$(get_session_baseline 0)"
assert_eq "best metric" "28.1" "$(get_best_metric 0)"

# ===========================
echo -e "${YELLOW}[4/8] Confidence score${NC}"
# ===========================
CONF=$(get_confidence 0)
assert_gt "confidence >= 2.0" "$CONF" "2.0"

# ===========================
echo -e "${YELLOW}[5/8] Run experiment (crash)${NC}"
# ===========================
RESULT=$(AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/run_experiment.sh" "./bench-crash.sh" 10)
assert_eq "crash detected" "false" "$(echo "$RESULT" | jq -r '.passed')"
assert_eq "exit code non-zero" "1" "$(echo "$RESULT" | jq -r '.exitCode')"
assert_eq "empty metrics on crash" "{}" "$(echo "$RESULT" | jq -c '.parsedMetrics')"

# ===========================
echo -e "${YELLOW}[6/8] Dashboard${NC}"
# ===========================
DASH=$(AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/dashboard.sh")
assert_contains "shows run count" "$DASH" "Runs: 5"
assert_contains "shows kept" "$DASH" "3 kept"
assert_contains "shows crashed" "$DASH" "1 crashed"
assert_contains "shows baseline" "$DASH" "42.50ms"
assert_contains "shows best" "$DASH" "28.10ms"
assert_contains "shows confidence" "$DASH" "real improvement"

# ===========================
echo -e "${YELLOW}[7/8] Hooks${NC}"
# ===========================
mkdir -p "$TESTDIR/autoresearch.hooks"
cat > "$TESTDIR/autoresearch.hooks/before.sh" << 'HOOK'
#!/bin/bash
read payload
echo "$payload" | jq -r '"Hook OK: \(.session.goal) run #\(.next_run)"'
HOOK
chmod +x "$TESTDIR/autoresearch.hooks/before.sh"

PAYLOAD='{"event":"before","cwd":"'"$TESTDIR"'","next_run":6,"last_run":null,"session":{"metric_name":"total_ms","metric_unit":"ms","direction":"lower","baseline_metric":42.5,"best_metric":28.1,"run_count":5,"goal":"e2e test"}}'

HOOK_OUT=$(bash "$_AR_SCRIPT_DIR/hooks.sh" before "$TESTDIR" "$PAYLOAD")
assert_contains "hook output contains goal" "$HOOK_OUT" "Hook OK: e2e test"
assert_contains "hook output contains run number" "$HOOK_OUT" "run #6"

# ===========================
echo -e "${YELLOW}[8/8] Git operations${NC}"
# ===========================
# Simulate keep: modify file, commit
echo "optimized" > "$TESTDIR/process.py"
git add -A && git commit -qm "ar(#6): test commit" >/dev/null
assert_eq "keep commit exists" "ar(#6): test commit" "$(git log --oneline -1 | sed 's/^[^ ]* //')"

# Simulate discard: modify file, revert
echo "bad change" > "$TESTDIR/process.py"
git checkout -- process.py 2>/dev/null
assert_eq "discard reverted" "optimized" "$(cat "$TESTDIR/process.py")"

# ===========================
echo ""
echo "=========================================="
TOTAL=$((pass + fail))
echo -e "Results: ${GREEN}${pass}${NC}/${TOTAL} passed, ${RED}${fail}${NC}/${TOTAL} failed"
echo "=========================================="

if [[ $fail -gt 0 ]]; then
  exit 1
fi
