---
name: autoresearch
description: Autonomous experiment loop for any optimization target. Set up and run iterative experiments with automatic metric tracking, git-backed keep/discard, confidence scoring, hooks, and finalization. Use when asked to "run autoresearch", "optimize X in a loop", "set up experiments for X", "start autoresearch on", or when the user wants to autonomously improve code performance, reduce bundle size, speed up tests, optimize ML training, or iteratively enhance any measurable target.
compatibility: requires git, jq, python3, bc
---

# Autoresearch

Autonomous experiment loop: try ideas, keep what works, discard what doesn't, never stop. Every experiment is tracked in `autoresearch.jsonl`, code changes are auto-committed (keep) or reverted (discard), and a confidence score tells you whether improvements are real or noise.

## Tools (via Bash)

All core operations go through scripts in `<SKILL_DIR>/scripts/`. Set `AR_WORKDIR` to the working directory before calling them.

| Script | Purpose |
|---|---|
| `scripts/jsonl.sh` | Source this for read/write helpers |
| `scripts/run_experiment.sh` | Execute command, time it, capture output, parse METRIC lines |
| `scripts/confidence.sh` | Compute confidence score (MAD-based) |
| `scripts/hooks.sh` | Fire before/after iteration hooks |
| `scripts/dashboard.sh` | Render experiment dashboard as ASCII table |

### `run_experiment.sh`

```bash
AR_WORKDIR=<workdir> bash <SKILL_DIR>/scripts/run_experiment.sh "<command>" [timeout_sec] [checks_timeout_sec]
```

Returns JSON with: `exitCode`, `durationSeconds`, `passed`, `crashed`, `timedOut`, `tailOutput`, `parsedMetrics`, `checksPass`, `checksTimedOut`, `checksOutput`, `checksDuration`.

### `jsonl.sh` helpers

Source it, then call:
- `jsonl_init_config <name> <metric_name> [metric_unit] [direction]` — write config header, returns new segment
- `jsonl_log_run <run#> <commit_hash> <status> <metric_value> <description> <segment> [metrics_json] [asi_json] [confidence]` — log a run
- `jsonl_last_run` — get last run entry as JSON
- `jsonl_run_count` — total run count
- `get_best_metric <segment>` — best kept metric value
- `get_session_baseline <segment>` — first run's metric
- `get_confidence <segment>` — confidence score

### `hooks.sh`

```
bash <SKILL_DIR>/scripts/hooks.sh <before|after> <workdir> '<payload_json>'
```

Function for generating mock payloads for hook testing:

```bash
build_hook_payload() {
  local event="$1"  # "before" or "after"
  local workdir="$2"
  local next_run="$3"
  local last_run_json="$4"  # last run entry as JSON, or "null"
  local session_name="$5"
  local metric_name="$6"
  local metric_unit="$7"
  local direction="$8"
  local baseline="$9"
  local best="${10}"
  local run_count="${11}"

  jq -n \
    --arg event "$event" \
    --arg cwd "$workdir" \
    --argjson next_run "$next_run" \
    --argjson last_run "$last_run_json" \
    --arg session_name "$session_name" \
    --arg metric_name "$metric_name" \
    --arg metric_unit "$metric_unit" \
    --arg direction "$direction" \
    --argjson baseline "$baseline" \
    --argjson best "$best" \
    --argjson run_count "$run_count" \
    '{
      event: $event,
      cwd: $cwd,
      next_run: $next_run,
      last_run: $last_run,
      session: {
        metric_name: $metric_name,
        metric_unit: $metric_unit,
        direction: $direction,
        baseline_metric: $baseline,
        best_metric: $best,
        run_count: $run_count,
        goal: $session_name
      }
    }'
}
```

## Workflow

### Phase 1 — Setup

1. **Gather requirements.** Ask the user (or infer from context):
   - **Goal**: What are we optimizing? (e.g. "Speed up unit test execution")
   - **Command**: What shell command measures the metric? (e.g. `./autoresearch.sh`)
   - **Primary metric**: Name + unit + direction (lower/higher is better)
   - **Files in scope**: Which source files may be modified?
   - **Constraints**: Tests must pass? No new deps? Budget limits?

2. **Create a branch.** `git checkout -b autoresearch/<goal-slug>-<YYYYMMDD>`

