#!/usr/bin/env bash
# real-world-python.sh — Full autoresearch simulation on a real Python project
# Reproduces the actual optimization session: 5 rounds with keep/discard/crash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TESTDIR=$(mktemp -d "${TMPDIR:-/tmp}/ar-python-XXXXXX")

cleanup() { rm -rf "$TESTDIR"; }
trap cleanup EXIT

cd "$TESTDIR"

echo "=== Real-World Python Autoresearch Test ==="
echo "Test dir: $TESTDIR"
echo ""

# ---- Setup project ----
cat > process.py << 'PY'
import re, time, random, string

def extract_emails(text):
    pattern = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    matches = re.findall(pattern, text)
    return [m.lower().strip() for m in matches if '.' in m.split('@')[-1]]

def count_words(text):
    return len(text.split())

def clean_data(records):
    cleaned = []
    for r in records:
        c = {}
        for k, v in r.items():
            if isinstance(v, str): c[k] = v.strip().lower()
            elif isinstance(v, (int, float)): c[k] = v
            else: c[k] = str(v)
        cleaned.append(c)
    return cleaned

def gen_data():
    random.seed(42)
    texts = []
    for _ in range(1000):
        t = ''.join(random.choices(string.ascii_letters + string.digits + ' .@-_', k=random.randint(50,500)))
        if random.random() > 0.5:
            p = random.randint(0, max(0, len(t)-20))
            t = t[:p] + f"user{random.randint(1,999)}@example.com" + t[p+20:]
        texts.append(t)
    records = [{'name':''.join(random.choices(string.ascii_letters,k=8)),
                'email':f"test{i}@m.com",'score':random.randint(0,100),
                'active':random.choice(['yes','no',None])} for i in range(500)]
    return texts, records

if __name__ == "__main__":
    texts, records = gen_data()
    start = time.perf_counter()
    for _ in range(50):
        for t in texts:
            extract_emails(t)
            count_words(t)
        clean_data(records)
    print(f"METRIC total_ms={(time.perf_counter()-start)*1000:.2f}")
PY

cat > autoresearch.sh << 'SH'
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
python3 process.py
SH
chmod +x autoresearch.sh

git init -q && git add -A && git commit -qm "initial" && git checkout -qb ar/test

export AR_WORKDIR="$TESTDIR"
export _AR_SCRIPT_DIR="$SKILL_DIR/scripts"
source "$_AR_SCRIPT_DIR/jsonl.sh"

# ===========================
echo ">>> RUN #1: Baseline"
# ===========================
S=$(jsonl_init_config "optimize text proc" "total_ms" "ms" "lower")

