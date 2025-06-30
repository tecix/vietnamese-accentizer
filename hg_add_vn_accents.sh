#!/bin/sh
MODEL="peterhung/vietnamese-accent-marker-xlm-roberta"

# Read all of stdin into TEXT
TEXT="$(cat)"

curl -sSL \
  -H "Authorization: Bearer $HF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"inputs\": \"$TEXT\"}" \
  "https://api-inference.huggingface.co/models/$MODEL"