3. **Create session files** in the working directory:

   **`autoresearch.md`** — The brain of the session. A fresh agent reading this should understand everything.

   ```markdown
   # Autoresearch: <goal>

   ## Objective
   <Specific description of what we're optimizing and the workload.>

   ## Metrics
   - **Primary**: <name> (<unit>, lower/higher is better) — the optimization target
   - **Secondary**: <name>, <name>, ... — independent tradeoff monitors

   ## How to Run
   `./autoresearch.sh` — outputs METRIC name=number lines.

   ## Files in Scope
   <Every file the agent may modify, with a brief note on what it does.>

   ## Off Limits
   <What must NOT be touched.>

   ## Constraints
   <Hard rules: tests must pass, no new deps, etc.>

   ## What's Been Tried
   <Update this section as experiments accumulate. Note key wins, dead ends,
   and architectural insights so the agent doesn't repeat failed approaches.>
   ```

   **`autoresearch.sh`** — The benchmark script. Must:
   - `set -euo pipefail`
   - Pre-check fast (syntax errors in <1s)
   - Run the benchmark
   - Output `METRIC name=value` lines to stdout (one per metric)
   - For noisy fast benchmarks (<5s), run multiple times and report median
   - Include whatever diagnostic data helps you make better decisions next iteration

   ```bash
   #!/bin/bash
   set -euo pipefail
   # Example: measure test execution time
   start=$(python3 -c 'import time; print(time.time())')
   pnpm test --run 2>&1 > /dev/null || echo "TESTS_FAILED"
   end=$(python3 -c 'import time; print(time.time())')
   elapsed=$(python3 -c "print(round(($end - $start) * 1000))")
   echo "METRIC total_ms=$elapsed"
   ```

   **`autoresearch.checks.sh`** (optional) — Correctness validation. Create only when constraints require it (e.g. "tests must pass"). Runs after every passing benchmark. Keep output minimal — only show errors. Has separate timeout (default 300s).

   ```bash
   #!/bin/bash
   set -euo pipefail
   pnpm test --run --reporter=dot 2>&1 | tail -50
   pnpm typecheck 2>&1 | grep -i error || true
   ```

4. **Commit setup files** to the branch.

### Phase 2 — Initialize and Baseline

1. Source the jsonl helpers:
   ```bash
   source <SKILL_DIR>/scripts/jsonl.sh
   ```

2. Initialize the session:
   ```bash
   AR_WORKDIR=<workdir> source <SKILL_DIR>/scripts/jsonl.sh
   SEGMENT=$(jsonl_init_config "<goal>" "<metric_name>" "<unit>" "<direction>")
   ```

3. Run baseline:
   ```bash
   RESULT=$(AR_WORKDIR=<workdir> bash <SKILL_DIR>/scripts/run_experiment.sh "./autoresearch.sh")
   ```
   Parse `$RESULT` with `jq`:
   - `parsedMetrics` → extract primary metric value
   - `passed`/`crashed`/`timedOut` → determine status

4. Log baseline:
   ```bash
   PRIMARY=$(echo "$RESULT" | jq -r '.parsedMetrics.<metric_name> // 0')
   SECONDARY=$(echo "$RESULT" | jq '.parsedMetrics | del(.<metric_name>)')
   COMMIT=$(git rev-parse --short HEAD)
   jsonl_log_run 1 "$COMMIT" "keep" "$PRIMARY" "Baseline measurement" "$SEGMENT" "$SECONDARY" "{}" null
   ```

### Phase 3 — The Loop (REPEAT FOREVER)

**NEVER ask "should I continue?" — keep going until the user interrupts.**

For each iteration:

1. **Fire before hook** (if `autoresearch.hooks/before.sh` exists):
   ```bash
   bash <SKILL_DIR>/scripts/hooks.sh before <workdir> '<payload_json>'
   ```
   Build payload using `build_hook_payload` with current session state.

2. **Form a hypothesis.** Based on what's been tried, the codebase, and profiling data. Record it — you'll pass it through ASI.

3. **Make code changes.** Edit files in scope. Think deep before acting — understand the workload, not just random variations.

4. **Run experiment:**
   ```bash
   RESULT=$(AR_WORKDIR=<workdir> bash <SKILL_DIR>/scripts/run_experiment.sh "./autoresearch.sh")
   ```

5. **Decide status:**
   - `crash` — command exited with signal or non-zero (not test failure). If trivial to fix, fix it; otherwise log and move on.
   - `checks_failed` — checks.sh failed (only applicable when checks file exists). Cannot keep.
   - `keep` — primary metric improved over best kept. Simple rule: direction is lower → smaller is keep; direction is higher → larger is keep. Secondary metrics rarely override.
   - `discard` — metric stayed same or worsened. Also discard ugly complexity for tiny gain.

6. **Build ASI** (Actionable Side Information). Record what you learned — not just what you did. What would help the next iteration? Especially annotate failures and crashes heavily — those code changes are about to be reverted.

   ```json
   {"hypothesis": "Inlining the hot path avoids function call overhead", "learned": "Compiler already inlines at -O2, manual inlining only adds code size", "next_focus": "look at cache misses instead"}
   ```

7. **Get commit hash** (only meaningful for keep):
   ```bash
   COMMIT=$(git rev-parse --short HEAD)
   ```

