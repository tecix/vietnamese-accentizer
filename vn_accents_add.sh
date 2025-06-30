#!/bin/sh
# File: vn_accents_add.sh
# Usage: echo "Nhin nhung mua thu di" | ./vn_accents_add.sh

# --- 0. Locate script dir and optional .venv ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV="$SCRIPT_DIR/.venv"

if [ -x "$VENV/bin/python3" ]; then
  PYTHON="$VENV/bin/python3"
  PIP="$VENV/bin/pip"
else
  PYTHON="python3"
  PIP="$PYTHON -m pip"
fi

# --- 1. Download tag file if missing ---
MODEL="peterhung/vietnamese-accent-marker-xlm-roberta"
CACHE_DIR="$HOME/.cache/vn_accent"
TAG_FILE="$CACHE_DIR/selected_tags_names.txt"
TAG_URL="https://huggingface.co/${MODEL}/resolve/main/selected_tags_names.txt"

if [ ! -f "$TAG_FILE" ]; then
  mkdir -p "$CACHE_DIR"
  echo "Downloading tag definitions…"
  if command -v curl >/dev/null 2>&1; then
    curl -sL "$TAG_URL" -o "$TAG_FILE"
  else
    wget -qO "$TAG_FILE" "$TAG_URL"
  fi
fi

# --- 2. Ensure Python deps are installed ---
"$PYTHON" - <<'CHECK'
import sys
try:
    import transformers, torch, numpy
except ImportError:
    sys.exit(1)
sys.exit(0)
CHECK

if [ $? -ne 0 ]; then
  echo "Installing Python dependencies…"
  $PIP install --upgrade pip
  $PIP install transformers torch numpy
fi

# --- 3. Slurp stdin into TEXT and export for Python ---
TEXT="$(cat)"
export VN_ACCENT_TEXT="$TEXT"

# --- 4. Run the Python accent-insertion snippet ---
"$PYTHON" <<'PY3'
import os, sys, torch, numpy as np
from transformers import AutoTokenizer, AutoModelForTokenClassification

# Config
MODEL = "peterhung/vietnamese-accent-marker-xlm-roberta"
TAG_FILE = os.path.expanduser("~/.cache/vn_accent/selected_tags_names.txt")

# Get the paragraph from the env var
text = os.environ.get("VN_ACCENT_TEXT", "").strip()
if not text:
    # nothing to do
    sys.exit(0)

# Load tokenizer & model
tokenizer = AutoTokenizer.from_pretrained(MODEL, add_prefix_space=True)
model     = AutoModelForTokenClassification.from_pretrained(MODEL).eval()

# Load tag mappings
with open(TAG_FILE, encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

# Tokenize words
words   = text.split()
inputs  = tokenizer(words,
                    is_split_into_words=True,
                    padding=True,
                    truncation=True,
                    return_tensors="pt")

# Run inference
with torch.no_grad():
    logits = model(**inputs).logits.cpu().numpy()[0]

# Strip off [CLS]/[SEP]
preds    = np.argmax(logits, axis=1)[1:-1]
tokens   = tokenizer.convert_ids_to_tokens(inputs["input_ids"][0])[1:-1]

# Merge sub-tokens & apply first changing tag
out, i = [], 0
while i < len(tokens):
    tok = tokens[i]
    if tok.startswith("▁"):
        word = tok[1:]; tags = {preds[i]}; j = i+1
        while j < len(tokens) and not tokens[j].startswith("▁"):
            word += tokens[j]; tags.add(preds[j]); j += 1
        for t in tags:
            raw, acc = labels[t].split("-")
            if raw and raw in word:
                word = word.replace(raw, acc)
                break
        out.append(word); i = j
    else:
        out.append(tok); i += 1

# Emit the accented paragraph
sys.stdout.write(" ".join(out))
PY3
