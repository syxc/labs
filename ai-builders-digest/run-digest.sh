#!/usr/bin/env bash
# run-digest.sh — Fetch latest feed data and generate AI Builders morning briefing
# Usage:
#   ./run-digest.sh              # auto mode: fetch feed -> build prompt for LLM
#   ./run-digest.sh --fetch-only # only fetch latest feed, don't generate prompt
#
# Output (all under ~/.follow-builders/):
#   - JSON blob:   ~/.follow-builders/cache/digest-input-YYYY-MM-DD.json
#   - LLM prompt:  ~/.follow-builders/cache/digest-prompt-YYYY-MM-DD.txt
#   - Final digest: ~/.follow-builders/output/YYYY-MM-DD-digest.md (written by the LLM)

set -uo pipefail

REPO_DIR="${FOLLOW_BUILDERS_REPO:-$HOME/ai/niuma/follow-builders}"
USER_DIR="${FOLLOW_BUILDERS_HOME:-$HOME/.follow-builders}"
PROMPT_TEMPLATE="${USER_DIR}/prompts/digest-morning-briefing.md"
OUTPUT_DIR="${USER_DIR}/output"
CACHE_DIR="${USER_DIR}/cache"
DATE=$(date +%Y-%m-%d)

JSON_BLOB="${CACHE_DIR}/digest-input-${DATE}.json"
PROMPT_FILE="${CACHE_DIR}/digest-prompt-${DATE}.txt"
DIGEST_OUTPUT="${OUTPUT_DIR}/${DATE}-digest.md"

mkdir -p "${CACHE_DIR}" "${OUTPUT_DIR}"

# Activate mise to get node
eval "$(mise activate bash)"

echo "==> Fetching latest feed data..."
cd "${REPO_DIR}"

# Try remote fetch; suppress errors
FETCH_OK=0
node scripts/prepare-digest.js > "${JSON_BLOB}" 2>/dev/null && FETCH_OK=1 || true

# Validate remote output
if [ "${FETCH_OK}" -eq 1 ] && [ -s "${JSON_BLOB}" ]; then
  FETCH_OK=$(python3 -c "
import json, sys
d = json.load(open('${JSON_BLOB}'))
sys.exit(0 if d.get('status') == 'ok' else 1)
" 2>/dev/null && echo 1 || echo 0)
fi

# Fallback: build JSON blob from local feed files committed by GitHub Actions
if [ "${FETCH_OK}" -ne 1 ]; then
  echo "WARN: Remote fetch failed, using local feed files as fallback"
  python3 << PYEOF
import json, os, sys

repo = "${REPO_DIR}"
date = "${DATE}"
out = "${JSON_BLOB}"

feeds = {}
for name in ['feed-x', 'feed-podcasts', 'feed-blogs']:
    path = os.path.join(repo, name + '.json')
    if os.path.exists(path):
        with open(path) as f:
            feeds[name] = json.load(f)

x_items = feeds.get('feed-x', {}).get('x', [])
podcast_items = feeds.get('feed-podcasts', {}).get('podcasts', [])
blog_items = feeds.get('feed-blogs', {}).get('blogs', [])

if not x_items and not podcast_items and not blog_items:
    print("ERROR: Local feed files are empty", file=sys.stderr)
    sys.exit(1)

blob = {
    'status': 'ok',
    'generatedAt': feeds.get('feed-x', {}).get('generatedAt', ''),
    'config': {'language': 'zh', 'frequency': 'daily', 'delivery': {'method': 'stdout'}},
    'x': x_items,
    'podcasts': podcast_items,
    'blogs': blog_items,
    'stats': {
        'xBuilders': len(x_items),
        'totalTweets': sum(len(b.get('tweets', [])) for b in x_items),
        'podcastEpisodes': len(podcast_items),
        'blogPosts': len(blog_items),
    },
    'prompts': {},
    'source': 'local-fallback',
}
with open(out, 'w') as f:
    json.dump(blob, f, ensure_ascii=False)
print(f"Fallback OK: {len(x_items)} builders, {len(podcast_items)} podcasts, {len(blog_items)} blogs")
PYEOF
fi

if [ ! -s "${JSON_BLOB}" ]; then
  echo "ERROR: No feed data available (remote and local both failed)"
  exit 1
fi

# Quick stats
STATS=$(python3 -c "
import json
d = json.load(open('${JSON_BLOB}'))
s = d.get('stats', {})
src = d.get('source', 'remote')
print(f\"Source: {src}\")
print(f\"X: {s.get('totalTweets', 0)} tweets from {s.get('xBuilders', 0)} builders\")
print(f\"Podcasts: {s.get('podcastEpisodes', 0)} episodes\")
print(f\"Blogs: {s.get('blogPosts', 0)} posts\")
print(f\"Feed generated: {s.get('feedGeneratedAt', d.get('generatedAt', 'unknown'))}\")
")
echo "${STATS}"

if [ "${1:-}" = "--fetch-only" ]; then
  echo "==> --fetch-only mode, skipping prompt generation"
  echo "JSON blob: ${JSON_BLOB}"
  exit 0
fi

echo "==> Building LLM prompt..."

# Read the prompt template
TEMPLATE=$(cat "${PROMPT_TEMPLATE}")

# Read the JSON blob
FEED_DATA=$(cat "${JSON_BLOB}")

# Build the final prompt
cat > "${PROMPT_FILE}" << 'PROMPT_HEADER'
You are generating today's AI Builders morning briefing digest.
PROMPT_HEADER

# Append the prompt template
echo "" >> "${PROMPT_FILE}"
echo "---" >> "${PROMPT_FILE}"
echo "" >> "${PROMPT_FILE}"
echo "## Digest Rules" >> "${PROMPT_FILE}"
echo "" >> "${PROMPT_FILE}"
echo "${TEMPLATE}" >> "${PROMPT_FILE}"

echo "" >> "${PROMPT_FILE}"
echo "---" >> "${PROMPT_FILE}"
echo "" >> "${PROMPT_FILE}"
echo "## Raw Feed Data (JSON)" >> "${PROMPT_FILE}"
echo "" >> "${PROMPT_FILE}"
echo '```json' >> "${PROMPT_FILE}"
echo "${FEED_DATA}" >> "${PROMPT_FILE}"
echo '```' >> "${PROMPT_FILE}"

echo "" >> "${PROMPT_FILE}"
echo "---" >> "${PROMPT_FILE}"
echo "" >> "${PROMPT_FILE}"
echo "Now generate the digest following the rules above. Output the complete digest in the fixed format. Save it to ${DIGEST_OUTPUT}" >> "${PROMPT_FILE}"

echo "==> Prompt ready: ${PROMPT_FILE}"
echo "==> Expected output: ${DIGEST_OUTPUT}"
echo ""
echo "Next step: Feed this prompt to Claude to generate the digest."
echo "  cat ${PROMPT_FILE}"
echo ""
echo "Or run manually in Claude Code:"
echo "  Read the prompt file, then generate the digest per rules."