8. **Get confidence:**
   ```bash
   CONF=$(bash <SKILL_DIR>/scripts/confidence.sh <workdir>/autoresearch.jsonl <segment> <direction>)
   ```

9. **Log experiment:**
   ```bash
   ASI_JSON='{"hypothesis": "...", "learned": "..."}'
   jsonl_log_run <run#> "$COMMIT" "<status>" "$PRIMARY" "<description>" "$SEGMENT" "$SECONDARY" "$ASI_JSON" "$CONF"
   ```

10. **Handle git:**
    - `keep` → `git add -A && git commit -m "autoresearch(#<run#>): <goal>: <description>"`
    - `discard` / `crash` / `checks_failed` → `git checkout -- .` (revert code, preserve autoresearch.* files)

11. **Fire after hook** (if `autoresearch.hooks/after.sh` exists).

12. **Update `autoresearch.md`** periodically — especially the "What's Been Tried" section. A fresh agent resuming this session must not repeat dead ends.

13. **Check ideas backlog.** When you discover complex but promising optimizations you won't pursue now, append them to `autoresearch.ideas.md`. On resume, check this file — prune stale entries, try the rest.

14. **Check max iterations.** If `autoresearch.config.json` has `maxIterations`, stop when reached and finalize.

15. **Loop.** Go back to step 1. Immediately. Always.

### Phase 4 — Finalize

When max iterations reached or user asks to finalize:

1. Read `autoresearch.jsonl` — filter to **kept** experiments only.
2. Group kept commits into logical changesets:
   - Preserve application order.
   - No two groups may touch the same file.
   - Keep groups small and focused.
3. Present proposed branches to user for approval.
4. Create independent branches from merge-base, one per group.
5. Report: branches created, overall metric improvement, cleanup commands.

## Loop Rules

- **Primary metric is king.** Improved → keep. Worse/equal → discard.
- **Simpler is better.** Removing code for equal perf = keep.
- **Don't thrash.** Repeatedly reverting the same idea? Try something structurally different.
- **Crashes:** fix if trivial, otherwise log and move on. Don't over-invest.
- **Think longer when stuck.** Re-read source files, study profiling data, reason about what the CPU is actually doing.
- **Resuming:** if `autoresearch.md` exists, read it + git log, continue looping. Reconstruct state from `autoresearch.jsonl`.
- **Confidence score interpretation:**
  - ≥2.0× → improvement is likely real
  - 1.0-2.0× → within noise, consider re-running
  - <1.0× → below noise floor

## Structured Output (autoresearch.sh)

The benchmark script MUST output `METRIC name=value` lines. These are parsed automatically.

```
METRIC total_ms=15200
METRIC compile_us=4200
METRIC test_count=47
```

- Names: word chars, dots, `µ` allowed. No `=`, spaces, or special chars.
- Values: finite numbers (no Infinity, NaN, hex).
- Duplicate names: last occurrence wins.
- Denied names (ignored): `__proto__`, `constructor`, `prototype`.

## Before/After Hooks

Optional scripts in `autoresearch.hooks/`:
- `before.sh` — fires before each iteration. Use for: fetching research, priming context, anti-thrash checks, idea rotation.
- `after.sh` — fires after each `log_experiment`. Use for: notifications, learning journals, auto-tagging winning commits.

Both receive JSON on stdin (see `build_hook_payload` above). Stdout (capped at 8KB) is delivered as a steer message. Empty stdout = silent.

See `<SKILL_DIR>/references/hook-examples/` for ready-to-use hook scripts.

## Configuration (`autoresearch.config.json`)

```json
{
  "maxIterations": 50,
  "workingDir": "/path/to/project"
}
```

- `maxIterations` — auto-stop after N experiments
- `workingDir` — override work directory (file I/O, command execution, git ops)

## Resuming a Session

When `autoresearch.md` exists in the working directory:
1. Read `autoresearch.md` + git log for context
2. Source `<SKILL_DIR>/scripts/jsonl.sh` with `AR_WORKDIR=<workdir>`
3. Call `jsonl_run_count` and `jsonl_last_run` to rebuild state
4. Continue the loop from Phase 3

## Dashboard

At any point, render the experiment dashboard:
```bash
AR_WORKDIR=<workdir> bash <SKILL_DIR>/scripts/dashboard.sh
```

Shows: run count, kept/discarded/crashed/checks_failed counts, baseline, best metric with delta%, confidence score, recent runs table, ideas backlog.

## Key Differences from pi-autoresearch

This skill replicates the pi-autoresearch workflow in Claude Code. Differences:
- No native tool registration — uses Bash scripts + JSONL files
- No TUI dashboard — ASCII table output instead
- No auto-resume on idle — agent manually re-enters the loop
- Git operations are explicit shell commands, not automatic
- Confidence score computed in bash (same MAD algorithm)
