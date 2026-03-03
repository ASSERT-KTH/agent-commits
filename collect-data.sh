#!/bin/bash

TIMESTAMP=$(date '+%Y-%m-%d-%H:%M:%S')

AGENT="noreply%40anthropic.com"
URL="https://github.com/search?q=%22$AGENT%22&type=commits"
mkdir -p commits/$AGENT
curl -o commits/$AGENT/html-${TIMESTAMP}.html $URL
COUNT=`curl -s "https://api.github.com/search/commits?q=%22$AGENT%22&per_page=1" \
  -H "Accept: application/vnd.github.cloak-preview" \
  | jq '.total_count'`
echo $COUNT
echo "$TIMESTAMP, $COUNT" >> ~/commits-agents/${AGENT}_commits.csv

AGENT="codex%40openai.com"
URL="https://github.com/search?q=%22$AGENT%22&type=commits"
mkdir -p commits/$AGENT
curl -o commits/$AGENT/html-${TIMESTAMP}.html $URL
COUNT=`curl -s "https://api.github.com/search/commits?q=%22$AGENT%22&per_page=1" \
  -H "Accept: application/vnd.github.cloak-preview" \
  | jq '.total_count'`
echo "$TIMESTAMP, $COUNT" >> ~/commits-agents/${AGENT}_commits.csv
