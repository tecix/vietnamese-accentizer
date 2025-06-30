#!/bin/sh
# File: vn_accents_add.sh
# Usage: echo "Nhin nhung mua thu di" | ./vn_accents_add.sh

TEXT="$(cat | sed 's/"/\\"/g')"
curl -s \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"$TEXT\"}" \
  http://127.0.0.1:8111/accent \
| awk -F'"' '/accented/ {print $4}'