RESULT=$(AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/run_experiment.sh" "./autoresearch.sh" 60)
METRIC=$(echo "$RESULT" | jq '.parsedMetrics.total_ms')
PASSED=$(echo "$RESULT" | jq -r '.passed')
echo "    Metric: ${METRIC}ms | Passed: $PASSED"

COMMIT=$(git rev-parse --short HEAD)
jsonl_log_run 1 "$COMMIT" "keep" "$METRIC" "Baseline measurement" "$S" '{}' '{"hypothesis":"baseline"}'
echo "    → KEEP (baseline)"
echo ""

# ===========================
echo ">>> RUN #2: Pre-compile regex"
# ===========================
cat > process.py << 'PY'
import re, time, random, string
_EMAIL_RE = re.compile(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
def extract_emails(text):
    return [m.lower().strip() for m in _EMAIL_RE.findall(text) if '.' in m.split('@')[-1]]
def count_words(text):
    return len(text.split())
def clean_data(records):
    cleaned = []
    for r in records:
        c = {}
        for k, v in r.items():
            if isinstance(v, str): c[k] = v.strip().lower()
            elif isinstance(v, (int, float)): c[k] = v
            else: c[k] = str(v)
        cleaned.append(c)
    return cleaned
def gen_data():
    random.seed(42)
    texts = []
    for _ in range(1000):
        t = ''.join(random.choices(string.ascii_letters + string.digits + ' .@-_', k=random.randint(50,500)))
        if random.random() > 0.5:
            p = random.randint(0, max(0, len(t)-20))
            t = t[:p] + f"user{random.randint(1,999)}@example.com" + t[p+20:]
        texts.append(t)
    records = [{'name':''.join(random.choices(string.ascii_letters,k=8)),
                'email':f"test{i}@m.com",'score':random.randint(0,100),
                'active':random.choice(['yes','no',None])} for i in range(500)]
    return texts, records
if __name__ == "__main__":
    texts, records = gen_data()
    start = time.perf_counter()
    for _ in range(50):
        for t in texts:
            extract_emails(t)
            count_words(t)
        clean_data(records)
    print(f"METRIC total_ms={(time.perf_counter()-start)*1000:.2f}")
PY

RESULT=$(AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/run_experiment.sh" "./autoresearch.sh" 60)
METRIC=$(echo "$RESULT" | jq '.parsedMetrics.total_ms')
echo "    Metric: ${METRIC}ms"

BEST=$(get_best_metric "$S")
if echo "$METRIC < $BEST" | bc -l | grep -q 1; then
  STATUS="keep"
  git add -A && git commit -qm "ar(#2): pre-compile regex: ${METRIC}ms"
else
  STATUS="discard"
  git checkout -- process.py 2>/dev/null
fi
COMMIT=$(git rev-parse --short HEAD)
jsonl_log_run 2 "$COMMIT" "$STATUS" "$METRIC" "Pre-compile email regex" "$S" '{}' '{"hypothesis":"compiled regex avoids recompilation per call"}'
echo "    → $STATUS"
echo ""

# ===========================
echo ">>> RUN #3: List comprehension + dict comp"
# ===========================
cat > process.py << 'PY'
import re, time, random, string
_EMAIL_RE = re.compile(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
def extract_emails(text):
    return [m.lower() for m in _EMAIL_RE.findall(text) if '.' in m.split('@')[-1]]
def count_words(text):
    return len(text.split())
def clean_data(records):
    return [{k: (v.strip().lower() if isinstance(v, str) else v if isinstance(v, (int, float)) else str(v)) for k, v in r.items()} for r in records]
def gen_data():
    random.seed(42)
    texts = []
    for _ in range(1000):
        t = ''.join(random.choices(string.ascii_letters + string.digits + ' .@-_', k=random.randint(50,500)))
        if random.random() > 0.5:
            p = random.randint(0, max(0, len(t)-20))
            t = t[:p] + f"user{random.randint(1,999)}@example.com" + t[p+20:]
        texts.append(t)
    records = [{'name':''.join(random.choices(string.ascii_letters,k=8)),
                'email':f"test{i}@m.com",'score':random.randint(0,100),
                'active':random.choice(['yes','no',None])} for i in range(500)]
    return texts, records
if __name__ == "__main__":
    texts, records = gen_data()
    start = time.perf_counter()
    for _ in range(50):
        for t in texts:
            extract_emails(t)
            count_words(t)
        clean_data(records)
    print(f"METRIC total_ms={(time.perf_counter()-start)*1000:.2f}")
PY

RESULT=$(AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/run_experiment.sh" "./autoresearch.sh" 60)
METRIC=$(echo "$RESULT" | jq '.parsedMetrics.total_ms')
echo "    Metric: ${METRIC}ms"

BEST=$(get_best_metric "$S")
if echo "$METRIC < $BEST" | bc -l | grep -q 1; then
  STATUS="keep"
  git add -A && git commit -qm "ar(#3): list comp: ${METRIC}ms"
else
  STATUS="discard"
  git checkout -- process.py 2>/dev/null
fi
COMMIT=$(git rev-parse --short HEAD)
jsonl_log_run 3 "$COMMIT" "$STATUS" "$METRIC" "List comprehension + dict comp" "$S" '{}' '{"hypothesis":"comprehensions avoid append overhead","learned":"marginal, noise-heavy"}'
echo "    → $STATUS"
echo ""

# ===========================
echo ">>> RUN #4: Crash test (intentional bug)"
# ===========================
cat > process.py << 'PY'
import re, time, random, string
_EMAIL_RE = re.compile(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
def extract_emails(text):
    return [m.lower() for m in _EMAIL_RE.findall(text) if '.' in m.split('@')[-1]]
def count_words(text):
    return len(text.split())
def clean_data(records):
    return [{k: (v.strip().lower() if isinstance(v, str) else v if isinstance(v, (int, float)) else str(v)) for k, v in r.items()} for r in records]
def gen_data():
    random.seed(42)
    texts = []
    for _ in range(1000):
        t = ''.join(random.choices(string.ascii_letters + string.digits + ' .@-_', k=random.randint(50,500)))
        if random.random() > 0.5:
            p = random.randint(0, max(0, len(t)-20))
            t = t[:p] + f"user{random.randint(1,999)}@example.com" + t[p+20:]
        texts.append(t)
    records = [{'name':''.join(random.choices(string.ascii_letters,k=8)),
                'email':f"test{i}@m.com",'score':random.randint(0,100),
                'active':random.choice(['yes','no',None])} for i in range(500)]
    return texts, records
if __name__ == "__main__":
    texts, records = gen_data()
    start = time.perf_counter()
    for _ in range(50):
        for t in texts:
            extract_emails(t)
            count_words(t)
        clean_data(records)
    elapsed_ms = (time.perf_counter() - undefined_var) * 1000
    print(f"METRIC total_ms={elapsed_ms:.2f}")
PY

RESULT=$(AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/run_experiment.sh" "./autoresearch.sh" 60)
EXIT_CODE=$(echo "$RESULT" | jq '.exitCode')
CRASHED=$(echo "$RESULT" | jq -r '.crashed')
PASSED=$(echo "$RESULT" | jq -r '.passed')
echo "    ExitCode: $EXIT_CODE | Crashed: $CRASHED | Passed: $PASSED"

COMMIT=$(git rev-parse --short HEAD)
jsonl_log_run 4 "$COMMIT" "crash" "0" "Intentional crash: undefined variable" "$S" '{}' '{"hypothesis":"N/A","learned":"benchmark script must use correct variable names"}'
git checkout -- process.py 2>/dev/null
echo "    → CRASH, reverted"
echo ""

# ===========================
echo ">>> RUN #5: Simplify email validation"
# ===========================
cat > process.py << 'PY'
import re, time, random, string
_EMAIL_RE = re.compile(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
def extract_emails(text):
    return [m.lower() for m in _EMAIL_RE.findall(text) if '.' in m]
def count_words(text):
    return len(text.split())
def clean_data(records):
    return [{k: (v.strip().lower() if isinstance(v, str) else v if isinstance(v, (int, float)) else str(v)) for k, v in r.items()} for r in records]
def gen_data():
    random.seed(42)
    texts = []
    for _ in range(1000):
        t = ''.join(random.choices(string.ascii_letters + string.digits + ' .@-_', k=random.randint(50,500)))
        if random.random() > 0.5:
            p = random.randint(0, max(0, len(t)-20))
            t = t[:p] + f"user{random.randint(1,999)}@example.com" + t[p+20:]
        texts.append(t)
    records = [{'name':''.join(random.choices(string.ascii_letters,k=8)),
                'email':f"test{i}@m.com",'score':random.randint(0,100),
                'active':random.choice(['yes','no',None])} for i in range(500)]
    return texts, records
if __name__ == "__main__":
    texts, records = gen_data()
    start = time.perf_counter()
    for _ in range(50):
        for t in texts:
            extract_emails(t)
            count_words(t)
        clean_data(records)
    print(f"METRIC total_ms={(time.perf_counter()-start)*1000:.2f}")
PY

RESULT=$(AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/run_experiment.sh" "./autoresearch.sh" 60)
METRIC=$(echo "$RESULT" | jq '.parsedMetrics.total_ms')
echo "    Metric: ${METRIC}ms"

BEST=$(get_best_metric "$S")
if echo "$METRIC < $BEST" | bc -l | grep -q 1; then
  STATUS="keep"
  git add -A && git commit -qm "ar(#5): simplified email validation: ${METRIC}ms"
else
  STATUS="discard"
  git checkout -- process.py 2>/dev/null
fi
COMMIT=$(git rev-parse --short HEAD)
jsonl_log_run 5 "$COMMIT" "$STATUS" "$METRIC" "Simplified email check" "$S" '{}' '{"hypothesis":"split redundant since regex validates domain","learned":"removing unnecessary string ops helps"}'
echo "    → $STATUS"
echo ""

# ===========================
echo "========== FINAL DASHBOARD =========="
# ===========================
AR_WORKDIR=$AR_WORKDIR bash "$_AR_SCRIPT_DIR/dashboard.sh" 10
echo ""

CONF=$(get_confidence 0)
echo "Confidence: ${CONF}"
echo ""

# ===========================
echo "========== HOOK TEST =========="
# ===========================
mkdir -p "$TESTDIR/autoresearch.hooks"
cp "$SKILL_DIR/references/hook-examples/before/hypothesis-reflection.sh" "$TESTDIR/autoresearch.hooks/before.sh"
chmod +x "$TESTDIR/autoresearch.hooks/before.sh"

LAST_RUN=$(jq -s 'map(select(.type == "run")) | last' "$TESTDIR/autoresearch.jsonl")
PAYLOAD=$(jq -n \
  --arg cwd "$TESTDIR" \
  --argjson next_run 6 \
  --argjson last_run "$LAST_RUN" \
  --arg session_name "optimize text proc" \
  --arg metric_name "total_ms" \
  --arg metric_unit "ms" \
  --arg direction "lower" \
  --argjson baseline "$(get_session_baseline 0)" \
  --argjson best "$(get_best_metric 0)" \
  --argjson run_count "$(jsonl_run_count)" \
  '{event:"before",cwd:$cwd,next_run:$next_run,last_run:$last_run,session:{metric_name:$metric_name,metric_unit:$metric_unit,direction:$direction,baseline_metric:$baseline,best_metric:$best,run_count:$run_count,goal:$session_name}}')

bash "$_AR_SCRIPT_DIR/hooks.sh" before "$TESTDIR" "$PAYLOAD"
echo ""

# ===========================
echo "========== GIT LOG =========="
# ===========================
git log --oneline
echo ""

# ===========================
echo "========== JSONL LOG =========="
# ===========================
jq -s '.' "$TESTDIR/autoresearch.jsonl"
echo ""
echo "Done."
