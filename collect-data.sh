#!/bin/bash
# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
DATE=$(date -u '+%Y-%m-%d')

NEW_DATA_POINTS=0

track_agent() {
  local AGENT="$1"
  local URL="https://github.com/search?q=%22$AGENT%22&type=commits"
  local DIR="$SCRIPT_DIR"

  local JSON_FILE="$DIR/data/${AGENT}_${TIMESTAMP}.json"

  mkdir -p "$DIR/html/$AGENT"
  curl -s -H "Authorization: token $GITHUB_TOKEN" -o "$DIR/html/$AGENT/html-${TIMESTAMP}.html" "$URL"

  curl -s "https://api.github.com/search/commits?q=%22$AGENT%22+author-date%3A2020-01-01..${DATE}&per_page=100&sort=author-date" \
    -H "Accept: application/vnd.github.cloak-preview" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -o "$JSON_FILE"

  if grep -q "You have exceeded a secondary rate limit" "$JSON_FILE"; then
    echo "Rate limit exceeded for $AGENT, deleting $JSON_FILE"
    rm "$JSON_FILE"
    return
  fi

  COUNT=$(jq '.total_count' "$JSON_FILE")

  echo "$TIMESTAMP, $COUNT" >> "$DIR/${AGENT}_commits.csv"
  echo "$AGENT: $COUNT"
  NEW_DATA_POINTS=$((NEW_DATA_POINTS + 1))
}

# Anthropic / Claude
track_agent "noreply%40anthropic.com"

# OpenAI Codex
track_agent "codex%40openai.com"

# GitHub Copilot
track_agent "copilot%40users.noreply.github.com"

# Google Gemini
track_agent "gemini-code-assist%40google.com"

# Cognition / Devin
track_agent "devin%40cognition.ai"

# Cursor
track_agent "cursor%40anysphere.io"

cd "$SCRIPT_DIR"
git add data/*json
git commit -m "automated commit ($NEW_DATA_POINTS new data points)" --author="monperrus-bot <monperrus-bot@monperrus.com>" -a
git push origin main

