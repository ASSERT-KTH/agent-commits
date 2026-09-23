#!/bin/bash
# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
DATE=$(date -u '+%Y-%m-%d')

# Stay silent for cron, but leave a trace and don't commit when the token is dead
# (the classic PAT expired on 2026-07-07 and the script committed nulls for months)
if ! curl -sf -o /dev/null -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit; then
  echo "$TIMESTAMP GITHUB_TOKEN rejected, nothing collected" >> "$SCRIPT_DIR/collect.log"
  exit 1
fi

NEW_DATA_POINTS=0

track_agent() {
  local AGENT="$1"
  local URL="https://github.com/search?q=%22$AGENT%22&type=commits"
  local DIR="$SCRIPT_DIR"

  local JSON_FILE="$DIR/data/${AGENT}_${TIMESTAMP}.json"

  mkdir -p "$DIR/html/$AGENT"
  curl -s -H "Authorization: token $GITHUB_TOKEN" -o "$DIR/html/$AGENT/html-${TIMESTAMP}.html" "$URL"

  curl -s "https://api.github.com/search/commits?q=%22$AGENT%22+author-date%3A2020-01-01..${DATE}&per_page=100&sort=author-date&incomplete_results=True" \
    -H "Accept: application/vnd.github.cloak-preview" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -o "$JSON_FILE"

  if grep -q "You have exceeded a secondary rate limit" "$JSON_FILE"; then
    echo "Rate limit exceeded for $AGENT, deleting $JSON_FILE"
    rm "$JSON_FILE"
    return
  fi

  COUNT=$(jq '.total_count // empty' "$JSON_FILE" 2>/dev/null)
  if [ -z "$COUNT" ]; then
    echo "$TIMESTAMP $AGENT: invalid response, deleting $JSON_FILE" >> "$DIR/collect.log"
    rm "$JSON_FILE"
    return
  fi

  echo "$TIMESTAMP, $COUNT" >> "$DIR/${AGENT}_commits.csv"
  DATA_POINTS=$(jq '.items | length' "$JSON_FILE")
  NEW_DATA_POINTS=$((NEW_DATA_POINTS+DATA_POINTS))
  sleep 5
}
NEW_DATA_POINTS=0
# Anthropic / Claude
track_agent "noreply%40anthropic.com"

# OpenAI Codex
track_agent "codex%40openai.com"

# GitHub Copilot
track_agent "copilot%40users.noreply.github.com"

# Google Gemini
track_agent "gemini-code-assist%40google.com"

# Cognition / Devin
#track_agent "devin%40cognition.ai"
track_agent "devin-ai-integration[bot]"
# Cursor
#track_agent "cursor%40anysphere.io"
track_agent "cursoragent%40cursor.com"

cd "$SCRIPT_DIR"
[ "$NEW_DATA_POINTS" -gt 0 ] || exit 0
# Only the CSVs: raw JSON is ~2 MB per run (67 GB by Sep 2026) and stays local,
# data/*json stopped being committed in April 2026 when the glob exceeded ARG_MAX
git add -- '*_commits.csv'
git commit -m "automated commit ($NEW_DATA_POINTS new data points)" --author="assert-bot <castor-bot@eecs.kth.se>" -a
git push origin main

