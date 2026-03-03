#!/bin/bash
TIMESTAMP=$(date '+%Y-%m-%d-%H:%M:%S')

track_agent() {
  local AGENT="$1"
  local URL="https://github.com/search?q=%22$AGENT%22&type=commits"
  local DIR=~/commits-agents

  mkdir -p "$DIR/html/$AGENT"
  curl -s -o "$DIR/html/$AGENT/html-${TIMESTAMP}.html" "$URL"

  COUNT=$(curl -s "https://api.github.com/search/commits?q=%22$AGENT%22&per_page=1" \
    -H "Accept: application/vnd.github.cloak-preview" \
    | tee "$DIR/data/${AGENT}_${TIMESTAMP}.json" | jq '.total_count')

  echo "$TIMESTAMP, $COUNT" >> "$DIR/${AGENT}_commits.csv"
  echo "$AGENT: $COUNT"
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

cd ~/commits-agents/
git add data/*json
git commit -m "automated commit" --author="monperrus-bot <monperrus-bot@monperrus.com>" -a
git push origin main

